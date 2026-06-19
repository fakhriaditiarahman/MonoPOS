import 'dart:convert';
import 'dart:math';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/result.dart';
import '../../constants/constants.dart';
import '../../utilities/console_logger.dart';

class InteractiveQrisInvoiceResponse {
  final String qrisContent;
  final String qrisRequestDate;
  final String qrisInvoiceId;
  final String qrisNmid;

  const InteractiveQrisInvoiceResponse({
    required this.qrisContent,
    required this.qrisRequestDate,
    required this.qrisInvoiceId,
    required this.qrisNmid,
  });
}

class InteractiveQrisPaymentService {
  final SharedPreferences _prefs;

  InteractiveQrisPaymentService(this._prefs);

  String? get _apiKey => _prefs.getString(Constants.qrisApiKey);
  String? get _mid => _prefs.getString(Constants.qrisMid);
  String? get _merchantName => _prefs.getString(Constants.qrisMerchantName);

  String get merchantName => _merchantName ?? 'Toko';

  static const String _baseUrl = 'https://qris.interactive.co.id/restapi/qris';

  bool get isConfigured => _apiKey != null && _apiKey!.isNotEmpty && _mid != null && _mid!.isNotEmpty;
  bool get isMockMode => !isConfigured;

  Future<Result<InteractiveQrisInvoiceResponse>> createQrisInvoice({
    required String orderId,
    required int grossAmount,
  }) async {
    if (isMockMode) {
      return _mockCreateQrisInvoice(orderId, grossAmount);
    }

    try {
      final uri = Uri.parse('$_baseUrl/show_qris.php').replace(
        queryParameters: {
          'do': 'create-invoice',
          'apikey': _apiKey!,
          'mID': _mid!,
          'cliTrxNumber': orderId,
          'cliTrxAmount': grossAmount.toString(),
          'useTip': 'no',
        },
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        return Result.failure(error: 'QRIS API error (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['status'] != 'success') {
        final errData = json['data'] as Map<String, dynamic>?;
        return Result.failure(error: errData?['qris_status'] as String? ?? 'Gagal membuat invoice QRIS');
      }

      final data = json['data'] as Map<String, dynamic>;

      return Result.success(
        data: InteractiveQrisInvoiceResponse(
          qrisContent: data['qris_content'] as String? ?? '',
          qrisRequestDate: data['qris_request_date'] as String? ?? '',
          qrisInvoiceId: data['qris_invoiceid'] as String? ?? '',
          qrisNmid: data['qris_nmid'] as String? ?? '',
        ),
      );
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<String>> checkInvoiceStatus({
    required String invoiceId,
    required int amount,
    required String date,
  }) async {
    if (isMockMode) {
      return _mockCheckInvoiceStatus(invoiceId);
    }

    try {
      final uri = Uri.parse('$_baseUrl/checkpaid_qris.php').replace(
        queryParameters: {
          'do': 'checkStatus',
          'apikey': _apiKey!,
          'mID': _mid!,
          'invid': invoiceId,
          'trxvalue': amount.toString(),
          'trxdate': date,
        },
      );

      final response = await http.get(
        uri,
        headers: {'Accept': 'application/json'},
      );

      if (response.statusCode != 200) {
        return Result.failure(error: 'QRIS status error (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['status'] == 'success') {
        return Result.success(data: 'paid');
      }

      return Result.success(data: 'pending');
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  // Mock implementation
  final Map<String, _MockQrisState> _mockStates = {};

  Result<InteractiveQrisInvoiceResponse> _mockCreateQrisInvoice(String orderId, int grossAmount) {
    final qrData = 'QRIS-MOCK-$orderId-${Random().nextInt(99999)}';
    final invoiceId = 'MOCK-INV-${DateTime.now().millisecondsSinceEpoch}';
    final now = DateTime.now();
    final dateStr =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

    _mockStates[orderId] = _MockQrisState(
      status: 'pending',
      createdAt: DateTime.now(),
    );

    cl('[QrisMock] Created invoice for $orderId: amount=$grossAmount');

    return Result.success(
      data: InteractiveQrisInvoiceResponse(
        qrisContent: qrData,
        qrisRequestDate: dateStr,
        qrisInvoiceId: invoiceId,
        qrisNmid: 'MOCK-NMID-00000',
      ),
    );
  }

  Future<Result<String>> _mockCheckInvoiceStatus(String orderId) async {
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
      cl('[QrisMock] Payment completed for $orderId');
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
