import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class NovaSupabase {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static bool get configured => url.isNotEmpty && key.isNotEmpty;
  static SupabaseClient get client => Supabase.instance.client;

  static Future<void> initialize() async {
    if (!configured) return;
    await Supabase.initialize(url: url, publishableKey: key);
  }

  static const authRedirectUrl = 'nova://auth-callback';

  static Future<AuthResponse> signIn({required String email, required String password}) async {
    if (!configured) throw const AuthException('خدمة الحساب غير مهيأة بعد.');
    return client.auth.signInWithPassword(email: email.trim(), password: password);
  }

  static Future<AuthResponse> signUp({required String email, required String password, required String role}) async {
    if (!configured) throw const AuthException('خدمة الحساب غير مهيأة بعد.');
    final response = await client.auth.signUp(email: email.trim(), password: password, emailRedirectTo: authRedirectUrl, data: {'role': role});
    if (response.user != null) { try { await setUserRole(response.user!.id, role); } catch (_) {} }
    return response;
  }

  static Future<void> sendPasswordReset(String email) async {
    if (!configured) throw const AuthException('خدمة الحساب غير مهيأة بعد.');
    await client.auth.resetPasswordForEmail(email.trim(), redirectTo: authRedirectUrl);
  }

  static Future<void> updatePassword(String password) async {
    if (!configured) throw const AuthException('خدمة الحساب غير مهيأة بعد.');
    await client.auth.updateUser(UserAttributes(password: password));
  }

  static Future<void> signInWithGoogle() async {
    if (!configured) throw const AuthException('خدمة الحساب غير مهيأة بعد.');
    await client.auth.signInWithOAuth(OAuthProvider.google, redirectTo: authRedirectUrl);
  }

  static Future<String?> currentUserRole() async {
    if (!configured || client.auth.currentUser == null) return null;
    final row = await client.from('profiles').select('role').eq('id', client.auth.currentUser!.id).maybeSingle();
    return row?['role']?.toString();
  }

  static Future<String?> uploadAvatar(String userId, Uint8List bytes) async {
    if (!configured) return null;
    final path = 'avatars/$userId/avatar.jpg';
    await client.storage.from('nova-media').uploadBinary(
      path, bytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );
    return client.storage.from('nova-media').getPublicUrl(path);
  }

  static Future<String?> uploadRestaurantImage(String restaurantId, Uint8List bytes) async {
    if (!configured) return null;
    final path = 'restaurants/$restaurantId/' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
    await client.storage.from('nova-media').uploadBinary(
      path, bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );
    return client.storage.from('nova-media').getPublicUrl(path);
  }

  static Future<List<Map<String, dynamic>>> restaurants() async {
    if (!configured) return [];
    final rows = await client.from('restaurants').select().eq('is_active', true).order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<List<Map<String, dynamic>>> restaurantMenu(String restaurantId) async {
    if (!configured) return [];
    final rows = await client.from('menu_items').select().eq('restaurant_id', restaurantId).eq('is_available', true).order('sort_order');
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> setUserRole(String userId, String role) async {
    if (!configured) return;
    await client.from('profiles').upsert({'id': userId, 'role': role});
  }

  static Future<List<Map<String, dynamic>>> courierOrders() async {
    if (!configured || client.auth.currentUser == null) return [];
    final userId = client.auth.currentUser!.id;
    final rejectedRows = await client
        .from('order_rejections')
        .select('order_id')
        .eq('courier_id', userId);
    final rejectedIds = Set<String>.from(
      (rejectedRows as List).map((row) => row['order_id'].toString()),
    );

    final rows = await client
        .from('orders')
        .select('*, order_items(*)')
        .eq('status', 'pending')
        .filter('courier_id', 'is', 'null')
        .order('created_at', ascending: false);

    return List<Map<String, dynamic>>.from(rows)
        .where((row) => !rejectedIds.contains(row['id'].toString()))
        .toList();
  }

  static RealtimeChannel watchCourierOrders(
    Future<void> Function() onChanged,
  ) {
    final channel = client.channel('nova-courier-orders');
    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'orders',
          callback: (_) => onChanged(),
        )
        .subscribe();
    return channel;
  }

  static Future<Map<String, dynamic>?> claimOrder(String orderId) async {
    if (!configured || client.auth.currentUser == null) return null;
    final result = await client.rpc(
      'claim_order',
      params: {'p_order_id': orderId},
    );
    if (result is Map<String, dynamic>) return result;
    if (result is List && result.isNotEmpty && result.first is Map) {
      return Map<String, dynamic>.from(result.first as Map);
    }
    return null;
  }

  static Future<void> rejectOrder(String orderId) async {
    if (!configured || client.auth.currentUser == null) return;
    await client.rpc(
      'reject_order',
      params: {'p_order_id': orderId},
    );
  }

  static Future<void> updateCourierLocation(
    String orderId,
    double lat,
    double lng,
  ) async {
    if (!configured || client.auth.currentUser == null) return;
    await client
        .from('orders')
        .update({
          'courier_lat': lat,
          'courier_lng': lng,
          'updated_at': DateTime.now().toUtc().toIso8601String(),
        })
        .eq('id', orderId)
        .eq('courier_id', client.auth.currentUser!.id);
  }
}
