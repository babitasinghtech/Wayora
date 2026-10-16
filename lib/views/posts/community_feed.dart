import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:share_plus/share_plus.dart';
import 'package:login_learn_new_app/widgets/common.dart';
import 'package:login_learn_new_app/services/db.dart';
import 'package:login_learn_new_app/views/posts/add_post_screen.dart';

class Post {
  Post({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.text,
    required this.image,
    required this.createdAt,
    required this.likes,
    required this.commentCount,
    required this.shareCount,
  });

  final String id, uid, authorName, text;
  final String? image;
  final DateTime createdAt;
  final List<String> likes;
  final int commentCount, shareCount;

  factory Post.fromDoc(QueryDocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data();
    final ts = m['createdAt'];
    return Post(
      id: d.id,
      uid: (m['uid'] ?? '') as String,
      authorName: (m['authorName'] ?? 'User') as String,
      text: (m['text'] ?? '') as String,
      image: m['image'] as String?,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
      likes: List<String>.from(m['likes'] ?? const []),
      commentCount: ((m['commentCount'] ?? 0) as num).toInt(),
      shareCount: ((m['shareCount'] ?? 0) as num).toInt(),
    );
  }
}

// ============================================================
// FEED
// ============================================================
class CommunityFeed extends StatelessWidget {
  const CommunityFeed({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: Db.postsStream(),
      builder: (context, snap) {
        if (snap.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Text(
                'Could not load posts.\n\nMake sure Firestore is created and the rules are deployed (see SOCIAL_SETUP.md).\n\n${snap.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54),
              ),
            ),
          );
        }
        if (!snap.hasData) {
          return const Center(
            child: CircularProgressIndicator(color: AppColor.kPrimary),
          );
        }
        final posts = snap.data!.docs.map(Post.fromDoc).toList();
        return ListView.builder(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          itemCount: posts.length + 1,
          itemBuilder: (context, i) {
            if (i == 0) {
              return Column(
                children: [
                  const _Composer(),
                  if (posts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 50),
                      child: Column(
                        children: [
                          Icon(
                            Icons.photo_camera_back_rounded,
                            size: 56,
                            color: Colors.black26,
                          ),
                          SizedBox(height: 10),
                          Text(
                            'No posts yet.\nBe the first to share a moment!',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.black45),
                          ),
                        ],
                      ),
                    ),
                ],
              );
            }
            return PostCard(post: posts[i - 1]);
          },
        );
      },
    );
  }
}

class _Composer extends StatelessWidget {
  const _Composer();

  @override
  Widget build(BuildContext context) {
    final name = Db.nameOf(Db.me);
    return GestureDetector(
      onTap: () => Get.to(() => const AddPostScreen()),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: softShadow,
        ),
        child: Row(
          children: [
            InitialAvatar(name: name, radius: 21),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Share your travel moment...',
                style: TextStyle(color: Colors.black45, fontSize: 15),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: AppColor.kPrimary.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.add_photo_alternate_rounded,
                color: AppColor.kPrimary,
                size: 22,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// POST CARD  (like / comment / share)
// ============================================================
class PostCard extends StatelessWidget {
  const PostCard({super.key, required this.post});
  final Post post;

  static final Map<String, Uint8List> _bytes = {}; // decode each image once

  bool get _mine => post.uid == Db.myUid;
  bool get _liked => post.likes.contains(Db.myUid);

  void _toggleLike() {
    Db.toggleLike(post.id, _liked).catchError((e) {
      showToast('Error', '$e', ok: false);
    });
  }

  Future<void> _share() async {
    final text = post.text.isEmpty
        ? 'Check out ${post.authorName}\'s post on Wanderly!'
        : '"${post.text}"\n— ${post.authorName} on Wanderly';
    try {
      await Share.share(text);
      await Db.countShare(post.id);
    } catch (e) {
      showToast('Could not share', '$e', ok: false);
    }
  }

  void _comments() {
    Get.bottomSheet(
      _CommentsSheet(postId: post.id),
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
    );
  }

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
              Db.deletePost(post.id).catchError((e) {
                showToast('Error', '$e', ok: false);
              });
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final liked = _liked;
    Uint8List? img;
    if (post.image != null && post.image!.isNotEmpty) {
      img = _bytes.putIfAbsent(post.id, () => base64Decode(post.image!));
    }

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
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 6, 6),
            child: Row(
              children: [
                InitialAvatar(name: post.authorName, radius: 21),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        post.authorName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColor.kInk,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        timeAgo(post.createdAt),
                        style: const TextStyle(
                          color: Colors.black45,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                if (_mine)
                  PopupMenuButton<String>(
                    icon: const Icon(
                      Icons.more_horiz_rounded,
                      color: Colors.black45,
                    ),
                    onSelected: (_) => _confirmDelete(),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete post'),
                      ),
                    ],
                  )
                else
                  const SizedBox(width: 8),
              ],
            ),
          ),
          if (post.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 10),
              child: Text(
                post.text,
                style: const TextStyle(
                  color: AppColor.kInk,
                  fontSize: 15,
                  height: 1.4,
                ),
              ),
            ),
          if (img != null)
            GestureDetector(
              onDoubleTap: () {
                if (!liked) _toggleLike(); // double-tap photo to like
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: AspectRatio(
                    aspectRatio: 1,
                    child: Image.memory(
                      img,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      gaplessPlayback: true,
                    ),
                  ),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
            child: Row(
              children: [
                _ActionButton(
                  icon: liked
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: liked ? Colors.redAccent : AppColor.kInk,
                  label: '${post.likes.length}',
                  onTap: _toggleLike,
                ),
                _ActionButton(
                  icon: Icons.mode_comment_outlined,
                  label: '${post.commentCount}',
                  onTap: _comments,
                ),
                _ActionButton(
                  icon: Icons.share_outlined,
                  label: '${post.shareCount}',
                  onTap: _share,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
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

// ============================================================
// COMMENTS BOTTOM SHEET
// ============================================================
class _CommentsSheet extends StatefulWidget {
  const _CommentsSheet({required this.postId});
  final String postId;

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final _text = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      await Db.addComment(widget.postId, t);
      _text.clear();
    } catch (e) {
      showToast('Could not comment', '$e', ok: false);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final inset = MediaQuery.of(context).viewInsets.bottom;
    return AnimatedPadding(
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
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: Db.commentsStream(widget.postId),
                builder: (context, snap) {
                  if (!snap.hasData) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: AppColor.kPrimary,
                      ),
                    );
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
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
                    itemCount: docs.length,
                    itemBuilder: (context, i) {
                      final m = docs[i].data();
                      final ts = m['createdAt'];
                      final name = (m['authorName'] ?? 'User') as String;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            InitialAvatar(name: name, radius: 18),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 10,
                                ),
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
                                            name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w800,
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        Text(
                                          timeAgo(
                                            ts is Timestamp
                                                ? ts.toDate()
                                                : DateTime.now(),
                                          ),
                                          style: const TextStyle(
                                            color: Colors.black45,
                                            fontSize: 11,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 3),
                                    Text((m['text'] ?? '') as String),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 12, 10),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _text,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
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
                      child: _sending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : IconButton(
                              onPressed: _send,
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
            ),
          ],
        ),
      ),
    );
  }
}
