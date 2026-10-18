import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/models/post_model.dart';
import 'package:login_learn_new_app/services/db.dart';
import 'package:login_learn_new_app/widgets/common.dart';

/// State for the comments sheet of ONE post.
class CommentsController extends GetxController {
  CommentsController(this.postId);
  final String postId;

  final TextEditingController input = TextEditingController();
  List<Comment> comments = [];
  bool isLoading = true;
  bool isSending = false;
  StreamSubscription? _sub;

  @override
  void onInit() {
    super.onInit();
    _sub = Db.commentsStream(postId).listen(
      (snap) {
        comments = snap.docs.map(Comment.fromDoc).toList();
        isLoading = false;
        update();
      },
      onError: (Object e) {
        isLoading = false;
        update();
        showToast('Could not load comments', '$e', ok: false);
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    input.dispose();
    super.onClose();
  }

  Future<void> send() async {
    final t = input.text.trim();
    if (t.isEmpty || isSending) return;
    isSending = true;
    update();
    try {
      await Db.addComment(postId, t);
      input.clear();
    } catch (e) {
      showToast('Could not comment', '$e', ok: false);
    } finally {
      isSending = false;
      update();
    }
  }
}
