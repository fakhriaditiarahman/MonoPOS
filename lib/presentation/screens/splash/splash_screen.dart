import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player/video_player.dart';

import '../../../core/themes/app_colors.dart';
import '../../providers/splash/splash_notifier.dart';
import '../../providers/splash/splash_state.dart';

const String _videoPhone = 'assets/videos/MonoPOS_splash_screen_animation_202607220319.mp4';
const String _videoTablet = 'assets/videos/MonoPOS_splash_screen_animation_table.mp4';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  VideoPlayerController? _videoController;
  AnimationController? _fadeController;
  bool _videoFinished = false;
  bool _navigating = false;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    final width = MediaQueryData.fromView(
      WidgetsBinding.instance.platformDispatcher.views.first,
    ).size.width;
    final isTablet = width >= 600;

    _videoController = VideoPlayerController.asset(
      isTablet ? _videoTablet : _videoPhone,
    );

    _videoController!
        .initialize()
        .then((_) {
          if (!mounted) return;
          setState(() {});
          _videoController!.setVolume(0);
          _videoController!.addListener(() {
            if (!_videoController!.value.isInitialized) return;
            if (_videoController!.value.isCompleted && !_videoFinished) {
              _videoFinished = true;
              _startInit();
            }
          });
          _videoController!.play();
        })
        .catchError((_) {
          if (!mounted) return;
          _startInit();
        });
  }

  void _startInit() {
    ref.read(splashNotifierProvider.notifier).initializeApp();
  }

  void _navigateAway() {
    if (_navigating) return;
    _navigating = true;

    _fadeController?.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        if (mounted) context.go('/login');
      }
    });
    _fadeController?.forward();
  }

  @override
  void dispose() {
    _videoController?.dispose();
    _fadeController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SplashState>(splashNotifierProvider, (_, state) {
      if (state.isInitialized && _videoFinished && !_navigating) {
        _navigateAway();
      }
    });

    final hasVideo = _videoController != null && _videoController!.value.isInitialized;

    return Scaffold(
      backgroundColor: AppColors.orange,
      body: Stack(
        children: [
          if (hasVideo)
            Positioned.fill(
              child: FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _videoController!.value.size.width,
                  height: _videoController!.value.size.height,
                  child: VideoPlayer(_videoController!),
                ),
              ),
            ),

          if (_navigating)
            Positioned.fill(
              child: FadeTransition(
                opacity: CurvedAnimation(
                  parent: _fadeController!,
                  curve: Curves.easeIn,
                ),
                child: Container(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
