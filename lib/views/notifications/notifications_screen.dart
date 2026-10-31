import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/controllers/notification_controller.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/models/notification_model.dart';
import 'package:login_learn_new_app/views/notifications/widgets/notification_settings_card.dart';
import 'package:login_learn_new_app/views/notifications/widgets/notification_tile.dart';
import 'package:login_learn_new_app/views/post/widgets/comments_sheet.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  void _open(NotificationController c, AppNotification n) {
    c.markRead(n);
    if (n.type == 'comment' && n.postId != null) CommentsSheet.show(n.postId!);
  }

  @override
  Widget build(BuildContext context) {
    return GetBuilder<NotificationController>(
      init: NotificationController.ensure(),
      builder: (c) => Scaffold(
        backgroundColor: const Color(0xFFF6FAF9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          iconTheme: const IconThemeData(color: AppColor.kInk),
          title: const Text(
            'Notifications',
            style: TextStyle(color: AppColor.kInk, fontWeight: FontWeight.w800),
          ),
          actions: [
            if (c.unread > 0)
              TextButton(
                onPressed: c.markAllRead,
                child: const Text('Mark all read'),
              ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 30),
          children: [
            NotificationSettingsCard(controller: c),
            const SizedBox(height: 22),
            const Padding(
              padding: EdgeInsets.fromLTRB(4, 0, 4, 10),
              child: Text(
                'Recent activity',
                style: TextStyle(
                  color: AppColor.kInk,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (c.isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: CircularProgressIndicator(color: AppColor.kPrimary),
                ),
              )
            else if (c.items.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Column(
                  children: [
                    Icon(
                      Icons.notifications_off_outlined,
                      size: 54,
                      color: Colors.black26,
                    ),
                    SizedBox(height: 10),
                    Text(
                      'No notifications yet.\nLikes and comments on your posts will show up here.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black45),
                    ),
                  ],
                ),
              )
            else
              for (final n in c.items)
                NotificationTile(
                  item: n,
                  onTap: () => _open(c, n),
                  onDismissed: () => c.remove(n),
                ),
          ],
        ),
      ),
    );
  }
}
