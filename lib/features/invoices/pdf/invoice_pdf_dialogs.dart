import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';

import '../../../app/app_theme.dart';
import '../../schedule/order_model.dart';
import '../invoice_model.dart';
import 'invoice_pdf_download.dart';
import 'invoice_pdf_export_service.dart';
import '../../../services/native_pdf_service.dart';

class InvoicePdfExportHelper {
  static Future<void> exportWithModalProgress({
    required BuildContext context,
    required InvoiceRecord invoice,
    SaveInvoiceInput? currentInput,
    OrderanSewa? order,
  }) async {
    NavigatorState? progressNavigator;
    var progressDialogClosed = false;

    final progressDialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        progressNavigator = Navigator.of(dialogContext);
        final theme = Theme.of(dialogContext);
        return PopScope(
          canPop: false,
          child: Dialog(
            key: const Key('invoice-pdf-progress-dialog'),
            insetPadding: const EdgeInsets.symmetric(
              horizontal: AppTokens.space24,
              vertical: AppTokens.space24,
            ),
            child: SizedBox(
              width: 320,
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.space24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    SizedBox(
                      key: const Key('invoice-pdf-progress-indicator'),
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: theme.colorScheme.primary,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: AppTokens.space16),
                    Text(
                      'Mengekspor PDF...',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                    const SizedBox(height: AppTokens.space4),
                    Text(
                      invoice.invoiceReference,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium,
                    ),
                    Text(
                      'sedang diproses',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppTokens.space24),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('invoice-pdf-progress-action'),
                        onPressed: null,
                        child: const Text('Memproses...'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );

    await Future<void>.delayed(Duration.zero);
    if (!context.mounted) return;

    try {
      final service = InvoicePdfExportService();
      final payload = InvoicePdfPayload.fromInvoiceRecord(
        invoice,
        currentInput: currentInput,
        order: order,
      );
      final fileName = sanitizeInvoicePdfFileName(
        invoice.invoiceReference.replaceAll('/', '-'),
      );

      final result = await service.export(payload: payload, fileName: fileName);
      final fileLocation = await downloadInvoicePdf(
        result.bytes,
        result.fileName,
      );

      if (progressNavigator?.mounted ?? false) {
        progressNavigator!.pop();
        await progressDialog;
        progressDialogClosed = true;
      }

      if (!context.mounted) return;

      await showInvoicePdfSuccessDialog(
        context: context,
        invoice: invoice,
        fileLocation: fileLocation,
        fileName: result.fileName,
      );
    } catch (e) {
      if (!progressDialogClosed && (progressNavigator?.mounted ?? false)) {
        progressNavigator!.pop();
        await progressDialog;
        progressDialogClosed = true;
      }

      if (!context.mounted) return;
      final theme = Theme.of(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Gagal mengekspor PDF: $e',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onErrorContainer,
            ),
          ),
          backgroundColor: theme.colorScheme.errorContainer,
        ),
      );
    } finally {
      if (!progressDialogClosed && (progressNavigator?.mounted ?? false)) {
        progressNavigator!.pop();
        await progressDialog;
      }
    }
  }

  static Future<void> showInvoicePdfSuccessDialog({
    required BuildContext context,
    required InvoiceRecord invoice,
    String? fileLocation,
    String? fileName,
    NativePdfService? nativePdfService,
  }) async {
    final pdfService = nativePdfService ?? NativePdfService.instance;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          key: const Key('invoice-pdf-success-dialog'),
          insetPadding: const EdgeInsets.symmetric(
            horizontal: AppTokens.space24,
            vertical: AppTokens.space24,
          ),
          child: SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsets.all(AppTokens.space24),
              child: Builder(
                builder: (context) {
                  final theme = Theme.of(context);
                  final colors = theme.colorScheme;
                  final operational = theme.extension<OperationalColors>();
                  final successSurface =
                      operational?.success ?? colors.surfaceContainer;
                  final successInk = operational?.onSuccess ?? colors.onSurface;
                  final dangerSurface =
                      operational?.danger ?? colors.errorContainer;
                  final dangerInk =
                      operational?.onDanger ?? colors.onErrorContainer;
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: <Widget>[
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: successSurface,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Icon(
                          Icons.check_rounded,
                          key: const Key('invoice-pdf-success-icon'),
                          size: 28,
                          color: successInk,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space16),
                      Text(
                        'Sukses',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppTokens.space4),
                      Text(
                        invoice.invoiceReference,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodyMedium,
                      ),
                      Text(
                        'Berhasil Export PDF',
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: successInk,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppTokens.space16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(AppTokens.space12),
                        decoration: BoxDecoration(
                          color: colors.surfaceContainer,
                          borderRadius: BorderRadius.circular(
                            AppTokens.controlRadius,
                          ),
                          border: Border.all(color: colors.outlineVariant),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.folder_outlined,
                              size: 20,
                              color: colors.onSurfaceVariant,
                            ),
                            const SizedBox(width: AppTokens.space8),
                            Expanded(
                              child: Text(
                                _storageLocationDescription(),
                                style: theme.textTheme.bodySmall,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppTokens.space24),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: FilledButton(
                              key: const Key('invoice-pdf-open-action'),
                              onPressed: fileLocation == null
                                  ? null
                                  : () async {
                                      try {
                                        await pdfService.previewPdf(
                                          fileLocation,
                                        );
                                      } catch (e) {
                                        if (!dialogContext.mounted) return;
                                        ScaffoldMessenger.of(
                                          dialogContext,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              e.toString(),
                                              style: theme.textTheme.bodyMedium
                                                  ?.copyWith(
                                                    color:
                                                        colors.onErrorContainer,
                                                  ),
                                            ),
                                            backgroundColor:
                                                colors.errorContainer,
                                          ),
                                        );
                                      }
                                    },
                              child: const Text('Buka File'),
                            ),
                          ),
                          const SizedBox(width: AppTokens.space8),
                          _InvoicePdfCircleAction(
                            key: const Key('invoice-pdf-share-action'),
                            icon: Icons.share_rounded,
                            label: 'Bagikan PDF invoice',
                            backgroundColor:
                                operational?.success ?? colors.surfaceContainer,
                            iconColor:
                                operational?.onSuccess ?? colors.onSurface,
                            onPressed: fileLocation == null
                                ? null
                                : () async {
                                    try {
                                      await pdfService.sharePdf(
                                        fileLocation,
                                        title:
                                            fileName ??
                                            invoice.invoiceReference,
                                      );
                                    } catch (e) {
                                      if (!dialogContext.mounted) return;
                                      ScaffoldMessenger.of(
                                        dialogContext,
                                      ).showSnackBar(
                                        SnackBar(
                                          content: Text(
                                            e.toString(),
                                            style: theme.textTheme.bodyMedium
                                                ?.copyWith(
                                                  color:
                                                      colors.onErrorContainer,
                                                ),
                                          ),
                                          backgroundColor:
                                              colors.errorContainer,
                                        ),
                                      );
                                    }
                                  },
                          ),
                          const SizedBox(width: AppTokens.space8),
                          _InvoicePdfCircleAction(
                            key: const Key('invoice-pdf-close-action'),
                            icon: Icons.close_rounded,
                            label: 'Tutup dialog export PDF',
                            backgroundColor: dangerSurface,
                            iconColor: dangerInk,
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _InvoicePdfCircleAction extends StatelessWidget {
  const _InvoicePdfCircleAction({
    required this.icon,
    required this.label,
    required this.backgroundColor,
    required this.iconColor,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Tooltip(
      message: label,
      child: IconButton(
        onPressed: onPressed,
        icon: Icon(icon, color: iconColor, size: 20),
        style: IconButton.styleFrom(
          minimumSize: const Size.square(AppTokens.minTouchTarget),
          maximumSize: const Size.square(AppTokens.minTouchTarget),
          backgroundColor: backgroundColor,
          disabledBackgroundColor: colors.surfaceContainer,
          disabledForegroundColor: colors.onSurfaceVariant,
          shape: const CircleBorder(),
        ),
      ),
    );
  }
}

String _storageLocationDescription() {
  if (kIsWeb) return 'Tersimpan di Unduhan Browser';
  try {
    if (Platform.isIOS) return 'Tersimpan di Files > Di iPhone Saya > MGRS';
    if (Platform.isAndroid) return 'Tersimpan di Penyimpanan > Download > MGRS';
    if (Platform.isWindows) return 'Tersimpan di folder Downloads\\MGRS';
  } catch (_) {}
  return 'Tersimpan di folder Downloads/MGRS';
}
