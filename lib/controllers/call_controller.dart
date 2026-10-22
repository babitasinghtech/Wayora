import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import 'package:login_learn_new_app/views/call/incoming_call_screen.dart';

/// Lives for the whole app. While a user is logged in it listens for calls
/// that are "ringing" for them and opens the incoming-call screen.
///
/// NOTE: this works while the app is open. For ringing when the app is closed
/// you need push notifications (FCM) + a native call UI - see SOCIAL_SETUP.md.
class CallController extends GetxController {
  StreamSubscription<User?>? _authSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _callSub;
  int _openScreens = 0;

  bool get busy => _openScreens > 0;
  void enter() => _openScreens++;
  void leave() {
    if (_openScreens > 0) _openScreens--;
  }

  @override
  void onInit() {
    super.onInit();
    _authSub = FirebaseAuth.instance.authStateChanges().listen(_onAuth);
  }

  @override
  void onClose() {
    _authSub?.cancel();
    _callSub?.cancel();
    super.onClose();
  }

  void _onAuth(User? user) {
    _callSub?.cancel();
    _callSub = null;
    if (user == null) return;
    _callSub = FirebaseFirestore.instance
        .collection('calls')
        .where('calleeId', isEqualTo: user.uid)
        .where('status', isEqualTo: 'ringing')
        .snapshots()
        .listen(
          _onCalls,
          onError: (e) => debugPrint('call listener error: $e'),
        );
  }

  void _onCalls(QuerySnapshot<Map<String, dynamic>> snap) {
    for (final change in snap.docChanges) {
      if (change.type != DocumentChangeType.added) continue;
      final data = change.doc.data();
      if (data == null) continue;

      // ignore old calls that were never answered
      final ts = data['createdAt'];
      if (ts is Timestamp &&
          DateTime.now().difference(ts.toDate()).inSeconds.abs() > 60) {
        continue;
      }

      if (busy) {
        change.doc.reference.update({'status': 'busy'});
        continue;
      }
      Get.to(() => IncomingCallScreen(callId: change.doc.id, data: data));
    }
  }
}
