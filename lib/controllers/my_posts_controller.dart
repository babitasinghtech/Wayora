import 'dart:async';

import 'package:login_learn_new_app/controllers/base_post_controller.dart';
import 'package:login_learn_new_app/models/post_model.dart';
import 'package:login_learn_new_app/services/db.dart';

/// Posts created by the logged-in account (profile section + "My posts").
class MyPostsController extends BasePostController {
  List<Post> posts = [];
  bool isLoading = true;
  String? error;
  StreamSubscription? _sub;

  int get totalLikes => posts.fold(0, (sum, p) => sum + p.likes.length);

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  void retry() => _listen();

  void _listen() {
    _sub?.cancel();
    isLoading = true;
    error = null;
    update();
    _sub = Db.myPostsStream().listen(
      (snap) {
        posts = snap.docs.map(Post.fromDoc).toList()
          ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
        pruneImages(posts);
        isLoading = false;
        error = null;
        update();
      },
      onError: (Object e) {
        error = e.toString();
        isLoading = false;
        update();
      },
    );
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }
}
