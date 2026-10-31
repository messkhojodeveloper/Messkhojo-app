import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:messkhojo_flutter/core/services/analytics_tracker.dart';
import 'package:messkhojo_flutter/core/services/utm_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'attribution_utm_source': 'google',
      'attribution_utm_campaign': 'diwali_special',
    });
  });

  group('Analytics & Tracking Architecture Tests', () {
    test('kAppVersion is defined for release parity', () {
      expect(kAppVersion, equals('1.0.0+1'));
    });

    test('UtmService initialization retrieves cached parameters', () async {
      final utm = UtmService.instance;
      await utm.initialize();
      expect(utm.attribution['utm_source'], equals('google'));
      expect(utm.attribution['utm_campaign'], equals('diwali_special'));
    });
  });
}
