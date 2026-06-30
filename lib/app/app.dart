import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/locale/app_locale.dart';
import '../presentation/providers/language/language_notifier.dart';
import '../presentation/providers/theme/theme_notifier.dart';
import 'di/app_providers.dart';
import 'error/error_handler_builder.dart';

class App extends ConsumerWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeNotifierProvider.select((s) => s.themeData));
    final locale = ref.watch(languageNotifierProvider.select((s) => s.locale));
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Mono POS',
      theme: theme,
      debugShowCheckedModeBanner: kDebugMode,
      routerConfig: router,
      locale: locale,
      supportedLocales: AppLocale.supportedLocales,
      localizationsDelegates: AppLocale.localizationsDelegates,
      builder: (context, child) => ErrorHandlerBuilder(child: child),
    );
  }
}
