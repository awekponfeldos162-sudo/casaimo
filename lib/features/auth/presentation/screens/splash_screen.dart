import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:video_player/video_player.dart';
import '../providers/auth_provider.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  VideoPlayerController? _controller;
  bool _videoReady = false;
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    // Fullscreen immersive
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    _initVideo();
  }

  Future<void> _initVideo() async {
    try {
      final ctrl = VideoPlayerController.asset(
        'assets/animations/splash.mp4',
      );
      await ctrl.initialize();
      ctrl.setVolume(0); // muet (pas de son dans la vidéo)
      ctrl.setLooping(false);
      if (mounted) {
        setState(() {
          _controller = ctrl;
          _videoReady = true;
        });
        ctrl.play();
        // Navigue à la fin de la vidéo
        ctrl.addListener(_onVideoProgress);
      }
    } catch (e) {
      // Fallback : si la vidéo ne charge pas, on navigue après 3s
      Future.delayed(const Duration(seconds: 3), _navigate);
    }
  }

  void _onVideoProgress() {
    final ctrl = _controller;
    if (ctrl == null) return;
    final pos = ctrl.value.position;
    final dur = ctrl.value.duration;
    if (dur.inMilliseconds > 0 &&
        pos.inMilliseconds >= dur.inMilliseconds - 100) {
      _navigate();
    }
  }

  Future<void> _navigate() async {
    if (_navigated) return;
    _navigated = true;
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    if (!mounted) return;

    final firebaseUser = FirebaseAuth.instance.currentUser;

    if (firebaseUser != null) {
      // Session active — attendre que le profil Firestore soit chargé (< 1s en général)
      var userModel = ref.read(authProvider);
      if (userModel == null) {
        for (var i = 0; i < 15 && userModel == null; i++) {
          await Future.delayed(const Duration(milliseconds: 100));
          userModel = ref.read(authProvider);
        }
      }
      if (!mounted) return;
      if (userModel?.isHost == true) {
        context.go('/host/dashboard');
      } else {
        context.go('/home');
      }
    } else {
      // Pas connecté — onboarding seulement à la toute première ouverture
      final prefs = await SharedPreferences.getInstance();
      if (!mounted) return;
      final seen = prefs.getBool('hasSeenOnboarding') ?? false;
      context.go(seen ? '/login' : '/onboarding');
    }
  }

  @override
  void dispose() {
    _controller?.removeListener(_onVideoProgress);
    _controller?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: _videoReady && _controller != null
          ? _VideoSplash(controller: _controller!)
          : const _FallbackSplash(),
    );
  }
}

// ── Vue vidéo ─────────────────────────────────────────────────────────────────
class _VideoSplash extends StatelessWidget {
  final VideoPlayerController controller;
  const _VideoSplash({required this.controller});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: FittedBox(
        fit: BoxFit.cover,
        child: SizedBox(
          width: controller.value.size.width,
          height: controller.value.size.height,
          child: VideoPlayer(controller),
        ),
      ),
    );
  }
}

// ── Fallback Flutter animé (si la vidéo ne charge pas) ───────────────────────
class _FallbackSplash extends StatefulWidget {
  const _FallbackSplash();

  @override
  State<_FallbackSplash> createState() => _FallbackSplashState();
}

class _FallbackSplashState extends State<_FallbackSplash>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;
  late Animation<double> _fade;

  static const _green = Color(0xFF22C55E);
  static const _dark = Color(0xFF0A1A0E);

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: 1600.ms);
    _scale = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.7, curve: Curves.elasticOut)),
    );
    _fade = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _ctrl, curve: const Interval(0, 0.5, curve: Curves.easeIn)),
    );
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: RadialGradient(
          colors: [Color(0xFF1A4228), _dark],
          radius: 1.3,
        ),
      ),
      child: Center(
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, _) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FadeTransition(
                opacity: _fade,
                child: ScaleTransition(
                  scale: _scale,
                  child: Container(
                    width: 160, height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _green.withValues(alpha: 0.15),
                      boxShadow: [
                        BoxShadow(color: _green.withValues(alpha: 0.4),
                            blurRadius: 50, spreadRadius: 10),
                      ],
                    ),
                    padding: const EdgeInsets.all(14),
                    child: Image.asset('assets/images/logo1.png',
                        fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              FadeTransition(
                opacity: _fade,
                child: const Text('CASAIMO',
                    style: TextStyle(
                      fontSize: 38, fontWeight: FontWeight.w800,
                      color: Colors.white, letterSpacing: 4,
                    )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ignore: unused_element
extension on int {
  Duration get ms => Duration(milliseconds: this);
}
