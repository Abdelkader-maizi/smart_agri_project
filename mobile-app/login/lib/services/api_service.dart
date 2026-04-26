import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
// Note: You can create models for these later if needed, but Maps work fine for simple parsing.

class ApiService {
  static const String baseUrl = 'http://192.168.1.41:5000/api';

  Future<Map<String, String>> _headers() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // --- Auth Methods ---
  
  Future<Map<String, dynamic>> login(String identifier, String password) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/login'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': identifier.contains('@') ? identifier : null,
        'phone': !identifier.contains('@') ? identifier : null,
        'password': password,
      }),
    );

    final data = jsonDecode(response.body);

    if (response.statusCode == 200 && data['success'] == true) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('jwt_token', data['token']);
      await prefs.setInt('user_id', data['user']['id']);
      return {'success': true, 'user': UserModel.fromJson(data['user'])};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Login failed'};
    }
  }

  Future<Map<String, dynamic>> register({
    required String name,
    required String phone,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/auth/register'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'phone': phone,
        'email': email,
        'password': password,
      }),
    );
    final data = jsonDecode(response.body);
    if (response.statusCode == 201 && data['success'] == true) {
      return {'success': true, 'user': UserModel.fromJson(data['user'])};
    } else {
      return {'success': false, 'error': data['error'] ?? 'Registration failed'};
    }
  }

  // --- Farms Methods ---
  
  Future<Map<String, dynamic>> getFarms() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/farms'), headers: await _headers());
      return jsonDecode(response.body);
    } catch(e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addFarm(String name, String city, double lat, double lon) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/farms'),
        headers: await _headers(),
        body: jsonEncode({'name': name, 'city': city, 'latitude': lat, 'longitude': lon}),
      );
      return jsonDecode(response.body);
    } catch(e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteFarm(int id) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/farms/$id'), headers: await _headers());
      return jsonDecode(response.body);
    } catch(e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- Weather Methods ---

  Future<Map<String, dynamic>> getWeather(int? farmId, double? lat, double? lon) async {
    try {
      String path = '$baseUrl/weather?';
      if (farmId != null) path += 'farm_id=$farmId';
      else if (lat != null && lon != null) path += 'lat=$lat&lon=$lon';
      
      final response = await http.get(Uri.parse(path), headers: await _headers());
      return jsonDecode(response.body);
    } catch(e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- Guides Methods ---

  Future<Map<String, dynamic>> getFertilizers() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/guides/fertilizers'), headers: await _headers());
      return jsonDecode(response.body);
    } catch(e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> getPlantingCalendar() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/guides/planting-calendar'), headers: await _headers());
      return jsonDecode(response.body);
    } catch(e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- Logbook Methods ---

  Future<Map<String, dynamic>> getLogbook() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/logbook'), headers: await _headers());
      return jsonDecode(response.body);
    } catch(e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> addLog(String id, int farmId, String activityType, String desc) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/logbook'),
        headers: await _headers(),
        body: jsonEncode({
          'id': id,
          'farm_id': farmId,
          'activity_type': activityType,
          'description': desc,
        }),
      );
      return jsonDecode(response.body);
    } catch(e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- Predict & Yield Methods ---

  Future<Map<String, dynamic>> getYieldPrediction(Map<String, dynamic> payload) async {
    // Expected payload: farm_id, crop_name, season, nitrogen, phosphorus, potassium, ph, farm_area_hectares
    // The backend auto-fetches weather given farm_id
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/yield'),
        headers: await _headers(),
        body: jsonEncode(payload),
      );
      return jsonDecode(response.body);
    } catch(e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- Irrigation Methods ---

  Future<Map<String, dynamic>> getIrrigation(Map<String, dynamic> payload) async {
    // Expected payload: farm_id, crop_name, water_need, soil_type, farm_area_hectares
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/irrigation'),
        headers: await _headers(),
        body: jsonEncode(payload),
      );
      return jsonDecode(response.body);
    } catch(e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- Chat Methods ---
  
  Future<Map<String, dynamic>> sendChatMessage(String message) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/chat'),
        headers: await _headers(),
        body: jsonEncode({'message': message}),
      );
      return jsonDecode(response.body);
    } catch(e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // --- Helper Methods ---
  
  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
    await prefs.remove('user_id');
  }
}
