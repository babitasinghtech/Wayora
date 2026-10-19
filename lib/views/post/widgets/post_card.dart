import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/controllers/base_post_controller.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/models/post_model.dart';
import 'package:login_learn_new_app/views/post/widgets/comments_sheet.dart';
import 'package:login_learn_new_app/widgets/common.dart';

/// One post in the feed (like / comment / share). Pure UI.
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post, required this.controller});
  final Post post;
  final BasePostController controller;

  void _confirmDelete() {
    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Text('Delete post?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: Get.back, child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              Get.back();
              controller.delete(post);
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liked = post.isLikedBy(controller.myUid);
    final img = controller.imageOf(post);

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: softShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _header(),
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: _ExpandableText(post.text),
            ),
          if (img != null)
            _LikeableImage(
              bytes: img,
              onDoubleTap: () => controller.likeOnly(post),
            ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Row(
              children: [
                PostActionButton(
                  icon: liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: liked ? Colors.redAccent : AppColor.kInk,
                  label: '${post.likes.length}',
                  onTap: () => controller.toggleLike(post),
                ),
                PostActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: '${post.commentCount}',
                  onTap: () => CommentsSheet.show(post.id),
                ),
                PostActionButton(
                  icon: Icons.share_outlined,
                  label: '${post.shareCount}',
                  onTap: () => controller.share(post),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _header() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 6, 6),
      child: Row(
        children: [
          InitialAvatar(name: post.authorName, radius: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        post.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColor.kInk,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    if (post.isOwnedBy(controller.myUid)) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: AppColor.kPrimary.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'You',
                          style: TextStyle(
                            color: AppColor.kPrimary,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                Text(
                  timeAgo(post.createdAt),
                  style: const TextStyle(color: Colors.black45, fontSize: 12),
                ),
              ],
            ),
          ),
          if (post.isOwnedBy(controller.myUid))
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_horiz_rounded, color: Colors.black45),
              onSelected: (_) => _confirmDelete(),
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'delete', child: Text('Delete post')),
              ],
            )
          else
            const SizedBox(width: 8),
        ],
      ),
    );
  }
}

class PostActionButton extends StatelessWidget {
  const PostActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColor.kInk,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        child: Row(
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) =>
                  ScaleTransition(scale: anim, child: child),
              child: Icon(icon, key: ValueKey(icon), color: color, size: 24),
            ),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

/// Text that collapses after 4 lines with a "more" toggle.
class _ExpandableText extends StatefulWidget {
  const _ExpandableText(this.text);
  final String text;

  @override
  State<_ExpandableText> createState() => _ExpandableTextState();
}

class _ExpandableTextState extends State<_ExpandableText> {
  static const _style = TextStyle(color: AppColor.kInk, fontSize: 15, height: 1.4);
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) {
        final tp = TextPainter(
          text: TextSpan(text: widget.text, style: _style),
          maxLines: 4,
          textDirection: TextDirection.ltr,
        )..layout(maxWidth: box.maxWidth);
        final overflows = tp.didExceedMaxLines;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.text,
              style: _style,
              maxLines: _open ? null : 4,
              overflow: _open ? TextOverflow.visible : TextOverflow.ellipsis,
            ),
            if (overflows)
              GestureDetector(
                onTap: () => setState(() => _open = !_open),
                child: Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    _open ? 'Show less' : 'more',
                    style: const TextStyle(
                      color: AppColor.kPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}

/// Post photo; double-tap shows a heart burst and likes the post.
class _LikeableImage extends StatefulWidget {
  const _LikeableImage({required this.bytes, required this.onDoubleTap});
  final Uint8List bytes;
  final VoidCallback onDoubleTap;

  @override
  State<_LikeableImage> createState() => _LikeableImageState();
}

class _LikeableImageState extends State<_LikeableImage> {
  bool _burst = false;

  void _onDoubleTap() {
    widget.onDoubleTap();
    setState(() => _burst = true);
    Future.delayed(const Duration(milliseconds: 650), () {
      if (mounted) setState(() => _burst = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: AspectRatio(
            aspectRatio: 1,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.memory(widget.bytes, fit: BoxFit.cover, gaplessPlayback: true),
                Center(
                  child: AnimatedScale(
                    scale: _burst ? 1.0 : 0.4,
                    duration: const Duration(milliseconds: 250),
                    curve: Curves.easeOutBack,
                    child: AnimatedOpacity(
                      opacity: _burst ? 1 : 0,
                      duration: const Duration(milliseconds: 200),
                      child: const Icon(
                        Icons.favorite_rounded,
                        color: Colors.white,
                        size: 96,
                        shadows: [Shadow(color: Colors.black38, blurRadius: 18)],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
