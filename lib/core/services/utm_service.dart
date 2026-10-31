import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service to extract, store, and provide UTM campaign and referral attributes
class UtmService {
  UtmService._();
  static final UtmService instance = UtmService._();

  static const String _keyUtmSource = 'attribution_utm_source';
  static const String _keyUtmMedium = 'attribution_utm_medium';
  static const String _keyUtmCampaign = 'attribution_utm_campaign';
  static const String _keyUtmTerm = 'attribution_utm_term';
  static const String _keyUtmContent = 'attribution_utm_content';
  static const String _keyRef = 'attribution_ref';

  Map<String, String> _cachedAttribution = {};

  /// Initialize and capture UTM params from initial URL (Web) or deep link
  Future<void> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Read from browser URL if on Web
      if (kIsWeb) {
        final uri = Uri.base;
        final params = uri.queryParameters;

        if (params.isNotEmpty) {
          if (params.containsKey('utm_source')) {
            await prefs.setString(_keyUtmSource, params['utm_source']!);
          }
          if (params.containsKey('utm_medium')) {
            await prefs.setString(_keyUtmMedium, params['utm_medium']!);
          }
          if (params.containsKey('utm_campaign')) {
            await prefs.setString(_keyUtmCampaign, params['utm_campaign']!);
          }
          if (params.containsKey('utm_term')) {
            await prefs.setString(_keyUtmTerm, params['utm_term']!);
          }
          if (params.containsKey('utm_content')) {
            await prefs.setString(_keyUtmContent, params['utm_content']!);
          }
          if (params.containsKey('ref')) {
            await prefs.setString(_keyRef, params['ref']!);
          }
        }
      }

      // Load cached parameters
      _cachedAttribution = {
        if (prefs.containsKey(_keyUtmSource)) 'utm_source': prefs.getString(_keyUtmSource)!,
        if (prefs.containsKey(_keyUtmMedium)) 'utm_medium': prefs.getString(_keyUtmMedium)!,
        if (prefs.containsKey(_keyUtmCampaign)) 'utm_campaign': prefs.getString(_keyUtmCampaign)!,
        if (prefs.containsKey(_keyUtmTerm)) 'utm_term': prefs.getString(_keyUtmTerm)!,
        if (prefs.containsKey(_keyUtmContent)) 'utm_content': prefs.getString(_keyUtmContent)!,
        if (prefs.containsKey(_keyRef)) 'ref': prefs.getString(_keyRef)!,
      };

      if (_cachedAttribution.isNotEmpty && kDebugMode) {
        debugPrint('🎯 Captured UTM Attribution: $_cachedAttribution');
      }
    } catch (e) {
      debugPrint('⚠️ UtmService init error: $e');
    }
  }

  /// Get current attribution metadata to attach to analytics events & inquiries
  Map<String, String> get attribution => Map.unmodifiable(_cachedAttribution);
}
