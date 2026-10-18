import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/controllers/post_controller.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/views/post/widgets/post_card.dart';
import 'package:login_learn_new_app/views/post/widgets/post_composer.dart';
import 'package:login_learn_new_app/views/post/widgets/post_states.dart';

/// Community feed tab. UI only - all state lives in [PostController].
class PostTab extends StatelessWidget {
  const PostTab({super.key});

  @override
  Widget build(BuildContext context) {
    return GetBuilder<PostController>(
      init: PostController(),
      builder: (c) => Scaffold(
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 18, 20, 12),
                child: Text(
                  'Community',
                  style: TextStyle(
                    color: AppColor.kInk,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Expanded(child: _body(c)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _body(PostController c) {
    if (c.isLoading) return const PostFeedSkeleton();
    if (c.error != null) {
      return PostErrorView(message: c.error!, onRetry: c.retry);
    }
    final posts = c.posts;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      itemCount: posts.length + 1,
      itemBuilder: (context, i) {
        if (i == 0) {
          return Column(
            children: [
              PostComposer(name: c.myName),
              if (posts.isEmpty) const PostEmptyView(),
            ],
          );
        }
        final post = posts[i - 1];
        return PostCard(key: ValueKey(post.id), post: post, controller: c);
      },
    );
  }
}
