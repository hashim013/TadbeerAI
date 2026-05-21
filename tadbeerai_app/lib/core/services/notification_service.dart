import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../models/execution_notification.dart';
import '../models/tadbeer_models.dart';
import '../models/user_profile.dart';
import 'alert_store.dart';
import 'user_profile_service.dart';

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  static const _channelId = 'tadbeer_execution';
  static const _channelName = 'Execution alerts';

  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _local.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTap,
    );

    const channel = AndroidNotificationChannel(
      _channelId,
      _channelName,
      description: 'Alerts when TadbeerAI executes an action',
      importance: Importance.high,
    );
    await _local
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    try {
      final messaging = FirebaseMessaging.instance;
      await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await messaging.getToken();
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (token != null && uid != null) {
        await UserProfileService.instance.updateFcmToken(uid, token);
      }
      FirebaseMessaging.onMessage.listen(_onForegroundMessage);
    } catch (e) {
      debugPrint('FCM init skipped: $e');
    }

    _initialized = true;
  }

  void _onNotificationTap(NotificationResponse response) {
    debugPrint('Notification tapped: ${response.payload}');
  }

  void _onForegroundMessage(RemoteMessage message) {
    debugPrint('FCM foreground: ${message.notification?.title}');
  }

  DeliveryReport buildDeliveryReport(
    SimulationResult result,
    UserProfile? profile,
  ) {
    if (result.deliveryReport != null) return result.deliveryReport!;
    if (profile == null) {
      return DeliveryReport(
        smsRecipients: 0,
        emailRecipients: 0,
        pushRecipients: result.usersReached,
        status: 'sent',
        smsSkipped: true,
        emailSkipped: true,
      );
    }
    return DeliveryReport.fallback(
      usersReached: result.usersReached,
      notifySms: profile.notifySms,
      notifyEmail: profile.notifyEmail,
      notifyPush: profile.notifyPush,
      hasPhone: profile.phone.isNotEmpty,
      hasEmail: profile.email.isNotEmpty,
    );
  }

  Future<ExecutionNotification> dispatchExecutionAlert({
    required SimulationResult result,
    String? actionTitle,
    UserProfile? profile,
  }) async {
    await initialize();

    final delivery = buildDeliveryReport(result, profile);
    final notification = ExecutionNotification.fromSimulation(
      result: result,
      delivery: delivery,
      title: actionTitle != null
          ? 'Executed: $actionTitle'
          : 'Execution completed',
    );

    await AlertStore.instance.addExecution(notification);

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      try {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .collection('execution_alerts')
            .doc(notification.id)
            .set(notification.toJson());
      } catch (e) {
        debugPrint('Firestore alert save failed: $e');
      }
    }

    await _showLocalNotification(notification);
    return notification;
  }

  Future<void> _showLocalNotification(ExecutionNotification n) async {
    final android = AndroidNotificationDetails(
      _channelId,
      _channelName,
      channelDescription: 'Execution result alerts',
      importance: Importance.high,
      priority: Priority.high,
      icon: '@mipmap/ic_launcher',
    );
    await _local.show(
      n.id.hashCode,
      n.title,
      n.summary,
      NotificationDetails(android: android),
      payload: n.id,
    );
  }
}
