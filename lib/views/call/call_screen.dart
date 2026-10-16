import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:get/get.dart' hide navigator;
import 'package:login_learn_new_app/core/constants/app_color.dart';
import 'package:login_learn_new_app/widgets/common.dart';
import 'package:login_learn_new_app/services/db.dart';
import 'package:login_learn_new_app/controllers/call_controller.dart';

/// One screen for both sides of a WebRTC call.
///  - caller : isCaller = true  (creates the call doc + offer)
///  - callee : isCaller = false (callId given, reads the offer, sends answer)
/// Signaling (offer / answer / ICE candidates) goes through Firestore.
class CallScreen extends StatefulWidget {
  const CallScreen({
    super.key,
    required this.peerId,
    required this.peerName,
    required this.video,
    required this.isCaller,
    this.callId,
  });

  final String peerId;
  final String peerName;
  final bool video;
  final bool isCaller;
  final String? callId;

  @override
  State<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends State<CallScreen> {
  // STUN only. Some mobile networks / strict NATs also need a TURN server
  // for calls to connect - add one here for production.
  static const Map<String, dynamic> _config = {
    'iceServers': [
      {
        'urls': [
          'stun:stun.l.google.com:19302',
          'stun:stun1.l.google.com:19302',
        ],
      },
    ],
    'sdpSemantics': 'unified-plan',
  };

  final FirebaseFirestore _fs = FirebaseFirestore.instance;
  final RTCVideoRenderer _local = RTCVideoRenderer();
  final RTCVideoRenderer _remote = RTCVideoRenderer();

  RTCPeerConnection? _pc;
  MediaStream? _stream;
  DocumentReference<Map<String, dynamic>>? _callRef;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _callSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _candSub;
  Timer? _ringTimeout;
  Timer? _clock;

  final List<RTCIceCandidate> _pending = [];
  bool _remoteSet = false;
  bool _answerHandled = false;
  bool _connected = false;
  bool _ended = false;

  bool _micOn = true;
  bool _camOn = true;
  bool _frontCamera = true;
  late bool _speaker;
  int _seconds = 0;
  String _status = 'Starting…';

  void _set(VoidCallback f) {
    if (mounted) setState(f);
  }

  @override
  void initState() {
    super.initState();
    _speaker =
        widget.video; // video calls start on speaker, audio calls on earpiece
    Get.find<CallController>().enter();
    _start();
  }

  // ------------------------------------------------------------------
  // SET-UP
  // ------------------------------------------------------------------
  Future<void> _start() async {
    try {
      await _local.initialize();
      await _remote.initialize();
      await _openMedia();
      await _createPeer();
      if (widget.isCaller) {
        await _startAsCaller();
      } else {
        await _startAsCallee();
      }
    } catch (e) {
      _finish(
        'Could not start the call. Check camera / microphone permission.\n$e',
      );
    }
  }

  Future<void> _openMedia() async {
    _stream = await navigator.mediaDevices.getUserMedia({
      'audio': true,
      'video': widget.video ? {'facingMode': 'user'} : false,
    });
    _local.srcObject = _stream;
    _set(() {});
    try {
      await Helper.setSpeakerphoneOn(_speaker);
    } catch (_) {}
  }

  Future<void> _createPeer() async {
    final pc = await createPeerConnection(_config);
    _pc = pc;

    for (final track in _stream!.getTracks()) {
      await pc.addTrack(track, _stream!);
    }

    pc.onTrack = (RTCTrackEvent e) {
      if (e.streams.isNotEmpty) {
        _remote.srcObject = e.streams[0];
        _set(() {});
      }
    };

    pc.onConnectionState = (RTCPeerConnectionState s) {
      if (s == RTCPeerConnectionState.RTCPeerConnectionStateConnected) {
        _onConnected();
      } else if (s == RTCPeerConnectionState.RTCPeerConnectionStateFailed) {
        _finish(
          'Connection failed. Both users may need a TURN server on this network.',
        );
      }
    };

    pc.onIceConnectionState = (RTCIceConnectionState s) {
      if (s == RTCIceConnectionState.RTCIceConnectionStateConnected ||
          s == RTCIceConnectionState.RTCIceConnectionStateCompleted) {
        _onConnected();
      }
    };
  }

  void _sendLocalCandidatesTo(String subcollection) {
    _pc!.onIceCandidate = (RTCIceCandidate c) {
      if (c.candidate == null) return;
      _callRef?.collection(subcollection).add(c.toMap());
    };
  }

  // ------------------------------------------------------------------
  // CALLER
  // ------------------------------------------------------------------
  Future<void> _startAsCaller() async {
    final me = FirebaseAuth.instance.currentUser!;
    _callRef = _fs.collection('calls').doc();

    // create the doc first (status "preparing") so candidates can be stored
    await _callRef!.set({
      'callerId': me.uid,
      'callerName': Db.nameOf(me),
      'calleeId': widget.peerId,
      'calleeName': widget.peerName,
      'type': widget.video ? 'video' : 'audio',
      'status': 'preparing',
      'createdAt': FieldValue.serverTimestamp(),
    });

    _sendLocalCandidatesTo('callerCandidates');

    final offer = await _pc!.createOffer();
    await _pc!.setLocalDescription(offer);

    // "ringing" makes it show up on the other phone
    await _callRef!.update({
      'offer': {'sdp': offer.sdp, 'type': offer.type},
      'status': 'ringing',
    });
    _set(() => _status = 'Ringing…');

    _callSub = _callRef!.snapshots().listen(_onCallDoc);
    _candSub = _callRef!
        .collection('calleeCandidates')
        .snapshots()
        .listen(_onRemoteCandidates);

    _ringTimeout = Timer(const Duration(seconds: 45), () {
      if (!_connected && !_ended) {
        _callRef?.update({'status': 'missed'});
        _finish('No answer');
      }
    });
  }

  // ------------------------------------------------------------------
  // CALLEE
  // ------------------------------------------------------------------
  Future<void> _startAsCallee() async {
    _callRef = _fs.collection('calls').doc(widget.callId);
    final snap = await _callRef!.get();
    final d = snap.data();
    if (d == null || d['offer'] == null || d['status'] != 'ringing') {
      _finish('This call is no longer available');
      return;
    }

    _sendLocalCandidatesTo('calleeCandidates');

    final o = Map<String, dynamic>.from(d['offer'] as Map);
    await _setRemote(
      RTCSessionDescription(o['sdp'] as String?, o['type'] as String?),
    );

    final answer = await _pc!.createAnswer();
    await _pc!.setLocalDescription(answer);
    await _callRef!.update({
      'answer': {'sdp': answer.sdp, 'type': answer.type},
      'status': 'accepted',
    });
    _set(() => _status = 'Connecting…');

    _callSub = _callRef!.snapshots().listen(_onCallDoc);
    _candSub = _callRef!
        .collection('callerCandidates')
        .snapshots()
        .listen(_onRemoteCandidates);
  }

  // ------------------------------------------------------------------
  // SIGNALING LISTENERS
  // ------------------------------------------------------------------
  Future<void> _onCallDoc(DocumentSnapshot<Map<String, dynamic>> snap) async {
    final d = snap.data();
    if (d == null || _ended) return;

    // caller receives the answer
    if (widget.isCaller && d['answer'] != null && !_answerHandled) {
      _answerHandled = true;
      final a = Map<String, dynamic>.from(d['answer'] as Map);
      try {
        await _setRemote(
          RTCSessionDescription(a['sdp'] as String?, a['type'] as String?),
        );
        _set(() => _status = 'Connecting…');
      } catch (e) {
        _finish('Could not connect: $e');
      }
    }

    switch (d['status']) {
      case 'rejected':
        _finish('Call declined');
        break;
      case 'busy':
        _finish('User is busy on another call');
        break;
      case 'ended':
        _finish('Call ended');
        break;
    }
  }

  Future<void> _setRemote(RTCSessionDescription desc) async {
    await _pc!.setRemoteDescription(desc);
    _remoteSet = true;
    for (final c in _pending) {
      await _pc!.addCandidate(c);
    }
    _pending.clear();
  }

  void _onRemoteCandidates(QuerySnapshot<Map<String, dynamic>> snap) {
    for (final change in snap.docChanges) {
      if (change.type != DocumentChangeType.added) continue;
      final m = change.doc.data();
      if (m == null) continue;
      final c = RTCIceCandidate(
        m['candidate'] as String?,
        m['sdpMid'] as String?,
        (m['sdpMLineIndex'] as num?)?.toInt(),
      );
      if (_remoteSet) {
        _pc?.addCandidate(c);
      } else {
        _pending.add(c); // answer not processed yet, add later
      }
    }
  }

  void _onConnected() {
    if (_connected || !mounted || _ended) return;
    _connected = true;
    _ringTimeout?.cancel();
    _clock = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _set(() => _seconds++),
    );
    _set(() => _status = 'Connected');
  }

