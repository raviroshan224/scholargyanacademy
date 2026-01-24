import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:state_notifier/state_notifier.dart';
// Some files in this repo rely on the legacy provider symbols. Import legacy
// to ensure `StateNotifierProvider` is available for older provider signatures.
import 'package:flutter_riverpod/legacy.dart' as riverpod_legacy;
import 'package:permission_handler/permission_handler.dart';

import '../model/live_class_models.dart';
import '../service/live_class_service.dart';

enum LiveClassJoinStatus {
  idle,
  fetchingToken,
  requestingPermissions,
  joining,
  waitingForHost,
  joined,
  failure,
}

class LiveClassJoinState {
  final LiveClassJoinStatus status;
  final String? errorMessage;
  final LiveClassJoinToken? token;
  final String? processingClassId;
  final bool hasJoinedOnce;

  const LiveClassJoinState({
    this.status = LiveClassJoinStatus.idle,
    this.errorMessage,
    this.token,
    this.processingClassId,
    this.hasJoinedOnce = false,
  });

  bool get isLoading =>
      status == LiveClassJoinStatus.fetchingToken ||
      status == LiveClassJoinStatus.requestingPermissions ||
      status == LiveClassJoinStatus.joining;

  bool get isWaitingForHost => status == LiveClassJoinStatus.waitingForHost;

  bool get isInMeeting =>
      status == LiveClassJoinStatus.joined ||
      status == LiveClassJoinStatus.waitingForHost;

  bool isProcessingClass(String classId) =>
      processingClassId == classId && (isLoading || isInMeeting);

  LiveClassJoinState copyWith({
    LiveClassJoinStatus? status,
    String? errorMessage,
    bool clearError = false,
    LiveClassJoinToken? token,
    bool clearToken = false,
    String? processingClassId,
    bool clearProcessingClass = false,
    bool? hasJoinedOnce,
  }) {
    return LiveClassJoinState(
      status: status ?? this.status,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      token: clearToken ? null : (token ?? this.token),
      processingClassId: clearProcessingClass
          ? null
          : (processingClassId ?? this.processingClassId),
      hasJoinedOnce: hasJoinedOnce ?? this.hasJoinedOnce,
    );
  }

  static LiveClassJoinState initial() => const LiveClassJoinState();
}

class LiveClassJoinViewModel extends StateNotifier<LiveClassJoinState> {
  LiveClassJoinViewModel(this._service)
      : super(LiveClassJoinState.initial());
  final LiveClassService _service;

  bool _isJoining = false;
  DateTime? _lastJoinAttempt;
  static const _joinDebounceMs = 1000;

  Future<void> joinLiveClass(String classId) async {
    // Feature disabled - showing alert instead of joining
    _setFailure("Live classes are currently unavailable in this version.");
    return;
  }

  void markAsJoined({bool waitingForHost = false}) {
     // No-op
  }

  Future<bool> _requestPermissions() async {
    try {
      final statuses = await [
        Permission.camera,
        Permission.microphone,
      ].request();

      final cameraGranted = statuses[Permission.camera]?.isGranted ?? false;
      final micGranted = statuses[Permission.microphone]?.isGranted ?? false;

      return cameraGranted && micGranted;
    } catch (e) {
      return false;
    }
  }

  Future<void> openAppSettingsRequest() async {
    try {
      await openAppSettings();
    } catch (_) {
    }
  }

  Future<void> leaveMeeting() async {
    reset();
  }

  void reset() {
    state = LiveClassJoinState.initial();
  }

  void _setFailure(String message) {
    state = state.copyWith(
      status: LiveClassJoinStatus.failure,
      errorMessage: message,
      clearProcessingClass: true,
      clearToken: true,
    );
  }
}

final liveClassJoinViewModelProvider = riverpod_legacy.StateNotifierProvider<
    LiveClassJoinViewModel, LiveClassJoinState>((ref) {
  final service = ref.read(liveClassServiceProvider);
  return LiveClassJoinViewModel(service);
});
