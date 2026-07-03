import 'dart:async';
import 'package:agora_rtc_engine/agora_rtc_engine.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../../../core/config/app_constants.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

enum _CallState { ringing, connected }

class CallScreen extends ConsumerStatefulWidget {
  final String calleeId;
  final String calleeName;
  final String calleeAvatar;

  const CallScreen({
    super.key,
    required this.calleeId,
    required this.calleeName,
    required this.calleeAvatar,
  });

  @override
  ConsumerState<CallScreen> createState() => _CallScreenState();
}

class _CallScreenState extends ConsumerState<CallScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse1, _pulse2, _pulse3;

  _CallState _callState = _CallState.ringing;
  bool _isMuted = false;
  bool _isSpeaker = false;
  int _seconds = 0;
  Timer? _timer;
  String? _callDocId;
  StreamSubscription<DocumentSnapshot>? _callSub;

  // Agora
  RtcEngine? _agoraEngine;
  bool get _useAgora => AppConstants.agoraAppId.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat();
    _pulse1 = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _pulseCtrl, curve: const Interval(0.0, 0.70, curve: Curves.easeOut)));
    _pulse2 = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _pulseCtrl, curve: const Interval(0.2, 0.90, curve: Curves.easeOut)));
    _pulse3 = Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _pulseCtrl, curve: const Interval(0.4, 1.00, curve: Curves.easeOut)));
    _initCall();
  }

  Future<void> _initCall() async {
    final user = ref.read(authProvider);
    if (user == null) { if (mounted) context.pop(); return; }

    final doc = await FirebaseFirestore.instance.collection('calls').add({
      'callerId':     user.id,
      'callerName':   user.name,
      'callerAvatar': user.avatarUrl,
      'calleeId':     widget.calleeId,
      'calleeName':   widget.calleeName,
      'calleeAvatar': widget.calleeAvatar,
      'status':       'ringing',
      'type':         'audio',
      'createdAt':    FieldValue.serverTimestamp(),
    });

    if (!mounted) return;
    setState(() => _callDocId = doc.id);

    if (_useAgora) {
      await _initAgora(doc.id);
    }

    _callSub = FirebaseFirestore.instance
        .collection('calls')
        .doc(doc.id)
        .snapshots()
        .listen((snap) {
      if (!snap.exists || !mounted) return;
      final status = snap.data()?['status'] as String?;
      if (status == 'accepted' && _callState == _CallState.ringing && !_useAgora) {
        setState(() => _callState = _CallState.connected);
        _startTimer();
      } else if (status == 'ended' || status == 'rejected') {
        _onCallEnded();
      }
    });
  }

  Future<void> _initAgora(String channelId) async {
    await [Permission.microphone].request();
    _agoraEngine = createAgoraRtcEngine();
    await _agoraEngine!.initialize(RtcEngineContext(appId: AppConstants.agoraAppId));
    _agoraEngine!.registerEventHandler(RtcEngineEventHandler(
      onJoinChannelSuccess: (conn, elapsed) {
        if (!mounted) return;
        setState(() => _callState = _CallState.connected);
        _startTimer();
      },
      onUserOffline: (conn, uid, reason) => _onCallEnded(),
      onError: (err, msg) => _onCallEnded(),
    ));
    await _agoraEngine!.enableAudio();
    await _agoraEngine!.joinChannel(
      token:     '',
      channelId: channelId,
      uid:       0,
      options:   const ChannelMediaOptions(clientRoleType: ClientRoleType.clientRoleBroadcaster),
    );
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _seconds++);
    });
  }

  Future<void> _endCall() async {
    if (_useAgora && _agoraEngine != null) {
      await _agoraEngine!.leaveChannel();
      await _agoraEngine!.release();
      _agoraEngine = null;
    }
    if (_callDocId != null) {
      await FirebaseFirestore.instance
          .collection('calls')
          .doc(_callDocId)
          .update({'status': 'ended'});
    }
    _onCallEnded();
  }

  void _onCallEnded() {
    _timer?.cancel();
    _callSub?.cancel();
    if (mounted) context.pop();
  }

  void _toggleMute() {
    setState(() => _isMuted = !_isMuted);
    _agoraEngine?.muteLocalAudioStream(_isMuted);
  }

  void _toggleSpeaker() {
    setState(() => _isSpeaker = !_isSpeaker);
    _agoraEngine?.setEnableSpeakerphone(_isSpeaker);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _timer?.cancel();
    _callSub?.cancel();
    _agoraEngine?.release();
    super.dispose();
  }

  String get _durationStr {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D2818),
      body: Stack(
        fit: StackFit.expand,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF0A1F10), Color(0xFF1B4332), Color(0xFF0A1F10)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 40),
                Text(
                  _callState == _CallState.ringing ? 'Appel en cours...' : _durationStr,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 15,
                    letterSpacing: _callState == _CallState.connected ? 3 : 0,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  widget.calleeName.isNotEmpty ? widget.calleeName : 'Utilisateur',
                  style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 8),
                Text(
                  _callState == _CallState.ringing ? 'CasaImo · Appel audio' : 'Connecté',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.5), fontSize: 13),
                ),
                const Spacer(),

                // Avatar avec pulsation
                AnimatedBuilder(
                  animation: _pulseCtrl,
                  builder: (ctx, child) {
                    const base = 64.0;
                    const max = 52.0;
                    return SizedBox(
                      width: (base + max) * 2,
                      height: (base + max) * 2,
                      child: Stack(alignment: Alignment.center, children: [
                        if (_callState == _CallState.ringing) ...[
                          _Ring(r: base + max * _pulse3.value, o: (1 - _pulse3.value) * 0.25),
                          _Ring(r: base + max * 0.7 * _pulse2.value, o: (1 - _pulse2.value) * 0.35),
                          _Ring(r: base + max * 0.4 * _pulse1.value, o: (1 - _pulse1.value) * 0.45),
                        ],
                        Container(
                          width: base * 2,
                          height: base * 2,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppColors.primaryContainer,
                            border: Border.all(color: Colors.white, width: 3),
                            image: widget.calleeAvatar.isNotEmpty
                                ? DecorationImage(image: NetworkImage(widget.calleeAvatar), fit: BoxFit.cover)
                                : null,
                          ),
                          child: widget.calleeAvatar.isEmpty
                              ? Center(
                                  child: Text(
                                    widget.calleeName.isNotEmpty ? widget.calleeName[0].toUpperCase() : '?',
                                    style: const TextStyle(fontSize: 46, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                )
                              : null,
                        ),
                      ]),
                    );
                  },
                ),

                const Spacer(),

                // Muet + Haut-parleur — toujours visibles
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _CtrlBtn(
                        icon: _isMuted ? Icons.mic_off_rounded : Icons.mic_rounded,
                        label: _isMuted ? 'Muet' : 'Micro',
                        active: _isMuted,
                        onTap: _toggleMute,
                      ),
                      _CtrlBtn(
                        icon: _isSpeaker ? Icons.volume_up_rounded : Icons.volume_off_rounded,
                        label: _isSpeaker ? 'Haut-parl.' : 'Écouteur',
                        active: _isSpeaker,
                        onTap: _toggleSpeaker,
                      ),
                      if (_callState == _CallState.connected)
                        _CtrlBtn(
                          icon: Icons.dialpad_rounded,
                          label: 'Clavier',
                          onTap: () {},
                        )
                      else
                        _CtrlBtn(
                          icon: Icons.person_rounded,
                          label: 'Contact',
                          onTap: () {},
                          dimmed: true,
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 36),

                GestureDetector(
                  onTap: _endCall,
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: const BoxDecoration(
                      color: Color(0xFFE53935),
                      shape: BoxShape.circle,
                      boxShadow: [BoxShadow(color: Color(0x55E53935), blurRadius: 20, spreadRadius: 4)],
                    ),
                    child: const Icon(Icons.call_end_rounded, color: Colors.white, size: 34),
                  ),
                ),
                const SizedBox(height: 60),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Ring extends StatelessWidget {
  final double r;
  final double o;
  const _Ring({required this.r, required this.o});

  @override
  Widget build(BuildContext context) => Container(
    width: r * 2,
    height: r * 2,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      border: Border.all(color: Colors.white.withValues(alpha: o), width: 1.5),
    ),
  );
}

class _CtrlBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool active;
  final bool dimmed;
  const _CtrlBtn({required this.icon, required this.label, required this.onTap, this.active = false, this.dimmed = false});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Opacity(
      opacity: dimmed ? 0.4 : 1.0,
      child: Column(children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: active ? Colors.white.withValues(alpha: 0.35) : Colors.white.withValues(alpha: 0.12),
          ),
          child: Icon(icon, color: Colors.white, size: 25),
        ),
        const SizedBox(height: 7),
        Text(label, style: TextStyle(color: Colors.white.withValues(alpha: 0.65), fontSize: 11)),
      ]),
    ),
  );
}
