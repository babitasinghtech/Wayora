import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:login_learn_new_app/core/constants/app_color.dart';

import 'package:login_learn_new_app/widgets/common.dart';
import 'package:login_learn_new_app/controllers/call_controller.dart';
import 'package:login_learn_new_app/views/call/call_screen.dart';

class IncomingCallScreen extends StatefulWidget {
  const IncomingCallScreen({super.key, required this.callId, required this.data});
  final String callId;
  final Map<String, dynamic> data;

  @override
  State<IncomingCallScreen> createState() => _IncomingCallScreenState();
}

class _IncomingCallScreenState extends State<IncomingCallScreen> {
  late final DocumentReference<Map<String, dynamic>> _ref;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _sub;
  Timer? _buzz;
  bool _handled = false;

  String get _callerName => (widget.data['callerName'] ?? 'Unknown') as String;
  bool get _video => widget.data['type'] == 'video';

  @override
  void initState() {
    super.initState();
    Get.find<CallController>().enter();
    _ref = FirebaseFirestore.instance.collection('calls').doc(widget.callId);

    // caller hung up / timed out -> close this screen
    _sub = _ref.snapshots().listen((s) {
      final status = s.data()?['status'];
      if (!_handled && status != null && status != 'ringing') {
        _handled = true;
        if (mounted) Get.back();
        showToast('Missed call', 'Call from $_callerName ended.', ok: false);
      }
    });

    HapticFeedback.vibrate();
    _buzz = Timer.periodic(const Duration(seconds: 2), (_) => HapticFeedback.vibrate());
  }

  @override
  void dispose() {
    _sub?.cancel();
    _buzz?.cancel();
    Get.find<CallController>().leave();
    super.dispose();
  }

  Future<void> _decline() async {
    if (_handled) return;
    _handled = true;
    try {
      await _ref.update({'status': 'rejected'});
    } catch (_) {}
    if (mounted) Get.back();
  }

  void _accept() {
    if (_handled) return;
    _handled = true; // stops the listener from closing the screen
    _sub?.cancel();
    Get.off(() => CallScreen(
          callId: widget.callId,
          peerId: widget.data['callerId'] as String,
          peerName: _callerName,
          video: _video,
          isCaller: false,
        ));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        body: Container(
          width: double.infinity,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [Color(0xFF062F2C), AppColor.kDark, AppColor.kPrimary],
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 70),
                Text(
                  _video ? 'Incoming video call' : 'Incoming audio call',
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 40),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 3),
                  ),
                  child: InitialAvatar(name: _callerName, radius: 62),
                ),
                const SizedBox(height: 26),
                Text(
                  _callerName,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text('Wanderly is calling you…', style: TextStyle(color: Colors.white70)),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(48, 0, 48, 56),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _circle(Icons.call_end_rounded, Colors.redAccent, 'Decline', _decline),
                      _circle(
                        _video ? Icons.videocam_rounded : Icons.call_rounded,
                        const Color(0xFF2ECC71),
                        'Accept',
                        _accept,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _circle(IconData icon, Color color, String label, VoidCallback onTap) {
    return Column(
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 74,
            height: 74,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 34),
          ),
        ),
        const SizedBox(height: 10),
        Text(label, style: const TextStyle(color: Colors.white)),
      ],
    );
  }
}
