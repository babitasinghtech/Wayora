import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/controllers/comments_controller.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/models/post_model.dart';
import 'package:login_learn_new_app/widgets/common.dart';

/// Bottom sheet with the comments of one post. Pure UI.
class CommentsSheet extends StatelessWidget {
  const CommentsSheet({super.key, required this.postId});
  final String postId;

  static void show(String postId) {
    Get.bottomSheet(
      CommentsSheet(postId: postId),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return GetBuilder<CommentsController>(
      init: CommentsController(postId),
      global: false, // one controller per open sheet, disposed with it
      builder: (c) => AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        padding: EdgeInsets.only(bottom: inset),
        child: SizedBox(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 14),
                child: Text(
                  'Comments',
                  style: TextStyle(
                    color: AppColor.kInk,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              const Divider(height: 1),
              Expanded(child: _list(c)),
              _inputBar(c),
            ],
          ),
        ),
      ),
    );
  }

  Widget _list(CommentsController c) {
    if (c.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: AppColor.kPrimary),
      );
    }
    if (c.comments.isEmpty) {
      return const Center(
        child: Text(
          'No comments yet.\nStart the conversation!',
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.black45),
        ),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: c.comments.length,
      itemBuilder: (context, i) => _CommentTile(comment: c.comments[i]),
    );
  }

  Widget _inputBar(CommentsController c) {
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: c.input,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => c.send(),
                decoration: InputDecoration(
                  hintText: 'Add a comment...',
                  filled: true,
                  fillColor: const Color(0xFFF2F6F6),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            CircleAvatar(
              radius: 23,
              backgroundColor: AppColor.kPrimary,
              child: c.isSending
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : IconButton(
                      onPressed: c.send,
                      icon: const Icon(
                        Icons.send_rounded,
                        color: Colors.white,
                        size: 20,
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({required this.comment});
  final Comment comment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InitialAvatar(name: comment.authorName, radius: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFF2F6F6),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          comment.authorName,
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                      Text(
                        timeAgo(comment.createdAt),
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(comment.text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
