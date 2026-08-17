import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/result.dart';
import '../../constants/constants.dart';
import '../../utilities/console_logger.dart';

class KlikQrisQrisResponse {
  final String orderId;
  final String qrUrl;
  final String qrImageBase64;
  final int totalAmount;
  final String status;
  final String signature;
  final String expiredAt;
  final int expiredMinutes;

  const KlikQrisQrisResponse({
    required this.orderId,
    required this.qrUrl,
    required this.qrImageBase64,
    required this.totalAmount,
    required this.status,
    required this.signature,
    required this.expiredAt,
    required this.expiredMinutes,
  });
}

class KlikQrisPaymentService {
  final SharedPreferences _prefs;

  KlikQrisPaymentService(this._prefs);

  String? get _apiKey => _prefs.getString(Constants.klikQrisApiKey);
  String? get _merchantId => _prefs.getString(Constants.klikQrisMerchantId);
  bool get _isSandbox => _prefs.getBool(Constants.klikQrisIsSandbox) ?? true;

  static const String _baseUrl = 'https://klikqris.com/api';

  String get _envBaseUrl => _isSandbox ? '$_baseUrl/sandbox' : _baseUrl;

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty && _merchantId != null && _merchantId!.isNotEmpty;

  bool get isMockMode => !isConfigured;

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    'x-api-key': _apiKey!,
    'id_merchant': _merchantId!,
  };

  Future<Result<KlikQrisQrisResponse>> generateQris({
    required String orderId,
    required int grossAmount,
  }) async {
    if (isMockMode) {
      return _mockGenerateQris(orderId, grossAmount);
    }

    try {
      final body = {
        'order_id': orderId,
        'id_merchant': _merchantId,
        'amount': grossAmount,
        'keterangan': 'Pembayaran QRIS MonoPOS',
      };

      final uri = Uri.parse('$_envBaseUrl/qris/create');
      final response = await http.post(uri, headers: _headers, body: jsonEncode(body));

      if (response.statusCode != 200 && response.statusCode != 201) {
        return Result.failure(error: 'KlikQRIS error (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as bool? ?? false;

      if (!status) {
        return Result.failure(error: json['message'] as String? ?? 'Gagal membuat QRIS');
      }

      final data = json['data'] as Map<String, dynamic>?;

      if (data == null) {
        return Result.failure(error: 'Respons KlikQRIS tidak valid');
      }

      final totalAmount = double.tryParse(data['total_amount'] as String? ?? '0')?.round() ?? grossAmount;
      final expiredMinutes = int.tryParse(data['expired_menit'] as String? ?? '') ?? 60;

      final result = KlikQrisQrisResponse(
        orderId: data['order_id'] as String? ?? orderId,
        qrUrl: data['qris_url'] as String? ?? '',
        qrImageBase64: data['qris_image'] as String? ?? '',
        totalAmount: totalAmount,
        status: data['status'] as String? ?? 'PENDING',
        signature: data['signature'] as String? ?? '',
        expiredAt: data['expired_at'] as String? ?? '',
        expiredMinutes: expiredMinutes,
      );

      cl(
        '[KlikQRIS] generateQris ok: orderId=${result.orderId} '
        'qrImageBase64.len=${result.qrImageBase64.length} '
        'qrUrl=${result.qrUrl} totalAmount=${result.totalAmount}',
      );

      return Result.success(data: result);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<String>> queryQrisStatus({
    required String orderId,
  }) async {
    if (isMockMode) {
      return _mockQueryQrisStatus(orderId);
    }

    try {
      final uri = Uri.parse('$_envBaseUrl/qris/status/$orderId');
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode != 200 && response.statusCode != 201) {
        return Result.failure(error: 'KlikQRIS status error (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final status = json['status'] as bool? ?? false;

      if (!status) {
        return Result.failure(error: json['message'] as String? ?? 'Gagal cek status');
      }

      final data = json['data'] as Map<String, dynamic>?;
      final transactionStatus = data?['status'] as String? ?? 'PENDING';

      switch (transactionStatus) {
        case 'SUCCESS':
          return Result.success(data: 'paid');
        case 'EXPIRED':
          return Result.failure(error: data?['message'] as String? ?? 'Pembayaran kedaluwarsa');
        default:
          return Result.success(data: 'pending');
      }
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  // Mock implementation

  final Map<String, _MockQrisState> _mockStates = {};

  Result<KlikQrisQrisResponse> _mockGenerateQris(String orderId, int grossAmount) {
    final qrUrl = 'https://klikqris.com/storage/sandbox/qris_$orderId.png';
    final now = DateTime.now();

    _mockStates[orderId] = _MockQrisState(
      status: 'pending',
      createdAt: DateTime.now(),
    );

    cl('[KlikQrisMock] Generated QRIS for $orderId: amount=$grossAmount');

    return Result.success(
      data: KlikQrisQrisResponse(
        orderId: orderId,
        qrUrl: qrUrl,
        qrImageBase64: '',
        totalAmount: grossAmount + Random().nextInt(99),
        status: 'PENDING',
        signature: 'MOCK-SIGNATURE',
        expiredAt: now.toUtc().toIso8601String(),
        expiredMinutes: 60,
      ),
    );
  }

  Future<Result<String>> _mockQueryQrisStatus(String orderId) async {
    final state = _mockStates[orderId];
    if (state == null) {
      return Result.success(data: 'failed');
    }

    if (state.status == 'paid') {
      return Result.success(data: 'paid');
    }

    final elapsed = DateTime.now().difference(state.createdAt);
    if (elapsed.inSeconds >= 30) {
      _mockStates[orderId] = state.copyWith(status: 'paid');
      cl('[KlikQrisMock] Payment completed for $orderId');
      return Result.success(data: 'paid');
    }

    return Result.success(data: 'pending');
  }
}

class _MockQrisState {
  final String status;
  final DateTime createdAt;

  const _MockQrisState({required this.status, required this.createdAt});

  _MockQrisState copyWith({String? status}) {
    return _MockQrisState(status: status ?? this.status, createdAt: createdAt);
  }
}
