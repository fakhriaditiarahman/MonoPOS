import 'dart:convert';
import 'dart:io';

class SupabaseConfig {
  SupabaseConfig._();

  static const String _defaultUrl = '';

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
    const publishable = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    if (publishable.isNotEmpty) return publishable;

    const legacy = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (legacy.isNotEmpty) return legacy;

    try {
      const file = String.fromEnvironment('SUPABASE_CONFIG_PATH');
      if (file.isNotEmpty) {
        final configFile = File(file);
        if (configFile.existsSync()) {
          final json = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
          final fromPublishable = json['SUPABASE_PUBLISHABLE_KEY'] as String?;
          if (fromPublishable != null && fromPublishable.isNotEmpty) return fromPublishable;
          final fromLegacy = json['SUPABASE_ANON_KEY'] as String?;
          if (fromLegacy != null && fromLegacy.isNotEmpty) return fromLegacy;
        }
      }
    } catch (_) {}

    return '';
  }

  static bool get isConfigured => supabaseUrl.isNotEmpty && supabaseAnonKey.isNotEmpty;

  static String get supabaseSecretKey {
    const secret = String.fromEnvironment('SUPABASE_SECRET_KEY');
    if (secret.isNotEmpty) return secret;

    try {
      const file = String.fromEnvironment('SUPABASE_CONFIG_PATH');
      if (file.isNotEmpty) {
        final configFile = File(file);
        if (configFile.existsSync()) {
          final json = jsonDecode(configFile.readAsStringSync()) as Map<String, dynamic>;
          final fromConfig = json['SUPABASE_SECRET_KEY'] as String?;
          if (fromConfig != null && fromConfig.isNotEmpty) return fromConfig;
        }
      }
    } catch (_) {}

    return '';
  }

  static const String usersTable = 'users';
  static const String productsTable = 'products';
  static const String productUnitsTable = 'product_units';
  static const String productTieredPricesTable = 'product_tiered_prices';
  static const String customersTable = 'customers';
  static const String transactionsTable = 'transactions';
  static const String orderedProductsTable = 'ordered_products';
  static const String queuedActionsTable = 'queued_actions';
  static const String receivablePaymentsTable = 'receivable_payments';
}
