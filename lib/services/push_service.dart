import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/services/db.dart';
import 'package:login_learn_new_app/views/notifications/notifications_screen.dart';

class PushService {
  static bool _listening = false;

  static Future<void> start() async {
    if (kIsWeb || Db.myUid.isEmpty) return;
    try {
      final fm = FirebaseMessaging.instance;
      final perm = await fm.requestPermission();
      if (perm.authorizationStatus == AuthorizationStatus.denied) return;

      await fm.setForegroundNotificationPresentationOptions(
        alert: true,
        badge: true,
        sound: true,
      );
      final token = await fm.getToken();
      if (token != null) await Db.addFcmToken(token);

      if (_listening) return;
      _listening = true;
      fm.onTokenRefresh.listen((t) {
        if (Db.myUid.isNotEmpty) Db.addFcmToken(t);
      });
      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen((_) => _openInbox());
      final initial = await fm.getInitialMessage(); // app opened from a push
      if (initial != null) {
        Future.delayed(const Duration(milliseconds: 800), _openInbox);
      }
    } catch (e) {
      debugPrint('push start failed: $e');
    }
  }

  /// Call BEFORE signing out so this device stops getting the user's pushes.
  static Future<void> stop() async {
    if (kIsWeb) return;
    try {
      final fm = FirebaseMessaging.instance;
      final token = await fm.getToken();
      if (token != null && Db.myUid.isNotEmpty) await Db.removeFcmToken(token);
      await fm.deleteToken();
    } catch (e) {
      debugPrint('push stop failed: $e');
    }
  }

  static void _openInbox() => Get.to(() => const NotificationsScreen());

  static void _onForeground(RemoteMessage m) {
    final n = m.notification;
    if (n == null) return;
    Get.snackbar(
      n.title ?? 'New notification',
      n.body ?? '',
      snackPosition: SnackPosition.TOP,
      margin: const EdgeInsets.all(16),
      borderRadius: 14,
      backgroundColor: AppColor.kDark,
      colorText: Colors.white,
      icon: const Icon(Icons.notifications_active_rounded, color: Colors.white),
      duration: const Duration(seconds: 4),
      onTap: (_) => _openInbox(),
    );
  }
}
