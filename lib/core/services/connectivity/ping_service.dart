import 'dart:async';
import 'dart:io';

import '../../utilities/console_logger.dart';

class PingService {
  Timer? _timer;
  bool _connected = false;
  bool _previousStatus = false;

  final List<Function(bool isConnected)> _connectionStatusListeners = [];
  final List<Function(List<int> latencies, List<String> lines)> _listeners = [];

  bool get isConnected => _connected;

  Future<void> startPing({
    String host = 'https://ntonhgleedhzhkcapdvk.supabase.co',
    int interval = 10,
  }) async {
    if (_timer != null) return;

    _check(host);
    _timer = Timer.periodic(Duration(seconds: interval), (_) => _check(host));
  }

  Future<void> _check(String url) async {
    try {
      final client = HttpClient()..connectionTimeout = const Duration(seconds: 5);
      final request = await client.getUrl(Uri.parse('$url/rest/v1/'));
      request.headers.set('Accept', 'application/json');
      final response = await request.close();
      _connected = response.statusCode == 200 || response.statusCode == 401;
      client.close();
    } catch (_) {
      _connected = false;
    }

    if (_previousStatus != _connected) {
      _previousStatus = _connected;
      cl('Supabase connected: $_connected');
      for (final listener in _connectionStatusListeners) {
        listener(_connected);
      }
    }

    _notifyListeners();
  }

  void addListener(Function(List<int> latencies, List<String> lines) listener) {
    if (_listeners.contains(listener)) return;
    _listeners.add(listener);
  }

  void removeListener(Function(List<int> latencies, List<String> lines) listener) {
    _listeners.remove(listener);
  }

  void clearListeners() {
    _listeners.clear();
  }

  void _notifyListeners() {
    for (final listener in _listeners) {
      listener([], []);
    }
  }

  void addConnectionStatusListener(Function(bool isConnected) listener) {
    if (_connectionStatusListeners.contains(listener)) return;
    _connectionStatusListeners.add(listener);
    listener(_connected);
  }

  void removeConnectionStatusListener(Function(bool isConnected) listener) {
    _connectionStatusListeners.remove(listener);
  }

  void clearConnectionStatusListeners() {
    _connectionStatusListeners.clear();
  }

  void stopPing() {
    _timer?.cancel();
    _timer = null;
  }

  void dispose() {
    stopPing();
    clearListeners();
    clearConnectionStatusListeners();
    _previousStatus = false;
    _connected = false;
  }
}
