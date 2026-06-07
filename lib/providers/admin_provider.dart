import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../models/admin_feature_flag.dart';
import '../models/admin_user.dart';
import '../services/api_service.dart';

class AdminProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  List<AdminUser> _users = [];
  bool _isLoading = false;
  String? _error;
  int _currentPage = 1;
  int _totalPages = 1;
  int _total = 0;
  String _searchQuery = '';
  String? _statusFilter;

  List<AdminUser> get users => _users;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get total => _total;
  String get searchQuery => _searchQuery;
  String? get statusFilter => _statusFilter;
  bool get hasNextPage => _currentPage < _totalPages;

  Future<void> fetchUsers({
    String? email,
    String? accountStatus,
    int page = 1,
  }) async {
    _isLoading = true;
    _error = null;
    if (page == 1) _users = [];
    notifyListeners();

    try {
      final params = <String, String>{
        'page': '$page',
        'per_page': '25',
      };
      if (email != null && email.isNotEmpty) params['email'] = email;
      if (accountStatus != null && accountStatus.isNotEmpty) {
        params['account_status'] = accountStatus;
      }

      final response = await _apiService.getWithParams('/admin/users', params);

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final rawUsers = (json['users'] as List<dynamic>?) ?? [];
        final meta = json['meta'] as Map<String, dynamic>? ?? {};

        final fetched = rawUsers
            .map((u) => AdminUser.fromJson(u as Map<String, dynamic>))
            .toList();

        final total = (meta['total'] as num?)?.toInt() ?? fetched.length;
        final perPage = (meta['per_page'] as num?)?.toInt() ?? 25;

        if (page == 1) {
          _users = fetched;
        } else {
          _users = [..._users, ...fetched];
        }
        _currentPage = page;
        _total = total;
        _totalPages = perPage > 0 ? (total / perPage).ceil() : 1;
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        _error = json?['error'] as String? ?? 'Error fetching users';
      }
    } catch (e) {
      _error = 'Error fetching users';
      if (kDebugMode) rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<AdminUserDetail?> fetchUserDetail(int userId) async {
    try {
      final response = await _apiService.get('/admin/users/$userId');
      if (response.statusCode == 200) {
        return AdminUserDetail.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      _error = json?['error'] as String? ?? 'Error fetching user';
      notifyListeners();
    } catch (e) {
      _error = 'Error fetching user';
      notifyListeners();
      if (kDebugMode) rethrow;
    }
    return null;
  }

  Future<bool> suspendUser(int userId) async {
    try {
      final response = await _apiService.post('/admin/users/$userId/suspend', {});
      if (response.statusCode == 200) {
        final updated = AdminUser.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        _updateUserInList(updated);
        return true;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      _error = json?['error'] as String? ?? 'Error suspending user';
      notifyListeners();
    } catch (e) {
      _error = 'Error suspending user';
      notifyListeners();
      if (kDebugMode) rethrow;
    }
    return false;
  }

  Future<bool> unsuspendUser(int userId) async {
    try {
      final response = await _apiService.post('/admin/users/$userId/unsuspend', {});
      if (response.statusCode == 200) {
        final updated = AdminUser.fromJson(
          jsonDecode(response.body) as Map<String, dynamic>,
        );
        _updateUserInList(updated);
        return true;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      _error = json?['error'] as String? ?? 'Error unsuspending user';
      notifyListeners();
    } catch (e) {
      _error = 'Error unsuspending user';
      notifyListeners();
      if (kDebugMode) rethrow;
    }
    return false;
  }

  void _updateUserInList(AdminUser updated) {
    final idx = _users.indexWhere((u) => u.id == updated.id);
    if (idx != -1) {
      _users = List.from(_users)..[idx] = updated;
    }
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  // ── Feature flags ──────────────────────────────────────────────────────────

  List<AdminFeatureFlag> _featureFlags = [];
  bool _isFlagsLoading = false;
  String? _flagsError;

  List<AdminFeatureFlag> get featureFlags => _featureFlags;
  bool get isFlagsLoading => _isFlagsLoading;
  String? get flagsError => _flagsError;

  Future<void> fetchFeatureFlags() async {
    _isFlagsLoading = true;
    _flagsError = null;
    notifyListeners();

    try {
      final response = await _apiService.get('/admin/feature_flags');
      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        final raw = (json['feature_flags'] as List<dynamic>?) ?? [];
        _featureFlags =
            raw.map((f) => AdminFeatureFlag.fromJson(f as Map<String, dynamic>)).toList();
      } else {
        final json = jsonDecode(response.body) as Map<String, dynamic>?;
        _flagsError = json?['error'] as String? ?? 'Error fetching feature flags';
      }
    } catch (e) {
      _flagsError = 'Error fetching feature flags';
      if (kDebugMode) rethrow;
    } finally {
      _isFlagsLoading = false;
      notifyListeners();
    }
  }

  Future<bool> enableFlag(String name) => _postFlagAction('/admin/feature_flags/$name/enable', {});

  Future<bool> disableFlag(String name) => _postFlagAction('/admin/feature_flags/$name/disable', {});

  Future<bool> enableFlagForUser(String name, String email) =>
      _postFlagAction('/admin/feature_flags/$name/enable_for_user', {'email': email});

  Future<bool> disableFlagForUser(String name, String email) =>
      _postFlagAction('/admin/feature_flags/$name/disable_for_user', {'email': email});

  Future<bool> enablePercentageOfActors(String name, int percentage) =>
      _postFlagAction('/admin/feature_flags/$name/enable_percentage_of_actors',
          {'percentage': percentage});

  Future<bool> disablePercentageOfActors(String name) =>
      _postFlagAction('/admin/feature_flags/$name/disable_percentage_of_actors', {});

  Future<bool> _postFlagAction(String path, Map<String, dynamic> body) async {
    try {
      final response = await _apiService.post(path, body);
      if (response.statusCode == 200) {
        final updated =
            AdminFeatureFlag.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
        _updateFlagInList(updated);
        return true;
      }
      final json = jsonDecode(response.body) as Map<String, dynamic>?;
      _flagsError = json?['error'] as String? ?? 'Error updating feature flag';
      notifyListeners();
    } catch (e) {
      _flagsError = 'Error updating feature flag';
      notifyListeners();
      if (kDebugMode) rethrow;
    }
    return false;
  }

  void _updateFlagInList(AdminFeatureFlag updated) {
    final idx = _featureFlags.indexWhere((f) => f.name == updated.name);
    if (idx != -1) {
      _featureFlags = List.from(_featureFlags)..[idx] = updated;
    }
    notifyListeners();
  }

  void clearFlagsError() {
    _flagsError = null;
    notifyListeners();
  }
}
