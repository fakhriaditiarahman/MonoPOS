import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:pointycastle/asn1.dart';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../common/result.dart';
import '../../constants/constants.dart';
import '../../utilities/console_logger.dart';

class DokuQrisResponse {
  final String qrContent;
  final String partnerReferenceNo;
  final String referenceNo;
  final String terminalId;

  const DokuQrisResponse({
    required this.qrContent,
    required this.partnerReferenceNo,
    required this.referenceNo,
    required this.terminalId,
  });
}

class DokuRefundResponse {
  final String responseCode;
  final String responseMessage;
  final String originalReferenceNo;
  final String originalPartnerReferenceNo;
  final String refundNo;
  final String partnerRefundNo;
  final String refundAmount;
  final String currency;
  final String refundTime;

  const DokuRefundResponse({
    required this.responseCode,
    required this.responseMessage,
    required this.originalReferenceNo,
    required this.originalPartnerReferenceNo,
    required this.refundNo,
    required this.partnerRefundNo,
    required this.refundAmount,
    required this.currency,
    required this.refundTime,
  });
}

class DokuDecodeResponse {
  final String responseCode;
  final String responseMessage;
  final String referenceNo;
  final String partnerReferenceNo;
  final String merchantName;
  final String transactionAmount;
  final String currency;
  final String merchantPan;
  final String acquirerName;
  final String postalCode;
  final String feeAmount;
  final String pointOfInitiationMethod;
  final String feeType;

  const DokuDecodeResponse({
    required this.responseCode,
    required this.responseMessage,
    required this.referenceNo,
    required this.partnerReferenceNo,
    required this.merchantName,
    required this.transactionAmount,
    required this.currency,
    required this.merchantPan,
    required this.acquirerName,
    required this.postalCode,
    required this.feeAmount,
    required this.pointOfInitiationMethod,
    required this.feeType,
  });
}

class DokuPaymentResponse {
  final String responseCode;
  final String responseMessage;
  final String referenceNo;
  final String partnerReferenceNo;
  final String amount;
  final String currency;
  final String feeAmount;
  final String approvalCode;

  const DokuPaymentResponse({
    required this.responseCode,
    required this.responseMessage,
    required this.referenceNo,
    required this.partnerReferenceNo,
    required this.amount,
    required this.currency,
    required this.feeAmount,
    required this.approvalCode,
  });
}

class DokuPaymentService {
  final SharedPreferences _prefs;

  DokuPaymentService(this._prefs);

  String? get _clientId => _prefs.getString(Constants.dokuClientId);
  String? get _clientSecret => _prefs.getString(Constants.dokuClientSecret);
  String? get _merchantId => _prefs.getString(Constants.dokuMerchantId);
  String? get _terminalId => _prefs.getString(Constants.dokuTerminalId);
  String? get _privateKey => _prefs.getString(Constants.dokuPrivateKey);
  bool get _isSandbox => _prefs.getBool(Constants.dokuIsSandbox) ?? true;

  static const String _sandboxBaseUrl = 'https://api-sandbox.doku.com';
  static const String _productionBaseUrl = 'https://api.doku.com';

  String get _baseUrl => _isSandbox ? _sandboxBaseUrl : _productionBaseUrl;

  bool get isConfigured =>
      _clientId != null &&
      _clientId!.isNotEmpty &&
      _clientSecret != null &&
      _clientSecret!.isNotEmpty &&
      _merchantId != null &&
      _merchantId!.isNotEmpty;

  bool get isMockMode => !isConfigured;

  String? _accessToken;
  DateTime? _tokenExpiry;

