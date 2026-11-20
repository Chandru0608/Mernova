import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config.dart';

class Api {
  static String? token;
  static Map<String,String> get headers => {
    'Content-Type':'application/json',
    if (token != null) 'Authorization':'Bearer $token',
  };
  static Future<void> loadToken() async {
    final p = await SharedPreferences.getInstance();
    token = p.getString('token');
  }
  static Future<void> saveToken(String value) async {
    token = value;
    final p = await SharedPreferences.getInstance();
    await p.setString('token', value);
  }
  static Future<void> logout() async {
    token = null;
    final p = await SharedPreferences.getInstance();
    await p.remove('token');
  }
  static Future<Map<String,dynamic>> post(String path, Map<String,dynamic> body) async {
    final r = await http.post(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: headers, body: jsonEncode(body));
    final data = jsonDecode(r.body) as Map<String,dynamic>;
    if (r.statusCode >= 400) throw Exception(data['message'] ?? 'Request failed');
    return data;
  }
  static Future<Map<String,dynamic>> get(String path) async {
    final r = await http.get(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: headers);
    final data = jsonDecode(r.body) as Map<String,dynamic>;
    if (r.statusCode >= 400) throw Exception(data['message'] ?? 'Request failed');
    return data;
  }
}
