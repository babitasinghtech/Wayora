import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/controllers/my_posts_controller.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/views/post/my_posts_screen.dart';

MyPostsController _controller() => Get.isRegistered<MyPostsController>()
    ? Get.find<MyPostsController>()
    : MyPostsController();

/// "Posts" number for the profile stats card (tap to open My posts).
class ProfilePostsStat extends StatelessWidget {
  const ProfilePostsStat({super.key});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GetBuilder<MyPostsController>(
        init: _controller(),
        builder: (c) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: openMyPosts,
          child: Column(
            children: [
              Text(
                '${c.posts.length}',
                style: const TextStyle(
                  color: AppColor.kInk,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Posts',
                style: TextStyle(color: Colors.black54, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
