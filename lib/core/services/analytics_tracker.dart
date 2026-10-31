import 'package:flutter/foundation.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'clarity_service.dart';
import 'utm_service.dart';

/// App Version constant for telemetry parity
const String kAppVersion = '1.0.0+1';

/// Production-grade unified analytics facade for MessKhojo.
/// Dispatches telemetry in 1:1 parity with the MessKhojo website across:
/// 1. Google Analytics 4 / Firebase Analytics
/// 2. Sentry (Breadcrumbs, User context & Error tracking)
/// 3. Microsoft Clarity (Session tags & User identify)
class AnalyticsTracker {
  AnalyticsTracker._();
  static final AnalyticsTracker instance = AnalyticsTracker._();

  FirebaseAnalytics? _analytics;
  bool _isInitialized = false;

  FirebaseAnalytics get analytics {
    _analytics ??= FirebaseAnalytics.instance;
    return _analytics!;
  }

  /// Initialize all tracking clients
  Future<void> initialize({
    String? clarityProjectId,
  }) async {
    if (_isInitialized) return;

    try {
      _analytics = FirebaseAnalytics.instance;

      // Set global user properties
      await _analytics?.setUserProperty(name: 'app_version', value: kAppVersion);
      await _analytics?.setUserProperty(name: 'platform', value: kIsWeb ? 'web' : defaultTargetPlatform.name);

      // Initialize Clarity
      if (clarityProjectId != null && clarityProjectId.isNotEmpty) {
        ClarityService.instance.initialize(clarityProjectId);
        ClarityService.instance.setTag('app_version', kAppVersion);
      }

      // Initialize UTM parameters
      await UtmService.instance.initialize();

      _isInitialized = true;
      debugPrint('📊 AnalyticsTracker initialized (v$kAppVersion)');
    } catch (e) {
      debugPrint('⚠️ AnalyticsTracker initialization warning: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Navigation & Page Views
  // ──────────────────────────────────────────────────────────────

  /// Track screen / page view
  Future<void> trackPageView(String path, {String? title}) async {
    try {
      final sanitizedPath = _sanitizeString(path);
      final screenTitle = title ?? path;

      final params = _cleanParams({
        'app_version': kAppVersion,
        ...UtmService.instance.attribution,
      });

      await analytics.logScreenView(
        screenName: sanitizedPath,
        screenClass: screenTitle,
        parameters: params,
      );

      // Add Sentry navigation breadcrumb
      Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'navigation',
          message: 'Navigated to $sanitizedPath',
          data: {'path': sanitizedPath, 'title': screenTitle},
          level: SentryLevel.info,
        ),
      );

      // Tag Clarity
      ClarityService.instance.setTag('current_screen', sanitizedPath);

      if (kDebugMode) {
        debugPrint('📊 [Analytics] PageView: $sanitizedPath ($screenTitle)');
      }
    } catch (e) {
      debugPrint('⚠️ trackPageView error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Discovery & Search Events
  // ──────────────────────────────────────────────────────────────

  /// Track search query and result metrics
  Future<void> trackSearch(
    String searchTerm,
    int resultsCount, {
    String? district,
    String? gender,
  }) async {
    try {
      final sanitizedTerm = _sanitizeString(searchTerm);
      final params = _cleanParams({
        'search_term': sanitizedTerm,
        'results_count': resultsCount,
        'district': district?.toLowerCase(),
        'gender': gender?.toLowerCase(),
        'app_version': kAppVersion,
      });

      await analytics.logEvent(
        name: 'mess_search',
        parameters: params,
      );

      Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'search',
          message: 'Search: "$sanitizedTerm" ($resultsCount results)',
          data: {'term': sanitizedTerm, 'count': resultsCount},
          level: SentryLevel.info,
        ),
      );

      if (kDebugMode) {
        debugPrint('📊 [Analytics] Search: "$sanitizedTerm" -> $resultsCount results');
      }
    } catch (e) {
      debugPrint('⚠️ trackSearch error: $e');
    }
  }

  /// Track filter selection
  Future<void> trackFilter(String filterType, String filterValue) async {
    try {
      await analytics.logEvent(
        name: 'filter_applied',
        parameters: {
          'filter_type': filterType,
          'filter_value': filterValue,
          'app_version': kAppVersion,
        },
      );

      Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'filter',
          message: 'Filter applied: $filterType = $filterValue',
          level: SentryLevel.info,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ trackFilter error: $e');
    }
  }

  /// Track location / city selection
  Future<void> trackLocationUsage(String method, {String? district}) async {
    try {
      final params = _cleanParams({
        'method': method, // 'gps', 'map', 'district_chip'
        'district': district?.toLowerCase(),
        'app_version': kAppVersion,
      });

      await analytics.logEvent(
        name: 'location_selected',
        parameters: params,
      );

      if (district != null) {
        ClarityService.instance.setTag('selected_district', district.toLowerCase());
      }
    } catch (e) {
      debugPrint('⚠️ trackLocationUsage error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Mess & Room Engagement
  // ──────────────────────────────────────────────────────────────

  /// Track Mess details viewing
  Future<void> trackMessView(
    String messId,
    String messName, {
    String? district,
    String? gender,
    double? startingPrice,
  }) async {
    try {
      final params = _cleanParams({
        'mess_id': messId,
        'mess_name': messName,
        'district': district?.toLowerCase(),
        'gender': gender?.toLowerCase(),
        'price': startingPrice,
        'app_version': kAppVersion,
      });

      await analytics.logEvent(
        name: 'mess_viewed',
        parameters: params,
      );

      // Also log standard GA4 ViewItem
      await analytics.logViewItem(
        currency: 'INR',
        value: startingPrice,
        items: [
          AnalyticsEventItem(
            itemId: messId,
            itemName: messName,
            itemCategory: 'Mess',
            itemCategory2: district,
            price: startingPrice,
          ),
        ],
      );

      Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'engagement',
          message: 'Viewed Mess: $messName ($messId)',
          data: {'mess_id': messId, 'name': messName},
          level: SentryLevel.info,
        ),
      );

      ClarityService.instance.setTag('last_viewed_mess', messId);

      if (kDebugMode) {
        debugPrint('📊 [Analytics] Mess Viewed: $messName ($messId)');
      }
    } catch (e) {
      debugPrint('⚠️ trackMessView error: $e');
    }
  }

  /// Track Room details viewing
  Future<void> trackRoomView(
    String roomId,
    String messId, {
    double? price,
    String? occupancyType,
    bool? hasAc,
  }) async {
    try {
      final params = _cleanParams({
        'room_id': roomId,
        'mess_id': messId,
        'price': price,
        'occupancy': occupancyType,
        'has_ac': hasAc != null ? (hasAc ? 'yes' : 'no') : null,
        'app_version': kAppVersion,
      });

      await analytics.logEvent(
        name: 'room_viewed',
        parameters: params,
      );
    } catch (e) {
      debugPrint('⚠️ trackRoomView error: $e');
    }
  }

  /// Track Wishlist toggle
  Future<void> trackWishlistToggle(
    String messId, {
    required bool isAdded,
    String? messName,
  }) async {
    try {
      final params = _cleanParams({
        'mess_id': messId,
        'mess_name': messName,
        'app_version': kAppVersion,
      });

      await analytics.logEvent(
        name: isAdded ? 'add_to_wishlist' : 'remove_from_wishlist',
        parameters: params,
      );

      Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'wishlist',
          message: '${isAdded ? "Added" : "Removed"} Mess ($messId) ${isAdded ? "to" : "from"} wishlist',
          level: SentryLevel.info,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ trackWishlistToggle error: $e');
    }
  }

  /// Track Share button click
  Future<void> trackShare(String platform, {String? messId, String? messName}) async {
    try {
      await analytics.logShare(
        contentType: 'mess',
        itemId: messId ?? 'general',
        method: platform,
      );
    } catch (e) {
      debugPrint('⚠️ trackShare error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // High-Value Conversions (Leads & Contacts)
  // ──────────────────────────────────────────────────────────────

  /// Track Contact Owner click (Primary Conversion Event)
  Future<void> trackContactClick(
    String contactType, // 'phone' or 'whatsapp'
    String messId, {
    String? ownerId,
    String? messName,
    String? district,
  }) async {
    try {
      final params = _cleanParams({
        'contact_type': contactType,
        'mess_id': messId,
        'owner_id': ownerId,
        'mess_name': messName,
        'district': district?.toLowerCase(),
        'app_version': kAppVersion,
        ...UtmService.instance.attribution,
      });

      // Custom conversion event
      await analytics.logEvent(name: 'contact_clicked', parameters: params);

      // Custom lead generation event
      await analytics.logEvent(name: 'generate_lead', parameters: params);

      Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'conversion',
          message: 'Contact Owner: $contactType for Mess $messId',
          data: {'channel': contactType, 'mess_id': messId},
          level: SentryLevel.info,
        ),
      );

      ClarityService.instance.logEvent('contact_owner_$contactType');

      if (kDebugMode) {
        debugPrint('🎯 [Conversion] Contact Owner Clicked: $contactType on Mess $messId');
      }
    } catch (e) {
      debugPrint('⚠️ trackContactClick error: $e');
    }
  }

  /// Track Booking Inquiry Initiation
  Future<void> trackBookingInitiated(
    String roomId,
    String messId, {
    double? price,
    String? messName,
  }) async {
    try {
      final params = _cleanParams({
        'room_id': roomId,
        'mess_id': messId,
        'price': price,
        'mess_name': messName,
        'app_version': kAppVersion,
        ...UtmService.instance.attribution,
      });

      await analytics.logEvent(
        name: 'booking_initiated',
        parameters: params,
      );

      await analytics.logBeginCheckout(
        value: price,
        currency: 'INR',
        items: [
          AnalyticsEventItem(
            itemId: roomId,
            itemName: messName ?? 'Room $roomId',
            itemCategory: 'Room',
            price: price,
          ),
        ],
      );

      ClarityService.instance.logEvent('booking_initiated');
    } catch (e) {
      debugPrint('⚠️ trackBookingInitiated error: $e');
    }
  }

  /// Track Room Availability check
  Future<void> trackAvailabilityCheck(String roomId, {String? messId}) async {
    try {
      final params = _cleanParams({
        'room_id': roomId,
        'mess_id': messId,
        'app_version': kAppVersion,
      });

      await analytics.logEvent(
        name: 'availability_checked',
        parameters: params,
      );
    } catch (e) {
      debugPrint('⚠️ trackAvailabilityCheck error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Partner & Mess Registration Funnel
  // ──────────────────────────────────────────────────────────────

  /// Track partner registration funnel steps
  Future<void> trackMessRegistration(
    bool started, {
    String? messId,
    int? step,
    String? messName,
    String? district,
  }) async {
    try {
      if (started) {
        final params = _cleanParams({
          'step': step,
          'app_version': kAppVersion,
          ...UtmService.instance.attribution,
        });

        await analytics.logEvent(
          name: 'mess_registration_started',
          parameters: params,
        );
        Sentry.addBreadcrumb(
          Breadcrumb(
            category: 'partner_funnel',
            message: 'Mess registration started (Step: $step)',
            level: SentryLevel.info,
          ),
        );
      } else {
        final params = _cleanParams({
          'mess_id': messId,
          'mess_name': messName,
          'district': district?.toLowerCase(),
          'app_version': kAppVersion,
          ...UtmService.instance.attribution,
        });

        await analytics.logEvent(
          name: 'mess_registration_completed',
          parameters: params,
        );
        Sentry.addBreadcrumb(
          Breadcrumb(
            category: 'partner_funnel',
            message: 'Mess registration completed: $messName ($messId)',
            level: SentryLevel.info,
          ),
        );
        ClarityService.instance.logEvent('mess_registration_completed');
      }
    } catch (e) {
      debugPrint('⚠️ trackMessRegistration error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // User Authentication & Identity
  // ──────────────────────────────────────────────────────────────

  /// Track login attempt
  Future<void> trackLoginAttempt(
    bool success, {
    String method = 'email',
    String? errorMsg,
  }) async {
    try {
      final params = _cleanParams({
        'status': success ? 'success' : 'failure',
        'method': method,
        'error': errorMsg != null ? _sanitizeString(errorMsg) : null,
        'app_version': kAppVersion,
      });

      await analytics.logEvent(
        name: 'login_attempted',
        parameters: params,
      );

      if (success) {
        await analytics.logLogin(loginMethod: method);
      }

      Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'auth',
          message: 'Login $method: ${success ? "SUCCESS" : "FAILED"}',
          level: success ? SentryLevel.info : SentryLevel.warning,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ trackLoginAttempt error: $e');
    }
  }

  /// Track signup attempt
  Future<void> trackSignupAttempt(
    bool success, {
    String method = 'email',
    String role = 'student',
    String? errorMsg,
  }) async {
    try {
      final params = _cleanParams({
        'status': success ? 'success' : 'failure',
        'method': method,
        'role': role,
        'error': errorMsg != null ? _sanitizeString(errorMsg) : null,
        'app_version': kAppVersion,
        ...UtmService.instance.attribution,
      });

      await analytics.logEvent(
        name: 'signup_attempted',
        parameters: params,
      );

      if (success) {
        await analytics.logSignUp(signUpMethod: method);
      }

      Sentry.addBreadcrumb(
        Breadcrumb(
          category: 'auth',
          message: 'SignUp $method ($role): ${success ? "SUCCESS" : "FAILED"}',
          level: success ? SentryLevel.info : SentryLevel.warning,
        ),
      );
    } catch (e) {
      debugPrint('⚠️ trackSignupAttempt error: $e');
    }
  }

  /// Track logout
  Future<void> trackLogout({String role = 'user'}) async {
    try {
      await analytics.logEvent(
        name: 'logout',
        parameters: {
          'role': role,
          'app_version': kAppVersion,
        },
      );

      await analytics.setUserId(id: null);
      await Sentry.configureScope((scope) => scope.setUser(null));
      ClarityService.instance.identify('anonymous');
    } catch (e) {
      debugPrint('⚠️ trackLogout error: $e');
    }
  }

  /// Track account deletion
  Future<void> trackAccountDelete(bool success, {String? errorMsg}) async {
    try {
      final params = _cleanParams({
        'status': success ? 'success' : 'failure',
        'error': errorMsg != null ? _sanitizeString(errorMsg) : null,
        'app_version': kAppVersion,
      });

      await analytics.logEvent(
        name: 'account_deleted',
        parameters: params,
      );
    } catch (e) {
      debugPrint('⚠️ trackAccountDelete error: $e');
    }
  }

  /// Set user ID and user properties across GA4, Sentry, and Clarity
  Future<void> identifyUser(
    String userId, {
    String? role,
    String? district,
    String? email,
    String? name,
  }) async {
    try {
      // 1. Google Analytics
      await analytics.setUserId(id: userId);
      if (role != null) {
        await analytics.setUserProperty(name: 'user_role', value: role);
      }
      if (district != null) {
        await analytics.setUserProperty(name: 'preferred_district', value: district.toLowerCase());
      }

      // 2. Sentry User Context (with PII protection)
      await Sentry.configureScope((scope) {
        final userData = <String, dynamic>{};
        if (role != null) userData['role'] = role;
        if (district != null) userData['district'] = district;

        scope.setUser(
          SentryUser(
            id: userId,
            data: userData.isNotEmpty ? userData : null,
          ),
        );
      });

      // 3. Microsoft Clarity
      final clarityProps = _cleanParams({
        'user_role': role,
        'district': district,
        'app_version': kAppVersion,
      });

      ClarityService.instance.identify(userId, clarityProps);

      if (kDebugMode) {
        debugPrint('📊 [Identify] User identified: $userId (Role: $role, District: $district)');
      }
    } catch (e) {
      debugPrint('⚠️ identifyUser error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Exceptions & Diagnostics
  // ──────────────────────────────────────────────────────────────

  /// Record non-fatal error / handled exception
  Future<void> trackException(
    Object error,
    StackTrace? stackTrace, {
    String? reason,
    bool fatal = false,
  }) async {
    try {
      // Log to Sentry
      await Sentry.captureException(
        error,
        stackTrace: stackTrace,
        withScope: (scope) {
          if (reason != null) {
            scope.setTag('error_reason', reason);
          }
          scope.level = fatal ? SentryLevel.fatal : SentryLevel.error;
        },
      );

      // Log event to GA4
      final params = _cleanParams({
        'error_type': error.runtimeType.toString(),
        'error_message': _sanitizeString(error.toString()),
        'is_fatal': fatal ? 'true' : 'false',
        'reason': reason != null ? _sanitizeString(reason) : null,
        'app_version': kAppVersion,
      });

      await analytics.logEvent(
        name: 'app_exception',
        parameters: params,
      );
    } catch (e) {
      debugPrint('⚠️ trackException error: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────
  // Helpers & Sanitization
  // ──────────────────────────────────────────────────────────────

  /// Strips null values from a parameter map
  Map<String, Object> _cleanParams(Map<String, Object?> input) {
    final clean = <String, Object>{};
    input.forEach((key, value) {
      if (value != null) {
        clean[key] = value;
      }
    });
    return clean;
  }

  /// Sanitizes text to strip phone numbers, tokens, and long sensitive strings
  String _sanitizeString(String text) {
    if (text.isEmpty) return '';
    // Redact 10-digit phone numbers
    var sanitized = text.replaceAll(RegExp(r'\b\d{10}\b'), '[PHONE_REDACTED]');
    // Redact email addresses
    sanitized = sanitized.replaceAll(RegExp(r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}'), '[EMAIL_REDACTED]');
    // Trim length
    return sanitized.length > 100 ? sanitized.substring(0, 100) : sanitized;
  }
}
