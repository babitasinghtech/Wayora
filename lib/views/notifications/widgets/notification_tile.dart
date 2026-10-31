import 'package:flutter/material.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/models/notification_model.dart';
import 'package:login_learn_new_app/widgets/common.dart' show softShadow, timeAgo;

/// One row of the notification list. Swipe to delete.
class NotificationTile extends StatelessWidget {
  const NotificationTile({
    super.key,
    required this.item,
    required this.onTap,
    required this.onDismissed,
  });
  final AppNotification item;
  final VoidCallback onTap;
  final VoidCallback onDismissed;

  (IconData, Color) get _look => switch (item.type) {
    'like' => (Icons.favorite_rounded, Colors.redAccent),
    'comment' => (Icons.mode_comment_rounded, AppColor.kPrimary),
    _ => (Icons.notifications_rounded, Colors.blueAccent),
  };

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _look;
    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => onDismissed(),
      background: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.only(right: 22),
        alignment: Alignment.centerRight,
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: item.read ? Colors.white : AppColor.kPrimary.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(18),
          boxShadow: softShadow,
        ),
        child: ListTile(
          onTap: onTap,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.14),
            child: Icon(icon, color: color, size: 22),
          ),
          title: Text(
            item.title,
            style: TextStyle(
              fontWeight: item.read ? FontWeight.w600 : FontWeight.w800,
              fontSize: 14.5,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              '${item.body}\n${timeAgo(item.createdAt)}',
              style: const TextStyle(fontSize: 12.5),
            ),
          ),
          isThreeLine: true,
          trailing: item.read
              ? null
              : Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: AppColor.kPrimary,
                    shape: BoxShape.circle,
                  ),
                ),
        ),
      ),
    );
  }
}
