import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// All Firestore reads/writes for users, posts, comments and chat.
class Db {
  static final FirebaseFirestore _fs = FirebaseFirestore.instance;

  static User? get me => FirebaseAuth.instance.currentUser;
  static String get myUid => me?.uid ?? '';

  /// Best display name we have for a Firebase user.
  static String nameOf(User? u) {
    if (u == null) return 'User';
    final n = u.displayName;
    if (n != null && n.trim().isNotEmpty) return n.trim();
    final e = u.email;
    if (e != null && e.isNotEmpty) return e.split('@').first;
    return u.phoneNumber ?? 'User';
  }

  // ---------------------------------------------------------------- users
  static Future<void> saveProfile(User u) {
    return _fs.collection('users').doc(u.uid).set({
      'uid': u.uid,
      'name': nameOf(u),
      'email': u.email,
      'phone': u.phoneNumber,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> usersStream() =>
      _fs.collection('users').limit(300).snapshots();

  // ---------------------------------------------------------------- posts
  static CollectionReference<Map<String, dynamic>> get _posts => _fs.collection('posts');

  static Stream<QuerySnapshot<Map<String, dynamic>>> postsStream() =>
      _posts.orderBy('createdAt', descending: true).limit(50).snapshots();

  static Future<void> addPost({required String text, String? imageB64}) {
    final u = me!;
    return _posts.add({
      'uid': u.uid,
      'authorName': nameOf(u),
      'text': text,
      'image': imageB64,
      'likes': <String>[],
      'commentCount': 0,
      'shareCount': 0,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> toggleLike(String postId, bool currentlyLiked) {
    return _posts.doc(postId).update({
      'likes': currentlyLiked
          ? FieldValue.arrayRemove([myUid])
          : FieldValue.arrayUnion([myUid]),
    });
  }

  static Future<void> deletePost(String postId) => _posts.doc(postId).delete();

  static Future<void> countShare(String postId) =>
      _posts.doc(postId).update({'shareCount': FieldValue.increment(1)});

  static Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(String postId) =>
      _posts.doc(postId).collection('comments').orderBy('createdAt').limit(200).snapshots();

  static Future<void> addComment(String postId, String text) {
    final u = me!;
    final post = _posts.doc(postId);
    final batch = _fs.batch();
    batch.set(post.collection('comments').doc(), {
      'uid': u.uid,
      'authorName': nameOf(u),
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(post, {'commentCount': FieldValue.increment(1)});
    return batch.commit();
  }

  // ----------------------------------------------------------------- chat
  static String chatId(String a, String b) {
    final ids = [a, b]..sort();
    return ids.join('_');
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> chatsStream() => _fs
      .collection('chats')
      .where('participants', arrayContains: myUid)
      .snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> messagesStream(String peerId) => _fs
      .collection('chats')
      .doc(chatId(myUid, peerId))
      .collection('messages')
      .orderBy('createdAt', descending: true)
      .limit(200)
      .snapshots();

  static Future<void> sendMessage({
    required String peerId,
    required String peerName,
    required String text,
  }) {
    final u = me!;
    final chat = _fs.collection('chats').doc(chatId(u.uid, peerId));
    final batch = _fs.batch();
    batch.set(chat, {
      'participants': [u.uid, peerId],
      'names': {u.uid: nameOf(u), peerId: peerName},
      'lastMessage': text,
      'lastSenderId': u.uid,
      'lastTime': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    batch.set(chat.collection('messages').doc(), {
      'senderId': u.uid,
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return batch.commit();
  }
}
