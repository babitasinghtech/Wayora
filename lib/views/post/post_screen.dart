import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/controllers/post_controller.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/views/post/my_posts_screen.dart';
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
        backgroundColor: const Color(0xFFF6FAF9),
        body: SafeArea(
          bottom: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _header(c),
              _scopeChips(c),
              Expanded(child: _body(c)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _header(PostController c) {
    final subtitle = c.scope == FeedScope.connections
        ? 'You and your circle'
        : 'Latest from everyone';
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 10),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Community',
                  style: TextStyle(
                    color: AppColor.kInk,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.black45, fontSize: 13),
                ),
              ],
            ),
          ),
          // OutlinedButton.icon(
          //   onPressed: openMyPosts,
          //   icon: const Icon(Icons.grid_view_rounded, size: 18),
          //   label: const Text('My posts'),
          //   style: OutlinedButton.styleFrom(
          //     foregroundColor: AppColor.kPrimary,
          //     backgroundColor: Colors.white,
          //     side: const BorderSide(color: AppColor.kPrimary),
          //     shape: RoundedRectangleBorder(
          //       borderRadius: BorderRadius.circular(20),
          //     ),
          //     textStyle: const TextStyle(fontWeight: FontWeight.w700),
          //   ),
          // ),
        ],
      ),
    );
  }

  Widget _scopeChips(PostController c) {
    Widget chip(String label, IconData icon, FeedScope s) {
      final selected = c.scope == s;
      return Padding(
        padding: const EdgeInsets.only(right: 10),
        child: ChoiceChip(
          avatar: Icon(
            icon,
            size: 18,
            color: selected ? Colors.white : AppColor.kPrimary,
          ),
          label: Text(label),
          selected: selected,
          onSelected: (_) => c.setScope(s),
          showCheckmark: false,
          selectedColor: AppColor.kPrimary,
          backgroundColor: Colors.white,
          labelStyle: TextStyle(
            color: selected ? Colors.white : AppColor.kInk,
            fontWeight: FontWeight.w700,
          ),
          side: BorderSide(
            color: selected ? AppColor.kPrimary : Colors.black12,
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
      child: Row(
        children: [
          chip('My circle', Icons.people_alt_rounded, FeedScope.connections),
          chip('Everyone', Icons.public_rounded, FeedScope.everyone),
        ],
      ),
    );
  }

  Widget _body(PostController c) {
    if (c.isLoading) return const PostFeedSkeleton();
    if (c.error != null) {
      return PostErrorView(message: c.error!, onRetry: c.retry);
    }
    final posts = c.posts;
    return RefreshIndicator(
      color: AppColor.kPrimary,
      onRefresh: () async {
        c.refreshFeed();
        await Future.delayed(const Duration(milliseconds: 700));
      },
      child: ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
        itemCount: posts.length + 1,
        itemBuilder: (context, i) {
          if (i == 0) {
            return Column(
              children: [
                PostComposer(name: c.myName),
                if (posts.isEmpty)
                  PostEmptyView(
                    message: c.scope == FeedScope.connections
                        ? 'No posts in your circle yet.\nPost something, or chat with people to see theirs here.'
                        : 'No posts yet.\nBe the first to share a moment!',
                  ),
              ],
            );
          }
          final post = posts[i - 1];
          return PostCard(key: ValueKey(post.id), post: post, controller: c);
        },
      ),
    );
  }
}
