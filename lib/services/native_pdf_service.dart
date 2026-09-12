import 'dart:io' show Platform, Process;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/services.dart';

/// Centralized service to interact with native platform PDF capabilities:
/// - iOS: QuickLook QLPreviewController & UIActivityViewController
/// - Android: Intent.ACTION_VIEW & Intent.ACTION_SEND via FileProvider
class NativePdfService {
  NativePdfService({MethodChannel? channel, this.isNativePlatform})
    : _channel = channel ?? const MethodChannel('mgrs/native_pdf');

  final MethodChannel _channel;
  final bool? isNativePlatform;

  bool get _useNativeChannel =>
      isNativePlatform ?? (!kIsWeb && (Platform.isIOS || Platform.isAndroid));

  // Lock to prevent concurrent/multiple presentations from rapid user taps
  bool _isBusy = false;

  static final NativePdfService instance = NativePdfService();

  /// Opens the PDF using native previewer (iOS QLPreviewController, Android Intent.ACTION_VIEW)
  Future<void> previewPdf(String filePath) async {
    final cleanPath = filePath.trim();
    if (cleanPath.isEmpty) {
      throw const NativePdfException(
        code: 'EMPTY_PATH',
        message: 'Path file PDF tidak boleh kosong.',
      );
    }

    if (_isBusy) return;
    _isBusy = true;

    try {
      if (kIsWeb) {
        throw const NativePdfException(
          code: 'UNSUPPORTED_PLATFORM',
          message: 'Native preview tidak didukung di web browser.',
        );
      }

      if (_useNativeChannel) {
        await _channel.invokeMethod<void>('previewPdf', {'path': cleanPath});
        return;
      }

      // Desktop fallback (Windows/macOS/Linux)
      await _openDesktopFallback(cleanPath);
    } on PlatformException catch (e) {
      throw NativePdfException(
        code: e.code,
        message: _mapPlatformErrorMessage(e),
        details: e.details,
      );
    } finally {
      // Small debounce delay before unlocking
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _isBusy = false;
    }
  }

  /// Opens the native share sheet with the PDF file as an attachment
  Future<void> sharePdf(String filePath, {String? title}) async {
    final cleanPath = filePath.trim();
    if (cleanPath.isEmpty) {
      throw const NativePdfException(
        code: 'EMPTY_PATH',
        message: 'Path file PDF tidak boleh kosong.',
      );
    }

    if (_isBusy) return;
    _isBusy = true;

    try {
      if (kIsWeb) {
        throw const NativePdfException(
          code: 'UNSUPPORTED_PLATFORM',
          message: 'Native share sheet tidak didukung di web browser.',
        );
      }

      if (_useNativeChannel) {
        await _channel.invokeMethod<void>('sharePdf', {
          'path': cleanPath,
          if (title != null && title.trim().isNotEmpty) 'title': title.trim(),
        });
        return;
      }

      // Desktop fallback: Open preview
      await _openDesktopFallback(cleanPath);
    } on PlatformException catch (e) {
      throw NativePdfException(
        code: e.code,
        message: _mapPlatformErrorMessage(e),
        details: e.details,
      );
    } finally {
      await Future<void>.delayed(const Duration(milliseconds: 400));
      _isBusy = false;
    }
  }

  Future<void> _openDesktopFallback(String path) async {
    try {
      if (Platform.isWindows) {
        await Process.run('cmd', ['/c', 'start', '', path], runInShell: true);
      } else if (Platform.isMacOS) {
        await Process.run('open', [path]);
      } else if (Platform.isLinux) {
        await Process.run('xdg-open', [path]);
      }
    } catch (e) {
      throw NativePdfException(
        code: 'OPEN_FAILED',
        message: 'Gagal membuka file PDF di desktop: $e',
      );
    }
  }

  String _mapPlatformErrorMessage(PlatformException e) {
    switch (e.code) {
      case 'FILE_NOT_FOUND':
        return 'File PDF tidak ditemukan di perangkat.';
      case 'NOT_A_PDF':
        return 'Format file bukan dokumen PDF yang valid.';
      case 'NO_PDF_APP':
        return 'Tidak ada aplikasi pembuka PDF di perangkat ini. Silakan pasang Google PDF Viewer atau aplikasi sejenis.';
      case 'ALREADY_PRESENTING':
        return 'Tampilan preview sedang dibuka.';
      case 'PREVIEW_FAILED':
        return e.message ?? 'Gagal membuka pratinjau PDF.';
      case 'SHARE_FAILED':
        return e.message ?? 'Gagal membagikan dokumen PDF.';
      default:
        return e.message ?? 'Terjadi kesalahan pada layanan PDF native.';
    }
  }
}

class NativePdfException implements Exception {
  const NativePdfException({
    required this.code,
    required this.message,
    this.details,
  });

  final String code;
  final String message;
  final Object? details;

  @override
  String toString() => message;
}
