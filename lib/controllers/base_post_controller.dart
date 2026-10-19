import 'dart:convert';
import 'dart:typed_data';

import 'package:get/get.dart';
import 'package:login_learn_new_app/models/post_model.dart';
import 'package:login_learn_new_app/services/db.dart';
import 'package:login_learn_new_app/widgets/common.dart';
import 'package:share_plus/share_plus.dart';

/// Shared post actions (like / share / delete / photo decoding) used by every
/// screen that shows [PostCard]s: the community feed and "My posts".
abstract class BasePostController extends GetxController {
  final Map<String, Uint8List> _imageCache = {}; // decode each photo only once

  String get myUid => Db.myUid;
  String get myName => Db.nameOf(Db.me);

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

  /// Drop cached photos of posts that are gone.
  void pruneImages(Iterable<Post> alive) {
    final ids = alive.map((p) => p.id).toSet();
    _imageCache.removeWhere((id, _) => !ids.contains(id));
  }

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
