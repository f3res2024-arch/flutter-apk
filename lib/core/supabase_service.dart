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
    String? fullName,
    String? phone,
  }) async {
    _requireReady();
    return client.auth.signUp(
      email: email.trim(),
      password: password,
      emailRedirectTo: authRedirectUrl,
      data: {
        'requested_role': role,
        'full_name': (fullName==null||fullName.trim().isEmpty) ? email.trim().split('@').first : fullName.trim(),
        'phone': (phone==null||phone.trim().isEmpty) ? null : phone.trim(),
      },
    );
  }

  static Future<AuthResponse> verifyEmailOtp({
    required String email,
    required String token,
  }) async {
    _requireReady();
    return client.auth.verifyOTP(
      email: email.trim(),
      token: token.trim(),
      type: OtpType.email,
    );
  }

  static Future<void> resendSignupOtp(String email) async {
    _requireReady();
    await client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
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
  static Future<void> updateRestaurant(String id,{String? name,String? description,String? logoUrl,String? coverUrl}) async { _requireReady(); if(await currentUserRole()!='admin')throw const AuthException('هذه الصلاحية للمالك فقط.'); final v=<String,dynamic>{'updated_at':DateTime.now().toUtc().toIso8601String()}; if(name!=null)v['name']=name;if(description!=null)v['description']=description;if(logoUrl!=null)v['logo_url']=logoUrl;if(coverUrl!=null)v['cover_url']=coverUrl; await client.from('restaurants').update(v).eq('id',id); }
  static Future<void> updateMenuItem(String id,{String? name,double? price,String? description,String? imageUrl}) async { _requireReady(); if(await currentUserRole()!='admin')throw const AuthException('هذه الصلاحية للمالك فقط.'); final v=<String,dynamic>{'updated_at':DateTime.now().toUtc().toIso8601String()}; if(name!=null)v['name']=name;if(price!=null)v['price']=price;if(description!=null)v['description']=description;if(imageUrl!=null)v['image_url']=imageUrl; await client.from('menu_items').update(v).eq('id',id); }
  static Future<void> addMenuItem(String restaurantId,{required String name,required double price,String description=''}) async { _requireReady(); if(await currentUserRole()!='admin')throw const AuthException('هذه الصلاحية للمالك فقط.'); await client.from('menu_items').insert({'restaurant_id':restaurantId,'name':name,'description':description,'price':price,'is_available':true}); }

  static Future<String?> uploadMenuImage(String itemId, Uint8List bytes) async {
    _requireReady();
    if(await currentUserRole()!='admin')throw const AuthException('هذه الصلاحية للمالك فقط.');
    final path='menu/'+itemId+'/'+DateTime.now().millisecondsSinceEpoch.toString()+'.jpg';
    await client.storage.from('nova-media').uploadBinary(path,bytes,fileOptions:const FileOptions(contentType:'image/jpeg'));
    return client.storage.from('nova-media').getPublicUrl(path);
  }
  static Future<String?> uploadContentImage(String key, Uint8List bytes) async {
    _requireReady();
    if(await currentUserRole()!='admin')throw const AuthException('هذه الصلاحية للمالك فقط.');
    final path='content/'+key+'/'+DateTime.now().millisecondsSinceEpoch.toString()+'.jpg';
    await client.storage.from('nova-media').uploadBinary(path,bytes,fileOptions:const FileOptions(contentType:'image/jpeg'));
    return client.storage.from('nova-media').getPublicUrl(path);
  }
  static Future<void> updateAppContentImage(String key,String url) async {
    _requireReady();
    if(await currentUserRole()!='admin')throw const AuthException('هذه الصلاحية للمالك فقط.');
    await client.from('app_content').upsert({'key':key,'image_url':url,'updated_at':DateTime.now().toUtc().toIso8601String()},onConflict:'key');
  }

  static Future<String?> uploadAvatar(String userId, Uint8List bytes) async {
    if (!_initialized) return null;
    if(currentUser==null || currentUser!.id!=userId) throw const AuthException('لا يمكنك تعديل صورة حساب مستخدم آخر.');
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

  static Future<List<Map<String,dynamic>>> catalog() async {
    _requireReady();
    final rs=await client.from('restaurants').select('id,name,description,logo_url,cover_url,rating').eq('is_active',true).order('name');
    final out=<Map<String,dynamic>>[];
    for(final raw in (rs as List)){
      final r=Map<String,dynamic>.from(raw as Map);
      final id=r['id'].toString();
      final bs=await client.from('branches').select('name,address,lat,lng,phone').eq('restaurant_id',id).eq('is_open',true).limit(10);
      final ms=await client.from('menu_items').select('name,description,image_url,price,sort_order').eq('restaurant_id',id).eq('is_available',true).order('sort_order');
      final branches=(bs as List).map((b)=>((b['name']??'')+' — '+(b['address']??'')).toString()).toList();
      final first=(bs as List).isNotEmpty?Map<String,dynamic>.from((bs as List).first as Map):<String,dynamic>{};
      r['address']=(first['address']??'').toString();
      r['lat']=(first['lat'] as num?)?.toDouble();
      r['lng']=(first['lng'] as num?)?.toDouble();
      r['branches']=branches;
      r['menu']=List<Map<String,dynamic>>.from((ms as List).map((m)=>Map<String,dynamic>.from(m as Map)));
      r['reviews']=0;
      out.add(r);
    }
    return out;
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

  static Future<String> createRestaurant({required String name, String description='', String phone='', double deliveryFee=0, double minOrder=0}) async {
    _requireReady();
    if(await currentUserRole()!='admin') throw const AuthException('هذه الصلاحية للمالك فقط.');
    final row=await client.from('restaurants').insert({'name':name.trim(),'description':description.trim(),'phone':phone.trim(),'delivery_fee':deliveryFee,'min_order':minOrder,'is_active':true}).select('id').single();
    return row['id'].toString();
  }
  static Future<void> deleteRestaurant(String id) async {
    _requireReady();
    if(await currentUserRole()!='admin') throw const AuthException('هذه الصلاحية للمالك فقط.');
    await client.from('restaurants').update({'is_active':false,'updated_at':DateTime.now().toUtc().toIso8601String()}).eq('id',id);
  }
  static Future<List<Map<String,dynamic>>> allRestaurantMenu(String restaurantId) async {
    _requireReady();
    if(await currentUserRole()!='admin') throw const AuthException('هذه الصلاحية للمالك فقط.');
    final rows=await client.from('menu_items').select('*, menu_categories(name)').eq('restaurant_id',restaurantId).order('sort_order');
    return List<Map<String,dynamic>>.from(rows);
  }
  static Future<void> setMenuItemAvailability(String id,bool available) async {
    _requireReady();
    if(await currentUserRole()!='admin') throw const AuthException('هذه الصلاحية للمالك فقط.');
    await client.from('menu_items').update({'is_available':available,'updated_at':DateTime.now().toUtc().toIso8601String()}).eq('id',id);
  }
  static Future<void> addMenuItemFull(String restaurantId,{required String name,required double price,String description='',String? imageUrl,String? categoryId}) async {
    _requireReady();
    if(await currentUserRole()!='admin') throw const AuthException('هذه الصلاحية للمالك فقط.');
    await client.from('menu_items').insert({'restaurant_id':restaurantId,'name':name.trim(),'description':description.trim(),'price':price,'image_url':imageUrl,'category_id':categoryId,'is_available':true});
  }
  static Future<List<Map<String,dynamic>>> ownerCoupons() async {
    _requireReady();
    if(await currentUserRole()!='admin') throw const AuthException('هذه الصلاحية للمالك فقط.');
    final rows=await client.from('coupons').select().order('created_at',ascending:false);
    return List<Map<String,dynamic>>.from(rows);
  }
  static Future<String> createCoupon({required String code,required String title,required String discountType,required double discountValue,double minOrder=0,double? maxDiscount,int? usageLimit,DateTime? startsAt,DateTime? endsAt,String description=''}) async {
    _requireReady();
    if(await currentUserRole()!='admin') throw const AuthException('هذه الصلاحية للمالك فقط.');
    final row=await client.from('coupons').insert({'code':code.trim().toUpperCase(),'title':title.trim(),'description':description.trim(),'discount_type':discountType,'discount_value':discountValue,'min_order':minOrder,'max_discount':maxDiscount,'usage_limit':usageLimit,'starts_at':(startsAt??DateTime.now()).toUtc().toIso8601String(),'ends_at':endsAt?.toUtc().toIso8601String(),'is_active':true}).select('id').single();
    return row['id'].toString();
  }
  static Future<void> updateCoupon(String id,Map<String,dynamic> values) async {
    _requireReady();
    if(await currentUserRole()!='admin') throw const AuthException('هذه الصلاحية للمالك فقط.');
    values['updated_at']=DateTime.now().toUtc().toIso8601String();
    await client.from('coupons').update(values).eq('id',id);
  }
  static Future<List<Map<String,dynamic>>> ownerOffers() async {
    _requireReady();
    if(await currentUserRole()!='admin') throw const AuthException('هذه الصلاحية للمالك فقط.');
    final rows=await client.from('offers').select('*, coupons(code,title)').order('sort_order').order('created_at',ascending:false);
    return List<Map<String,dynamic>>.from(rows);
  }
  static Future<String> createOffer({required String title,String subtitle='',String? imageUrl,String? couponId,int sortOrder=0}) async {
    _requireReady();
    if(await currentUserRole()!='admin') throw const AuthException('هذه الصلاحية للمالك فقط.');
    final row=await client.from('offers').insert({'title':title.trim(),'subtitle':subtitle.trim(),'image_url':imageUrl,'coupon_id':couponId,'sort_order':sortOrder,'is_active':true}).select('id').single();
    return row['id'].toString();
  }
  static Future<void> updateOffer(String id,Map<String,dynamic> values) async {
    _requireReady();
    if(await currentUserRole()!='admin') throw const AuthException('هذه الصلاحية للمالك فقط.');
    values['updated_at']=DateTime.now().toUtc().toIso8601String();
    await client.from('offers').update(values).eq('id',id);
  }
  static Future<String?> uploadOfferImage(String offerId, Uint8List bytes) async {
    _requireReady();
    if(await currentUserRole()!='admin') throw const AuthException('هذه الصلاحية للمالك فقط.');
    final path='content/offers/'+offerId+'/'+DateTime.now().millisecondsSinceEpoch.toString()+'.jpg';
    await client.storage.from('nova-media').uploadBinary(path,bytes,fileOptions:const FileOptions(contentType:'image/jpeg'));
    return client.storage.from('nova-media').getPublicUrl(path);
  }
  static Future<String?> uploadRestaurantCover(String restaurantId, Uint8List bytes) async {
    _requireReady();
    if(await currentUserRole()!='admin') throw const AuthException('هذه الصلاحية للمالك فقط.');
    final path='restaurants/'+restaurantId+'/cover-'+DateTime.now().millisecondsSinceEpoch.toString()+'.jpg';
    await client.storage.from('nova-media').uploadBinary(path,bytes,fileOptions:const FileOptions(contentType:'image/jpeg'));
    return client.storage.from('nova-media').getPublicUrl(path);
  }
  static void _requireReady() {
    if (!_initialized) {
      final error = _initializationError;
      if (error is AuthException) throw error;
      throw const AuthException('خدمة الحساب غير مهيأة حالياً. حاول مرة أخرى.');
    }
  }
}