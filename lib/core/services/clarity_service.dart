import 'package:flutter/foundation.dart';
import 'clarity_service_stub.dart'
    if (dart.library.js_interop) 'clarity_service_web.dart';

/// Microsoft Clarity Cross-Platform Service Bridge
class ClarityService {
  ClarityService._();
  static final ClarityService instance = ClarityService._();

  bool _isInitialized = false;

  /// Initialize Clarity with Project ID
  void initialize(String projectId) {
    if (_isInitialized || projectId.isEmpty) return;
    if (kIsWeb) {
      try {
        initClarityPlatform(projectId);
        _isInitialized = true;
        debugPrint('📊 Microsoft Clarity initialized for Flutter Web');
      } catch (e) {
        debugPrint('⚠️ Clarity init warning: $e');
      }
    }
  }

  /// Identify user in Clarity session replay
  void identify(String userId, [Map<String, dynamic>? properties]) {
    if (kIsWeb) {
      try {
        clarityIdentifyPlatform(userId, properties);
      } catch (_) {}
    }
  }

  /// Set custom session tag in Clarity
  void setTag(String key, String value) {
    if (kIsWeb) {
      try {
        claritySetPlatform(key, value);
      } catch (_) {}
    }
  }

  /// Trigger custom event in Clarity
  void logEvent(String eventName) {
    if (kIsWeb) {
      try {
        clarityEventPlatform(eventName);
      } catch (_) {}
    }
  }
}
