import 'package:flutter/foundation.dart';

import '../connectivity/ping_service.dart';

enum SyncMode { auto, online, offline }

class SyncService extends ChangeNotifier {
  final PingService _pingService;
  SyncMode _mode = SyncMode.auto;
  bool _forcedOffline = false;

  SyncService(this._pingService);

  SyncMode get mode => _mode;
  bool get forcedOffline => _forcedOffline;

  bool get isOnline {
    if (_forcedOffline) return false;
    if (_mode == SyncMode.offline) return false;
    if (_mode == SyncMode.online) return true;
    return _pingService.isConnected;
  }

  void setMode(SyncMode mode) {
    _mode = mode;
    _forcedOffline = mode == SyncMode.offline;
    notifyListeners();
  }

  void toggleMode() {
    switch (_mode) {
      case SyncMode.auto:
        setMode(SyncMode.offline);
      case SyncMode.offline:
        setMode(SyncMode.online);
      case SyncMode.online:
        setMode(SyncMode.auto);
    }
  }
}
