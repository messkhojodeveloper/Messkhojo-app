import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'firebase_options.dart';
import 'data/repositories/data_seeder.dart';

// Core
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/utils/connectivity_provider.dart';

// Services
import 'data/services/notification_service.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/districts_provider.dart';

// Screens
import 'screens/auth/login_screen.dart';
import 'screens/auth/partner_login_screen.dart';
import 'screens/auth/signup_screen.dart';
import 'screens/home/home_screen.dart';
import 'screens/home/mess_explorer_map_screen.dart';
import 'screens/city/city_screen.dart';
import 'screens/mess_details/mess_details_screen.dart';
import 'screens/room_details/room_details_screen.dart';
import 'screens/profile/profile_screen.dart';
import 'screens/wishlist/wishlist_screen.dart';
import 'screens/mess_registration/mess_registration_screen.dart';
import 'screens/find_your_room/find_your_room_screen.dart';
import 'screens/find_your_room/find_your_room_results_screen.dart';
import 'screens/about/about_screen.dart';
import 'screens/legal/privacy_policy_screen.dart';
import 'screens/legal/terms_screen.dart';
import 'screens/admin_dashboard/admin_dashboard_screen.dart';
import 'screens/main_shell/main_shell_screen.dart';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_performance/firebase_performance.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'core/services/analytics_tracker.dart';

import 'package:flutter_web_plugins/url_strategy.dart';
import 'core/utils/app_provider_observer.dart';
import 'widgets/global_error_boundary.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  usePathUrlStrategy();

  // Modern Edge-to-Edge display configuration for Android 10+ (API 29-35)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      statusBarBrightness: Brightness.light,
      systemNavigationBarColor: Colors.transparent,
      systemNavigationBarIconBrightness: Brightness.dark,
      systemNavigationBarDividerColor: Colors.transparent,
    ),
  );

  // Custom Global Error Boundary for widget rendering crashes
  ErrorWidget.builder = GlobalErrorBoundary.buildErrorWidget;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Non-critical init is deferred to after first frame (see _initNonCritical below)

  // Configure Crashlytics (not supported on Web)
  if (!kIsWeb) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Disable Crashlytics in debug mode — fire-and-forget, no await
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(kReleaseMode).catchError((_) {});
  }

  // Register FCM background handler — must be called before runApp
  if (!kIsWeb) {
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  // Sentry DSN configuration
  const sentryDsn = String.fromEnvironment(
    'SENTRY_DSN',
    defaultValue: 'https://e7241355162fe29339312027e6cb897b@o4511456031014912.ingest.us.sentry.io/4511456070926336',
  );

  if (kIsWeb && kDebugMode) {
    runApp(
      ProviderScope(
        observers: [const AppProviderObserver()],
        child: const MessKhojoApp(),
      ),
    );
    _initNonCritical();
    return;
  }

  await SentryFlutter.init(
    (options) {
      options.dsn = sentryDsn;
      options.release = 'messkhojo_flutter@$kAppVersion';
      options.environment = kReleaseMode ? 'production' : 'development';
      options.tracesSampleRate = kReleaseMode ? 0.1 : 1.0;
      options.enableAutoPerformanceTracing = true;
      options.enableAppLifecycleBreadcrumbs = true;
      options.enableUserInteractionBreadcrumbs = true;
      options.sendDefaultPii = false; // Strict PII protection
      options.attachScreenshot = false; // PII protection
    },
    appRunner: () {
      runApp(
        ProviderScope(
          observers: [const AppProviderObserver()],
          child: const MessKhojoApp(),
        ),
      );
      _initNonCritical();
    },
  );
}

