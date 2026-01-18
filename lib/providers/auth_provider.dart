import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import 'locale_provider.dart';

class AuthProvider with ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  final ApiService _apiService = ApiService();
  LocaleProvider? _localeProvider;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  int? get userId => _user?.id;

  void setLocaleProvider(LocaleProvider localeProvider) {
    _localeProvider = localeProvider;
  }

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
        
        // Fetch full user profile with settings
        await fetchProfile();
        
        // Initialize language and currency from backend
        if (_localeProvider != null && _user != null) {
          await _localeProvider!.initializeFromUser(
            _user!.defaultLanguage,
            _user!.defaultCurrency,
          );
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
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
            // If auto-login fails, still keep user authenticated
            // User is already authenticated from registration, just notify
            notifyListeners();
          }
          // Return true since registration succeeded (user is authenticated)
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> fetchProfile() async {
    try {
      final response = await _apiService.get('/api/v1/profile');
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _user = User.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      // Silently fail - profile fetch is optional
    }
  }

  Future<bool> updateProfile({
    String? firstName,
    String? lastName,
    String? username,
    String? defaultCurrency,
    String? defaultLanguage,
  }) async {
    try {
      final Map<String, dynamic> userData = {};
      if (firstName != null) userData['first_name'] = firstName;
      if (lastName != null) userData['last_name'] = lastName;
      if (username != null) userData['username'] = username;
      // Email is read-only and cannot be updated through profile endpoint
      if (defaultCurrency != null) userData['default_currency'] = defaultCurrency;
      if (defaultLanguage != null) userData['default_language'] = defaultLanguage;

      final Map<String, dynamic> body = {'user': userData};
      final response = await _apiService.put('/api/v1/profile', body);
      if (response.statusCode == 200 || response.statusCode == 204) {
        if (response.statusCode == 200 && response.body.isNotEmpty) {
          final data = jsonDecode(response.body);
          _user = User.fromJson(data);
        } else {
          // For 204, fetch the updated profile
          await fetchProfile();
        }
        
        // Update locale provider if language or currency changed
        if (_localeProvider != null) {
          if (defaultLanguage != null) {
            await _localeProvider!.setLocale(Locale(defaultLanguage.toLowerCase()));
          }
          if (defaultCurrency != null) {
            await _localeProvider!.setCurrency(defaultCurrency);
          }
        }
        
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> changePassword(String currentPassword, String newPassword) async {
    try {
      final response = await _apiService.put('/api/v1/profile', {
        'user': {
          'current_password': currentPassword,
          'password': newPassword,
          'password_confirmation': newPassword,
        },
      });
      return response.statusCode == 200 || response.statusCode == 204;
    } catch (e) {
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
    if (_isAuthenticated) {
      if (_user == null) {
        // Try to fetch profile if authenticated but user is null
        await fetchProfile();
      }
      // Initialize language and currency from backend if available
      if (_localeProvider != null && _user != null) {
        await _localeProvider!.initializeFromUser(
          _user!.defaultLanguage,
          _user!.defaultCurrency,
        );
      }
    }
    notifyListeners();
  }
}
