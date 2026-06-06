import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:deltabooks/providers/feature_flag_provider.dart';

void main() {
  group('FeatureFlagProvider', () {
    test('isEnabled returns false for unknown flag on fresh provider', () {
      final provider = FeatureFlagProvider();
      expect(provider.isEnabled('unknown_flag'), isFalse);
      expect(provider.isEnabled('reading_goals'), isFalse);
    });

    test('fetchFlags with 200 response correctly populates flags', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'feature_flags': {
              'reading_goals': true,
              'subscriptions': false,
              'beta_feature': true,
            }
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = FeatureFlagProvider(client: client);
      await provider.fetchFlags('test-token');

      expect(provider.isEnabled('reading_goals'), isTrue);
      expect(provider.isEnabled('beta_feature'), isTrue);
      expect(provider.isEnabled('subscriptions'), isFalse);
      expect(provider.isEnabled('unknown'), isFalse);
    });

    test('fetchFlags with non-200 response leaves flags at defaults', () async {
      final client = MockClient((request) async {
        return http.Response('{"error": "unauthorized"}', 401);
      });

      final provider = FeatureFlagProvider(client: client);
      await provider.fetchFlags('bad-token');

      expect(provider.isEnabled('reading_goals'), isFalse);
      expect(provider.isEnabled('subscriptions'), isFalse);
    });

    test('reset returns flags to defaults and notifyListeners is called', () async {
      final client = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'feature_flags': {'reading_goals': true}
          }),
          200,
          headers: {'content-type': 'application/json'},
        );
      });

      final provider = FeatureFlagProvider(client: client);
      await provider.fetchFlags('test-token');
      expect(provider.isEnabled('reading_goals'), isTrue);

      var notified = false;
      provider.addListener(() => notified = true);

      provider.reset();

      expect(provider.isEnabled('reading_goals'), isFalse);
      expect(notified, isTrue);
    });
  });
}
