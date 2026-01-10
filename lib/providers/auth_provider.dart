import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  final ApiService _apiService = ApiService();

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.post('/users/sign_in', {
        'user': {'email': email, 'password': password}
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data);
        _isAuthenticated = true;
        
        // Store token if provided
        final prefs = await SharedPreferences.getInstance();
        // Extract token from response headers if available
        final authHeader = response.headers['authorization'];
        if (authHeader != null) {
          final token = authHeader.replaceFirst('Bearer ', '');
          await prefs.setString('auth_token', token);
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Login error: $e');
      return false;
    }
  }

  Future<bool> register(String email, String password) async {
    try {
      final response = await _apiService.post('/users', {
        'user': {'email': email, 'password': password}
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data);
        _isAuthenticated = true;
        
        // Store token if provided (same as login)
        final prefs = await SharedPreferences.getInstance();
        // Extract token from response headers if available
        final authHeader = response.headers['authorization'];
        if (authHeader != null) {
          final token = authHeader.replaceFirst('Bearer ', '');
          await prefs.setString('auth_token', token);
          notifyListeners();
          return true;
        } else {
          // If no token in registration response, automatically sign in to get token
          final loginSuccess = await login(email, password);
          if (!loginSuccess) {
            // If auto-login fails, still keep user authenticated but log warning
            debugPrint('Registration succeeded but auto-login failed');
            // User is already authenticated from registration, just notify
            notifyListeners();
          }
          // Return true since registration succeeded (user is authenticated)
          return true;
        }
      }
      return false;
    } catch (e) {
      debugPrint('Register error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _user = null;
    _isAuthenticated = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    notifyListeners();
  }

  void checkAuthStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    _isAuthenticated = token != null;
    notifyListeners();
  }
}
