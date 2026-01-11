import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static String _baseUrl = 'http://localhost:3000';
  static String? _userId;

  static Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString('api_url') ?? 'http://localhost:3000';
    _userId = prefs.getString('user_id');
  }

  static Future<void> setApiUrl(String url) async {
    _baseUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_url', url);
  }

  static Future<void> setUserId(String id) async {
    _userId = id;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_id', id);
  }

  static String? get userId => _userId;
  static String get apiUrl => _baseUrl;

  static Future<Map<String, dynamic>?> getStats({String? startDate, String? endDate}) async {
    if (_userId == null) return null;
    
    try {
      var url = '$_baseUrl/api/stats/$_userId';
      final params = <String>[];
      if (startDate != null) params.add('startDate=$startDate');
      if (endDate != null) params.add('endDate=$endDate');
      if (params.isNotEmpty) url += '?${params.join('&')}';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('API Error: $e');
    }
    return null;
  }

  static Future<Map<String, dynamic>?> getData({String? startDate, String? endDate}) async {
    if (_userId == null) return null;
    
    try {
      var url = '$_baseUrl/api/data/$_userId';
      final params = <String>[];
      if (startDate != null) params.add('startDate=$startDate');
      if (endDate != null) params.add('endDate=$endDate');
      if (params.isNotEmpty) url += '?${params.join('&')}';
      
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        return json.decode(response.body);
      }
    } catch (e) {
      print('API Error: $e');
    }
    return null;
  }
}
