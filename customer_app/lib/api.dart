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
  static Map<String,dynamic> _decode(http.Response r) {
    final body=r.body.trim();
    try {
      final decoded=jsonDecode(body);
      if(decoded is Map<String,dynamic>) {
        if(r.statusCode>=400) throw Exception(decoded['message']??'Request failed (HTTP ${r.statusCode})');
        return decoded;
      }
      throw Exception('Unexpected API response (HTTP ${r.statusCode}).');
    } on FormatException {
      final preview=body.length>160?body.substring(0,160):body;
      throw Exception('API returned non-JSON content (HTTP ${r.statusCode}). Check that the QuickDeliver backend is running on port 5000 and restart it after pulling updates. Response: $preview');
    }
  }
  static Future<Map<String,dynamic>> post(String path, Map<String,dynamic> body) async {
    final r = await http.post(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: headers, body: jsonEncode(body));
    return _decode(r);
  }
  static Future<Map<String,dynamic>> patch(String path, Map<String,dynamic> body) async {
    final r = await http.patch(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: headers, body: jsonEncode(body));
    return _decode(r);
  }
  static Future<Map<String,dynamic>> get(String path) async {
    final r = await http.get(Uri.parse('${AppConfig.apiBaseUrl}$path'), headers: headers);
    return _decode(r);
  }
}