/// Deferred initialization — runs after the first frame is painted.
/// Nothing here should block the user from seeing the home screen.
void _initNonCritical() {
  WidgetsBinding.instance.addPostFrameCallback((_) async {
    // Analytics — fire-and-forget, no await
    AnalyticsTracker.instance.initialize(clarityProjectId: 'xnfb08puiv');

    // Firebase Performance Monitoring — release only
    if (!kDebugMode) {
      try {
        await FirebasePerformance.instance.setPerformanceCollectionEnabled(true);
      } catch (_) {}
    }

    // Google Sign-In — lazy-initializes on first use
    try {
      String clientId = const String.fromEnvironment('GOOGLE_CLIENT_ID');
      if (clientId.isEmpty) {
        clientId = '746163731012-ofvefmag2gvhhsv85gb56u3jc8dtnj4r.apps.googleusercontent.com';
      }
      GoogleSignIn.instance.initialize(clientId: clientId).catchError((e) {
        debugPrint('GoogleSignIn init error: $e');
      });
    } catch (e) {
      debugPrint('GoogleSignIn init error: $e');
    }

    // Data seeder — debug only, deferred so it doesn't delay first paint
    if (kDebugMode) {
      try {
        await DataSeeder.seedIfEmpty();
      } catch (e) {
        debugPrint('Database seeding error: $e');
      }
    }
  });
}

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);

  return GoRouter(
    initialLocation: '/home',
    observers: [
      FirebaseAnalyticsObserver(analytics: AnalyticsTracker.instance.analytics),
      SentryNavigatorObserver(),
    ],
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final isLoggedIn = authState.value != null;
      final currentPath = state.matchedLocation;

      // Root / onboarding always go to home if logged in, or /login if logged out
      if (currentPath == '/' || currentPath == '/onboarding') {
        return isLoggedIn ? '/home' : '/login';
      }

      // ── Public routes — no login required ───────────────────────────────────
      // /partner-login is public so a logged-in user can switch to partner mode.
      // The partner_login_screen itself handles signing out the current session.
      const publicRoutes = {
        '/login',
        '/signup',
        '/partner-login',
        '/privacy',
        '/terms',
        '/about',
      };
      final isPublicRoute = publicRoutes.contains(currentPath);

      // ── Auth wall — redirect all private routes to /login ──────────────────
      if (!isLoggedIn && !isPublicRoute) {
        if (currentPath == '/home') return '/login';
        // Preserve deep-link so the user lands back after signing in
        final encoded = Uri.encodeComponent(currentPath);
        return '/login?redirect=$encoded';
      }

      // ── Admin / Partner route guard ─────────────────────────────────────────
      // /admin requires a partner or admin role; redirect non-partners to partner-login
      if (currentPath == '/admin') {
        if (!isLoggedIn) return '/partner-login';
        final profile = ref.read(userProfileProvider).value;
        if (profile != null && !profile.isPartnerOrAdmin) return '/home';
        return null;
      }

      // ── If already logged in as partner and hits /partner-login → go to /admin
      if (isLoggedIn && currentPath == '/partner-login') {
        final profile = ref.read(userProfileProvider).value;
        if (profile != null && profile.isPartnerOrAdmin) return '/admin';
      }

      // ── If already logged in and hits /login or /signup → go to /home ───────
      if (isLoggedIn && (currentPath == '/login' || currentPath == '/signup')) {
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/onboarding',
        redirect: (context, state) => '/home',
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => _slidePage(state, const LoginScreen()),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => _slidePage(state, const SignupScreen()),
      ),
      // ── Main Shell with Persistent Bottom Navigation Bar ──
      ShellRoute(
        builder: (context, state, child) => MainShellScreen(child: child),
        routes: [
          // ── Tab 0: Home & Discovery Flow ──
          GoRoute(
            path: '/home',
            pageBuilder: (context, state) => _fadePage(state, const HomeScreen()),
          ),
          GoRoute(
            path: '/city/:districtId/:cityId',
            pageBuilder: (context, state) => _slidePage(
              state,
              CityScreen(
                districtId: state.pathParameters['districtId']!,
                cityId: state.pathParameters['cityId']!,
              ),
            ),
          ),
          GoRoute(
            path: '/explorer',
            pageBuilder: (context, state) => _slidePage(state, const MessExplorerMapScreen()),
          ),
          GoRoute(
            path: '/mess/:id',
            pageBuilder: (context, state) => _slidePage(
              state, MessDetailsScreen(messId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/room/:id',
            pageBuilder: (context, state) => _slidePage(
              state, RoomDetailsScreen(roomId: state.pathParameters['id']!),
            ),
          ),
          GoRoute(
            path: '/wishlist',
            pageBuilder: (context, state) => _slidePage(state, const WishlistScreen()),
          ),

          // ── Tab 1: Find Room Flow ──
          GoRoute(
            path: '/find-your-room',
            pageBuilder: (context, state) => _fadePage(state, const FindYourRoomScreen()),
          ),
          GoRoute(
            path: '/find-your-room/results',
            pageBuilder: (context, state) {
              final inquiry = state.extra as Map<String, dynamic>? ?? {};
              return _slidePage(state, FindYourRoomResultsScreen(inquiry: inquiry));
            },
          ),

          // ── Tab 2: Profile & Account Flow ──
          GoRoute(
            path: '/profile',
            pageBuilder: (context, state) => _fadePage(state, const ProfileScreen()),
          ),
          GoRoute(
            path: '/register-mess',
            pageBuilder: (context, state) => _slidePage(state, const MessRegistrationScreen()),
          ),
          GoRoute(
            path: '/partner-login',
            pageBuilder: (context, state) => _slidePage(state, const PartnerLoginScreen()),
          ),
          GoRoute(
            path: '/admin',
            pageBuilder: (context, state) => _slidePage(state, const AdminDashboardScreen()),
          ),
          GoRoute(
            path: '/about',
            pageBuilder: (context, state) => _slidePage(state, const AboutScreen()),
          ),
          GoRoute(
            path: '/privacy',
            pageBuilder: (context, state) => _slidePage(state, const PrivacyPolicyScreen()),
          ),
          GoRoute(
            path: '/terms',
            pageBuilder: (context, state) => _slidePage(state, const TermsScreen()),
          ),
        ],
      ),
    ],
  );
});

