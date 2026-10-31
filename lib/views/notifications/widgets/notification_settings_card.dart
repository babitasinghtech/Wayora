import 'package:flutter/material.dart';
import 'package:login_learn_new_app/controllers/notification_controller.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/widgets/common.dart' show softShadow;

/// Push notification switches (saved in users/{uid}.notifPrefs).
class NotificationSettingsCard extends StatelessWidget {
  const NotificationSettingsCard({super.key, required this.controller});
  final NotificationController controller;

  @override
  Widget build(BuildContext context) {
    final pushOn = controller.prefs['push'] ?? true;

    Widget row(String key, String title, String subtitle, IconData icon, {bool master = false}) {
      final enabled = master || pushOn;
      return SwitchListTile(
        value: controller.prefs[key] ?? true,
        onChanged: enabled ? (v) => controller.setPref(key, v) : null,
        activeTrackColor: AppColor.kPrimary,
        contentPadding: EdgeInsets.zero,
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColor.kPrimary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: AppColor.kPrimary, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: softShadow,
      ),
      child: Column(
        children: [
          row('push', 'Push notifications', 'Alerts on this phone', Icons.notifications_active_rounded, master: true),
          const Divider(height: 1),
          row('likes', 'Likes', 'When someone likes your post', Icons.favorite_rounded),
          row('comments', 'Comments', 'When someone comments on your post', Icons.mode_comment_rounded),
          row('messages', 'Messages', 'New chat messages', Icons.chat_bubble_rounded),
        ],
      ),
    );
  }
}
