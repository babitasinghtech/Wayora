import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/models/notification_model.dart';
import 'package:login_learn_new_app/services/db.dart';
import 'package:login_learn_new_app/widgets/common.dart';

/// Notification inbox + push settings of the logged-in user.
/// Permanent: it follows the login state, so the bell badge is always right.
class NotificationController extends GetxController {
  static NotificationController ensure() =>
      Get.isRegistered<NotificationController>()
      ? Get.find<NotificationController>()
      : Get.put(NotificationController(), permanent: true);

  static const _defaults = {
    'push': true,
    'likes': true,
    'comments': true,
    'messages': true,
  };

  List<AppNotification> items = [];
  Map<String, bool> prefs = Map.of(_defaults);
  bool isLoading = true;

  int get unread => items.where((n) => !n.read).length;

  StreamSubscription? _authSub, _listSub, _prefSub;

  @override
  void onInit() {
    super.onInit();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_bind);
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _listSub?.cancel();
    _prefSub?.cancel();
    super.onClose();
  }

  void _bind(User? u) {
    _listSub?.cancel();
    _prefSub?.cancel();
    items = [];
    prefs = Map.of(_defaults);
    isLoading = u != null;
    update();
    if (u == null) return;

    _listSub = Db.notificationsStream().listen(
      (snap) {
        items = snap.docs.map(AppNotification.fromDoc).toList();
        isLoading = false;
        update();
      },
      onError: (Object e) {
        isLoading = false;
        update();
      },
    );
    _prefSub = Db.myProfileStream().listen((doc) {
      final saved = (doc.data()?['notifPrefs'] as Map?) ?? const {};
      prefs = {
        for (final k in _defaults.keys) k: (saved[k] as bool?) ?? _defaults[k]!,
      };
      update();
    }, onError: (Object e) {});
  }

  // ------------------------------------------------------------ actions
  Future<void> setPref(String key, bool value) async {
    prefs[key] = value; // optimistic
    update();
    try {
      await Db.setNotifPref(key, value);
    } catch (e) {
      prefs[key] = !value;
      update();
      showToast('Could not save setting', '$e', ok: false);
    }
  }

  Future<void> markRead(AppNotification n) async {
    if (n.read) return;
    try {
      await Db.markNotificationRead(n.id);
    } catch (_) {}
  }

  Future<void> markAllRead() async {
    final ids = items.where((n) => !n.read).map((n) => n.id).toList();
    if (ids.isEmpty) return;
    try {
      await Db.markAllNotificationsRead(ids);
    } catch (e) {
      showToast('Error', '$e', ok: false);
    }
  }

  Future<void> remove(AppNotification n) async {
    try {
      await Db.deleteMyNotification(n.id);
    } catch (e) {
      showToast('Error', '$e', ok: false);
    }
  }
}
