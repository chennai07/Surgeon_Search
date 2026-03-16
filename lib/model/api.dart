// 🧩 LOGIN API
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

Future<Map<String, dynamic>> loginUser({
  required String email,
  required String password,
}) async {
  try {
    dynamic baseUrl;
    final uri = Uri.parse('$baseUrl/login');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    debugPrint('📩 Login Response (${response.statusCode}): ${response.body}');

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = jsonDecode(response.body);

      final token = data['token'];
      final expiresIn = data['expiresIn'] ?? 7200; // seconds (default 2h)

      if (token != null) {
        final prefs = await SharedPreferences.getInstance();

        // 🧠 Save token + expiry timestamp
        final expiryTime = DateTime.now()
            .add(Duration(seconds: expiresIn))
            .millisecondsSinceEpoch;

        await prefs.setString('token', token);
        await prefs.setInt('token_expiry', expiryTime);

        debugPrint('🔐 Token saved, expires in ${expiresIn ~/ 60} minutes.');

        return {'success': true, 'data': data};
      } else {
        return {'success': false, 'message': 'Token missing from response'};
      }
    } else {
      final err = jsonDecode(response.body);
      return {
        'success': false,
        'message': err['message'] ?? 'Invalid credentials',
      };
    }
  } catch (e) {
    debugPrint('🚨 Login error: $e');
    return {'success': false, 'message': e.toString()};
  }
}
