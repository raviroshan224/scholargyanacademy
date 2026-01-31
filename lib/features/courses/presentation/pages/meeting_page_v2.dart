import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_videosdk/flutter_zoom_view.dart' as zoom_view;
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_chat_message.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_event_listener.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';

import '../../../../core/services/zoom_service.dart';
import '../../model/live_class_models.dart';
import '../../view_model/live_class_join_view_model.dart';
import 'meeting/models/meeting_state.dart';

class MeetingPageV2 extends ConsumerStatefulWidget {
  const MeetingPageV2({
    super.key,
    required this.token,
    required this.classId,
  });

  final LiveClassJoinToken token;
  final String classId;

  @override
  ConsumerState<MeetingPageV2> createState() => _MeetingPageV2State();
}

class _MeetingPageV2State extends ConsumerState<MeetingPageV2>
    with WidgetsBindingObserver {
  final ZoomVideoSdk _zoom = ZoomVideoSdk();
  final ZoomVideoSdkEventListener _eventListener = ZoomVideoSdkEventListener();

  final List<StreamSubscription> _subscriptions = [];
  late final ZoomService _zoomService;

  MeetingState _meetingState = const MeetingState();

  final Map<String, String> _userNameMap = {};
  final Set<String> _receivedChatMessageIds = <String>{};

  final TextEditingController _chatController = TextEditingController();
  final ScrollController _chatScrollController = ScrollController();

  Timer? _activeSpeakerDebounce;
  Timer? _shareReconcileDebounce;

  bool _isLoading = true;
  bool _isJoining = true;
  String? _errorMessage;

  // Share state used by UI renderer
  int? _activeShareSourceId;
  String? _activeShareUserId;
  int? _lastGoodShareSourceId;

  // Share UX guards
  bool _isShareToggling = false;
  bool _shareStarting = false;
  bool _shareStopping = false;
  DateTime? _shareRequestAt;

  void _safeSetState(VoidCallback fn) {
    if (!mounted) return;
    try {
      setState(fn);
    } catch (e) {
      debugPrint('[MeetingV2] safeSetState error: $e');
    }
  }

  String _getDisplayName(ZoomVideoSdkUser? user) {
    if (user == null) return 'Unknown';
    final id = user.userId;
    if (id != null && _userNameMap.containsKey(id)) return _userNameMap[id]!;
    final zoomName = user.userName ?? '';
    if (zoomName.isNotEmpty && zoomName.toLowerCase() != 'participant') {
      return zoomName;
    }
    return 'Participant';
  }

  ZoomVideoSdkUser? _findUserInParticipants(String? userId) {
    if (userId == null) return null;
    try {
      return _meetingState.participants.firstWhere((u) => u.userId == userId);
    } catch (_) {
      return null;
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _zoomService = ref.read(zoomServiceProvider);

    debugPrint('[MeetingV2] initState');
    _setupEventListeners();
    _joinZoomSession();
  }

  @override
  void dispose() {
    debugPrint('[MeetingV2] dispose');

    _activeSpeakerDebounce?.cancel();
    _shareReconcileDebounce?.cancel();

    _chatController.dispose();
    _chatScrollController.dispose();

    for (final sub in _subscriptions) {
      try {
        sub.cancel();
      } catch (_) {}
    }
    _subscriptions.clear();

    _receivedChatMessageIds.clear();

    try {
      _zoomService.leaveMeeting();
    } catch (e) {
      debugPrint('[MeetingV2] leaveMeeting error: $e');
    }

    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    debugPrint('[MeetingV2] lifecycle=$state');

    // IMPORTANT:
    // Do not reconcile on inactive, it happens during MediaProjection picker on Android.
    if (state == AppLifecycleState.resumed) {
      Future.delayed(const Duration(milliseconds: 600), () async {
        await _refreshMeetingState();
        await _reconcileShareState(reason: 'resume');
      });
    }
  }

  // ========== LISTENERS ==========

  void _setupEventListeners() {
    debugPrint('[MeetingV2] setupEventListeners');

    _subscriptions.addAll([
      _eventListener.addListener(EventType.onSessionJoin, _handleSessionJoin),
      _eventListener.addListener(EventType.onSessionLeave, _handleSessionLeave),
      _eventListener.addListener(EventType.onUserJoin, _handleUserJoin),
      _eventListener.addListener(EventType.onUserLeave, _handleUserLeave),
      _eventListener.addListener(
          EventType.onUserVideoStatusChanged, _handleVideoChange),
      _eventListener.addListener(
          EventType.onUserAudioStatusChanged, _handleAudioChange),
      _eventListener.addListener(
          EventType.onUserActiveAudioChanged, _handleActiveSpeaker),
      _eventListener.addListener(
          EventType.onChatNewMessageNotify, _handleChatMessage),
      _eventListener.addListener(
          EventType.onUserShareStatusChanged, _handleUserShareStatusChanged),
      _eventListener.addListener(EventType.onError, _handleError),
    ]);

    debugPrint('[MeetingV2] listeners=${_subscriptions.length}');
  }

  void _handleSessionJoin(dynamic data) async {
    debugPrint('[MeetingV2] onSessionJoin');
    await _initializeMeetingState();
    await _reconcileShareState(reason: 'onSessionJoin');
  }

  void _handleSessionLeave(dynamic data) {
    debugPrint('[MeetingV2] onSessionLeave');
    if (mounted) Navigator.pop(context);
  }

  void _handleError(dynamic data) {
    debugPrint('[MeetingV2] onError: $data');
    final errorType =
        (data is Map) ? data['errorType']?.toString() : data.toString();
    _showSnackbar(errorType ?? 'Unknown error', isError: true);
  }

  void _handleUserJoin(dynamic data) async {
    debugPrint('[MeetingV2] onUserJoin: $data');

    await _refreshMeetingState();
    await _reconcileShareState(reason: 'onUserJoin');

    // fill name map
    final remoteUsers = await _zoom.session.getRemoteUsers() ?? [];
    for (final user in remoteUsers) {
      final id = user.userId;
      final name = user.userName ?? '';
      if (id != null &&
          name.isNotEmpty &&
          name.toLowerCase() != 'participant' &&
          !_userNameMap.containsKey(id)) {
        _userNameMap[id] = name;
      }
    }
  }

  void _handleUserLeave(dynamic data) async {
    debugPrint('[MeetingV2] onUserLeave: $data');

    await _refreshMeetingState();
    await _reconcileShareState(reason: 'onUserLeave');

    if (!mounted) return;

    _safeSetState(() {
      // clear pin if pinned user left
      if (_meetingState.pinnedUser != null) {
        final stillPresent = _meetingState.participants
            .any((u) => u.userId == _meetingState.pinnedUser?.userId);
        if (!stillPresent) {
          _meetingState = _meetingState.copyWith(clearPinned: true);
        }
      }

      // clear share if sharing user left
      if (_activeShareUserId != null) {
        final shareStillPresent = _meetingState.participants
            .any((u) => u.userId == _activeShareUserId);
        if (!shareStillPresent) {
          _activeShareSourceId = null;
          _activeShareUserId = null;
          _lastGoodShareSourceId = null;
          _meetingState =
              _meetingState.copyWith(clearSharing: true, clearStatus: true);
        }
      }
    });
  }

  void _handleVideoChange(dynamic data) {
    debugPrint('[MeetingV2] onUserVideoStatusChanged');
    if (mounted) setState(() {});
  }

  void _handleAudioChange(dynamic data) async {
    debugPrint('[MeetingV2] onUserAudioStatusChanged');
    final mySelf = await _zoom.session.getMySelf();
    if (mySelf != null) {
      final isMuted = await mySelf.audioStatus?.isMuted() ?? false;
      _safeSetState(() {
        _meetingState = _meetingState.copyWith(isMuted: isMuted);
      });
    }
  }

  void _handleActiveSpeaker(dynamic data) {
    _activeSpeakerDebounce?.cancel();
    _activeSpeakerDebounce = Timer(const Duration(milliseconds: 450), () {
      try {
        final raw = (data is Map) ? data['changedUsers'] : null;
        List<dynamic> users = [];

        if (raw is String) {
          final decoded = jsonDecode(raw);
          if (decoded is List) users = decoded;
        } else if (raw is List) {
          users = raw;
        }

        if (users.isEmpty) return;

        final first = users.first;
        String? userId;
        if (first is Map) userId = first['userId']?.toString();
        if (userId == null) return;

        final activeUser = _meetingState.participants.firstWhere(
          (u) => u.userId == userId,
          orElse: () => _meetingState.participants.first,
        );

        _safeSetState(() {
          _meetingState = _meetingState.copyWith(activeUser: activeUser);
        });
      } catch (e) {
        debugPrint('[MeetingV2] active speaker parse error: $e');
      }
    });
  }

  void _handleChatMessage(dynamic data) {
    try {
      Map<String, dynamic> messageJson;

      if (data is Map) {
        final rawMessage = data['message'];
        if (rawMessage is String) {
          messageJson = Map<String, dynamic>.from(jsonDecode(rawMessage));
        } else if (rawMessage is Map) {
          messageJson = Map<String, dynamic>.from(rawMessage);
        } else {
          return;
        }
      } else {
        return;
      }

      final model = ZoomVideoSdkChatMessage.fromJson(messageJson);

      final isSelf = model.isSelfSend ?? false;
      if (isSelf) return;

      final messageId = messageJson['messageID']?.toString();
      if (messageId == null || messageId.isEmpty) return;

      if (_receivedChatMessageIds.contains(messageId)) return;
      _receivedChatMessageIds.add(messageId);

      String senderId = '';
      String senderName = 'Unknown';

      final rawSender = messageJson['senderUser'];
      if (rawSender is String) {
        final senderMap = Map<String, dynamic>.from(jsonDecode(rawSender));
        senderId = senderMap['userId']?.toString() ?? '';
        senderName = senderMap['userName']?.toString() ?? 'Unknown';

        if (senderId.isNotEmpty && senderName.isNotEmpty) {
          _userNameMap[senderId] = senderName;
        }
      }

      final content = model.content;
      if (content.isEmpty) return;

      final chatMessage = ChatMessage(
        senderId: senderId,
        senderName: _userNameMap[senderId] ?? senderName,
        message: content,
        timestamp: DateTime.now(),
        isSentByMe: false,
      );

      _safeSetState(() {
        _meetingState = _meetingState.copyWith(
          messages: [..._meetingState.messages, chatMessage],
          unreadCount:
              _meetingState.showChat ? 0 : _meetingState.unreadCount + 1,
        );
      });

      if (_meetingState.showChat) {
        Future.delayed(const Duration(milliseconds: 80), () {
          if (_chatScrollController.hasClients) {
            _chatScrollController.animateTo(
              _chatScrollController.position.maxScrollExtent,
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOut,
            );
          }
        });
      }
    } catch (e, st) {
      debugPrint('[MeetingV2] chat parse error: $e');
      debugPrint(st.toString());
    }
  }

  // ========== SHARE HANDLING (FIXED) ==========

  void _handleUserShareStatusChanged(dynamic data) async {
    debugPrint('[MeetingV2] onUserShareStatusChanged raw: $data');

    try {
      Map<String, dynamic> root;
      if (data is Map) {
        root = Map<String, dynamic>.from(data);
      } else if (data is String) {
        root = Map<String, dynamic>.from(jsonDecode(data));
      } else {
        return;
      }

      final rawUser = root['user'];
      final rawAction = root['shareAction'];

      Map<String, dynamic> userMap = {};
      Map<String, dynamic> actionMap = {};

      if (rawUser is String)
        userMap = Map<String, dynamic>.from(jsonDecode(rawUser));
      if (rawUser is Map) userMap = Map<String, dynamic>.from(rawUser);

      if (rawAction is String)
        actionMap = Map<String, dynamic>.from(jsonDecode(rawAction));
      if (rawAction is Map) actionMap = Map<String, dynamic>.from(rawAction);

      final sharingUserId = userMap['userId']?.toString();
      final shareStatus = actionMap['shareStatus']?.toString() ?? '';

      final shareSourceRaw = actionMap['shareSourceId'];
      final shareSourceId = int.tryParse(shareSourceRaw?.toString() ?? '');

      final isStart = shareStatus.contains('Start') ||
          shareStatus.toLowerCase().contains('start');
      final isStop = shareStatus.contains('Stop') ||
          shareStatus.toLowerCase().contains('stop');

      // IMPORTANT FIX:
      // Do NOT let reconcile instantly clear start state.
      // Keep state until STOP event or SDK confirms no share.
      if (isStart && shareSourceId != null && sharingUserId != null) {
        // Use participant instance if available (more reliable than fromJson)
        final participantUser = _findUserInParticipants(sharingUserId) ??
            ZoomVideoSdkUser.fromJson(userMap);

        _safeSetState(() {
          _activeShareSourceId = shareSourceId;
          _activeShareUserId = sharingUserId;
          _lastGoodShareSourceId = shareSourceId;

          _meetingState = _meetingState.copyWith(
            sharingUser: participantUser,
            statusMessage:
                '${_getDisplayName(participantUser)} is sharing screen',
          );
        });

        _shareStarting = false;
        _shareStopping = false;
        _shareRequestAt = null;

        debugPrint(
            '[MeetingV2] SHARE START user=$sharingUserId source=$shareSourceId');

        // Reconcile, but it will NOT clear while SDK says someone is sharing
        await _reconcileShareState(reason: 'shareStartEvent');
        return;
      }

      if (isStop) {
        _safeSetState(() {
          _activeShareSourceId = null;
          _activeShareUserId = null;
          _lastGoodShareSourceId = null;
          _meetingState =
              _meetingState.copyWith(clearSharing: true, clearStatus: true);
        });

        _shareStarting = false;
        _shareStopping = false;
        _shareRequestAt = null;

        debugPrint('[MeetingV2] SHARE STOP');
        await _reconcileShareState(reason: 'shareStopEvent');
        return;
      }

      // For any other status, just reconcile without clearing aggressively
      await _reconcileShareState(reason: 'shareOtherStatus');
    } catch (e, st) {
      debugPrint('[MeetingV2] share parse error: $e');
      debugPrint(st.toString());
    }
  }

  Future<void> _reconcileShareState({required String reason}) async {
    _shareReconcileDebounce?.cancel();
    _shareReconcileDebounce =
        Timer(const Duration(milliseconds: 250), () async {
      try {
        // SDK truth
        final otherSharing = await _zoom.shareHelper.isOtherSharing();
        final iAmSharing = await _zoom.shareHelper.isSharingOut();
        final anySharing = otherSharing || iAmSharing;

        debugPrint(
            '[MeetingV2] reconcile($reason): anySharing=$anySharing, other=$otherSharing, me=$iAmSharing');

        if (!mounted) return;

        // If SDK says nobody is sharing, then clear.
        if (!anySharing) {
          if (_activeShareSourceId != null ||
              _meetingState.sharingUser != null) {
            _safeSetState(() {
              _activeShareSourceId = null;
              _activeShareUserId = null;
              _lastGoodShareSourceId = null;
              _meetingState =
                  _meetingState.copyWith(clearSharing: true, clearStatus: true);
            });
            debugPrint(
                '[MeetingV2] reconcile($reason): cleared share (SDK says none)');
          }
          return;
        }

        // Someone is sharing. Do NOT clear state.
        // If we already have the share info, keep it.
        if ((_activeShareSourceId ?? _lastGoodShareSourceId) != null &&
            _meetingState.sharingUser != null) {
          return;
        }

        // Try to restore sharingUser using cached userId
        ZoomVideoSdkUser? restoredUser;
        if (_activeShareUserId != null) {
          restoredUser = _findUserInParticipants(_activeShareUserId);
        }

        // Fallback: scan participants (some platforms may set isSharing)
        restoredUser ??= _meetingState.participants
            .where((u) => u.isSharing == true)
            .cast<ZoomVideoSdkUser?>()
            .firstWhere((u) => u != null, orElse: () => null);

        if (restoredUser != null) {
          _safeSetState(() {
            _meetingState = _meetingState.copyWith(
              sharingUser: restoredUser,
              statusMessage:
                  '${_getDisplayName(restoredUser)} is sharing screen',
            );
          });
          debugPrint(
              '[MeetingV2] reconcile($reason): restored sharingUser=${restoredUser.userId}');
        }

        // If shareSourceId is missing but we had a last one, keep lastGood
        if (_activeShareSourceId == null && _lastGoodShareSourceId != null) {
          _safeSetState(() {
            _activeShareSourceId = _lastGoodShareSourceId;
          });
        }

        // If still no shareSourceId, we cannot render share view,
        // but we still must not clear because SDK says sharing exists.
      } catch (e) {
        debugPrint('[MeetingV2] reconcile($reason) error: $e');
      }
    });
  }

  // ========== JOIN FLOW ==========

  Future<void> _joinZoomSession() async {
    debugPrint('[MeetingV2] joinZoomSession');
    debugPrint(
      '[MeetingV2] userName="${widget.token.userName}" session="${widget.token.sessionName}"',
    );

    try {
      final joinNotifier = ref.read(liveClassJoinViewModelProvider.notifier);

      final joinResult = await _zoomService.joinMeeting(
        sdkJwtToken: widget.token.token,
        sessionName: widget.token.sessionName,
        userName: widget.token.userName,
      );

      if (!joinResult.success) {
        if (!mounted) return;
        _safeSetState(() {
          _isLoading = false;
          _isJoining = false;
          _errorMessage = joinResult.errorMessage ?? 'Failed to join';
        });

        try {
          joinNotifier.reset();
        } catch (_) {}

        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
        return;
      }

      try {
        joinNotifier.markAsJoined(waitingForHost: joinResult.isWaitingForHost);
      } catch (_) {}

      _safeSetState(() => _isJoining = false);

      await _initializeMeetingState();
      await _reconcileShareState(reason: 'postJoin');
    } catch (e, st) {
      debugPrint('[MeetingV2] join error: $e');
      debugPrint(st.toString());

      if (!mounted) return;

      _safeSetState(() {
        _isLoading = false;
        _isJoining = false;
        _errorMessage = 'Failed to join: $e';
      });

      try {
        ref.read(liveClassJoinViewModelProvider.notifier).reset();
      } catch (_) {}

      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> _initializeMeetingState() async {
    debugPrint('[MeetingV2] initializeMeetingState');

    try {
      final mySelf = await _zoom.session.getMySelf();
      final remoteUsers = await _zoom.session.getRemoteUsers() ?? [];

      if (mySelf == null) {
        _safeSetState(() => _isLoading = false);
        return;
      }

      if (mySelf.userId != null) {
        _userNameMap[mySelf.userId!] = widget.token.userName;
      }

      final allUsers = [mySelf, ...remoteUsers];

      final host = allUsers.firstWhere(
        (u) => u.isHost,
        orElse: () => allUsers.first,
      );

      final audioMuted = await mySelf.audioStatus?.isMuted() ?? false;
      final videoOn = await mySelf.videoStatus?.isOn() ?? true;

      _safeSetState(() {
        _meetingState = _meetingState.copyWith(
          participants: allUsers,
          hostUser: host,
          mySelf: mySelf,
          isMuted: audioMuted,
          isVideoOn: videoOn,
        );
        _isLoading = false;
      });
    } catch (e, st) {
      debugPrint('[MeetingV2] init error: $e');
      debugPrint(st.toString());
      _safeSetState(() => _isLoading = false);
    }
  }

  Future<void> _refreshMeetingState() async {
    try {
      final mySelf = await _zoom.session.getMySelf();
      if (mySelf == null) return;

      final remoteUsers = await _zoom.session.getRemoteUsers() ?? [];
      final allUsers = [mySelf, ...remoteUsers];

      _safeSetState(() {
        _meetingState = _meetingState.copyWith(
          participants: allUsers,
          mySelf: mySelf,
        );
      });
    } catch (e) {
      debugPrint('[MeetingV2] refresh error: $e');
    }
  }

  // ========== USER ACTIONS ==========

  Future<void> _toggleAudio() async {
    try {
      final mySelf = _meetingState.mySelf;
      if (mySelf?.audioStatus == null) return;

      final isMuted = await mySelf!.audioStatus!.isMuted();
      if (isMuted) {
        await _zoom.audioHelper.unMuteAudio(mySelf.userId);
      } else {
        await _zoom.audioHelper.muteAudio(mySelf.userId);
      }
    } catch (e) {
      debugPrint('[MeetingV2] toggle audio error: $e');
      _showSnackbar('Failed to toggle audio', isError: true);
    }
  }

  Future<void> _toggleVideo() async {
    try {
      final mySelf = _meetingState.mySelf;
      if (mySelf?.videoStatus == null) return;

      final isOn = await mySelf!.videoStatus!.isOn();
      if (isOn) {
        await _zoom.videoHelper.stopVideo();
      } else {
        await _zoom.videoHelper.startVideo();
      }

      _safeSetState(() {
        _meetingState = _meetingState.copyWith(isVideoOn: !isOn);
      });
    } catch (e) {
      debugPrint('[MeetingV2] toggle video error: $e');
      _showSnackbar('Failed to toggle video', isError: true);
    }
  }

  Future<void> _toggleScreenShare() async {
    if (_isShareToggling || _shareStarting || _shareStopping) return;
    _isShareToggling = true;

    try {
      // SDK truth
      final otherSharing = await _zoom.shareHelper.isOtherSharing();
      final iAmSharing = await _zoom.shareHelper.isSharingOut();

      // If someone else is sharing, block my share
      if (otherSharing && !iAmSharing) {
        _showSnackbar('Someone else is sharing right now', isError: false);
        return;
      }

      // STOP MY SHARE
      if (iAmSharing) {
        debugPrint('[MeetingV2] stopShare requested');
        _shareStopping = true;

        _safeSetState(() {
          _meetingState =
              _meetingState.copyWith(statusMessage: 'Stopping screen share...');
        });

        try {
          await _zoom.shareHelper.stopShare();
        } catch (e) {
          debugPrint('[MeetingV2] stopShare error: $e');
        }

        // Let event come, then reconcile
        await Future.delayed(const Duration(milliseconds: 450));
        await _reconcileShareState(reason: 'stopShareButton');

        _safeSetState(() {
          _shareStopping = false;
          _shareStarting = false;
          _shareRequestAt = null;
        });

        _showSnackbar('Stopped sharing', isError: false);
        return;
      }

      // START MY SHARE
      debugPrint('[MeetingV2] shareScreen requested');
      _shareStarting = true;
      _shareRequestAt = DateTime.now();

      _safeSetState(() {
        _meetingState =
            _meetingState.copyWith(statusMessage: 'Starting screen share...');
      });

      // This opens Android MediaProjection permission dialog automatically
      await _zoom.shareHelper.shareScreen();

      // Do not clear state during permission flow, your lifecycle handler already avoids reconcile on inactive
      await Future.delayed(const Duration(milliseconds: 900));
      await _reconcileShareState(reason: 'startShareButton');

      _showSnackbar('Screen share started', isError: false);
    } catch (e) {
      debugPrint('[MeetingV2] toggle share error: $e');

      _safeSetState(() {
        _shareStarting = false;
        _shareStopping = false;
        _shareRequestAt = null;
        _meetingState = _meetingState.copyWith(clearStatus: true);
      });

      _showSnackbar('Screen share failed: $e', isError: true);
    } finally {
      _isShareToggling = false;
    }
  }

  void _pinUser(ZoomVideoSdkUser user) {
    _safeSetState(() {
      _meetingState = _meetingState.copyWith(pinnedUser: user);
    });
    _showSnackbar('Pinned ${_getDisplayName(user)}');
  }

  void _unpinUser() {
    _safeSetState(() {
      _meetingState = _meetingState.copyWith(clearPinned: true);
    });
    _showSnackbar('Unpinned');
  }

  void _toggleChat() {
    _safeSetState(() {
      final newShowChat = !_meetingState.showChat;
      _meetingState = _meetingState.copyWith(
        showChat: newShowChat,
        unreadCount: newShowChat ? 0 : _meetingState.unreadCount,
      );
    });
  }

  Future<void> _sendChatMessage() async {
    final message = _chatController.text.trim();
    if (message.isEmpty) return;

    final myMessage = ChatMessage(
      senderId: _meetingState.mySelf?.userId ?? '',
      senderName: _getDisplayName(_meetingState.mySelf),
      message: message,
      timestamp: DateTime.now(),
      isSentByMe: true,
    );

    _safeSetState(() {
      final newMessages = List<ChatMessage>.from(_meetingState.messages)
        ..add(myMessage);
      _meetingState = _meetingState.copyWith(messages: newMessages);
    });

    Future.delayed(const Duration(milliseconds: 80), () {
      if (_chatScrollController.hasClients) {
        _chatScrollController.animateTo(
          _chatScrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });

    try {
      await _zoom.chatHelper.sendChatToAll(message);
      _chatController.clear();
    } catch (e) {
      debugPrint('[MeetingV2] send chat error: $e');

      _safeSetState(() {
        final messages = List<ChatMessage>.from(_meetingState.messages);
        messages.removeWhere((m) =>
            m.timestamp == myMessage.timestamp &&
            m.isSentByMe &&
            m.senderId == myMessage.senderId);
        _meetingState = _meetingState.copyWith(messages: messages);
      });

      _showSnackbar('Failed to send message', isError: true);
    }
  }

  Future<void> _leaveSession() async {
    try {
      await _zoom.leaveSession(false);
    } catch (e) {
      debugPrint('[MeetingV2] leave error: $e');
    }
    if (mounted) Navigator.pop(context);
  }

  void _showSnackbar(String message, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ========== UI ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Stack(
          children: [
            if (_errorMessage != null)
              _buildErrorState()
            else if (_isLoading || _isJoining)
              _buildLoadingState()
            else
              Column(
                children: [
                  Expanded(child: _buildPrimaryView()),
                  if (_meetingState.secondaryUsers.isNotEmpty)
                    _buildSecondaryStrip(),
                  const SizedBox(height: 80),
                ],
              ),
            if (_meetingState.statusMessage != null) _buildStatusBanner(),
            if (!_isLoading && !_isJoining) _buildParticipantCount(),
            if (!_isLoading && !_isJoining && _errorMessage == null)
              _buildControlBar(),
            if (_meetingState.showChat) _buildChatPanel(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 64),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            const Text(
              'Returning to class...',
              style: TextStyle(color: Colors.white70, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            _isJoining ? 'Joining meeting...' : 'Loading...',
            style: const TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  /// If share is active, show share stream as primary.
  Widget _buildPrimaryView() {
    final shareSourceId = _activeShareSourceId ?? _lastGoodShareSourceId;
    final sharingUser = _meetingState.sharingUser;

    // SHOW SHARE VIEW (fixed: state no longer gets cleared instantly)
    if (shareSourceId != null && sharingUser != null) {
      return GestureDetector(
        onTap: () {
          _safeSetState(() {
            _meetingState = _meetingState.copyWith(
              controlsVisible: !_meetingState.controlsVisible,
            );
          });
        },
        child: Container(
          color: Colors.black,
          child: Stack(
            fit: StackFit.expand,
            children: [
              zoom_view.View(
                key: ValueKey(
                    'share_primary_${sharingUser.userId}_$shareSourceId'),
                creationParams: {
                  // Keep your params, but add extra keys that are ignored if unsupported
                  "userId": sharingUser.userId,
                  "sharing": true,
                  "isSharing": true,
                  "shareSourceId": shareSourceId,
                  "shareSourceID": shareSourceId,
                  "videoAspect": VideoAspect.Original,
                  "fullScreen": false,
                },
              ),
              Positioned(
                top: 16,
                left: 16,
                right: 16,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.screen_share,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${_getDisplayName(sharingUser)} is sharing screen',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    // If user tapped share and permission sheet is ongoing, show a local banner
    if (_shareStarting) {
      return Container(
        color: Colors.black,
        child: const Center(
          child: Text(
            'Starting screen share...',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ),
      );
    }

    final primaryUser = _meetingState.primaryUser;

    if (primaryUser == null) {
      return const Center(
        child: Text(
          'Waiting for participants...',
          style: TextStyle(color: Colors.white70, fontSize: 16),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        _safeSetState(() {
          _meetingState = _meetingState.copyWith(
            controlsVisible: !_meetingState.controlsVisible,
          );
        });
      },
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            zoom_view.View(
              key: ValueKey('primary_${primaryUser.userId}'),
              creationParams: {
                "userId": primaryUser.userId,
                "videoAspect": VideoAspect.Original,
                "fullScreen": false,
              },
            ),
            Positioned(
              bottom: 16,
              left: 16,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (primaryUser.isHost)
                      Container(
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Text(
                      _getDisplayName(primaryUser),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (_meetingState.pinnedUser?.userId == primaryUser.userId)
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: Colors.amber,
                    shape: BoxShape.circle,
                  ),
                  child:
                      const Icon(Icons.push_pin, color: Colors.black, size: 20),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildSecondaryStrip() {
    return Container(
      height: 120,
      color: Colors.black87,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
        itemCount: _meetingState.secondaryUsers.length,
        itemBuilder: (context, index) {
          final user = _meetingState.secondaryUsers[index];
          return _buildSecondaryTile(user);
        },
      ),
    );
  }

  Widget _buildSecondaryTile(ZoomVideoSdkUser user) {
    final isPinned = _meetingState.pinnedUser?.userId == user.userId;

    return GestureDetector(
      onTap: () => _pinUser(user),
      onLongPress: () {
        if (isPinned) _unpinUser();
      },
      child: Container(
        width: 90,
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isPinned ? Colors.amber : Colors.transparent,
            width: 2,
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: zoom_view.View(
                key: ValueKey('secondary_${user.userId}'),
                creationParams: {
                  "userId": user.userId,
                  "videoAspect": VideoAspect.Original,
                  "fullScreen": false,
                },
              ),
            ),
            Positioned(
              bottom: 4,
              left: 4,
              right: 4,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getDisplayName(user),
                  style: const TextStyle(color: Colors.white, fontSize: 10),
                  overflow: TextOverflow.ellipsis,
                  maxLines: 1,
                ),
              ),
            ),
            if (isPinned)
              const Positioned(
                top: 4,
                right: 4,
                child: Icon(Icons.push_pin, color: Colors.amber, size: 16),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBanner() {
    return Positioned(
      top: 16,
      left: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.blue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          _meetingState.statusMessage!,
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildParticipantCount() {
    return Positioned(
      top: 16,
      right: 16,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people, color: Colors.white, size: 18),
            const SizedBox(width: 4),
            Text(
              '${_meetingState.participants.length}',
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    if (!_meetingState.controlsVisible) return const SizedBox.shrink();

    final myId = _meetingState.mySelf?.userId;
    final iAmSharing = _meetingState.sharingUser?.userId == myId;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.8),
          borderRadius: BorderRadius.circular(32),
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildControlButton(
                icon: _meetingState.isMuted ? Icons.mic_off : Icons.mic,
                color: _meetingState.isMuted ? Colors.red : Colors.white,
                onPressed: _toggleAudio,
              ),
              const SizedBox(width: 16),
              _buildControlButton(
                icon: _meetingState.isVideoOn
                    ? Icons.videocam
                    : Icons.videocam_off,
                color: _meetingState.isVideoOn ? Colors.white : Colors.red,
                onPressed: _toggleVideo,
              ),
              const SizedBox(width: 16),
              _buildControlButton(
                icon: Icons.screen_share,
                color: (iAmSharing || _shareStarting)
                    ? Colors.green
                    : Colors.white,
                onPressed: _toggleScreenShare,
              ),
              const SizedBox(width: 16),
              Stack(
                children: [
                  _buildControlButton(
                    icon: Icons.chat,
                    color: Colors.white,
                    onPressed: _toggleChat,
                  ),
                  if (_meetingState.unreadCount > 0)
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        constraints:
                            const BoxConstraints(minWidth: 20, minHeight: 20),
                        child: Text(
                          '${_meetingState.unreadCount}',
                          style: const TextStyle(
                              color: Colors.white, fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 16),
              _buildControlButton(
                icon: Icons.call_end,
                color: Colors.white,
                backgroundColor: Colors.red,
                onPressed: _leaveSession,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlButton({
    required IconData icon,
    required Color color,
    Color? backgroundColor,
    required VoidCallback onPressed,
  }) {
    return Material(
      color: backgroundColor ?? Colors.white.withOpacity(0.1),
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 48,
          height: 48,
          alignment: Alignment.center,
          child: Icon(icon, color: color, size: 24),
        ),
      ),
    );
  }

  Widget _buildChatPanel() {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  const Text(
                    'Group Chat',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: _toggleChat,
                  ),
                ],
              ),
            ),
            Expanded(
              child: _meetingState.messages.isEmpty
                  ? const Center(
                      child: Text('No messages yet',
                          style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      controller: _chatScrollController,
                      padding: const EdgeInsets.all(16),
                      itemCount: _meetingState.messages.length,
                      itemBuilder: (context, index) {
                        final message = _meetingState.messages[index];
                        return _buildChatMessage(message);
                      },
                    ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[200],
                border: Border(top: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _chatController,
                      decoration: const InputDecoration(
                        hintText: 'Type a message...',
                        border: OutlineInputBorder(),
                        contentPadding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      onSubmitted: (_) => _sendChatMessage(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.blue,
                    onPressed: _sendChatMessage,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChatMessage(ChatMessage message) {
    return Align(
      alignment:
          message.isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        constraints:
            BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.7),
        decoration: BoxDecoration(
          color: message.isSentByMe ? Colors.blue : Colors.grey[300],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!message.isSentByMe)
              Text(
                message.senderName,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              ),
            if (!message.isSentByMe) const SizedBox(height: 4),
            Text(
              message.message,
              style: TextStyle(
                color: message.isSentByMe ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
