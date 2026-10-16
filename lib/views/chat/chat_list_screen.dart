import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';

import 'package:login_learn_new_app/views/call/call_screen.dart';
import 'package:login_learn_new_app/widgets/common.dart';
import 'package:login_learn_new_app/services/db.dart';
import 'package:login_learn_new_app/views/chat/chat_screen.dart';

class ChatListScreen extends StatelessWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        body: Column(
          children: [
            Container(
              padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 8, 16, 16),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [AppColor.kDark, AppColor.kPrimary],
                ),
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(30)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconButton(
                        onPressed: Get.back,
                        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      ),
                      const Text(
                        'Messages',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: TabBar(
                      dividerColor: Colors.transparent,
                      indicatorSize: TabBarIndicatorSize.tab,
                      indicator: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(13),
                      ),
                      labelColor: AppColor.kDark,
                      unselectedLabelColor: Colors.white,
                      labelStyle: const TextStyle(fontWeight: FontWeight.w800),
                      tabs: const [Tab(text: 'Chats'), Tab(text: 'People')],
                    ),
                  ),
                ],
              ),
            ),
            const Expanded(
              child: TabBarView(children: [_ChatsTab(), _PeopleTab()]),
            ),
          ],
        ),
      ),
    );
  }
}

// ------------------------------------------------------------
// CHATS (conversations I already have)
// ------------------------------------------------------------
class _ChatsTab extends StatelessWidget {
  const _ChatsTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: Db.chatsStream(),
      builder: (context, snap) {
        if (snap.hasError) return _error(snap.error);
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColor.kPrimary));
        }
        final docs = snap.data!.docs.toList()
          ..sort((a, b) {
            final ta = a.data()['lastTime'];
            final tb = b.data()['lastTime'];
            final da = ta is Timestamp ? ta.toDate() : DateTime.now();
            final db = tb is Timestamp ? tb.toDate() : DateTime.now();
            return db.compareTo(da);
          });
        if (docs.isEmpty) {
          return const _Empty(
            icon: Icons.chat_bubble_outline_rounded,
            title: 'No conversations yet',
            subtitle: 'Open the People tab and say hello!',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          itemCount: docs.length,
          separatorBuilder: (context, i) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final m = docs[i].data();
            final parts = List<String>.from(m['participants'] ?? const []);
            final peerId = parts.firstWhere((p) => p != Db.myUid, orElse: () => '');
            final names = Map<String, dynamic>.from(m['names'] ?? const {});
            final peerName = (names[peerId] ?? 'User') as String;
            final last = (m['lastMessage'] ?? '') as String;
            final mine = m['lastSenderId'] == Db.myUid;
            final ts = m['lastTime'];
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Get.to(() => ChatScreen(peerId: peerId, peerName: peerName)),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: softShadow,
                ),
                child: Row(
                  children: [
                    InitialAvatar(name: peerName, radius: 26),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            peerName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColor.kInk,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${mine ? 'You: ' : ''}$last',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      ts is Timestamp ? timeAgo(ts.toDate()) : 'now',
                      style: const TextStyle(color: Colors.black45, fontSize: 12),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

// ------------------------------------------------------------
// PEOPLE (everyone who signed up) - chat / audio / video
// ------------------------------------------------------------
class _PeopleTab extends StatelessWidget {
  const _PeopleTab();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: Db.usersStream(),
      builder: (context, snap) {
        if (snap.hasError) return _error(snap.error);
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator(color: AppColor.kPrimary));
        }
        final users = snap.data!.docs.where((d) => d.id != Db.myUid).toList();
        if (users.isEmpty) {
          return const _Empty(
            icon: Icons.group_outlined,
            title: 'No other users yet',
            subtitle: 'Sign up with a second account (another phone or emulator) to chat and call.',
          );
        }
        return ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 24),
          itemCount: users.length,
          separatorBuilder: (context, i) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            final m = users[i].data();
            final id = users[i].id;
            final name = (m['name'] ?? 'User') as String;
            final sub = (m['email'] ?? m['phone'] ?? '') as String;
            return InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => Get.to(() => ChatScreen(peerId: id, peerName: name)),
              child: Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 6, 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: softShadow,
                ),
                child: Row(
                  children: [
                    InitialAvatar(name: name, radius: 24),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColor.kInk,
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                            ),
                          ),
                          if (sub.isNotEmpty)
                            Text(
                              sub,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(color: Colors.black45, fontSize: 12),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Audio call',
                      onPressed: () => Get.to(() => CallScreen(
                            peerId: id,
                            peerName: name,
                            video: false,
                            isCaller: true,
                          )),
                      icon: const Icon(Icons.call_rounded, color: AppColor.kPrimary),
                    ),
                    IconButton(
                      tooltip: 'Video call',
                      onPressed: () => Get.to(() => CallScreen(
                            peerId: id,
                            peerName: name,
                            video: true,
                            isCaller: true,
                          )),
                      icon: const Icon(Icons.videocam_rounded, color: AppColor.kPrimary),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

Widget _error(Object? e) => Center(
  child: Padding(
    padding: const EdgeInsets.all(28),
    child: Text(
      'Something went wrong.\nCheck that Firestore is created and the rules are deployed.\n\n$e',
      textAlign: TextAlign.center,
      style: const TextStyle(color: Colors.black54),
    ),
  ),
);

class _Empty extends StatelessWidget {
  const _Empty({required this.icon, required this.title, required this.subtitle});
  final IconData icon;
  final String title, subtitle;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 60, color: Colors.black26),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                color: AppColor.kInk,
                fontSize: 18,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }
}
