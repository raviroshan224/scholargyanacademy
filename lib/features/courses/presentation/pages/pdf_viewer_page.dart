import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class PdfViewerScreen extends StatefulWidget {
  final String pdfUrl;
  final String fileName;
  final String? title;
  final Map<String, String>? headers;
  final Dio? dio;

  const PdfViewerScreen({
    super.key,
    required this.pdfUrl,
    required this.fileName,
    this.title,
    this.headers,
    this.dio,
  });

  @override
  State<PdfViewerScreen> createState() => _PdfViewerScreenState();
}

class _PdfViewerScreenState extends State<PdfViewerScreen> {
  PdfController? _pdfController;
  File? _tempFile;
  late final Dio _dio;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _dio = widget.dio ??
        Dio(
          BaseOptions(
            responseType: ResponseType.bytes,
            connectTimeout: const Duration(seconds: 30),
            receiveTimeout: const Duration(seconds: 30),
            headers: widget.headers,
          ),
        );
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadAndOpenPdf());
  }

  Future<void> _loadAndOpenPdf({bool userInitiated = false}) async {
    if (!mounted) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    var downloadSucceeded = false;

    try {
      final response = await _dio.get<List<int>>(
        widget.pdfUrl,
        options: Options(
          responseType: ResponseType.bytes,
          headers: widget.headers ?? const <String, dynamic>{},
          extra: const {'requiresAuth': false},
          followRedirects: true,
        ),
      );

      final data = response.data;
      if (data == null || data.isEmpty) {
        throw const PdfLoadException('Empty PDF response');
      }

      final bytes = Uint8List.fromList(data);
      final tempDir = await getTemporaryDirectory();
      final tempPath =
          '${tempDir.path}/${DateTime.now().microsecondsSinceEpoch}_${widget.fileName}';
      final tempFile = File(tempPath);
      await tempFile.writeAsBytes(bytes, flush: true);

      final controller = PdfController(
        document: PdfDocument.openFile(tempFile.path),
      );

      if (!mounted) {
        controller.dispose();
        try {
          tempFile.deleteSync();
        } catch (_) {}
        return;
      }

      _pdfController?.dispose();
      if (_tempFile != null) {
        try {
          if (_tempFile!.existsSync()) {
            _tempFile!.deleteSync();
          }
        } catch (_) {}
      }

      setState(() {
        _tempFile = tempFile;
        _pdfController = controller;
      });
      downloadSucceeded = true;
    } on DioException catch (dioError) {
      _setError(
          'Failed to download PDF (${dioError.response?.statusCode ?? ''})');
    } on PdfLoadException catch (e) {
      _setError(e.message);
    } catch (_) {
      _setError('Unable to open PDF');
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        if (userInitiated && downloadSucceeded && _errorMessage == null) {
          _showSnackBar('PDF cached for offline use.');
        }
      }
    }
  }

  void _setError(String message) {
    if (!mounted) return;
    setState(() {
      _errorMessage = message;
    });
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    _pdfController?.dispose();
    if (_tempFile != null && _tempFile!.existsSync()) {
      try {
        _tempFile!.deleteSync();
      } catch (_) {}
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.title ?? widget.fileName;
    return Scaffold(
      appBar: AppBar(
        title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
        actions: [
          IconButton(
            tooltip: 'Cache PDF',
            onPressed:
                _isLoading ? null : () => _loadAndOpenPdf(userInitiated: true),
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.download),
          ),
        ],
      ),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 250),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _loadAndOpenPdf,
                child: const Text('Try again'),
              ),
            ],
          ),
        ),
      );
    }

    if (_pdfController == null) {
      return const Center(child: Text('PDF unavailable'));
    }

    return PdfView(
      controller: _pdfController!,
      scrollDirection: Axis.vertical,
      pageSnapping: false,
      physics: const BouncingScrollPhysics(),
      onDocumentError: (error) {
        _setError('Failed to render PDF: $error');
      },
      builders: PdfViewBuilders<DefaultBuilderOptions>(
        options: const DefaultBuilderOptions(),
        documentLoaderBuilder: (_) => const Center(
          child: CircularProgressIndicator(),
        ),
        pageLoaderBuilder: (_) => const Center(
          child: CircularProgressIndicator(strokeWidth: 1.4),
        ),
        errorBuilder: (_, error) => Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text('Page render error: $error'),
          ),
        ),
      ),
    );
  }
}

class PdfLoadException implements Exception {
  final String message;
  const PdfLoadException(this.message);

  @override
  String toString() => message;
}
