import 'package:flutter/material.dart';
import 'package:login_learn_new_app/views/posts/community_feed.dart';

class PostTab extends StatelessWidget {
  const PostTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: SafeArea(child: CommunityFeed()));
  }
}
