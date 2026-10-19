import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/controllers/my_posts_controller.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/views/post/add_post_screen.dart';
import 'package:login_learn_new_app/views/post/widgets/post_card.dart';
import 'package:login_learn_new_app/views/post/widgets/post_states.dart';

void openMyPosts() => Get.to(() => const MyPostsScreen());

/// Everything this account has posted, in one screen. UI only.
class MyPostsScreen extends StatelessWidget {
  const MyPostsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<MyPostsController>(
      init: Get.isRegistered<MyPostsController>()
          ? Get.find<MyPostsController>()
          : MyPostsController(),
      builder: (c) => Scaffold(
        backgroundColor: const Color(0xFFF6FAF9),
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          title: Text(
            'My posts (${c.posts.length})',
            style: const TextStyle(
              color: AppColor.kInk,
              fontWeight: FontWeight.w800,
            ),
          ),
          iconTheme: const IconThemeData(color: AppColor.kInk),
          actions: [
            IconButton(
              tooltip: 'New post',
              onPressed: () => Get.to(() => const AddPostScreen()),
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
        body: _body(c),
      ),
    );
  }

  Widget _body(MyPostsController c) {
    if (c.isLoading) return const PostFeedSkeleton();
    if (c.error != null) {
      return PostErrorView(message: c.error!, onRetry: c.retry);
    }
    if (c.posts.isEmpty) {
      return const Center(
        child: PostEmptyView(
          message: 'You have not posted anything yet.\nTap + to share your first moment!',
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      itemCount: c.posts.length,
      itemBuilder: (context, i) => PostCard(
        key: ValueKey(c.posts[i].id),
        post: c.posts[i],
        controller: c,
      ),
    );
  }
}
