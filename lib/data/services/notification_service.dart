import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter/material.dart';

/// Top-level background message handler.
/// Must be a top-level (not class) function — called by FCM when app is in background/killed.
/// Firebase is already initialised at this point by the plugin.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase.initializeApp() is NOT needed here — the FCM plugin already initialises
  // Firebase before invoking this handler.
  debugPrint('[FCM] Background message: ${message.messageId}');
  // The OS automatically displays the notification from the `notification` payload.
  // No UI work needed here.
}

/// Manages all FCM push notification functionality:
/// - Permission requests
/// - Token retrieval & Firestore storage
/// - Topic subscriptions (flexible — set per notification in Firebase Console)
/// - Foreground notification display via flutter_local_notifications
/// - Deep-link navigation on notification tap (background & killed states)
class NotificationService {
  NotificationService._();

  static final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  /// The Android notification channel used for all MessKhojo notifications.
  static const AndroidNotificationChannel _channel = AndroidNotificationChannel(
    'messkhojo_channel',
    'MessKhojo Notifications',
    description: 'Notifications for new messes, updates, and alerts from MessKhojo.',
    importance: Importance.high,
    playSound: true,
    enableVibration: true,
  );

  // ──────────────────────────────────────────────────────────────────────────
  // Initialisation
  // ──────────────────────────────────────────────────────────────────────────

  /// Call once from [main.dart] after Firebase is initialised.
  /// [context] is used for deep-link navigation.
  static Future<void> initialize(BuildContext context) async {
    try {
      if (Firebase.apps.isEmpty) return;
      await _requestPermissions();
      await _initLocalNotifications();
      await _createAndroidChannel();
      if (!context.mounted) return;
      _setupForegroundListener(context);
      await _handleInitialMessage(context);
      if (!context.mounted) return;
      _setupBackgroundOpenListener(context);
    } catch (e) {
      debugPrint('[NotificationService] Init note: $e');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Permissions
  // ──────────────────────────────────────────────────────────────────────────

  static Future<void> _requestPermissions() async {
    // Web & iOS: request FCM permission
    if (kIsWeb) {
      await _fcm.requestPermission(alert: true, badge: true, sound: true);
      return;
    }
    // Android 13+ requires explicit POST_NOTIFICATIONS permission (already in manifest).
    // The FCM plugin handles the actual OS dialog on Android 13+.
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      announcement: false,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
    );
    debugPrint('[FCM] Permission: ${settings.authorizationStatus}');
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Local notifications setup (foreground display)
  // ──────────────────────────────────────────────────────────────────────────

  static Future<void> _initLocalNotifications() async {
    if (kIsWeb) return; // Web uses browser notifications, not local notifications

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwinInit = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidInit,
      iOS: darwinInit,
    );

    await _localNotifications.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse details) {
        // Tapping a local notification while app is open
        // The payload is the deep link string
        debugPrint('[LocalNotification] Tapped: ${details.payload}');
      },
    );
  }

  static Future<void> _createAndroidChannel() async {
    if (kIsWeb) return;
    if (defaultTargetPlatform != TargetPlatform.android) return;

    await _localNotifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Foreground message listener
  // ──────────────────────────────────────────────────────────────────────────

  /// When the app is OPEN, FCM does not show a system notification automatically.
  /// We use flutter_local_notifications to display one manually.
  static void _setupForegroundListener(BuildContext context) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[FCM] Foreground message: ${message.notification?.title}');
      _showLocalNotification(message);
    });
  }

  static Future<void> _showLocalNotification(RemoteMessage message) async {
    if (kIsWeb) return;
    final notification = message.notification;
    if (notification == null) return;

    final deepLink = message.data['deepLink'] as String? ?? '';

    await _localNotifications.show(
      id: notification.hashCode,
      title: notification.title,
      body: notification.body,
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          _channel.id,
          _channel.name,
          channelDescription: _channel.description,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
          color: const Color(0xFF300868),
        ),
        iOS: const DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: deepLink,
    );
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Deep-link navigation
  // ──────────────────────────────────────────────────────────────────────────

  /// Handles the case where the app was completely KILLED and user taps notification.
  static Future<void> _handleInitialMessage(BuildContext context) async {
    final RemoteMessage? message = await _fcm.getInitialMessage();
    if (message != null) {
      debugPrint('[FCM] App opened from killed state via notification.');
      // Small delay to ensure the router is ready
      await Future.delayed(const Duration(milliseconds: 500));
      if (context.mounted) {
        _navigateToDeepLink(context, message);
      }
    }
  }

  /// Handles the case where the app was BACKGROUNDED and user taps notification.
  static void _setupBackgroundOpenListener(BuildContext context) {
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('[FCM] App resumed from background via notification.');
      if (context.mounted) {
        _navigateToDeepLink(context, message);
      }
    });
  }

  static void _navigateToDeepLink(BuildContext context, RemoteMessage message) {
    final deepLink = message.data['deepLink'] as String?;
    if (deepLink != null && deepLink.isNotEmpty) {
      debugPrint('[FCM] Navigating to: $deepLink');
      GoRouter.of(context).go(deepLink);
    } else {
      debugPrint('[FCM] No deepLink in notification data — staying on current screen.');
    }
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Token management
  // ──────────────────────────────────────────────────────────────────────────

  /// Returns the current FCM registration token for this device.
  static Future<String?> getToken() async {
    try {
      if (kIsWeb) {
        // Web push requires a VAPID key — skip for v1
        return null;
      }
      return await _fcm.getToken();
    } catch (e) {
      debugPrint('[FCM] getToken error: $e');
      return null;
    }
  }

  /// Saves the FCM token to Firestore under users/{uid}.
  /// Called after login so the token is always up to date.
  static Future<void> saveTokenToFirestore(String uid) async {
    try {
      final token = await getToken();
      if (token == null) return;
      debugPrint('[FCM] Saving token for user: $uid');
      await FirebaseFirestore.instance.collection('users').doc(uid).set(
        {
          'fcmToken': token,
          'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint('[FCM] saveTokenToFirestore error: $e');
    }
  }

  /// Listens for FCM token refreshes and keeps Firestore in sync.
  static void listenForTokenRefresh(String uid) {
    _fcm.onTokenRefresh.listen((newToken) async {
      debugPrint('[FCM] Token refreshed for user: $uid');
      try {
        await FirebaseFirestore.instance.collection('users').doc(uid).set(
          {
            'fcmToken': newToken,
            'fcmTokenUpdatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      } catch (e) {
        debugPrint('[FCM] Token refresh save error: $e');
      }
    });
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Topic subscriptions
  // ──────────────────────────────────────────────────────────────────────────

  /// Subscribe to an FCM topic.
  /// Topics are set freely in the Firebase Console per notification — no hardcoding.
  /// Call this during onboarding or after login.
  static Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return; // FCM topics are not supported on web
    try {
      await _fcm.subscribeToTopic(topic);
      debugPrint('[FCM] Subscribed to topic: $topic');
    } catch (e) {
      debugPrint('[FCM] subscribeToTopic error ($topic): $e');
    }
  }

  /// Unsubscribe from an FCM topic.
  static Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    try {
      await _fcm.unsubscribeFromTopic(topic);
      debugPrint('[FCM] Unsubscribed from topic: $topic');
    } catch (e) {
      debugPrint('[FCM] unsubscribeFromTopic error ($topic): $e');
    }
  }
}
