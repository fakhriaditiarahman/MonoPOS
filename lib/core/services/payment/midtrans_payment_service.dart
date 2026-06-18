import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/result.dart';
import '../../constants/constants.dart';
import '../../utilities/console_logger.dart';

class MidtransQrisResponse {
  final String qrCode;
  final String transactionId;
  final String orderId;

  const MidtransQrisResponse({
    required this.qrCode,
    required this.transactionId,
    required this.orderId,
  });
}

class MidtransPaymentService {
  final SharedPreferences _prefs;

  MidtransPaymentService(this._prefs);

  bool get _isProduction => _prefs.getBool(Constants.midtransIsProduction) ?? false;
  String? get _serverKey => _prefs.getString(Constants.midtransServerKey);

  String get _baseUrl => _isProduction ? 'https://api.midtrans.com/v2' : 'https://api.sandbox.midtrans.com/v2';

  bool get isConfigured => _serverKey != null && _serverKey!.isNotEmpty;

  bool get isMockMode => !isConfigured;

  String get merchantName => _prefs.getString(Constants.midtransMerchantName) ?? 'Toko';

  Future<Result<MidtransQrisResponse>> createQrisCharge({
    required String orderId,
    required int grossAmount,
  }) async {
    if (isMockMode) {
      return _mockCreateQrisCharge(orderId, grossAmount);
    }

    try {
      final body = jsonEncode({
        'payment_type': 'qris',
        'transaction_details': {
          'order_id': orderId,
          'gross_amount': grossAmount,
        },
      });

      final response = await http.post(
        Uri.parse('$_baseUrl/charge'),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_serverKey:'))}',
        },
        body: body,
      );

      if (response.statusCode != 201) {
        return Result.failure(error: 'Midtrans error (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      String? qrCode;
      final actions = json['actions'] as List?;
      if (actions != null) {
        for (final action in actions) {
          if (action['name'] == 'generate_qr_code') {
            qrCode = action['url'] as String?;
            break;
          }
        }
      }

      qrCode ??= json['qr_code'] as String?;

      if (qrCode == null) {
        return Result.failure(error: 'No QR code found in Midtrans response');
      }

      return Result.success(
        data: MidtransQrisResponse(
          qrCode: qrCode,
          transactionId: json['transaction_id'] as String? ?? '',
          orderId: json['order_id'] as String? ?? orderId,
        ),
      );
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<String>> checkTransactionStatus(String orderId) async {
    if (isMockMode) {
      return _mockCheckTransactionStatus(orderId);
    }

    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/$orderId/status'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Basic ${base64Encode(utf8.encode('$_serverKey:'))}',
        },
      );

      if (response.statusCode != 200) {
        return Result.failure(error: 'Midtrans status error (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final transactionStatus = json['transaction_status'] as String? ?? 'unknown';

      return Result.success(data: _normalizeStatus(transactionStatus));
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  String _normalizeStatus(String status) {
    switch (status) {
      case 'settlement':
      case 'capture':
        return 'paid';
      case 'pending':
        return 'pending';
      case 'deny':
      case 'cancel':
      case 'expire':
        return 'failed';
      default:
        return 'pending';
    }
  }

  // Mock implementation for testing
  final Map<String, _MockQrisState> _mockStates = {};

  Result<MidtransQrisResponse> _mockCreateQrisCharge(String orderId, int grossAmount) {
    final qrData = 'QRIS-MOCK-$orderId-${Random().nextInt(99999)}';
    final txId = 'MOCK-TRX-${DateTime.now().millisecondsSinceEpoch}';

    _mockStates[orderId] = _MockQrisState(
      status: 'pending',
      createdAt: DateTime.now(),
    );

    cl('[MidtransMock] Created QRIS for $orderId: amount=$grossAmount');

    return Result.success(
      data: MidtransQrisResponse(
        qrCode: qrData,
        transactionId: txId,
        orderId: orderId,
      ),
    );
  }

  Future<Result<String>> _mockCheckTransactionStatus(String orderId) async {
    final state = _mockStates[orderId];
    if (state == null) {
      return Result.success(data: 'failed');
    }

    if (state.status == 'paid') {
      return Result.success(data: 'paid');
    }

    // Simulate payment after 30 seconds
    final elapsed = DateTime.now().difference(state.createdAt);
    if (elapsed.inSeconds >= 30) {
      _mockStates[orderId] = state.copyWith(status: 'paid');
      cl('[MidtransMock] Payment completed for $orderId');
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
