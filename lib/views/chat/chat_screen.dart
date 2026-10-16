import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';

import 'package:login_learn_new_app/views/call/call_screen.dart';
import 'package:login_learn_new_app/widgets/common.dart';
import 'package:login_learn_new_app/services/db.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key, required this.peerId, required this.peerName});
  final String peerId;
  final String peerName;

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _text = TextEditingController();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final t = _text.text.trim();
    if (t.isEmpty) return;
    _text.clear(); // clear right away so it feels instant
    try {
      await Db.sendMessage(peerId: widget.peerId, peerName: widget.peerName, text: t);
    } catch (e) {
      showToast('Message not sent', '$e', ok: false);
    }
  }

  void _call(bool video) {
    Get.to(() => CallScreen(
          peerId: widget.peerId,
          peerName: widget.peerName,
          video: video,
          isCaller: true,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 1,
        shadowColor: Colors.black12,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppColor.kInk),
          onPressed: Get.back,
        ),
        title: Row(
          children: [
            InitialAvatar(name: widget.peerName, radius: 19),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                widget.peerName,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: AppColor.kInk,
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Audio call',
            onPressed: () => _call(false),
            icon: const Icon(Icons.call_rounded, color: AppColor.kPrimary),
          ),
          IconButton(
            tooltip: 'Video call',
            onPressed: () => _call(true),
            icon: const Icon(Icons.videocam_rounded, color: AppColor.kPrimary),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: Db.messagesStream(widget.peerId),
              builder: (context, snap) {
                if (snap.hasError) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text('${snap.error}', textAlign: TextAlign.center),
                    ),
                  );
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColor.kPrimary));
                }
                final docs = snap.data!.docs;
                if (docs.isEmpty) {
                  return Center(
                    child: Text(
                      'Say hi to ${widget.peerName} 👋',
                      style: const TextStyle(color: Colors.black45),
                    ),
                  );
                }
                return ListView.builder(
                  reverse: true, // newest at the bottom
                  padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                  itemCount: docs.length,
                  itemBuilder: (context, i) {
                    final m = docs[i].data();
                    final mine = m['senderId'] == Db.myUid;
                    final ts = m['createdAt'];
                    return _Bubble(
                      text: (m['text'] ?? '') as String,
                      mine: mine,
                      time: ts is Timestamp ? clockTime(ts.toDate()) : '',
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            top: false,
            child: Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
              color: Colors.white,
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      minLines: 1,
                      maxLines: 4,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: 'Type a message...',
                        filled: true,
                        fillColor: const Color(0xFFF2F6F6),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(26),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: _send,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [AppColor.kPrimary, Color(0xFF2FD3A3)],
                        ),
                      ),
                      child: const Icon(Icons.send_rounded, color: Colors.white, size: 22),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Bubble extends StatelessWidget {
  const _Bubble({required this.text, required this.mine, required this.time});
  final String text;
  final bool mine;
  final String time;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.76),
        margin: const EdgeInsets.symmetric(vertical: 3),
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 7),
        decoration: BoxDecoration(
          gradient: mine
              ? const LinearGradient(colors: [AppColor.kPrimary, Color(0xFF2FB9A0)])
              : null,
          color: mine ? null : Colors.white,
          boxShadow: mine ? null : softShadow,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(mine ? 18 : 4),
            bottomRight: Radius.circular(mine ? 4 : 18),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              text,
              style: TextStyle(
                color: mine ? Colors.white : AppColor.kInk,
                fontSize: 15.5,
                height: 1.3,
              ),
            ),
            if (time.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                time,
                style: TextStyle(
                  color: mine ? Colors.white70 : Colors.black38,
                  fontSize: 10.5,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