/// Slide-up + fade transition for most screens (200ms, easeOutCubic).
CustomTransitionPage<void> _slidePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 200),
    reverseTransitionDuration: const Duration(milliseconds: 150),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curve = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return FadeTransition(
        opacity: curve,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, 0.04),
            end: Offset.zero,
          ).animate(curve),
          child: child,
        ),
      );
    },
  );
}

/// Pure fade for splash/home (150ms) — feels instant.
CustomTransitionPage<void> _fadePage(GoRouterState state, Widget child) {
  return CustomTransitionPage<void>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 150),
    reverseTransitionDuration: const Duration(milliseconds: 100),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return FadeTransition(
        opacity: CurvedAnimation(parent: animation, curve: Curves.easeIn),
        child: child,
      );
    },
  );
}


class MessKhojoApp extends ConsumerStatefulWidget {
  const MessKhojoApp({super.key});

  @override
  ConsumerState<MessKhojoApp> createState() => _MessKhojoAppState();
}

class _MessKhojoAppState extends ConsumerState<MessKhojoApp> {
  @override
  void initState() {
    super.initState();
    // Initialise FCM after the first frame so GoRouter context is available
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        NotificationService.initialize(context);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(districtsStreamProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      routerConfig: router,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        // Clamp accessibility text scaler between 0.85x and 1.25x to prevent UI overflow on large text settings
        final clampedTextScaler = mediaQuery.textScaler.clamp(
          minScaleFactor: 0.85,
          maxScaleFactor: 1.25,
        );

        return MediaQuery(
          data: mediaQuery.copyWith(textScaler: clampedTextScaler),
          child: Stack(
            children: [
              child ?? const SizedBox.shrink(),
              const ConnectivityBannerOverlay(),
            ],
          ),
        );
      },
    );
  }
}

class ConnectivityBannerOverlay extends ConsumerWidget {
  const ConnectivityBannerOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityAsync = ref.watch(connectivityProvider);
    final isOnline = connectivityAsync.value ?? true;

    if (isOnline) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: Material(
        color: Colors.red.shade600,
        elevation: 4,
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              children: [
                const Icon(Icons.wifi_off_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'No internet connection. Operating offline.',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
