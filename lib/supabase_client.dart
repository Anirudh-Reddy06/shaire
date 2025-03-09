import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseClient {
  static final client = Supabase.instance.client;

  static Future<PostgrestList> getData(String tableName) async {
    final response = await client.from(tableName).select('*');
    return response;
  }

  static Future<PostgrestResponse> insertData(String tableName, Map<String, dynamic> data) async {
    final response = await client.from(tableName).insert([data]);
    return response;
  }

  static Future<PostgrestResponse> updateData(String tableName, Map<String, dynamic> data, String column, dynamic value) async {
    final response = await client.from(tableName).update(data).eq(column, value);
    return response;
  }

  static Future<PostgrestResponse> deleteData(String tableName, String column, dynamic value) async {
    final response = await client.from(tableName).delete().eq(column, value);
    return response;
  }

  static Stream<PostgrestList> streamData(String tableName, List<String> primaryKey) {
    return client.from(tableName).stream(primaryKey: primaryKey);
  }
}