  Future<String?> _getAccessToken() async {
    if (_accessToken != null && _tokenExpiry != null && DateTime.now().isBefore(_tokenExpiry!)) {
      return _accessToken;
    }

    if (_privateKey == null || _privateKey!.isEmpty) {
      cl('[Doku] Private key not configured, cannot get token');
      return null;
    }

    try {
      final timestamp = DateTime.now().toUtc().toIso8601String();
      final stringToSign = '$_clientId|$timestamp';
      final signature = _rsaSign(stringToSign, _privateKey!);

      final uri = Uri.parse('$_baseUrl/authorization/v1/access-token/b2b');
      final response = await http.post(
        uri,
        headers: {
          'X-SIGNATURE': signature,
          'X-TIMESTAMP': timestamp,
          'X-CLIENT-KEY': _clientId!,
          'Content-Type': 'application/json',
        },
        body: jsonEncode({'grantType': 'client_credentials'}),
      );

      if (response.statusCode != 200) {
        cl('[Doku] Token error (${response.statusCode}): ${response.body}');
        return null;
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['responseCode'] != '2007300') {
        cl('[Doku] Token failed: ${json['responseMessage']}');
        return null;
      }

      _accessToken = json['accessToken'] as String?;
      final expiresIn = json['expiresIn'] as int? ?? 900;
      _tokenExpiry = DateTime.now().add(Duration(seconds: expiresIn));

      return _accessToken;
    } catch (e) {
      cl('[Doku] Token exception: $e');
      return null;
    }
  }

