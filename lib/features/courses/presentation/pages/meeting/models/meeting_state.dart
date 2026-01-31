import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';

/// Chat message model for group chat
class ChatMessage {
  final String senderId;
  final String senderName;
  final String message;
  final DateTime timestamp;
  final bool isSentByMe;

  ChatMessage({
    required this.senderId,
    required this.senderName,
    required this.message,
    required this.timestamp,
    required this.isSentByMe,
  });
}

/// Centralized meeting state for student app
class MeetingState {
  // UI state
  final bool showChat;
  final bool controlsVisible;

  // Participants
  final List<ZoomVideoSdkUser> participants;
  final ZoomVideoSdkUser? hostUser; // The host (teacher)
  final ZoomVideoSdkUser? activeUser; // Current active speaker
  final ZoomVideoSdkUser? pinnedUser; // Locally pinned user
  final ZoomVideoSdkUser? sharingUser; // User sharing screen
  final ZoomVideoSdkUser? mySelf; // Current user

  // Chat
  final List<ChatMessage> messages;
  final int unreadCount;

  // My state
  final bool isMuted;
  final bool isVideoOn;

  // Network & status
  final bool isReconnecting;
  final String? statusMessage;

  const MeetingState({
    this.showChat = false,
    this.controlsVisible = true,
    this.participants = const [],
    this.hostUser,
    this.activeUser,
    this.pinnedUser,
    this.sharingUser,
    this.mySelf,
    this.messages = const [],
    this.unreadCount = 0,
    this.isMuted = false,
    this.isVideoOn = true,
    this.isReconnecting = false,
    this.statusMessage,
  });

  /// Get the user to display in primary (large) view
  /// Priority: Pinned > Sharing > Active Speaker > Host
  ZoomVideoSdkUser? get primaryUser {
    // 1. Pinned user (local override)
    if (pinnedUser != null) return pinnedUser;
    
    // 2. Screen sharing user
    if (sharingUser != null) return sharingUser;
    
    // 3. Active speaker (if not host)
    if (activeUser != null && activeUser?.userId != hostUser?.userId) {
      return activeUser;
    }
    
    // 4. Default to host
    return hostUser;
  }

  /// Get users for small video tiles (excluding primary user)
  List<ZoomVideoSdkUser> get secondaryUsers {
    final primary = primaryUser;
    if (primary == null) return participants;
    
    return participants.where((user) => user.userId != primary.userId).toList();
  }

  MeetingState copyWith({
    bool? showChat,
    bool? controlsVisible,
    List<ZoomVideoSdkUser>? participants,
    ZoomVideoSdkUser? hostUser,
    ZoomVideoSdkUser? activeUser,
    ZoomVideoSdkUser? pinnedUser,
    ZoomVideoSdkUser? sharingUser,
    ZoomVideoSdkUser? mySelf,
    List<ChatMessage>? messages,
    int? unreadCount,
    bool? isMuted,
    bool? isVideoOn,
    bool? isReconnecting,
    String? statusMessage,
    bool clearPinned = false,
    bool clearSharing = false,
    bool clearActive = false,
    bool clearStatus = false,
    bool clearHost = false,
  }) {
    return MeetingState(
      showChat: showChat ?? this.showChat,
      controlsVisible: controlsVisible ?? this.controlsVisible,
      participants: participants ?? this.participants,
      hostUser: clearHost ? null : (hostUser ?? this.hostUser),
      activeUser: clearActive ? null : (activeUser ?? this.activeUser),
      pinnedUser: clearPinned ? null : (pinnedUser ?? this.pinnedUser),
      sharingUser: clearSharing ? null : (sharingUser ?? this.sharingUser),
      mySelf: mySelf ?? this.mySelf,
      messages: messages ?? this.messages,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isVideoOn: isVideoOn ?? this.isVideoOn,
      isReconnecting: isReconnecting ?? this.isReconnecting,
      statusMessage: clearStatus ? null : (statusMessage ?? this.statusMessage),
    );
  }
}
