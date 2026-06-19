import 'dart:io';
import 'dart:math';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/common/result.dart';
import '../../../core/services/storage/s3_storage_service.dart';
import '../../../core/services/supabase/supabase_config.dart';
import '../../../core/services/supabase/supabase_service.dart';
import '../interfaces/storage_datasource.dart';

class StorageRemoteDataSourceImpl extends StorageDatasource {
  StorageRemoteDataSourceImpl();

  SupabaseClient? get _client => SupabaseService.client;

  S3StorageService? _s3Service;

  S3StorageService _getS3Service() {
    _s3Service ??= S3StorageService(
      accessKey: SupabaseConfig.s3AccessKey,
      secretKey: SupabaseConfig.s3SecretKey,
      region: SupabaseConfig.s3Region,
      endpoint: SupabaseConfig.s3Endpoint,
    );
    return _s3Service!;
  }

  String _publicUrl(String bucket, String path) =>
      '${SupabaseConfig.supabaseUrl}/storage/v1/object/public/$bucket/$path';

  @override
  Future<Result<String>> uploadUserPhoto({
    required String userId,
    required String filePath,
  }) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      final file = File(filePath);
      if (!file.existsSync()) return Result.failure(error: 'File not found: $filePath');

      final ext = filePath.split('.').last;
      final random = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
      final fileName = '$random.$ext';
      final path = '$userId/$fileName';

      // Upload via S3 protocol with AWS SigV4
      final s3 = _getS3Service();
      await s3.uploadFile(
        bucket: SupabaseConfig.avatarsBucket,
        key: path,
        file: file,
      );

      final url = _publicUrl(SupabaseConfig.avatarsBucket, path);

      return Result.success(data: url);
    } catch (e) {
      return Result.failure(error: e);
    }
  }

  @override
  Future<Result<String>> uploadProductImage({
    required String productId,
    required String filePath,
  }) async {
    try {
      final client = _client;
      if (client == null) return Result.failure(error: 'Supabase not configured');

      final file = File(filePath);
      if (!file.existsSync()) return Result.failure(error: 'File not found: $filePath');

      final ext = filePath.split('.').last;
      final random = '${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(99999)}';
      final fileName = '$random.$ext';
      final path = '$productId/$fileName';

      // Upload via S3 protocol with AWS SigV4
      final s3 = _getS3Service();
      await s3.uploadFile(
        bucket: SupabaseConfig.productsBucket,
        key: path,
        file: file,
      );

      final url = _publicUrl(SupabaseConfig.productsBucket, path);

      return Result.success(data: url);
    } catch (e) {
      return Result.failure(error: e);
    }
  }
}
