import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk.dart';
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_user.dart';
import 'package:flutter_zoom_videosdk/flutter_zoom_view.dart' as zoom_view;
import 'package:flutter_zoom_videosdk/native/zoom_videosdk_event_listener.dart';

import '../../../../core/services/zoom_service.dart';
import '../../model/live_class_models.dart';
import '../../view_model/live_class_join_view_model.dart';

/// CRITICAL FIX: MeetingPage now sets up event listeners BEFORE joining Zoom
/// This prevents the NullPointerException crash in the Zoom Flutter plugin
/// 
/// Previous flow (BROKEN):
/// 1. Join Zoom in ViewModel
/// 2. Navigate to MeetingPage
/// 3. Set up event listeners (TOO LATE - SDK already firing events)
/// 4. CRASH - EventSink is null
///
/// New flow (FIXED):
/// 1. Fetch token in ViewModel
/// 2. Navigate to MeetingPage with token
/// 3. Set up event listeners FIRST
/// 4. Join Zoom (listeners are ready)
/// 5. Success!
class MeetingPage extends ConsumerStatefulWidget {
  const MeetingPage({
    super.key,
    required this.token,
    required this.classId,
  });

  final LiveClassJoinToken token;
  final String classId;

  @override
  ConsumerState<MeetingPage> createState() => _MeetingPageState();
}

class _MeetingPageState extends ConsumerState<MeetingPage> with WidgetsBindingObserver {
  final ZoomVideoSdk _zoom = ZoomVideoSdk();
  final ZoomVideoSdkEventListener _eventListener = ZoomVideoSdkEventListener();
  
  // FIX #2: Properly managed subscriptions
  final List<StreamSubscription> _subscriptions = [];
  
  // Save service reference to avoid using ref in dispose
  late final ZoomService _zoomService;
  
  List<ZoomVideoSdkUser> _users = [];
  
  // FIX #5: Initial state matches Zoom join config
  bool _isMuted = false; // Matches audioOptions: {'mute': false}
  bool _isVideoOn = true; // Matches videoOptions: {'localVideoOn': true}
  
  bool _isLoading = true;
  bool _isJoining = true;
  String? _errorMessage;
  
  // FIX #9: Network state tracking
  bool _isReconnecting = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    
    // Save zoom service reference for use in dispose
    _zoomService = ref.read(zoomServiceProvider);
    
    // CRITICAL: Set up event listeners FIRST (before joining)
    debugPrint('[MeetingPage] 1. Setting up event listeners...');
    _setupEventListeners();
    
