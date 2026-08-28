import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app/app.dart';
import 'app/di/app_providers.dart';
import 'core/services/supabase/supabase_config.dart';
import 'core/services/supabase/supabase_service.dart';
import 'core/utilities/console_logger.dart';

void main() async {
  // Initialize binding
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize shared preferences
  final sharedPreferences = await SharedPreferences.getInstance();

  // Load runtime Supabase credentials (admin settings) before init
  await SupabaseConfig.init();

  // Initialize Supabase (if configured)
  final supabaseReady = await SupabaseService.initialize();
  if (!supabaseReady) {
    cw('Supabase tidak dikonfigurasi — sync & remote nonaktif. Jalankan dengan --dart-define-from-file config.json');
  }

  // Set/lock screen orientation
  await SystemChrome.setPreferredOrientations([]);

  // Set Default SystemUIOverlayStyle
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      systemNavigationBarColor: Colors.transparent,
      statusBarColor: Colors.transparent,
    ),
  );

  runApp(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(sharedPreferences)],
      child: const App(),
    ),
  );
}
