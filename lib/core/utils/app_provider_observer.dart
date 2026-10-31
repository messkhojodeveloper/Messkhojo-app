import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import '../services/analytics_tracker.dart';

/// Riverpod Observer that catches uncaught provider errors across the entire app
/// and records them to Sentry, Crashlytics, and GA4 in release builds.
base class AppProviderObserver extends ProviderObserver {
  const AppProviderObserver();

  @override
  void providerDidFail(
    ProviderObserverContext context,
    Object error,
    StackTrace stackTrace,
  ) {
    final providerName = context.provider.name ?? context.provider.runtimeType.toString();
    debugPrint('[ProviderError] $providerName: $error');

    // Forward to AnalyticsTracker (Sentry & GA4)
    AnalyticsTracker.instance.trackException(
      error,
      stackTrace,
      reason: 'Riverpod Provider Failure ($providerName)',
      fatal: false,
    );

    if (kDebugMode) {
      debugPrintStack(stackTrace: stackTrace);
    } else {
      try {
        if (!kIsWeb) {
          FirebaseCrashlytics.instance.recordError(
            error,
            stackTrace,
            reason: 'Riverpod Provider failed: $providerName',
            fatal: false,
          );
        }
      } catch (e) {
        debugPrint('[ProviderObserver] Crashlytics record error failed: $e');
      }
    }
  }
}

