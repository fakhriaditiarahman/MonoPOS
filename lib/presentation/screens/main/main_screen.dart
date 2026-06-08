import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/di/app_providers.dart';
import '../../../generated/app_localizations.dart';
import '../../providers/main/main_notifier.dart';
import '../splash/splash_screen.dart';

class MainScreen extends ConsumerStatefulWidget {
  final Widget child;

  const MainScreen({
    super.key,
    required this.child,
  });

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(mainNotifierProvider.notifier).initMainProvider();
    });
  }

  @override
  Widget build(BuildContext context) {
    final isLoaded = ref.watch(mainNotifierProvider.select((p) => p.isLoaded));

    // Display loading while data is being loaded
    if (!isLoaded) {
      return const SplashScreen();
    }

    return Scaffold(
      body: widget.child,
      bottomNavigationBar: BottomNavigationBar(
        items: <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: const Icon(Icons.maps_home_work_outlined),
            label: AppLocalizations.of(context)!.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.dashboard_customize_outlined),
            label: AppLocalizations.of(context)!.products,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.receipt_long_rounded),
            label: AppLocalizations.of(context)!.transactions,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.account_circle_outlined),
            label: AppLocalizations.of(context)!.settings,
          ),
        ],
        currentIndex: _calculateSelectedIndex(),
        onTap: (int idx) => _onItemTapped(idx),
      ),
    );
  }

  int _calculateSelectedIndex() {
    final String location = ref.read(goRouterProvider).state.uri.path;

    if (location.startsWith('/home')) {
      return 0;
    }

    if (location.startsWith('/products')) {
      return 1;
    }

    if (location.startsWith('/transactions')) {
      return 2;
    }

    if (location.startsWith('/account')) {
      return 3;
    }

    return 0;
  }

  void _onItemTapped(int index) {
    final router = ref.read(goRouterProvider);

    switch (index) {
      case 0:
        router.go('/home');
      case 1:
        router.go('/products');
      case 2:
        router.go('/transactions');
      case 3:
        router.go('/account');
    }
  }
}