    // Then join Zoom (event listeners are now ready to receive events)
    debugPrint('[MeetingPage] 2. Event listeners ready, now joining Zoom...');
    _joinZoomSession();
  }

  @override
  void dispose() {
    // FIX #2: Proper cleanup - cancel all subscriptions
    debugPrint('[MeetingPage] Disposing - cleaning up ${_subscriptions.length} listeners');
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();
    
    // FIX 3: CRITICAL - Only leave if NOT joining or waiting for host
    // The ZoomService guard will prevent leaving during these states
    if (!_isJoining && !_isLoading) {
      debugPrint('[MeetingPage] Calling leaveMeeting (safe to leave)');
      _zoomService.leaveMeeting();
    } else {
      debugPrint('[MeetingPage] Skipping leaveMeeting (join/load in progress)');
    }
    
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Handle app lifecycle for better resource management
    if (state == AppLifecycleState.paused) {
      debugPrint('[MeetingPage] App paused');
    } else if (state == AppLifecycleState.resumed) {
      debugPrint('[MeetingPage] App resumed - refreshing state');
      _refreshMeetingState();
    }
  }

  /// FIX #2: Setup event listeners with proper lifecycle management
  void _setupEventListeners() {
    debugPrint('[MeetingPage] Setting up event listeners');
    
    // Clear any existing subscriptions first
    for (var sub in _subscriptions) {
      sub.cancel();
    }
    _subscriptions.clear();

    // Add all listeners
    _subscriptions.addAll([
      _eventListener.addListener(EventType.onSessionJoin, _handleSessionJoin),
      _eventListener.addListener(EventType.onUserJoin, _updateUserList),
      _eventListener.addListener(EventType.onUserLeave, _updateUserList),
      _eventListener.addListener(EventType.onUserVideoStatusChanged, _handleVideoChange),
      _eventListener.addListener(EventType.onUserAudioStatusChanged, _handleAudioChange),
      _eventListener.addListener(EventType.onSessionLeave, _handleSessionLeave),
      _eventListener.addListener(EventType.onError, _handleError),
      
      // FIX #9: Network-related events
      _eventListener.addListener(EventType.onSessionNeedPassword, _handleSessionNeedPassword),
    ]);

    debugPrint('[MeetingPage] ✅ ${_subscriptions.length} event listeners registered');
  }

  /// CRITICAL FIX: Join Zoom session AFTER event listeners are set up
  Future<void> _joinZoomSession() async {
    debugPrint('[MeetingPage] Joining Zoom session with token...');
    
    try {
      final joinNotifier = ref.read(liveClassJoinViewModelProvider.notifier);
      
      final joinResult = await _zoomService.joinMeeting(
        sdkJwtToken: widget.token.token,
        sessionName: widget.token.sessionName,
        userName: widget.token.userName,
      );

      if (!joinResult.success) {
        debugPrint('[MeetingPage] ❌ Join failed: ${joinResult.errorMessage}');
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isJoining = false;
            _errorMessage = joinResult.errorMessage ?? 'Failed to join meeting';
          });
          
          // Notify ViewModel of failure
          joinNotifier.reset();
          
          // Auto-exit after showing error
          Future.delayed(const Duration(seconds: 3), () {
            if (mounted) Navigator.pop(context);
          });
        }
        return;
      }

      debugPrint('[MeetingPage] ✅ Join successful (waitingForHost=${joinResult.isWaitingForHost})');
      
      // Notify ViewModel of successful join
      joinNotifier.markAsJoined(waitingForHost: joinResult.isWaitingForHost);
      
      if (mounted) {
        setState(() {
          _isJoining = false;
        });
      }
      
      // Initialize meeting state
      await _initializeMeetingState();
      
    } catch (e) {
      debugPrint('[MeetingPage] ❌ Join exception: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isJoining = false;
          _errorMessage = 'Failed to join meeting: $e';
        });
        
        // Notify ViewModel of failure
        ref.read(liveClassJoinViewModelProvider.notifier).reset();
        
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  Future<void> _initializeMeetingState() async {
    debugPrint('[MeetingPage] Initializing meeting state...');
    try {
      final mySelf = await _zoom.session.getMySelf();
      final remoteUsers = await _zoom.session.getRemoteUsers() ?? [];
      
      if (mySelf != null && mounted) {
        setState(() {
          _users = [mySelf, ...remoteUsers];
          _isLoading = false;
        });
        await _updateAudioVideoStatus();
        debugPrint('[MeetingPage] ✅ Initialized with ${_users.length} users');
      } else if (mounted) {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      debugPrint('[MeetingPage] Error initializing: $e');
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _refreshMeetingState() async {
    try {
      final mySelf = await _zoom.session.getMySelf();
      if (mySelf == null) return;
      
      final remoteUsers = await _zoom.session.getRemoteUsers() ?? [];
      if (mounted) {
        setState(() {
          _users = [mySelf, ...remoteUsers];
        });
        await _updateAudioVideoStatus();
      }
    } catch (e) {
      debugPrint('[MeetingPage] Error refreshing state: $e');
    }
  }

  /// FIX #5: Properly sync UI state with Zoom SDK state
  Future<void> _updateAudioVideoStatus() async {
    try {
      final mySelf = await _zoom.session.getMySelf();
      if (mySelf == null) return;
      
      final audioStatus = await mySelf.audioStatus?.isMuted() ?? true;
      final videoStatus = await mySelf.videoStatus?.isOn() ?? false;
      
      if (mounted) {
        setState(() {
          _isMuted = audioStatus;
          _isVideoOn = videoStatus;
        });
        debugPrint('[MeetingPage] A/V Status: muted=$_isMuted, video=$_isVideoOn');
      }
    } catch (e) {
      debugPrint('[MeetingPage] Error updating A/V status: $e');
    }
  }

  // ========== Event Handlers ==========

  void _handleSessionJoin(dynamic data) async {
    debugPrint('[MeetingPage] onSessionJoin: $data');
    try {
      final mySelf = ZoomVideoSdkUser.fromJson(jsonDecode(data['sessionUser']));
      final remoteUsers = await _zoom.session.getRemoteUsers() ?? [];
      
      if (mounted) {
        setState(() {
          _users = [mySelf, ...remoteUsers];
          _isLoading = false;
        });
        _updateAudioVideoStatus();
      }
    } catch (e) {
      debugPrint('[MeetingPage] Error parsing session join: $e');
      await _initializeMeetingState();
    }
  }

  void _updateUserList(dynamic data) async {
    debugPrint('[MeetingPage] User list update: $data');
    try {
      final mySelf = await _zoom.session.getMySelf();
      if (mySelf == null) return;
      
      final remoteUsers = await _zoom.session.getRemoteUsers() ?? [];
      if (mounted) {
        setState(() {
          _users = [mySelf, ...remoteUsers];
        });
      }
    } catch (e) {
      debugPrint('[MeetingPage] Error updating user list: $e');
    }
  }

  void _handleVideoChange(dynamic data) async {
    debugPrint('[MeetingPage] Video status changed: $data');
    await _updateAudioVideoStatus();
    // FIX #1: Force rebuild to refresh video views
    if (mounted) setState(() {});
  }

  void _handleAudioChange(dynamic data) async {
    debugPrint('[MeetingPage] Audio status changed: $data');
    await _updateAudioVideoStatus();
  }
  
  void _handleSessionLeave(dynamic data) {
    debugPrint('[MeetingPage] Session leave: $data');
    if (mounted) {
      Navigator.pop(context);
    }
  }

  void _handleError(dynamic data) {
    debugPrint('[MeetingPage] ❌ Zoom Error: $data');
    
    // FIX #9: Detect network errors
    final errorType = data['errorType']?.toString() ?? '';
    final isNetworkError = errorType.toLowerCase().contains('network') ||
                          errorType.toLowerCase().contains('connection');
    
    if (isNetworkError) {
      _handleNetworkError(errorType);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Meeting error: $errorType'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    }
  }

  void _handleSessionNeedPassword(dynamic data) {
    debugPrint('[MeetingPage] Session needs password: $data');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This meeting requires a password'),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  /// FIX #9: Handle network disconnection
  void _handleNetworkError(String errorType) {
    debugPrint('[MeetingPage] 🌐 Network error detected: $errorType');
    
    if (mounted) {
      setState(() {
        _isReconnecting = true;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              const SizedBox(width: 12),
              const Text('Connection lost. Reconnecting...'),
            ],
          ),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 5),
        ),
      );

      // Try to refresh state after a delay
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted) {
          _refreshMeetingState();
          setState(() {
            _isReconnecting = false;
          });
        }
      });
    }
  }

  // ========== User Actions ==========

  Future<void> _toggleAudio() async {
    try {
      final mySelf = await _zoom.session.getMySelf();
      if (mySelf?.audioStatus == null) return;
      
      final isMuted = await mySelf!.audioStatus!.isMuted();
      if (isMuted) {
        await _zoom.audioHelper.unMuteAudio(mySelf.userId);
      } else {
        await _zoom.audioHelper.muteAudio(mySelf.userId);
      }
    } catch (e) {
      debugPrint('[MeetingPage] Error toggling audio: $e');
      _showErrorSnackbar('Failed to toggle audio');
    }
  }

  Future<void> _toggleVideo() async {
    try {
      final mySelf = await _zoom.session.getMySelf();
      if (mySelf?.videoStatus == null) return;
      
      final isOn = await mySelf!.videoStatus!.isOn();
      if (isOn) {
        await _zoom.videoHelper.stopVideo();
      } else {
        await _zoom.videoHelper.startVideo();
      }
    } catch (e) {
      debugPrint('[MeetingPage] Error toggling video: $e');
      _showErrorSnackbar('Failed to toggle video');
    }
  }

  Future<void> _leaveSession() async {
    try {
      await _zoom.leaveSession(false);
    } catch (e) {
      debugPrint('[MeetingPage] Error leaving: $e');
    }
    if (mounted) Navigator.pop(context);
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  // ========== UI Build ==========

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      body: SafeArea(
        child: Stack(
          children: [
            // Show error state if join failed
            if (_errorMessage != null)
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline,
                        color: Colors.red,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _errorMessage!,
                        style: const TextStyle(color: Colors.white, fontSize: 16),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Returning to class details...',
                        style: TextStyle(color: Colors.white70, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              )
            else if (_isLoading || _isJoining)
              Center(
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
              )
            else
              _buildVideoGrid(),
            
            // FIX #9: Show reconnecting overlay
            if (_isReconnecting)
              Positioned(
                top: 16,
                left: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        ),
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Reconnecting...',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            
            if (!_isLoading && !_isJoining && _errorMessage == null)
              _buildControlBar(),
            
            // Participant count badge
            if (!_isLoading && !_isJoining && _errorMessage == null)
              Positioned(
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
                        '${_users.length}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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

  Widget _buildVideoGrid() {
    if (_users.isEmpty) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_outline, color: Colors.white54, size: 64),
            SizedBox(height: 16),
            Text(
              'Waiting for participants...',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ],
        ),
      );
    }
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 100), // Space for controls
      child: GridView.builder(
        padding: const EdgeInsets.all(8),
        physics: const ClampingScrollPhysics(),
        itemCount: _users.length,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: _users.length <= 2 ? 1 : 2,
          crossAxisSpacing: 8,
          mainAxisSpacing: 8,
          childAspectRatio: _users.length <= 2 ? 0.75 : 1.0,
        ),
        itemBuilder: (context, index) => _VideoTile(
          user: _users[index],
          // FIX #10: Stable key combining userId, userName, and index
          key: ValueKey('${_users[index].userId}_${_users[index].userName}_$index'),
        ),
      ),
    );
  }

  Widget _buildControlBar() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        margin: const EdgeInsets.all(16),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.black.withOpacity(0.7),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ControlButton(
              icon: _isMuted ? Icons.mic_off : Icons.mic,
              color: _isMuted ? Colors.red : Colors.white,
              onPressed: _toggleAudio,
              tooltip: _isMuted ? 'Unmute' : 'Mute',
            ),
            const SizedBox(width: 24),
            _ControlButton(
              icon: _isVideoOn ? Icons.videocam : Icons.videocam_off,
              color: _isVideoOn ? Colors.white : Colors.red,
              onPressed: _toggleVideo,
              tooltip: _isVideoOn ? 'Stop Video' : 'Start Video',
            ),
            const SizedBox(width: 24),
            _ControlButton(
              icon: Icons.call_end,
              color: Colors.white,
              backgroundColor: Colors.red,
              onPressed: _leaveSession,
              tooltip: 'Leave',
            ),
          ],
        ),
      ),
    );
  }
}

