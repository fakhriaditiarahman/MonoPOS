import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/themes/app_colors.dart';
import '../../providers/splash/splash_notifier.dart';
import '../../providers/splash/splash_state.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _timerDone = false;

  @override
  void initState() {
    super.initState();
    _startMinimumTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(splashNotifierProvider.notifier).initializeApp();
    });
  }

  void _startMinimumTimer() {
    Timer(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _timerDone = true);
        _tryNavigate();
      }
    });
  }

  void _tryNavigate() {
    final initState = ref.read(splashNotifierProvider);
    if (initState.isInitialized && _timerDone) {
      _navigate();
    }
  }

  void _navigate() {
    context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<SplashState>(splashNotifierProvider, (_, state) {
      if (state.isInitialized && _timerDone) {
        _navigate();
      }
    });

    return Scaffold(
      backgroundColor: AppColors.orange,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Spacer(flex: 2),
              Image.asset(
                'assets/images/logomonopos-removebg-preview.png',
                width: 120,
                height: 120,
              ),
              const SizedBox(height: 24),
              Text(
                'MonoPOS',
                style: Theme.of(context).textTheme.displayLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Point of Sale',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white70,
                ),
              ),
              const Spacer(flex: 3),
              const SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 3,
                ),
              ),
              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
