import 'dart:io';

import 'package:aws_common/aws_common.dart';
import 'package:aws_signature_v4/aws_signature_v4.dart';

class S3StorageService {
  S3StorageService({
    required String accessKey,
    required String secretKey,
    required String region,
    required String endpoint,
  })  : _signer = AWSSigV4Signer(
          credentialsProvider: AWSCredentialsProvider(
            AWSCredentials(accessKey, secretKey),
          ),
        ),
        _region = region,
        _endpoint = endpoint;

  final AWSSigV4Signer _signer;
  final String _region;
  final String _endpoint;

  Future<void> uploadFile({
    required String bucket,
    required String key,
    required File file,
  }) async {
    final bytes = await file.readAsBytes();
    final uri = Uri.parse('$_endpoint/$bucket/$key');

    final request = AWSHttpRequest(
      method: AWSHttpMethod.put,
      uri: uri,
      headers: {
        AWSHeaders.contentLength: bytes.length.toString(),
        AWSHeaders.contentType: _getMimeType(key),
      },
      body: bytes,
    );

    final scope = AWSCredentialScope(
      region: _region,
      service: AWSService.s3,
    );

    final signedRequest = await _signer.sign(request, credentialScope: scope);
    final operation = signedRequest.send();
    final response = await operation.response;

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception('Upload failed with status ${response.statusCode}');
    }
  }

  String _getMimeType(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    switch (ext) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      case 'gif':
        return 'image/gif';
      default:
        return 'application/octet-stream';
    }
  }
}