  // ------------------------------------------------------------------
  // CONTROLS
  // ------------------------------------------------------------------
  void _toggleMic() {
    final tracks = _stream?.getAudioTracks() ?? [];
    _micOn = !_micOn;
    for (final t in tracks) {
      t.enabled = _micOn;
    }
    _set(() {});
  }

  void _toggleCam() {
    final tracks = _stream?.getVideoTracks() ?? [];
    _camOn = !_camOn;
    for (final t in tracks) {
      t.enabled = _camOn;
    }
    _set(() {});
  }

  Future<void> _switchCamera() async {
    final tracks = _stream?.getVideoTracks() ?? [];
    if (tracks.isEmpty) return;
    await Helper.switchCamera(tracks.first);
    _set(() => _frontCamera = !_frontCamera);
  }

  Future<void> _toggleSpeaker() async {
    _speaker = !_speaker;
    try {
      await Helper.setSpeakerphoneOn(_speaker);
    } catch (_) {}
    _set(() {});
  }

  Future<void> _hangUp() async {
    if (_ended) return;
    try {
      await _callRef?.update({'status': 'ended'});
    } catch (_) {}
    _finish(null);
  }

  /// Closes the screen. [message] is shown as a toast (null = none).
  void _finish(String? message) {
    if (_ended) return;
    _ended = true;
    _ringTimeout?.cancel();
    _clock?.cancel();
    if (mounted) Get.back();
    if (message != null) {
      showToast('Call', message, ok: message == 'Call ended');
    }
  }

