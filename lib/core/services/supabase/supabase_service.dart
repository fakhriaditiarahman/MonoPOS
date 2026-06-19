import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_config.dart';

class SupabaseService {
  SupabaseService._();

  static SupabaseClient? get client {
    if (!SupabaseConfig.isConfigured) return null;

    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  static Future<bool> initialize() async {
    if (!SupabaseConfig.isConfigured) return false;

    try {
      await Supabase.initialize(
        url: SupabaseConfig.supabaseUrl,
        publishableKey: SupabaseConfig.supabaseAnonKey,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static Future<void> signOut() async {
    try {
      await client?.auth.signOut();
    } catch (_) {}
  }
}
