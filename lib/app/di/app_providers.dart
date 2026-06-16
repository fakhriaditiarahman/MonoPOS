import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/services/connectivity/ping_service.dart';
import '../../core/services/database/database_service.dart';
import '../../core/services/info/device_info_service.dart';
import '../../core/services/logger/error_logger_service.dart';
import '../../core/services/printer/printer_service.dart';
import '../../data/datasources/local/auth_local_datasource_impl.dart';
import '../../data/datasources/local/product_local_datasource_impl.dart';
import '../../data/datasources/local/transaction_local_datasource_impl.dart';
import '../../data/datasources/local/user_local_datasource_impl.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/product_repository_impl.dart';
import '../../data/repositories/transaction_repository_impl.dart';
import '../../data/repositories/user_repository_impl.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/repositories/product_repository.dart';
import '../../domain/repositories/transaction_repository.dart';
import '../../domain/repositories/user_repository.dart';
import '../../presentation/providers/auth/auth_notifier.dart';
import '../routes/app_routes.dart';

// Startup overrides
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider must be overridden at app startup.'),
);

// Third parties
final deviceInfoPluginProvider = Provider<DeviceInfoPlugin>((ref) => DeviceInfoPlugin());

// Routes
final goRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authNotifierProvider);
  return AppRoutes().build(isAuthenticated: authState.isAuthenticated);
});

// Services
final databaseServiceProvider = Provider<DatabaseService>((ref) => DatabaseService.instance);
final pingServiceProvider = Provider<PingService>((ref) => PingService());
final deviceInfoServiceProvider = Provider<DeviceInfoService>(
  (ref) => DeviceInfoService(ref.watch(deviceInfoPluginProvider)),
);
final errorLoggerServiceProvider = Provider<ErrorLoggerService>(
  (ref) => ErrorLoggerService(),
);
final printerServiceProvider = Provider<PrinterService>(
  (ref) => PrinterService(ref.watch(sharedPreferencesProvider)),
);

// Datasources
// Local Datasources
final authLocalDataSourceProvider = Provider<AuthLocalDataSourceImpl>(
  (ref) => AuthLocalDataSourceImpl(ref.watch(userLocalDatasourceProvider)),
);
final productLocalDatasourceProvider = Provider<ProductLocalDatasourceImpl>(
  (ref) => ProductLocalDatasourceImpl(ref.watch(databaseServiceProvider)),
);
final transactionLocalDatasourceProvider = Provider<TransactionLocalDatasourceImpl>(
  (ref) => TransactionLocalDatasourceImpl(ref.watch(databaseServiceProvider)),
);
final userLocalDatasourceProvider = Provider<UserLocalDatasourceImpl>(
  (ref) => UserLocalDatasourceImpl(ref.watch(databaseServiceProvider)),
);

// Repositories
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    authLocalDataSource: ref.watch(authLocalDataSourceProvider),
  ),
);
final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ProductRepositoryImpl(
    productLocalDatasource: ref.watch(productLocalDatasourceProvider),
  ),
);
final transactionRepositoryProvider = Provider<TransactionRepository>(
  (ref) => TransactionRepositoryImpl(
    transactionLocalDatasource: ref.watch(transactionLocalDatasourceProvider),
  ),
);
final userRepositoryProvider = Provider<UserRepository>(
  (ref) => UserRepositoryImpl(
    userLocalDatasource: ref.watch(userLocalDatasourceProvider),
  ),
);
