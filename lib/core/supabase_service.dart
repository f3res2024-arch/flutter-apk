import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';

class NovaSupabase {
  static const url = String.fromEnvironment('SUPABASE_URL');
  static const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  static const authRedirectUrl = 'nova://auth-callback';

  static bool _initialized = false;
  static Object? _initializationError;

  static bool get configured => url.isNotEmpty && key.isNotEmpty;
  static bool get initialized => _initialized;
  static Object? get initializationError => _initializationError;

  static SupabaseClient get client {
    if (!_initialized) {
      throw const AuthException('خدمة الحساب غير مهيأة. أعد فتح التطبيق بعد التأكد من إعدادات الخادم.');
    }
    return Supabase.instance.client;
  }

  static Future<void> initialize() async {
    if (_initialized) return;
    if (!configured) {
      _initializationError = const AuthException('إعدادات الخادم غير موجودة في نسخة التطبيق.');
      return;
    }
    try {
      await Supabase.initialize(
        url: url,
        publishableKey: key,
        authOptions: const FlutterAuthClientOptions(
          autoRefreshToken: true,
          detectSessionInUri: true,
        ),
      );
      _initialized = true;
      _initializationError = null;
    } catch (error) {
      _initializationError = error;
      rethrow;
    }
  }

  static Session? get session =>
      _initialized ? Supabase.instance.client.auth.currentSession : null;

  static User? get currentUser =>
      _initialized ? Supabase.instance.client.auth.currentUser : null;

  static Stream<AuthState> get authStateChanges =>
      _initialized ? client.auth.onAuthStateChange : const Stream<AuthState>.empty();

  static Future<void> signOut() async {
    if (_initialized) await client.auth.signOut();
  }

  static Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    _requireReady();
    return client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  static Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String role,
  }) async {
    _requireReady();
    return client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: authRedirectUrl,
      data: {
        'requested_role': role,
        'full_name': email.trim().split('@').first,
      },
    );
  }

  static Future<void> sendPasswordReset(String email) async {
    _requireReady();
    await client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: authRedirectUrl,
    );
  }

  static Future<void> updatePassword(String password) async {
    _requireReady();
    await client.auth.updateUser(UserAttributes(password: password));
  }

  static Future<void> signInWithGoogle() async {
    _requireReady();
    await client.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: authRedirectUrl,
    );
  }

  static Future<String?> currentUserRole() async {
    if (!_initialized || currentUser == null) return null;
    final row = await client.from('profiles').select('role').eq('id', currentUser!.id).maybeSingle();
    return row?['role']?.toString();
  }

  static Future<String?> uploadAvatar(String userId, Uint8List bytes) async {
    if (!_initialized) return null;
    final path = 'avatars/' + userId + '/avatar.jpg';
    await client.storage.from('nova-media').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(upsert: true, contentType: 'image/jpeg'),
    );
    return client.storage.from('nova-media').getPublicUrl(path);
  }

  static Future<String?> uploadRestaurantImage(String restaurantId, Uint8List bytes) async {
    if (!_initialized) return null;
    final path = 'restaurants/' + restaurantId + '/' + DateTime.now().millisecondsSinceEpoch.toString() + '.jpg';
    await client.storage.from('nova-media').uploadBinary(
      path,
      bytes,
      fileOptions: const FileOptions(contentType: 'image/jpeg'),
    );
    return client.storage.from('nova-media').getPublicUrl(path);
  }

  static Future<List<Map<String, dynamic>>> restaurants() async {
    if (!_initialized) return [];
    final rows = await client.from('restaurants').select().eq('is_active', true).order('name');
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<List<Map<String, dynamic>>> restaurantMenu(String restaurantId) async {
    if (!_initialized) return [];
    final rows = await client.from('menu_items').select().eq('restaurant_id', restaurantId).eq('is_available', true).order('sort_order');
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<List<Map<String, dynamic>>> courierOrders() async {
    if (!_initialized || currentUser == null) return [];
    final rejectedRows = await client.from('order_rejections').select('order_id').eq('courier_id', currentUser!.id);
    final rejectedIds = Set<String>.from((rejectedRows as List).map((row) => row['order_id'].toString()));
    final rows = await client.from('orders').select('*, order_items(*)').eq('status', 'pending').filter('courier_id', 'is', 'null').order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows).where((row) => !rejectedIds.contains(row['id'].toString())).toList();
  }

  static RealtimeChannel watchCourierOrders(Future<void> Function() onChanged) {
    final channel = client.channel('nova-courier-orders');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'orders',
      callback: (_) => onChanged(),
    ).subscribe();
    return channel;
  }

  static Future<Map<String, dynamic>?> claimOrder(String orderId) async {
    _requireReady();
    if (currentUser == null) return null;
    final result = await client.rpc('claim_order', params: {'p_order_id': orderId});
    if (result is Map<String, dynamic>) return result;
    if (result is List && result.isNotEmpty && result.first is Map) return Map<String, dynamic>.from(result.first as Map);
    return null;
  }

  static Future<void> rejectOrder(String orderId) async {
    _requireReady();
    if (currentUser == null) return;
    await client.rpc('reject_order', params: {'p_order_id': orderId});
  }

  static Future<void> updateCourierLocation(String orderId, double lat, double lng) async {
    _requireReady();
    if (currentUser == null) return;
    await client.from('orders').update({
      'courier_lat': lat,
      'courier_lng': lng,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }).eq('id', orderId).eq('courier_id', currentUser!.id);
  }

  static void _requireReady() {
    if (!_initialized) {
      final error = _initializationError;
      if (error is AuthException) throw error;
      throw const AuthException('خدمة الحساب غير مهيأة حالياً. حاول مرة أخرى.');
    }
  }
}