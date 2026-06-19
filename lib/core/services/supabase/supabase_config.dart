import 'dart:convert';
import 'dart:io';

class SupabaseConfig {
  SupabaseConfig._();

  static const String _defaultUrl = '';
  static const String _defaultAnonKey = '';

  static String get supabaseUrl {
    const envUrl = String.fromEnvironment('SUPABASE_URL');
    if (envUrl.isNotEmpty) return envUrl;

    try {
      const file = String.fromEnvironment('SUPABASE_CONFIG_PATH');
      if (file.isNotEmpty) {
        final configFile = File(file);
        if (configFile.existsSync()) {
          final json = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
          return json['supabaseUrl'] as String;
        }
      }
    } catch (_) {}

    return _defaultUrl;
  }

  static String get supabaseAnonKey {
    const envKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (envKey.isNotEmpty) return envKey;

    try {
      const file = String.fromEnvironment('SUPABASE_CONFIG_PATH');
      if (file.isNotEmpty) {
        final configFile = File(file);
        if (configFile.existsSync()) {
          final json = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
          return json['supabaseAnonKey'] as String;
        }
      }
    } catch (_) {}

    return _defaultAnonKey;
  }

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static const String usersTable = 'users';
  static const String productsTable = 'products';
  static const String productUnitsTable = 'product_units';
  static const String transactionsTable = 'transactions';
  static const String orderedProductsTable = 'ordered_products';
  static const String queuedActionsTable = 'queued_actions';

  // Storage buckets
  static const String avatarsBucket = 'avatars';
  static const String productsBucket = 'products';

  // S3 Configuration for Supabase Storage
  static const String _defaultS3Endpoint = '';
  static const String _defaultS3Region = '';
  static const String _defaultS3AccessKey = '';
  static const String _defaultS3SecretKey = '';

  static String get s3Endpoint {
    const env = String.fromEnvironment('S3_ENDPOINT');
    if (env.isNotEmpty) return env;
    return _defaultS3Endpoint;
  }

  static String get s3Region {
    const env = String.fromEnvironment('S3_REGION');
    if (env.isNotEmpty) return env;
    return _defaultS3Region;
  }

  static String get s3AccessKey {
    const env = String.fromEnvironment('S3_ACCESS_KEY');
    if (env.isNotEmpty) return env;
    return _defaultS3AccessKey;
  }

  static String get s3SecretKey {
    const env = String.fromEnvironment('S3_SECRET_KEY');
    if (env.isNotEmpty) return env;
    return _defaultS3SecretKey;
  }
}