  @override
  void dispose() {
    _ringTimeout?.cancel();
    _clock?.cancel();
    _callSub?.cancel();
    _candSub?.cancel();

    // screen closed without pressing end (e.g. error) -> tell the other side
    if (!_ended) {
      _callRef?.update({'status': 'ended'}).catchError((_) {});
    }

    for (final t in _stream?.getTracks() ?? <MediaStreamTrack>[]) {
      t.stop();
    }
    _stream?.dispose();
    _pc?.close();
    _pc?.dispose();
    _local.srcObject = null;
    _remote.srcObject = null;
    _local.dispose();
    _remote.dispose();

    Get.find<CallController>().leave();
    super.dispose();
  }

  // ------------------------------------------------------------------
  // UI
  // ------------------------------------------------------------------
  String get _timeText {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final showRemoteVideo = widget.video && _remote.srcObject != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _hangUp();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          fit: StackFit.expand,
          children: [
            // ----- background / remote video -----
            if (showRemoteVideo)
              RTCVideoView(
                _remote,
                objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              )
            else
              Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Color(0xFF062F2C),
                      AppColor.kDark,
                      AppColor.kPrimary,
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white24, width: 3),
                        ),
                        child: InitialAvatar(name: widget.peerName, radius: 62),
                      ),
                    ],
                  ),
                ),
              ),

            // ----- top info -----
            SafeArea(
              child: Align(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.only(top: 18),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        widget.peerName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black54),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _connected ? _timeText : _status,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 15,
                          shadows: [
                            Shadow(blurRadius: 8, color: Colors.black54),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // ----- my own camera (picture-in-picture) -----
            if (widget.video && _local.srcObject != null && _camOn)
              SafeArea(
                child: Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 78, right: 14),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: SizedBox(
                        width: 104,
                        height: 150,
                        child: RTCVideoView(
                          _local,
                          mirror: _frontCamera,
                          objectFit:
                              RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
                        ),
                      ),
                    ),
                  ),
                ),
              ),

            // ----- controls -----
            SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  margin: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(34),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _control(
                        _micOn ? Icons.mic_rounded : Icons.mic_off_rounded,
                        active: _micOn,
                        onTap: _toggleMic,
                      ),
                      if (widget.video)
                        _control(
                          _camOn
                              ? Icons.videocam_rounded
                              : Icons.videocam_off_rounded,
                          active: _camOn,
                          onTap: _toggleCam,
                        ),
                      if (widget.video)
                        _control(
                          Icons.cameraswitch_rounded,
                          active: true,
                          onTap: _switchCamera,
                        ),
                      _control(
                        _speaker
                            ? Icons.volume_up_rounded
                            : Icons.volume_down_rounded,
                        active: _speaker,
                        onTap: _toggleSpeaker,
                      ),
                      GestureDetector(
                        onTap: _hangUp,
                        child: Container(
                          width: 62,
                          height: 62,
                          decoration: const BoxDecoration(
                            color: Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.call_end_rounded,
                            color: Colors.white,
                            size: 30,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _control(
    IconData icon, {
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 52,
        height: 52,
        decoration: BoxDecoration(
          color: active ? Colors.white.withValues(alpha: 0.22) : Colors.white,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          color: active ? Colors.white : Colors.black87,
          size: 26,
        ),
      ),
    );
  }
}
