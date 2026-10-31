import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  const AppNotification({
    required this.id,
    required this.type,
    required this.title,
    required this.body,
    required this.fromName,
    required this.postId,
    required this.read,
    required this.createdAt,
  });

  final String id, type, title, body, fromName;
  final String? postId;
  final bool read;
  final DateTime createdAt;

  factory AppNotification.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? const <String, dynamic>{};
    final ts = m['createdAt'];
    return AppNotification(
      id: d.id,
      type: (m['type'] ?? '') as String,
      title: (m['title'] ?? '') as String,
      body: (m['body'] ?? '') as String,
      fromName: (m['fromName'] ?? 'Someone') as String,
      postId: m['postId'] as String?,
      read: (m['read'] ?? false) as bool,
      createdAt: ts is Timestamp ? ts.toDate() : DateTime.now(),
    );
  }
}
