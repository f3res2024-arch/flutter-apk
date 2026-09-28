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
  static Future<Map<String,dynamic>?> profile() async { _requireReady(); if(currentUser==null)return null; final row=await client.from('profiles').select().eq('id',currentUser!.id).maybeSingle(); return row==null?null:Map<String,dynamic>.from(row); }
  static Future<void> updateProfile({String? fullName,String? avatarUrl}) async { _requireReady(); if(currentUser==null)throw const AuthException('يجب تسجيل الدخول أولاً.'); final v=<String,dynamic>{'updated_at':DateTime.now().toUtc().toIso8601String()}; if(fullName!=null&&fullName.trim().isNotEmpty)v['full_name']=fullName.trim(); if(avatarUrl!=null)v['avatar_url']=avatarUrl; await client.from('profiles').update(v).eq('id',currentUser!.id); }
  static Future<List<Map<String,dynamic>>> appContent() async { _requireReady(); final rows=await client.from('app_content').select().order('key'); return List<Map<String,dynamic>>.from(rows); }
  static Future<void> updateAppContent(String key,String value) async { _requireReady(); if(await currentUserRole()!='admin')throw const AuthException('هذه الصلاحية للمالك فقط.'); await client.from('app_content').upsert({'key':key,'text_value':value,'updated_at':DateTime.now().toUtc().toIso8601String()},onConflict:'key'); }
  static Future<void> updateRestaurant(String id,{String? name,String? description}) async { _requireReady(); if(await currentUserRole()!='admin')throw const AuthException('هذه الصلاحية للمالك فقط.'); final v=<String,dynamic>{'updated_at':DateTime.now().toUtc().toIso8601String()}; if(name!=null)v['name']=name;if(description!=null)v['description']=description; await client.from('restaurants').update(v).eq('id',id); }
  static Future<void> updateMenuItem(String id,{String? name,double? price,String? description}) async { _requireReady(); if(await currentUserRole()!='admin')throw const AuthException('هذه الصلاحية للمالك فقط.'); final v=<String,dynamic>{'updated_at':DateTime.now().toUtc().toIso8601String()}; if(name!=null)v['name']=name;if(price!=null)v['price']=price;if(description!=null)v['description']=description; await client.from('menu_items').update(v).eq('id',id); }
  static Future<void> addMenuItem(String restaurantId,{required String name,required double price,String description=''}) async { _requireReady(); if(await currentUserRole()!='admin')throw const AuthException('هذه الصلاحية للمالك فقط.'); await client.from('menu_items').insert({'restaurant_id':restaurantId,'name':name,'description':description,'price':price,'is_available':true}); }

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

  static Future<List<Map<String, dynamic>>> addresses() async {
    _requireReady();
    if (currentUser == null) return [];
    final rows = await client.from('addresses').select().eq('user_id', currentUser!.id).order('is_default', ascending: false).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<Map<String, dynamic>> createAddress({
    required String label,
    required String address,
    double? lat,
    double? lng,
    bool isDefault = true,
  }) async {
    _requireReady();
    if (currentUser == null) throw const AuthException('يجب تسجيل الدخول أولاً.');
    if (isDefault) {
      await client.from('addresses').update({'is_default': false}).eq('user_id', currentUser!.id);
    }
    final row = await client.from('addresses').insert({
      'user_id': currentUser!.id,
      'label': label,
      'address': address,
      'lat': lat,
      'lng': lng,
      'is_default': isDefault,
    }).select().single();
    return Map<String, dynamic>.from(row);
  }

  static Future<String> createCustomerOrder({
    required String restaurantName,
    required List<Map<String, dynamic>> items,
    required String addressId,
    String paymentMethod = 'cash',
    String notes = '',
  }) async {
    _requireReady();
    if (currentUser == null) throw const AuthException('يجب تسجيل الدخول أولاً.');
    final restaurant = await client.from('restaurants').select('id').eq('name', restaurantName).eq('is_active', true).maybeSingle();
    if (restaurant == null) throw const AuthException('المطعم غير متاح حالياً.');
    final normalized = <Map<String, dynamic>>[];
    for (final item in items) {
      final menu = await client.from('menu_items')
          .select('id')
          .eq('restaurant_id', restaurant['id'])
          .eq('name', item['name'])
          .eq('is_available', true)
          .maybeSingle();
      if (menu == null) throw AuthException('الصنف ${item['name']} غير متاح حالياً.');
      normalized.add({
        'menu_item_id': menu['id'],
        'quantity': item['quantity'],
      });
    }
    final key = '${currentUser!.id}-${DateTime.now().microsecondsSinceEpoch}';
    final result = await client.rpc('create_customer_order', params: {
      'p_restaurant_id': restaurant['id'],
      'p_items': normalized,
      'p_address_id': addressId,
      'p_payment_method': paymentMethod,
      'p_notes': notes,
      'p_idempotency_key': key,
    });
    return result.toString();
  }

  static Future<List<Map<String, dynamic>>> customerOrders() async {
    _requireReady();
    if (currentUser == null) return [];
    final rows = await client.from('orders').select('*, order_items(*)').eq('customer_id', currentUser!.id).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static RealtimeChannel watchCustomerOrders(Future<void> Function() onChanged) {
    final channel = client.channel('nova-customer-orders');
    channel.onPostgresChanges(
      event: PostgresChangeEvent.all,
      schema: 'public',
      table: 'orders',
      callback: (_) => onChanged(),
    ).subscribe();
    return channel;
  }

  static Future<List<Map<String, dynamic>>> notifications() async {
    _requireReady();
    if (currentUser == null) return [];
    final rows = await client.from('notifications').select().eq('user_id', currentUser!.id).order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  static Future<void> markNotificationRead(String id) async {
    _requireReady();
    if (currentUser == null) return;
    await client.from('notifications').update({'is_read': true}).eq('id', id).eq('user_id', currentUser!.id);
  }

  static void _requireReady() {
    if (!_initialized) {
      final error = _initializationError;
      if (error is AuthException) throw error;
      throw const AuthException('خدمة الحساب غير مهيأة حالياً. حاول مرة أخرى.');
    }
  }
}