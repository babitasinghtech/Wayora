import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:login_learn_new_app/controllers/base_post_controller.dart';
import 'package:login_learn_new_app/models/post_model.dart';
import 'package:login_learn_new_app/services/db.dart';

enum FeedScope { connections, everyone }

/// Community feed.
/// - connections: my own posts + posts of people I have chatted with
/// - everyone:    latest posts of all users
class PostController extends BasePostController {
  static const _maxFeedUsers = 30; // Firestore whereIn limit (me + 29 people)

  List<Post> posts = [];
  bool isLoading = true;
  String? error;
  FeedScope scope = FeedScope.connections;
  int connectionCount = 0;

  StreamSubscription? _chatSub;
  StreamSubscription? _postSub;
  Set<String> _feedIds = {};

  @override
  void onInit() {
    super.onInit();
    _listen();
  }

  @override
  void onClose() {
    _cancelAll();
    super.onClose();
  }

  void _cancelAll() {
    _chatSub?.cancel();
    _postSub?.cancel();
    _chatSub = null;
    _postSub = null;
    _feedIds = {};
  }

  void setScope(FeedScope s) {
    if (s == scope) return;
    scope = s;
    _listen();
  }

  void retry() => _listen();

  /// Pull-to-refresh: re-subscribe without flashing the loading skeleton.
  void refreshFeed() => _listen(showLoader: false);

  void _listen({bool showLoader = true}) {
    _cancelAll();
    if (showLoader) {
      isLoading = true;
      error = null;
      update();
    }

    if (scope == FeedScope.everyone) {
      _postSub = Db.postsStream().listen(_onPosts, onError: _onError);
      return;
    }

    // Connections = everyone I have a chat with.
    _chatSub = Db.chatsStream().listen((snap) {
      final peers = <String>{};
      for (final d in snap.docs) {
        final list = List<String>.from(d.data()['participants'] ?? const []);
        peers.addAll(list.where((id) => id.isNotEmpty && id != myUid));
      }
      connectionCount = peers.length;
      final ids = <String>{myUid, ...peers.take(_maxFeedUsers - 1)};
      if (_postSub != null &&
          ids.length == _feedIds.length &&
          ids.containsAll(_feedIds)) {
        return; // same people, the posts stream is already live
      }
      _feedIds = ids;
      _postSub?.cancel();
      _postSub = Db.postsByUsersStream(ids.toList()).listen(
        _onPosts,
        onError: _onError,
      );
    }, onError: _onError);
  }

  void _onPosts(QuerySnapshot<Map<String, dynamic>> snap) {
    final list = snap.docs.map(Post.fromDoc).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    posts = list.take(50).toList();
    pruneImages(posts);
    isLoading = false;
    error = null;
    update();
  }

  void _onError(Object e) {
    error = e.toString();
    isLoading = false;
    update();
  }
}