  Future<Result<DokuQrisResponse>> generateQris({
    required String orderId,
    required int grossAmount,
  }) async {
    if (isMockMode) {
      return _mockGenerateQris(orderId, grossAmount);
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return Result.failure(error: 'Gagal mendapatkan access token Doku');
      }

      final timestamp = DateTime.now().toUtc().toIso8601String();
      final externalId = '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(99999)}';

      final body = {
        'partnerReferenceNo': orderId,
        'amount': {
          'value': '$grossAmount.00',
          'currency': 'IDR',
        },
        'merchantId': _merchantId,
        'terminalId': _terminalId ?? 'POS-001',
        'validityPeriod': _generateValidityPeriod(),
        'additionalInfo': {
          'postalCode': '00000',
          'feeType': '1',
        },
      };

      final requestBody = jsonEncode(body);
      final endpointUrl = '/snap-adapter/b2b/v1.0/qr/qr-mpm-generate';
      final hexBody = _sha256Hex(requestBody);
      final stringToSign = 'POST:$endpointUrl:$accessToken:$hexBody:$timestamp';
      final signature = _hmacSha512(_clientSecret!, stringToSign);

      final uri = Uri.parse('$_baseUrl$endpointUrl');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-PARTNER-ID': _clientId!,
          'X-EXTERNAL-ID': externalId,
          'X-TIMESTAMP': timestamp,
          'X-SIGNATURE': signature,
          'Authorization': 'Bearer $accessToken',
          'CHANNEL-ID': 'H2H',
        },
        body: requestBody,
      );

      if (response.statusCode != 200) {
        return Result.failure(error: 'Doku QRIS error (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['responseCode'] != '2002600') {
        return Result.failure(error: json['responseMessage'] as String? ?? 'Gagal membuat QRIS');
      }

      return Result.success(
        data: DokuQrisResponse(
          qrContent: json['qrContent'] as String? ?? '',
          partnerReferenceNo: orderId,
          referenceNo: json['referenceNo'] as String? ?? '',
          terminalId: json['terminalId'] as String? ?? '',
        ),
      );
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<String>> queryQrisStatus({
    required String partnerReferenceNo,
    required String referenceNo,
  }) async {
    if (isMockMode) {
      return _mockQueryQrisStatus(partnerReferenceNo);
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return Result.failure(error: 'Gagal mendapatkan access token Doku');
      }

      final timestamp = DateTime.now().toUtc().toIso8601String();
      final externalId = '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(99999)}';

      final body = {
        'originalPartnerReferenceNo': partnerReferenceNo,
        'originalReferenceNo': referenceNo,
        'serviceCode': '47',
        'merchantId': _merchantId,
      };

      final requestBody = jsonEncode(body);
      final endpointUrl = '/snap-adapter/b2b/v1.0/qr/qr-mpm-query';
      final hexBody = _sha256Hex(requestBody);
      final stringToSign = 'POST:$endpointUrl:$accessToken:$hexBody:$timestamp';
      final signature = _hmacSha512(_clientSecret!, stringToSign);

      final uri = Uri.parse('$_baseUrl$endpointUrl');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-PARTNER-ID': _clientId!,
          'X-EXTERNAL-ID': externalId,
          'X-TIMESTAMP': timestamp,
          'X-SIGNATURE': signature,
          'Authorization': 'Bearer $accessToken',
          'CHANNEL-ID': 'H2H',
        },
        body: requestBody,
      );

      if (response.statusCode != 200) {
        return Result.failure(error: 'Doku status error (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final transactionStatus = json['latestTransactionStatus'] as String? ?? '07';

      switch (transactionStatus) {
        case '00':
          return Result.success(data: 'paid');
        case '03':
          return Result.success(data: 'pending');
        case '06':
          return Result.failure(error: json['transactionStatusDesc'] as String? ?? 'Pembayaran gagal');
        default:
          return Result.success(data: 'pending');
      }
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<void>> cancelQris({
    required String partnerReferenceNo,
    required String referenceNo,
  }) async {
    if (isMockMode) {
      _mockCancelQris(partnerReferenceNo);
      return Result.success(data: null);
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return Result.failure(error: 'Gagal mendapatkan access token Doku');
      }

      final timestamp = DateTime.now().toUtc().toIso8601String();
      final externalId = '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(99999)}';

      final body = {
        'partnerReferenceNo': partnerReferenceNo,
        'referenceNo': referenceNo,
        'merchantId': _merchantId,
        'reason': 'Cancelled by merchant',
      };

      final requestBody = jsonEncode(body);
      final endpointUrl = '/snap-adapter/b2b/v1.0/qr/qr-expire';
      final hexBody = _sha256Hex(requestBody);
      final stringToSign = 'POST:$endpointUrl:$accessToken:$hexBody:$timestamp';
      final signature = _hmacSha512(_clientSecret!, stringToSign);

      final uri = Uri.parse('$_baseUrl$endpointUrl');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-PARTNER-ID': _clientId!,
          'X-EXTERNAL-ID': externalId,
          'X-TIMESTAMP': timestamp,
          'X-SIGNATURE': signature,
          'Authorization': 'Bearer $accessToken',
          'CHANNEL-ID': 'H2H',
        },
        body: requestBody,
      );

      if (response.statusCode != 200) {
        return Result.failure(error: 'Doku cancel error (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      if (json['responseCode'] != '2002800') {
        return Result.failure(error: json['responseMessage'] as String? ?? 'Gagal membatalkan QRIS');
      }

      return Result.success(data: null);
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<DokuRefundResponse>> refundQris({
    required String originalPartnerReferenceNo,
    required String originalReferenceNo,
    required String partnerRefundNo,
    required int refundAmount,
    required String reason,
    required String approvalCode,
  }) async {
    if (isMockMode) {
      return _mockRefundQris(originalReferenceNo, partnerRefundNo, refundAmount);
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return Result.failure(error: 'Gagal mendapatkan access token Doku');
      }

      final timestamp = DateTime.now().toUtc().toIso8601String();
      final externalId = '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(99999)}';

      final body = {
        'merchantId': _merchantId,
        'originalPartnerReferenceNo': originalPartnerReferenceNo,
        'originalReferenceNo': originalReferenceNo,
        'partnerRefundNo': partnerRefundNo,
        'refundAmount': {
          'value': '$refundAmount.00',
          'currency': 'IDR',
        },
        'reason': reason,
        'additionalInfo': {
          'approvalCode': approvalCode,
        },
      };

      final requestBody = jsonEncode(body);
      final endpointUrl = '/snap-adapter/b2b/v1.0/qr/qr-mpm-refund';
      final hexBody = _sha256Hex(requestBody);
      final stringToSign = 'POST:$endpointUrl:$accessToken:$hexBody:$timestamp';
      final signature = _hmacSha512(_clientSecret!, stringToSign);

      final uri = Uri.parse('$_baseUrl$endpointUrl');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-PARTNER-ID': _clientId!,
          'X-EXTERNAL-ID': externalId,
          'X-TIMESTAMP': timestamp,
          'X-SIGNATURE': signature,
          'Authorization': 'Bearer $accessToken',
          'CHANNEL-ID': 'H2H',
        },
        body: requestBody,
      );

      if (response.statusCode != 200) {
        return Result.failure(error: 'Doku refund error (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;

      return Result.success(
        data: DokuRefundResponse(
          responseCode: json['responseCode'] as String? ?? '',
          responseMessage: json['responseMessage'] as String? ?? '',
          originalReferenceNo: json['originalReferenceNo'] as String? ?? '',
          originalPartnerReferenceNo: json['originalPartnerReferenceNo'] as String? ?? '',
          refundNo: json['refundNo'] as String? ?? '',
          partnerRefundNo: json['partnerRefundNo'] as String? ?? '',
          refundAmount: (json['refundAmount'] as Map<String, dynamic>?)?['value'] as String? ?? '',
          currency: (json['refundAmount'] as Map<String, dynamic>?)?['currency'] as String? ?? 'IDR',
          refundTime: json['refundTime'] as String? ?? '',
        ),
      );
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<DokuDecodeResponse>> decodeQris({
    required String partnerReferenceNo,
    required String qrContent,
    required String scanTime,
  }) async {
    if (isMockMode) {
      return _mockDecodeQris(partnerReferenceNo, qrContent);
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return Result.failure(error: 'Gagal mendapatkan access token Doku');
      }

      final timestamp = DateTime.now().toUtc().toIso8601String();
      final externalId = '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(99999)}';

      final body = {
        'partnerReferenceNo': partnerReferenceNo,
        'qrContent': qrContent,
        'scanTime': scanTime,
      };

      final requestBody = jsonEncode(body);
      final endpointUrl = '/snap-adapter/b2b/v1.0/qr/qr-mpm-decode';
      final hexBody = _sha256Hex(requestBody);
      final stringToSign = 'POST:$endpointUrl:$accessToken:$hexBody:$timestamp';
      final signature = _hmacSha512(_clientSecret!, stringToSign);

      final uri = Uri.parse('$_baseUrl$endpointUrl');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-PARTNER-ID': _clientId!,
          'X-EXTERNAL-ID': externalId,
          'X-TIMESTAMP': timestamp,
          'X-SIGNATURE': signature,
          'Authorization': 'Bearer $accessToken',
          'CHANNEL-ID': 'H2H',
        },
        body: requestBody,
      );

      if (response.statusCode != 200) {
        return Result.failure(error: 'Doku decode error (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final merchantInfos = (json['merchantInfos'] as List<dynamic>?) ?? [];
      final merchantInfo = merchantInfos.isNotEmpty ? merchantInfos[0] as Map<String, dynamic> : null;
      final additionalInfo = json['additionalInfo'] as Map<String, dynamic>?;

      return Result.success(
        data: DokuDecodeResponse(
          responseCode: json['responseCode'] as String? ?? '',
          responseMessage: json['responseMessage'] as String? ?? '',
          referenceNo: json['referenceNo'] as String? ?? '',
          partnerReferenceNo: json['partnerReferenceNo'] as String? ?? '',
          merchantName: json['merchantName'] as String? ?? '',
          transactionAmount: (json['transactionAmount'] as Map<String, dynamic>?)?['value'] as String? ?? '',
          currency: (json['transactionAmount'] as Map<String, dynamic>?)?['currency'] as String? ?? 'IDR',
          merchantPan: merchantInfo?['merchantPAN'] as String? ?? '',
          acquirerName: merchantInfo?['acquirerName'] as String? ?? '',
          postalCode: json['postalCode'] as String? ?? '',
          feeAmount: (json['feeAmount'] as Map<String, dynamic>?)?['value'] as String? ?? '',
          pointOfInitiationMethod: additionalInfo?['pointOfInitiationMethod'] as String? ?? '',
          feeType: additionalInfo?['feeType'] as String? ?? '',
        ),
      );
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  Future<Result<DokuPaymentResponse>> paymentQris({
    required String partnerReferenceNo,
    required int amount,
    required String qrContent,
    required String authorizationCustomer,
    int? feeAmount,
  }) async {
    if (isMockMode) {
      return _mockPaymentQris(partnerReferenceNo, amount);
    }

    try {
      final accessToken = await _getAccessToken();
      if (accessToken == null) {
        return Result.failure(error: 'Gagal mendapatkan access token Doku');
      }

      final timestamp = DateTime.now().toUtc().toIso8601String();
      final externalId = '${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(99999)}';

      final body = {
        'partnerReferenceNo': partnerReferenceNo,
        'amount': {
          'value': '$amount.00',
          'currency': 'IDR',
        },
        if (feeAmount != null)
          'feeAmount': {
            'value': '$feeAmount.00',
            'currency': 'IDR',
          },
        'additionalInfo': {
          'qrContent': qrContent,
        },
      };

      final requestBody = jsonEncode(body);
      final endpointUrl = '/snap-adapter/b2b2c/v1.0/qr/qr-mpm-payment';
      final hexBody = _sha256Hex(requestBody);
      final stringToSign = 'POST:$endpointUrl:$accessToken:$hexBody:$timestamp';
      final signature = _hmacSha512(_clientSecret!, stringToSign);

      final uri = Uri.parse('$_baseUrl$endpointUrl');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-PARTNER-ID': _clientId!,
          'X-EXTERNAL-ID': externalId,
          'X-TIMESTAMP': timestamp,
          'X-SIGNATURE': signature,
          'Authorization': 'Bearer $accessToken',
          'Authorization-Customer': 'Bearer $authorizationCustomer',
          'CHANNEL-ID': 'H2H',
        },
        body: requestBody,
      );

      if (response.statusCode != 200) {
        return Result.failure(error: 'Doku payment error (${response.statusCode}): ${response.body}');
      }

      final json = jsonDecode(response.body) as Map<String, dynamic>;
      final additionalInfo = json['additionalInfo'] as Map<String, dynamic>?;

      return Result.success(
        data: DokuPaymentResponse(
          responseCode: json['responseCode'] as String? ?? '',
          responseMessage: json['responseMessage'] as String? ?? '',
          referenceNo: json['referenceNo'] as String? ?? '',
          partnerReferenceNo: json['partnerReferenceNo'] as String? ?? '',
          amount: (json['amount'] as Map<String, dynamic>?)?['value'] as String? ?? '',
          currency: (json['amount'] as Map<String, dynamic>?)?['currency'] as String? ?? 'IDR',
          feeAmount: (json['feeAmount'] as Map<String, dynamic>?)?['value'] as String? ?? '',
          approvalCode: additionalInfo?['approvalCode'] as String? ?? '',
        ),
      );
    } catch (e) {
      return Result.failure(error: e.toString());
    }
  }

  // Crypto helpers

  String _hmacSha512(String key, String data) {
    final hmac = Hmac(sha512, utf8.encode(key));
    final digest = hmac.convert(utf8.encode(data));
    return base64.encode(digest.bytes);
  }

  String _sha256Hex(String data) {
    final bytes = utf8.encode(data);
    return sha256.convert(bytes).toString();
  }

  String _rsaSign(String data, String privateKeyPem) {
    final key = _parseRsaPrivateKey(privateKeyPem);

    final signer = RSASigner(SHA256Digest(), '0609608648016503040201');
    signer.init(true, PrivateKeyParameter<RSAPrivateKey>(key));
    final signature = signer.generateSignature(utf8.encode(data));

    return base64.encode(signature.bytes);
  }

  RSAPrivateKey _parseRsaPrivateKey(String pem) {
    final bytes = ASN1Utils.getBytesFromPEMString(pem);
    final parser = ASN1Parser(bytes);
    final top = parser.nextObject();

    ASN1Sequence keySeq;

    if (top is ASN1Sequence && top.elements!.length == 4) {
      // PKCS#8: outer SEQUENCE (version, algo, privateKey octets, [attributes])
      final innerOctet = top.elements!.elementAt(2) as ASN1OctetString;
      final innerParser = ASN1Parser(innerOctet.valueBytes!);
      keySeq = innerParser.nextObject() as ASN1Sequence;
    } else if (top is ASN1Sequence && top.elements!.length >= 9) {
      // PKCS#1: direct SEQUENCE of integers
      keySeq = top;
    } else {
      throw ArgumentError('Unsupported RSA private key format');
    }

    final n = (keySeq.elements![1] as ASN1Integer).integer!;
    final d = (keySeq.elements![3] as ASN1Integer).integer!;
    final p = (keySeq.elements![4] as ASN1Integer).integer!;
    final q = (keySeq.elements![5] as ASN1Integer).integer!;

    return RSAPrivateKey(n, d, p, q);
  }

  String _generateValidityPeriod() {
    final expiry = DateTime.now().toUtc().add(const Duration(hours: 1));
    return expiry.toIso8601String();
  }

  // Mock implementation

  final Map<String, _MockQrisState> _mockStates = {};

  Result<DokuQrisResponse> _mockGenerateQris(String orderId, int grossAmount) {
    final qrData = 'QRIS-DOKU-MOCK-$orderId-${Random().nextInt(99999)}';
    final now = DateTime.now();

    _mockStates[orderId] = _MockQrisState(
      status: 'pending',
      createdAt: DateTime.now(),
    );

    cl('[DokuMock] Generated QRIS for $orderId: amount=$grossAmount');

    return Result.success(
      data: DokuQrisResponse(
        qrContent: qrData,
        partnerReferenceNo: orderId,
        referenceNo: 'MOCK-REF-${now.millisecondsSinceEpoch}',
        terminalId: 'MOCK-TERMINAL',
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
      cl('[DokuMock] Payment completed for $orderId');
      return Result.success(data: 'paid');
    }

    return Result.success(data: 'pending');
  }

  void _mockCancelQris(String orderId) {
    _mockStates.remove(orderId);
    cl('[DokuMock] Cancelled QRIS for $orderId');
  }

  Result<DokuRefundResponse> _mockRefundQris(
    String originalReferenceNo,
    String partnerRefundNo,
    int refundAmount,
  ) {
    cl('[DokuMock] Refund QRIS for $originalReferenceNo: amount=$refundAmount');
    return Result.success(
      data: DokuRefundResponse(
        responseCode: '2002800',
        responseMessage: 'Successful',
        originalReferenceNo: originalReferenceNo,
        originalPartnerReferenceNo: 'MOCK-ORIGINAL-PARTNER-REF',
        refundNo: 'MOCK-REFUND-${DateTime.now().millisecondsSinceEpoch}',
        partnerRefundNo: partnerRefundNo,
        refundAmount: '$refundAmount.00',
        currency: 'IDR',
        refundTime: DateTime.now().toUtc().toIso8601String(),
      ),
    );
  }

  Result<DokuDecodeResponse> _mockDecodeQris(String partnerReferenceNo, String qrContent) {
    cl('[DokuMock] Decode QRIS for $partnerReferenceNo');
    return Result.success(
      data: DokuDecodeResponse(
        responseCode: '2002500',
        responseMessage: 'Successful',
        referenceNo: 'MOCK-REF-${DateTime.now().millisecondsSinceEpoch}',
        partnerReferenceNo: partnerReferenceNo,
        merchantName: 'Mock Merchant',
        transactionAmount: '0.00',
        currency: 'IDR',
        merchantPan: '9360012345678901234',
        acquirerName: 'Mock Acquirer',
        postalCode: '12345',
        feeAmount: '0.00',
        pointOfInitiationMethod: '11',
        feeType: '1',
      ),
    );
  }

  Result<DokuPaymentResponse> _mockPaymentQris(String partnerReferenceNo, int amount) {
    cl('[DokuMock] Payment QRIS for $partnerReferenceNo: amount=$amount');
    return Result.success(
      data: DokuPaymentResponse(
        responseCode: '2002400',
        responseMessage: 'Successful',
        referenceNo: 'MOCK-REF-${DateTime.now().millisecondsSinceEpoch}',
        partnerReferenceNo: partnerReferenceNo,
        amount: '$amount.00',
        currency: 'IDR',
        feeAmount: '0.00',
        approvalCode: 'MOCK-APPROVAL-${DateTime.now().millisecondsSinceEpoch}',
      ),
    );
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
