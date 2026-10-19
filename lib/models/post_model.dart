import 'package:cloud_firestore/cloud_firestore.dart';

DateTime _toTime(dynamic ts) => ts is Timestamp ? ts.toDate() : DateTime.now();

class Post {
  const Post({
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

  bool get hasImage => image != null && image!.isNotEmpty;
  bool isLikedBy(String userId) => likes.contains(userId);
  bool isOwnedBy(String userId) => uid == userId;

  factory Post.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return Post(
      id: d.id,
      uid: (m['uid'] ?? '') as String,
      authorName: (m['authorName'] ?? 'User') as String,
      text: (m['text'] ?? '') as String,
      image: m['image'] as String?,
      createdAt: _toTime(m['createdAt']),
      likes: List<String>.from(m['likes'] ?? const []),
      commentCount: ((m['commentCount'] ?? 0) as num).toInt(),
      shareCount: ((m['shareCount'] ?? 0) as num).toInt(),
    );
  }
}

/// A comment under a post.
class Comment {
  const Comment({
    required this.id,
    required this.uid,
    required this.authorName,
    required this.text,
    required this.createdAt,
  });

  final String id, uid, authorName, text;
  final DateTime createdAt;

  factory Comment.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    return Comment(
      id: d.id,
      uid: (m['uid'] ?? '') as String,
      authorName: (m['authorName'] ?? 'User') as String,
      text: (m['text'] ?? '') as String,
      createdAt: _toTime(m['createdAt']),
    );
  }
}
