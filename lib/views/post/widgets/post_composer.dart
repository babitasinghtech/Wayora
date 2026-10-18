import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/views/post/add_post_screen.dart';
import 'package:login_learn_new_app/widgets/common.dart';

/// "Share your travel moment..." bar at the top of the feed.
class PostComposer extends StatelessWidget {
  const PostComposer({super.key, required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Get.to(() => const AddPostScreen()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: softShadow,
        ),
        child: Row(
          children: [
            InitialAvatar(name: name, radius: 21),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Share your travel moment...',
                style: TextStyle(color: Colors.black45, fontSize: 15),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColor.kPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                color: AppColor.kPrimary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