/// FIX #1, #10: Improved video tile with better rendering and stable keys
class _VideoTile extends StatelessWidget {
  final ZoomVideoSdkUser user;
  const _VideoTile({required this.user, super.key});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        color: Colors.black,
        child: Stack(
          fit: StackFit.expand,
          children: [
            // FIX #1: Improved video view with better aspect ratio handling
            zoom_view.View(
              // FIX #10: More stable key combining userId and userName
              key: ValueKey('video_${user.userId}_${user.userName}'),
              creationParams: {
                "userId": user.userId,
                // FIX #1: Use Original aspect for better compatibility
                "videoAspect": VideoAspect.Original,
                "fullScreen": false,
              },
            ),
            
            // Name Tag
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (user.isHost)
                      Container(
                        margin: const EdgeInsets.only(right: 4),
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                        decoration: BoxDecoration(
                          color: Colors.amber,
                          borderRadius: BorderRadius.circular(2),
                        ),
                        child: const Text(
                          'HOST',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 8,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    Flexible(
                      child: Text(
                        user.userName,
                        style: const TextStyle(color: Colors.white, fontSize: 12),
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
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final VoidCallback onPressed;
  final String tooltip;

  const _ControlButton({
    required this.icon,
    required this.color,
    this.backgroundColor,
    required this.onPressed,
    required this.tooltip,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: backgroundColor ?? Colors.white.withOpacity(0.1),
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            child: Icon(icon, color: color, size: 28),
          ),
        ),
      ),
    );
  }
}
