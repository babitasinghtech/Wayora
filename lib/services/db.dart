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
    return 'User'; // never expose the phone number as a public name
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

  /// Extra profile data kept in users/{uid}: bio + photo (base64).
  static Future<Map<String, dynamic>> myProfile() async {
    final d = await _fs.collection('users').doc(myUid).get();
    return d.data() ?? <String, dynamic>{};
  }

  static Future<void> saveProfileExtras({
    required String bio,
    String? photoB64,
    bool removePhoto = false,
  }) {
    final data = <String, dynamic>{
      'bio': bio,
      'updatedAt': FieldValue.serverTimestamp(),
    };
    if (photoB64 != null) data['photo'] = photoB64;
    if (removePhoto) data['photo'] = FieldValue.delete();
    return _fs.collection('users').doc(myUid).set(data, SetOptions(merge: true));
  }

  /// After a phone user sets their name, replace the old (phone-number)
  /// author name on their existing posts.
  static Future<void> updateMyPostsName(String name) async {
    final snap = await _fs.collection('posts').where('uid', isEqualTo: myUid).get();
    if (snap.docs.isEmpty) return;
    final batch = _fs.batch();
    for (final d in snap.docs) {
      batch.update(d.reference, {'authorName': name});
    }
    await batch.commit();
  }

  static Stream<QuerySnapshot<Map<String, dynamic>>> usersStream() =>
      _fs.collection('users').limit(300).snapshots();

  // ---------------------------------------------------------------- posts
  static CollectionReference<Map<String, dynamic>> get _posts => _fs.collection('posts');

  static Stream<QuerySnapshot<Map<String, dynamic>>> postsStream() =>
      _posts.orderBy('createdAt', descending: true).limit(50).snapshots();

  /// Posts of the given users (max 30 ids). No orderBy on purpose, so no
  /// composite index is needed - the controller sorts by time.
  static Stream<QuerySnapshot<Map<String, dynamic>>> postsByUsersStream(List<String> uids) =>
      _posts.where('uid', whereIn: uids).snapshots();

  static Stream<QuerySnapshot<Map<String, dynamic>>> myPostsStream() =>
      _posts.where('uid', isEqualTo: myUid).snapshots();

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

  static Future<void> toggleLike(
    String postId,
    bool currentlyLiked, {
    String? ownerUid,
  }) async {
    await _posts.doc(postId).update({
      'likes': currentlyLiked
          ? FieldValue.arrayRemove([myUid])
          : FieldValue.arrayUnion([myUid]),
    });
    if (ownerUid == null || ownerUid.isEmpty || ownerUid == myUid) return;
    final id = 'like_${postId}_$myUid'; // one notification per person per post
    try {
      if (currentlyLiked) {
        await removeNotification(ownerUid, id);
      } else {
        await addNotification(
          toUid: ownerUid,
          type: 'like',
          title: '${nameOf(me)} liked your post',
          body: 'Your post got a new like.',
          postId: postId,
          docId: id,
        );
      }
    } catch (_) {/* notification is best-effort */}
  }

  static Future<void> deletePost(String postId) => _posts.doc(postId).delete();

  static Future<void> countShare(String postId) =>
      _posts.doc(postId).update({'shareCount': FieldValue.increment(1)});

  static Stream<QuerySnapshot<Map<String, dynamic>>> commentsStream(String postId) =>
      _posts.doc(postId).collection('comments').orderBy('createdAt').limit(200).snapshots();

  static Future<void> addComment(String postId, String text) async {
    final u = me!;
    final post = _posts.doc(postId);
    final ownerUid = ((await post.get()).data()?['uid'] ?? '') as String;
    final batch = _fs.batch();
    batch.set(post.collection('comments').doc(), {
      'uid': u.uid,
      'authorName': nameOf(u),
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(post, {'commentCount': FieldValue.increment(1)});
    await batch.commit();
    try {
      await addNotification(
        toUid: ownerUid,
        type: 'comment',
        title: '${nameOf(u)} commented on your post',
        body: text.length > 80 ? '${text.substring(0, 80)}...' : text,
        postId: postId,
      );
    } catch (_) {/* notification is best-effort */}
  }

  // -------------------------------------------------------- notifications
  static CollectionReference<Map<String, dynamic>> _notifs(String uid) =>
      _fs.collection('users').doc(uid).collection('notifications');

  static Stream<QuerySnapshot<Map<String, dynamic>>> notificationsStream() =>
      _notifs(myUid).orderBy('createdAt', descending: true).limit(50).snapshots();

  /// Writes an in-app notification into the receiver's inbox. A Cloud Function
  /// (see SETUP_NOTIFICATIONS.md) turns each new doc into a push message.
  static Future<void> addNotification({
    required String toUid,
    required String type, // like | comment
    required String title,
    required String body,
    String? postId,
    String? docId,
  }) {
    if (toUid.isEmpty || toUid == myUid) return Future.value();
    final ref = docId == null ? _notifs(toUid).doc() : _notifs(toUid).doc(docId);
    return ref.set({
      'type': type,
      'title': title,
      'body': body,
      'postId': postId,
      'fromUid': myUid,
      'fromName': nameOf(me),
      'read': false,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> removeNotification(String toUid, String docId) =>
      _notifs(toUid).doc(docId).delete();

  static Future<void> markNotificationRead(String id) =>
      _notifs(myUid).doc(id).update({'read': true});

  static Future<void> markAllNotificationsRead(Iterable<String> ids) async {
    final batch = _fs.batch();
    for (final id in ids) {
      batch.update(_notifs(myUid).doc(id), {'read': true});
    }
    await batch.commit();
  }

  static Future<void> deleteMyNotification(String id) => _notifs(myUid).doc(id).delete();

  static Stream<DocumentSnapshot<Map<String, dynamic>>> myProfileStream() =>
      _fs.collection('users').doc(myUid).snapshots();

  static Future<void> setNotifPref(String key, bool value) =>
      _fs.collection('users').doc(myUid).set({
        'notifPrefs': {key: value},
      }, SetOptions(merge: true));

  static Future<void> addFcmToken(String token) =>
      _fs.collection('users').doc(myUid).set({
        'fcmTokens': FieldValue.arrayUnion([token]),
      }, SetOptions(merge: true));

  static Future<void> removeFcmToken(String token) =>
      _fs.collection('users').doc(myUid).set({
        'fcmTokens': FieldValue.arrayRemove([token]),
      }, SetOptions(merge: true));

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
