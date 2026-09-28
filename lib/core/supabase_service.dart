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
}
