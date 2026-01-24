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
  });

  final String url;
  final String? title;
  final Map<String, String>? headers;
  final String? lectureId;
  final WatchUrlResolver? getWatchUrl;

  @override
  ConsumerState<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends ConsumerState<VideoPlayerPage> {
  VideoPlayerController? _videoController;
  ChewieController? _chewieController;

  bool _isFetchingLink = false;
  bool _isInitializingPlayer = false;
  String? _errorMessage;

  String? _activeUrl;
  Map<String, String>? _activeHeaders;

  final List<_ProbeLog> _probeLogs = <_ProbeLog>[];

  int _loadToken = 0;
  int _autoRefreshAttempts = 0;

  bool get _isLoading => _isFetchingLink || _isInitializingPlayer;

  @override
  void initState() {
    super.initState();
    _preparePlayback(forceRefresh: false, origin: 'initial load');
  }

  @override
  void didUpdateWidget(covariant VideoPlayerPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    final urlChanged = oldWidget.url != widget.url;
    final headersChanged = !_mapEquals(oldWidget.headers, widget.headers);
    if (urlChanged || headersChanged) {
      _preparePlayback(forceRefresh: true, origin: 'widget update');
    }
  }

  @override
  void dispose() {
    unawaited(_disposeControllers());
    super.dispose();
  }

  Future<void> _preparePlayback(
      {required bool forceRefresh, required String origin}) async {
    final int token = ++_loadToken;
    await _disposeControllers();

    setState(() {
      _isFetchingLink = true;
      _isInitializingPlayer = false;
      _errorMessage = null;
    });

    try {
      final _PlaybackSource? source = await _resolvePlaybackSource(
        forceRefresh: forceRefresh,
        origin: origin,
        token: token,
      );
      if (!mounted || token != _loadToken) {
        return;
      }

      if (source == null) {
        setState(() {
          _isFetchingLink = false;
          _errorMessage ??= 'Unable to obtain video link. Please retry.';
        });
        return;
      }

      _probeLogs
        ..clear()
        ..addAll(source.probeLogs);

      setState(() {
        _isFetchingLink = false;
        _isInitializingPlayer = true;
        _activeUrl = source.url.toString();
        _activeHeaders = source.headers;
      });

      final VideoPlayerController controller = _createVideoController(
        source.url,
        source.headers,
      );
      await controller.initialize();
      if (!mounted || token != _loadToken) {
        await controller.dispose();
        return;
      }

      final ChewieController chewie = _createChewieController(controller);
      setState(() {
        _isInitializingPlayer = false;
        _videoController = controller;
        _chewieController = chewie;
        _errorMessage = null;
      });
      _autoRefreshAttempts = 0;
    } catch (error, stackTrace) {
      debugPrint('Video prepare failed ($origin): $error\n$stackTrace');
      if (!mounted || token != _loadToken) {
        return;
      }

      final String message = _describeError(error);
      setState(() {
        _isFetchingLink = false;
        _isInitializingPlayer = false;
        _errorMessage = message;
      });

      if (_shouldAttemptSignedUrlRefresh(error) &&
          _canRefreshSignedUrl &&
          _autoRefreshAttempts < 1) {
        _autoRefreshAttempts += 1;
        await Future<void>.delayed(const Duration(milliseconds: 300));
        if (mounted) {
          await _preparePlayback(
              forceRefresh: true, origin: 'auto refresh after forbidden');
        }
      }
    }
  }

  Future<_PlaybackSource?> _resolvePlaybackSource({
    required bool forceRefresh,
    required String origin,
    required int token,
  }) async {
    try {
      final _WatchLinkResult? watchLink = await _fetchSignedUrl(
        forceRefresh: forceRefresh,
        origin: origin,
      );
      if (!mounted || token != _loadToken) {
        return null;
      }

      if (watchLink == null || watchLink.url.isEmpty) {
        setState(() {
          _errorMessage = 'Server did not return a playback URL.';
        });
        return null;
      }

      final Uri? parsed = Uri.tryParse(watchLink.url);
      if (parsed == null || !parsed.hasScheme) {
        setState(() {
          _errorMessage = 'Received an invalid playback URL.';
        });
        return null;
      }

      final Map<String, String>? headers =
          _sanitizeHeaders(parsed, watchLink.headers);
      final List<_ProbeLog> probeLogs = await _probeStream(parsed, headers);

      return _PlaybackSource(
          url: parsed, headers: headers, probeLogs: probeLogs);
    } catch (error, stackTrace) {
      debugPrint(
          'Playback source resolution failed ($origin): $error\n$stackTrace');
      setState(() {
        _errorMessage = 'Failed to prepare playback. ${_describeError(error)}';
      });
      return null;
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

  Future<List<_ProbeLog>> _probeStream(
      Uri uri, Map<String, String>? headers) async {
    final logs = <_ProbeLog>[];
    final options = BaseOptions(
      connectTimeout: const Duration(seconds: 8),
      receiveTimeout: const Duration(seconds: 8),
      followRedirects: true,
      validateStatus: (_) => true,
    );
    final dio = Dio(options);

    Future<void> record(
        String method, Future<Response<dynamic>> Function() request) async {
      final stopwatch = Stopwatch()..start();
      try {
        final response = await request();
        stopwatch.stop();
        logs.add(_ProbeLog(
          method: method,
          statusCode: response.statusCode,
          message: response.statusMessage,
          duration: stopwatch.elapsed,
          finalUri: response.realUri,
        ));
      } on DioException catch (error) {
        stopwatch.stop();
        logs.add(_ProbeLog(
          method: method,
          statusCode: error.response?.statusCode,
          message: error.message ?? error.error?.toString(),
          duration: stopwatch.elapsed,
          finalUri: error.response?.realUri,
          errorType: error.type.toString(),
        ));
      } catch (error) {
        stopwatch.stop();
        logs.add(_ProbeLog(
          method: method,
          message: error.toString(),
          duration: stopwatch.elapsed,
        ));
      }
    }

    await record(
      'HEAD',
      () => dio.requestUri<void>(
        uri,
        options: Options(
            method: 'HEAD', headers: headers, responseType: ResponseType.plain),
      ),
    );

    final _ProbeLog? first = logs.isEmpty ? null : logs.first;
    if (first == null ||
        (first.statusCode != null && first.statusCode! >= 400)) {
      await record(
        'GET range',
        () => dio.requestUri<List<int>>(
          uri,
          options: Options(
            method: 'GET',
            headers: <String, String>{
              if (headers != null) ...headers,
              'Range': 'bytes=0-0',
            },
            responseType: ResponseType.bytes,
          ),
        ),
      );
    }

    dio.close(force: true);
    return logs;
  }

  VideoPlayerController _createVideoController(
      Uri uri, Map<String, String>? headers) {
    if (headers == null || headers.isEmpty) {
      return VideoPlayerController.networkUrl(uri);
    }
    return VideoPlayerController.networkUrl(uri, httpHeaders: headers);
  }

  ChewieController _createChewieController(VideoPlayerController controller) {
    return ChewieController(
      videoPlayerController: controller,
      autoPlay: true,
      looping: false,
      showControlsOnInitialize: false,
      allowPlaybackSpeedChanging: true,
      allowedScreenSleep: false,
      materialProgressColors: ChewieProgressColors(
        handleColor: AppColors.primary,
        backgroundColor: AppColors.gray300,
        bufferedColor: AppColors.gray400,
        playedColor: AppColors.secondary,
      ),
      errorBuilder: (context, message) {
        final fallback = message.isNotEmpty
            ? message
            : 'Playback error encountered. Please try again.';
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: CText(
              fallback,
              type: TextType.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ),
        );
      },
    );
  }

  bool get _canRefreshSignedUrl =>
      widget.getWatchUrl != null ||
      (widget.lectureId != null && widget.lectureId!.trim().isNotEmpty);

  bool _shouldAttemptSignedUrlRefresh(Object error) {
    final message = error.toString().toLowerCase();
    if (message.contains('403') || message.contains('forbidden')) {
      return true;
    }
    if (message.contains('410') || message.contains('expired')) {
      return true;
    }
    return false;
  }

  String _describeError(Object error) {
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

  Future<void> _retry() async {
    await _preparePlayback(forceRefresh: true, origin: 'user retry');
  }

  Future<void> _copyDiagnostics() async {
    final buffer = StringBuffer()
      ..writeln('Playback diagnostics')
      ..writeln('-------------------');

    if (_activeUrl != null) {
      buffer.writeln('Active URL: $_activeUrl');
    }

    if (_activeHeaders != null && _activeHeaders!.isNotEmpty) {
      buffer.writeln('Headers:');
      _activeHeaders!.forEach((key, value) => buffer.writeln('  $key: $value'));
    }

    if (_probeLogs.isNotEmpty) {
      buffer.writeln('Probe results:');
      for (final log in _probeLogs) {
        buffer.writeln('  ${log.summary()}');
      }
    }

    if (_errorMessage != null) {
      buffer.writeln('Last error: $_errorMessage');
    }

    final text = buffer.toString();
    if (text.trim().isEmpty) {
      return;
    }
    await Clipboard.setData(ClipboardData(text: text));
    if (!mounted) {
      return;
    }
    AppMethods.showCustomSnackBar(
      context: context,
      message: 'Diagnostics copied to clipboard',
    );
  }

  Future<void> _disposeControllers() async {
    final ChewieController? chewie = _chewieController;
    final VideoPlayerController? controller = _videoController;
    _chewieController = null;
    _videoController = null;

    if (chewie != null) {
      chewie.dispose();
    }
    if (controller != null) {
      await controller.dispose();
    }
  }

  @override
  Widget build(BuildContext context) {
    final chewie = _chewieController;
    return Scaffold(
      appBar: AppBar(
        title: CText(widget.title ?? 'Lecture', type: TextType.titleMedium),
        actions: [
          if (!_isLoading)
            IconButton(
              tooltip: 'Reload',
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
            ),
          if (_probeLogs.isNotEmpty || _errorMessage != null)
            IconButton(
              tooltip: 'Copy diagnostics',
              onPressed: _copyDiagnostics,
              icon: const Icon(Icons.content_copy),
            ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _isLoading
            ? _buildLoading()
            : chewie != null
                ? _buildPlayer(chewie)
                : _buildErrorState(),
      ),
    );
  }

  Widget _buildPlayer(ChewieController chewie) {
    return SafeArea(
      child: Container(
        color: Colors.black,
        alignment: Alignment.center,
        child: Chewie(controller: chewie),
      ),
    );
  }

  Widget _buildLoading() {
    final String message =
        _isFetchingLink ? 'Requesting video link...' : 'Preparing player...';
    return SafeArea(
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            AppSpacing.verticalSpaceSmall,
            CText(message, type: TextType.bodyMedium),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    final diagnosticsCards = _probeLogs
        .map((log) => _DiagnosticsCard(
              title: log.method,
              details: log.summary(),
            ))
        .toList();

    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            CText(
              _errorMessage ?? 'Unable to load video',
              type: TextType.bodyMedium,
              textAlign: TextAlign.center,
            ),
            AppSpacing.verticalSpaceAverage,
            ElevatedButton.icon(
              onPressed: _retry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
            if (_activeUrl != null && _activeUrl!.isNotEmpty) ...[
              AppSpacing.verticalSpaceLarge,
              _DiagnosticsRow(label: 'Current URL', value: _activeUrl!),
            ],
            if (_activeHeaders != null && _activeHeaders!.isNotEmpty) ...[
              AppSpacing.verticalSpaceSmall,
              _DiagnosticsRow(
                label: 'Applied headers',
                value: _activeHeaders!.entries
                    .map((entry) => '${entry.key}: ${entry.value}')
                    .join('\n'),
              ),
            ],
            if (diagnosticsCards.isNotEmpty) ...[
              AppSpacing.verticalSpaceLarge,
              CText(
                'Probe attempts',
                type: TextType.bodySmall,
                color: AppColors.gray600,
              ),
              AppSpacing.verticalSpaceSmall,
              ...diagnosticsCards,
            ],
          ],
        ),
      ),
    );
  }

  bool _mapEquals(Map<String, String>? a, Map<String, String>? b) {
    if (a == null && b == null) {
      return true;
    }
    if (a == null || b == null || a.length != b.length) {
      return false;
    }
    for (final key in a.keys) {
      if (a[key] != b[key]) {
        return false;
      }
    }
    return true;
  }
}

class _PlaybackSource {
  _PlaybackSource({
    required this.url,
    required this.headers,
    required this.probeLogs,
  });

  final Uri url;
  final Map<String, String>? headers;
  final List<_ProbeLog> probeLogs;
}

class _WatchLinkResult {
  _WatchLinkResult({
    required this.url,
    this.headers,
  });

  final String url;
  final Map<String, String>? headers;
}

class _ProbeLog {
  _ProbeLog({
    required this.method,
    this.statusCode,
    this.message,
    this.duration,
    this.finalUri,
    this.errorType,
  });

  final String method;
  final int? statusCode;
  final String? message;
  final Duration? duration;
  final Uri? finalUri;
  final String? errorType;

  String summary() {
    final buffer = StringBuffer()..write(method);
    if (statusCode != null) {
      buffer.write(' -> $statusCode');
    }
    if (message != null && message!.isNotEmpty) {
      buffer.write(' ($message)');
    }
    if (duration != null) {
      buffer.write(' in ${duration!.inMilliseconds} ms');
    }
    if (finalUri != null && finalUri.toString() != finalUri!.origin) {
      buffer.write(' -> ${finalUri.toString()}');
    }
    if (errorType != null) {
      buffer.write(' [$errorType]');
    }
    return buffer.toString();
  }
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
          CText(label, type: TextType.bodySmall, color: AppColors.gray600),
          AppSpacing.verticalSpaceSmall,
          SelectableText(
            value,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}

class _DiagnosticsCard extends StatelessWidget {
  const _DiagnosticsCard({
    required this.title,
    required this.details,
  });

  final String title;
  final String details;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SelectableText(
              title,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            AppSpacing.verticalSpaceSmall,
            SelectableText(details,
                style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}
