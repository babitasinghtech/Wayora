import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:login_learn_new_app/models/post_model.dart';
import 'package:login_learn_new_app/services/db.dart';
import 'package:login_learn_new_app/widgets/common.dart';
import 'package:share_plus/share_plus.dart';

/// Owns the community feed state: live posts, like / share / delete actions.
class PostController extends GetxController {
  List<Post> posts = [];
  bool isLoading = true;
  String? error;

  StreamSubscription? _sub;
  final Map<String, Uint8List> _imageCache = {}; // decode each photo only once

  String get myUid => Db.myUid;
  String get myName => Db.nameOf(Db.me);

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  @override
  void onClose() {
    _sub?.cancel();
    super.onClose();
  }

  void _listen() {
    _sub?.cancel();
    isLoading = true;
    error = null;
    update();
    _sub = Db.postsStream().listen(
      (snap) {
        posts = snap.docs.map(Post.fromDoc).toList();
        final alive = posts.map((p) => p.id).toSet();
        _imageCache.removeWhere((id, _) => !alive.contains(id));
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

  void retry() => _listen();

  /// Decoded photo bytes for a post (null when it has no / a broken photo).
  Uint8List? imageOf(Post p) {
    if (!p.hasImage) return null;
    final cached = _imageCache[p.id];
    if (cached != null) return cached;
    try {
      return _imageCache[p.id] = base64Decode(p.image!);
    } catch (_) {
      return null;
    }
  }

  // ------------------------------------------------------------ actions
  void toggleLike(Post p) {
    Db.toggleLike(p.id, p.isLikedBy(myUid)).catchError((e) {
      showToast('Error', '$e', ok: false);
    });
  }

  /// Double-tap on a photo: only ever likes, never un-likes.
  void likeOnly(Post p) {
    if (!p.isLikedBy(myUid)) toggleLike(p);
  }

  Future<void> share(Post p) async {
    final text = p.text.isEmpty
        ? 'Check out ${p.authorName}\'s post on Wanderly!'
        : '"${p.text}"\n— ${p.authorName} on Wanderly';
    try {
      await Share.share(text);
      await Db.countShare(p.id);
    } catch (e) {
      showToast('Could not share', '$e', ok: false);
    }
  }

  Future<void> delete(Post p) async {
    try {
      await Db.deletePost(p.id);
    } catch (e) {
      showToast('Error', '$e', ok: false);
    }
  }
}
