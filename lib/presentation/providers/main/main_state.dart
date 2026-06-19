import '../../../core/services/sync/sync_service.dart';
import '../../../domain/entities/user_entity.dart';

class MainState {
  final bool isLoaded;
  final bool isHasInternet;
  final bool isHasQueuedActions;
  final bool isSyncronizing;
  final SyncMode syncMode;
  final UserEntity? user;

  const MainState({
    this.isLoaded = false,
    this.isHasInternet = true,
    this.isHasQueuedActions = false,
    this.isSyncronizing = false,
    this.syncMode = SyncMode.auto,
    this.user,
  });

  MainState copyWith({
    bool? isLoaded,
    bool? isHasInternet,
    bool? isHasQueuedActions,
    bool? isSyncronizing,
    SyncMode? syncMode,
    UserEntity? user,
  }) {
    return MainState(
      isLoaded: isLoaded ?? this.isLoaded,
      isHasInternet: isHasInternet ?? this.isHasInternet,
      isHasQueuedActions: isHasQueuedActions ?? this.isHasQueuedActions,
      isSyncronizing: isSyncronizing ?? this.isSyncronizing,
      syncMode: syncMode ?? this.syncMode,
      user: user ?? this.user,
    );
  }
}
