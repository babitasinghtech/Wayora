import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class StoryViewerScreen extends StatefulWidget {
  const StoryViewerScreen({
    super.key,
    required this.userId,
    required this.userName,
  });

  final String userId;
  final String userName;

  @override
  State<StoryViewerScreen> createState() => _StoryViewerScreenState();
}

class _StoryViewerScreenState extends State<StoryViewerScreen> {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;
  final _commentController = TextEditingController();

  int _index = 0;
  bool _sending = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike(String storyId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final likeRef = _db
        .collection('stories')
        .doc(storyId)
        .collection('likes')
        .doc(user.uid);

    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(likeRef);

      if (snapshot.exists) {
        transaction.delete(likeRef);
      } else {
        transaction.set(likeRef, {
          'userId': user.uid,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  Future<void> _sendComment(String storyId) async {
    final user = _auth.currentUser;
    final text = _commentController.text.trim();

    if (user == null || text.isEmpty || _sending) return;

    setState(() => _sending = true);

    try {
      await _db.collection('stories').doc(storyId).collection('comments').add({
        'userId': user.uid,
        'userName': user.displayName ?? 'User',
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });

      _commentController.clear();
      if (mounted) {
        FocusScope.of(context).unfocus();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Comment send nahi hua.')));
      }
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      return const Scaffold(
        body: Center(child: Text('Please login to view stories')),
      );
    }

    final storiesQuery = _db
        .collection('stories')
        .where('userId', isEqualTo: widget.userId)
        .where('expiresAt', isGreaterThan: Timestamp.now())
        .orderBy('expiresAt')
        .orderBy('createdAt');

    return Scaffold(
      backgroundColor: Colors.black,
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: storiesQuery.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(
              child: Text(
                'Stories load nahi hui.',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final stories = snapshot.data!.docs;

          if (stories.isEmpty) {
            return const Center(
              child: Text(
                'No active stories',
                style: TextStyle(color: Colors.white),
              ),
            );
          }

          if (_index >= stories.length) _index = stories.length - 1;

          final story = stories[_index];
          final data = story.data();
          final storyId = story.id;
          final imageUrl = data['imageUrl'] as String? ?? '';

          return Stack(
            fit: StackFit.expand,
            children: [
              if (imageUrl.isNotEmpty)
                Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (_, __, ___) => const Center(
                    child: Icon(
                      Icons.broken_image,
                      color: Colors.white,
                      size: 50,
                    ),
                  ),
                ),

              // Tap left/right to navigate stories.
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (_index > 0) {
                          setState(() => _index--);
                        }
                      },
                    ),
                  ),
                  Expanded(
                    child: GestureDetector(
                      behavior: HitTestBehavior.translucent,
                      onTap: () {
                        if (_index < stories.length - 1) {
                          setState(() => _index++);
                        } else {
                          Navigator.pop(context);
                        }
                      },
                    ),
                  ),
                ],
              ),

              // Header
              SafeArea(
                child: Align(
                  alignment: Alignment.topCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const CircleAvatar(child: Icon(Icons.person)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            widget.userName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Like and comment controls
              Positioned(
                left: 16,
                right: 16,
                bottom: 20,
                child: Column(
                  children: [
                    Row(
                      children: [
                        StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                          stream: _db
                              .collection('stories')
                              .doc(storyId)
                              .collection('likes')
                              .doc(currentUser.uid)
                              .snapshots(),
                          builder: (context, likeSnapshot) {
                            final liked = likeSnapshot.data?.exists ?? false;

                            return IconButton(
                              onPressed: () => _toggleLike(storyId),
                              icon: Icon(
                                liked ? Icons.favorite : Icons.favorite_border,
                                color: liked ? Colors.red : Colors.white,
                                size: 30,
                              ),
                            );
                          },
                        ),
                        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                          stream: _db
                              .collection('stories')
                              .doc(storyId)
                              .collection('likes')
                              .snapshots(),
                          builder: (context, likeSnapshot) {
                            return Text(
                              '${likeSnapshot.data?.docs.length ?? 0} likes',
                              style: const TextStyle(color: Colors.white),
                            );
                          },
                        ),
                      ],
                    ),

                    // Recent comments
                    StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                      stream: _db
                          .collection('stories')
                          .doc(storyId)
                          .collection('comments')
                          .orderBy('createdAt', descending: true)
                          .limit(3)
                          .snapshots(),
                      builder: (context, commentSnapshot) {
                        final comments = commentSnapshot.data?.docs ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: comments.map((comment) {
                            final c = comment.data();
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 5),
                              child: Text(
                                '${c['userName'] ?? 'User'}: ${c['text'] ?? ''}',
                                style: const TextStyle(color: Colors.white),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            );
                          }).toList(),
                        );
                      },
                    ),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _commentController,
                            style: const TextStyle(color: Colors.white),
                            decoration: InputDecoration(
                              hintText: 'Add a comment...',
                              hintStyle: const TextStyle(color: Colors.white70),
                              filled: true,
                              fillColor: Colors.white12,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 12,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(28),
                                borderSide: BorderSide.none,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          onPressed: _sending
                              ? null
                              : () => _sendComment(storyId),
                          icon: const Icon(
                            Icons.send_rounded,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
