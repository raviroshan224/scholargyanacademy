import 'dart:async';

import 'package:chewie/chewie.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:video_player/video_player.dart';

import '../../../../core/core.dart';
import '../../service/course_service.dart';

typedef WatchUrlResolver = Future<String?> Function();

class VideoPlayerPage extends ConsumerStatefulWidget {
  const VideoPlayerPage({
    super.key,
    required this.url,
    this.title,
    this.headers,
    this.lectureId,
    this.getWatchUrl,
    this.thumbnailUrl,
    this.processingStatus,
    this.startPositionSeconds,
  });

  final String url;
  final String? title;
  final Map<String, String>? headers;
  final String? lectureId;
  final WatchUrlResolver? getWatchUrl;
  final String? thumbnailUrl;
  final String? processingStatus;
  
  /// If provided, seek to this position (in seconds) when video starts playing
  final int? startPositionSeconds;

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> with WidgetsBindingObserver {
  ChewieController? _chewieController;
  VideoPlayerController? _videoPlayerController;

  bool _isFetchingLink = false;
  String? _errorMessage;
  bool _hasMarkedComplete = false;

  String? _activeUrl;
  Map<String, String>? _activeHeaders;

  int _loadToken = 0;
  int _autoRefreshAttempts = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Delay initialization until after first frame to ensure smooth transition
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _preparePlayback(forceRefresh: false, origin: 'initial load');
    });
  }

  @override
  void didUpdateWidget(covariant VideoPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final urlChanged = oldWidget.url != widget.url;
    // Map equality check (could be improved with deeper check if needed)
    final headersChanged = !_mapEquals(oldWidget.headers, widget.headers);
    if (urlChanged || headersChanged) {
      _preparePlayback(forceRefresh: true, origin: 'widget update');
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused) {
      _videoPlayerController?.pause();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _disposeControllers();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _chewieController;
    final bool isProcessing = widget.processingStatus != null &&
        widget.processingStatus != 'ready';
    
    // Determine state
    final bool showLoading = _isFetchingLink || isProcessing;
    final bool showPlayer = chewie != null && !showLoading && _errorMessage == null;
    final bool showError = _errorMessage != null && !_isFetchingLink;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Video Player Center Stage
            if (showPlayer)
              Center(
                child: Chewie(controller: chewie),
              ),

            // Thumbnail + Loading Overlay
            if (!_isPlayingOrReady() && !showError)
               _buildLoadingOverlay(isProcessing: isProcessing),

            // Error State
            if (showError)
              _buildErrorState(),
              
             // Back Button (custom if Chewie doesn't show it or we need an overlay)
             // Chewie usually handles this, so we rely on Chewie's Cupertino controls or Material controls
          ],
        ),
      ),
    );
  }

  bool _isPlayingOrReady() {
    return _videoPlayerController != null &&
        _videoPlayerController!.value.isInitialized &&
        !_isFetchingLink;
  }

  Widget _buildLoadingOverlay({required bool isProcessing}) {
    final String message = isProcessing
        ? 'Video is being processed...'
        : _isFetchingLink
            ? 'Requesting video link...'
            : 'Loading video...';

    return Container(
      color: Colors.black,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Thumbnail placeholder
          if (widget.thumbnailUrl != null && widget.thumbnailUrl!.isNotEmpty)
            Positioned.fill(
              child: CustomCachedNetworkImage(
                imageUrl: widget.thumbnailUrl!,
                fitStatus: BoxFit.contain,
              ),
            ),
          // Dark overlay with loading indicator
          Positioned.fill(
            child: Container(
              color: Colors.black54,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (isProcessing)
                    const Icon(
                      Icons.hourglass_bottom,
                      color: AppColors.white,
                      size: 48,
                    )
                  else
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation(AppColors.white),
                    ),
                  AppSpacing.verticalSpaceSmall,
                  CText(
                    message,
                    type: TextType.bodyMedium,
                    color: AppColors.white,
                  ),
                ],
              ),
            ),
          ),
          // Back button always available in loading state
          Positioned(
            top: 16,
            left: 16,
            child: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
     return Container(
        color: Colors.black,
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.redAccent),
            AppSpacing.verticalSpaceAverage,
            CText(
              _errorMessage ?? 'Unable to load video',
              type: TextType.bodyMedium,
              textAlign: TextAlign.center,
              color: AppColors.white,
            ),
            AppSpacing.verticalSpaceLarge,
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
             AppSpacing.verticalSpaceAverage,
            TextButton(
               onPressed: () => Navigator.of(context).pop(),
               child: const Text('Go Back'),
            ),
             if (_activeUrl != null && _activeUrl!.isNotEmpty) ...[
                AppSpacing.verticalSpaceLarge,
                _DiagnosticsRow(label: 'Current URL', value: _activeUrl!),
              ],
          ],
        ),
      );
  }

  Future<void> _preparePlayback(
      {required bool forceRefresh, required String origin}) async {
    // Block playback if video is still processing
    if (widget.processingStatus != null && widget.processingStatus != 'ready') {
      if (!mounted) return;
      setState(() {
        _isFetchingLink = false;
        _errorMessage = null;
      });
      return;
    }

    final int token = ++_loadToken;
    await _disposeControllers();

    setState(() {
      _isFetchingLink = true;
      _errorMessage = null;
      _hasMarkedComplete = false;
    });

    try {
      final _WatchLinkResult? linkResult = await _fetchSignedUrl(
        forceRefresh: forceRefresh,
        origin: origin,
      );
      
      if (!mounted || token != _loadToken) {
        return;
      }

      if (linkResult == null || linkResult.url.isEmpty) {
        setState(() {
          _isFetchingLink = false;
          _errorMessage ??= 'Unable to obtain video link. Please retry.';
        });
        return;
      }

       final Uri? parsed = Uri.tryParse(linkResult.url);
      if (parsed == null || !parsed.hasScheme) {
         setState(() {
           _isFetchingLink = false;
          _errorMessage = 'Received an invalid playback URL.';
        });
        return;
      }

      // Sanitize headers
      final Map<String, String>? headers = _sanitizeHeaders(parsed, linkResult.headers);
      
      setState(() {
         _activeUrl = linkResult.url;
         _activeHeaders = headers;
      });

      debugPrint('Initializing VideoPlayerController for URL: ${linkResult.url}');

      // Initialize VideoPlayerController
      final videoController = VideoPlayerController.networkUrl(
        parsed,
        httpHeaders: headers ?? {}, 
      );
      
      await videoController.initialize();
      
      if (!mounted || token != _loadToken) {
        await videoController.dispose();
        return;
      }

      // Prepare initial seek if needed
      if (widget.startPositionSeconds != null && widget.startPositionSeconds! > 0) {
        final duration = videoController.value.duration;
        final seekTo = Duration(seconds: widget.startPositionSeconds!);
        if (seekTo < duration) {
           await videoController.seekTo(seekTo);
        }
      }

      // Initialize ChewieController
      final chewieController = ChewieController(
        videoPlayerController: videoController,
        autoPlay: true,
        looping: false,
        aspectRatio: videoController.value.aspectRatio, // Use video's aspect ratio
        errorBuilder: (context, errorMessage) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text(
                  errorMessage,
                  style: const TextStyle(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            );
        },
        allowedScreenSleep: false,
        fullScreenByDefault: false,
      );

      setState(() {
        _isFetchingLink = false;
        _videoPlayerController = videoController;
        _chewieController = chewieController;
        _autoRefreshAttempts = 0;
      });
      
      // Listen for errors on the video controller
      videoController.addListener(() {
          if (videoController.value.hasError) {
             _handleVideoError(videoController.value.errorDescription, token);
          }
          final val = videoController.value;
          
          // Debug logs for playback progress (throttle these in real app, but useful for debug now)
          // debugPrint('Playback: ${val.position} / ${val.duration} | Playing: ${val.isPlaying} | Complete: $_hasMarkedComplete');

          if (val.isInitialized &&
              !val.isPlaying &&
              val.duration != Duration.zero &&
              (val.position >= val.duration || 
               val.duration - val.position <= const Duration(milliseconds: 1000))) {
             debugPrint('Video/Chewie detected end of playback. Pos: ${val.position}, Dur: ${val.duration}');
            _handleVideoComplete(token);
          }
      });

    } catch (error, stackTrace) {
      debugPrint('Video prepare failed ($origin): $error\n$stackTrace');
      if (!mounted || token != _loadToken) {
        return;
      }
      _handleVideoError(error, token);
    }
  }

  void _handleVideoError(Object? error, int token) async {
      if (!mounted || token != _loadToken) return;

      final String message = _describeError(error);
      
      // If header is already showing error, don't continually setState unless logic requires it
      if (_errorMessage != message) {
          setState(() {
            _isFetchingLink = false;
            _errorMessage = message;
            // Dispose bad controllers to prevent further errors
            _chewieController?.dispose();
            _chewieController = null;
          });
      }

      if (_shouldAttemptSignedUrlRefresh(error) &&
          _canRefreshSignedUrl &&
          _autoRefreshAttempts < 1) {
        _autoRefreshAttempts += 1;
        debugPrint('Attempting auto-refresh due to forbidden/expired error...');
        await Future<void>.delayed(const Duration(milliseconds: 500));
        if (mounted) {
          await _preparePlayback(
              forceRefresh: true, origin: 'auto refresh after forbidden');
        }
      }
  }

  void _handleVideoComplete(int token) async {
    if (_hasMarkedComplete) return;
    if (!mounted || token != _loadToken) return;

    _hasMarkedComplete = true; // prevent double firing

    final String? lectureId = widget.lectureId?.trim();
    if (lectureId != null && lectureId.isNotEmpty) {
      debugPrint('Video completed. Marking lecture $lectureId as complete.');
      final courseService = ref.read(courseServiceProvider);
      // Fire-and-forget the completion call
      courseService.completeLecture(lectureId).then((result) {
        if (result.isLeft) {
          debugPrint('Failed to mark lecture complete: ${result.left.message}');
        } else {
          debugPrint('Lecture $lectureId marked complete successfully.');
        }
      });
    }
  }

  Future<_WatchLinkResult?> _fetchSignedUrl({
    required bool forceRefresh,
    required String origin,
  }) async {
    if (!forceRefresh) {
      if (_activeUrl != null && _activeUrl!.isNotEmpty) {
        return _WatchLinkResult(
            url: _activeUrl!, headers: _activeHeaders ?? widget.headers);
      }
      final String initial = widget.url.trim();
      if (initial.isNotEmpty) {
        debugPrint('Using provided signed URL for playback (origin: $origin).');
        return _WatchLinkResult(url: initial, headers: widget.headers);
      }
    }

    debugPrint('Requesting fresh signed URL for playback (origin: $origin).');

    if (widget.getWatchUrl != null) {
      final String? resolved = await widget.getWatchUrl!();
      if (resolved == null || resolved.trim().isEmpty) {
        setState(() {
          _errorMessage = 'No playback URL returned by resolver.';
        });
        return null;
      }
      return _WatchLinkResult(url: resolved.trim(), headers: widget.headers);
    }

    final String? lectureId = widget.lectureId?.trim();
    if (lectureId != null && lectureId.isNotEmpty) {
      final courseService = ref.read(courseServiceProvider);
      final result = await courseService.watchLecture(lectureId);
      return result.fold(
        (failure) {
          setState(() {
            _errorMessage = failure.message.isNotEmpty
                ? 'Watch request failed: ${failure.message}'
                : 'Unable to fetch playback URL.';
          });
          return null;
        },
        (payload) {
          final String? resolved = _extractUrlFromPayload(payload);
          if (resolved == null || resolved.isEmpty) {
            setState(() {
              _errorMessage = 'Watch endpoint returned no playback URL.';
            });
            return null;
          }
          debugPrint('Fetched signed URL from backend for lecture $lectureId.');
          return _WatchLinkResult(url: resolved, headers: widget.headers);
        },
      );
    }

    final String fallback = widget.url.trim();
    if (fallback.isNotEmpty) {
      debugPrint(
          'Falling back to existing signed URL for playback (no resolver available).');
      return _WatchLinkResult(url: fallback, headers: widget.headers);
    }

    setState(() {
      _errorMessage = 'No playback URL available to start streaming.';
    });
    return null;
  }
  
  String? _extractUrlFromPayload(Map<String, dynamic> payload) {
    const candidates = <String>[
      'url',
      'videoUrl',
      'signedUrl',
      'playbackUrl',
      'streamUrl'
    ];
    for (final key in candidates) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  Future<void> _disposeControllers() async {
    try {
      _chewieController?.dispose();
    } catch (_) {}
    try {
      await _videoPlayerController?.dispose();
    } catch(_) {}
    _chewieController = null;
    _videoPlayerController = null;
  }
  
  Future<void> _retry() async {
    await _preparePlayback(forceRefresh: true, origin: 'user retry');
  }

  // --- Helpers similar to previous implementation ---

  Map<String, String>? _sanitizeHeaders(Uri uri, Map<String, String>? source) {
    if (source == null || source.isEmpty) {
      return null;
    }
    final headers = Map<String, String>.from(source)
      ..removeWhere((key, value) => value.trim().isEmpty);
    if (headers.isEmpty) {
      return null;
    }

    if (_looksSignedUri(uri)) {
      headers.removeWhere((key, _) => key.toLowerCase() == 'authorization');
    }

    return headers.isEmpty ? null : headers;
  }

  bool _looksSignedUri(Uri uri) {
    if (!uri.hasQuery) {
      return false;
    }
    const signedQueryHints = <String>{
      'token',
      'signature',
      'expires',
      'sig',
      'policy',
      'x-amz-signature',
      'x-amz-security-token',
      'x-goog-signature',
      'x-goog-credential',
      'x-goog-date',
      'x-ms-signature',
      'x-ms-blob-type',
      'auth',
      'key',
    };
    return uri.queryParameters.keys
        .any((key) => signedQueryHints.contains(key.toLowerCase()));
  }

   bool get _canRefreshSignedUrl =>
      widget.getWatchUrl != null ||
      (widget.lectureId != null && widget.lectureId!.trim().isNotEmpty);

  bool _shouldAttemptSignedUrlRefresh(Object? error) {
    if (error == null) return false;
    final message = error.toString().toLowerCase();
    if (message.contains('403') || message.contains('forbidden')) {
      return true;
    }
    if (message.contains('410') || message.contains('expired')) {
      return true;
    }
    return false;
  }

  String _describeError(Object? error) {
    if (error == null) return 'Unknown error occurred';
    final text = error.toString();
    if (text.contains('403')) {
      return 'Streaming endpoint responded with status 403 (forbidden). Tap retry to request a fresh signed link.';
    }
    if (text.contains('404')) {
      return 'Streaming endpoint responded with status 404 (not found).';
    }
    if (text.contains('SocketException')) {
      return 'Network connection failed while preparing playback.';
    }
    return text;
  }

  bool _mapEquals(Map<String, String>? a, Map<String, String>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null || a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }
}

class _WatchLinkResult {
  _WatchLinkResult({
    required this.url,
    this.headers,
  });

  final String url;
  final Map<String, String>? headers;
}

class _DiagnosticsRow extends StatelessWidget {
  const _DiagnosticsRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CText(label, type: TextType.bodySmall, color: AppColors.gray400),
          AppSpacing.verticalSpaceSmall,
          SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.gray300,
                ),
          ),
        ],
      ),
    );
  }
}
