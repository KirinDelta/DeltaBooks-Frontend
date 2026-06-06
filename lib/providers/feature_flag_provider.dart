import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/feature_flags.dart';
import '../services/api_service.dart';

// Usage:
//   final flags = context.read<FeatureFlagProvider>();
//   if (flags.isEnabled('reading_goals')) { ... }
//
//   Or in a widget tree:
//   Consumer<FeatureFlagProvider>(
//     builder: (_, flags, __) =>
//       flags.isEnabled('subscriptions') ? SubscriptionBanner() : const SizedBox(),
//   )

class FeatureFlagProvider extends ChangeNotifier {
  final http.Client _client;

  FeatureFlagProvider({http.Client? client}) : _client = client ?? http.Client();

  FeatureFlags _flags = FeatureFlags.defaults;
  bool _isLoading = false;

  bool get isLoading => _isLoading;
  bool isEnabled(String flag) => _flags.isEnabled(flag);

  Future<void> fetchFlags(String token) async {
    _isLoading = true;
    notifyListeners();

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/api/v1/feature_flags');
      final response = await _client.get(
        uri,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        _flags = FeatureFlags.fromJson(json);
      }
      // Non-200 responses are silently ignored — keep previous state.
    } catch (_) {
      // Silent fail: feature flags are non-critical infrastructure.
      // If the endpoint is unreachable, all flags default to false.
      if (kDebugMode) {
        rethrow;
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reset() {
    _flags = FeatureFlags.defaults;
    _isLoading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }
}
