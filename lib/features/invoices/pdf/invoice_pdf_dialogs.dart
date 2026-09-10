import 'package:flutter/material.dart';

import '../../schedule/order_model.dart';
import '../invoice_model.dart';
import 'invoice_pdf_download.dart';
import 'invoice_pdf_export_service.dart';

class InvoicePdfExportHelper {
  static Future<void> exportWithModalProgress({
    required BuildContext context,
    required InvoiceRecord invoice,
    SaveInvoiceInput? currentInput,
    OrderanSewa? order,
  }) async {
    NavigatorState? progressNavigator;
    var progressDialogClosed = false;

    // 1. Tampilkan Progress Modal Dialog persis seperti di mgrs_flutter
    final progressDialog = showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        progressNavigator = Navigator.of(dialogContext);
        return PopScope(
          canPop: false,
          child: Dialog(
            key: const Key('invoice-pdf-progress-dialog'),
            insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            backgroundColor: Colors.white,
            elevation: 8,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: SizedBox(
              width: 320,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: <Widget>[
                    Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: Color(0xFFF4F4F5),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: const SizedBox(
                        key: Key('invoice-pdf-progress-indicator'),
                        width: 28,
                        height: 28,
                        child: CircularProgressIndicator(
                          color: Color(0xFF18181B),
                          strokeWidth: 2.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Text(
                      'Mengekspor PDF...',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF18181B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      invoice.invoiceReference,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF71717A),
                      ),
                    ),
                    const Text(
                      'sedang diproses',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        color: Color(0xFFA1A1AA),
                      ),
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        key: const Key('invoice-pdf-progress-action'),
                        onPressed: null,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(42),
                          backgroundColor: const Color(0xFFF4F4F5),
                          disabledBackgroundColor: const Color(0xFFF4F4F5),
                          disabledForegroundColor: const Color(0xFFA1A1AA),
                          shape: const StadiumBorder(),
                        ),
                        child: const Text(
                          'Memproses...',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
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
      final fileLocation = await downloadInvoicePdf(result.bytes, result.fileName);

      // Tutup dialog progress
      if (progressNavigator?.mounted ?? false) {
        progressNavigator!.pop();
        await progressDialog;
        progressDialogClosed = true;
      }

      if (!context.mounted) return;

      // 2. Tampilkan Success Dialog persis seperti di mgrs_flutter
      await showInvoicePdfSuccessDialog(
        context: context,
        invoice: invoice,
        fileLocation: fileLocation,
        fileName: result.fileName,
      );
    } catch (e) {
      // Tutup dialog progress jika masih terbuka
      if (!progressDialogClosed && (progressNavigator?.mounted ?? false)) {
        progressNavigator!.pop();
        await progressDialog;
        progressDialogClosed = true;
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal mengekspor PDF: $e'),
          backgroundColor: const Color(0xFF9F2F2D),
          duration: const Duration(seconds: 4),
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
  }) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PopScope(
        canPop: false,
        child: Dialog(
          key: const Key('invoice-pdf-success-dialog'),
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          backgroundColor: Colors.white,
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          child: SizedBox(
            width: 320,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: <Widget>[
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      color: Color(0xFFEDF3EC),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      Icons.check_rounded,
                      key: Key('invoice-pdf-success-icon'),
                      size: 28,
                      color: Color(0xFF346538),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Text(
                    'Sukses',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18181B),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    invoice.invoiceReference,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF71717A),
                    ),
                  ),
                  const Text(
                    'Berhasil Export PDF',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      color: Color(0xFF346538),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: <Widget>[
                      Expanded(
                        child: FilledButton(
                          key: const Key('invoice-pdf-open-action'),
                          onPressed: fileLocation == null
                              ? null
                              : () async {
                                  await openInvoicePdf(fileLocation);
                                },
                          style: FilledButton.styleFrom(
                            minimumSize: const Size.fromHeight(42),
                            backgroundColor: const Color(0xFF18181B),
                            foregroundColor: Colors.white,
                            shape: const StadiumBorder(),
                          ),
                          child: const Text(
                            'Buka File',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _InvoicePdfCircleAction(
                        key: const Key('invoice-pdf-share-action'),
                        icon: Icons.share_rounded,
                        label: 'Bagikan PDF invoice',
                        backgroundColor: const Color(0xFF346538),
                        onPressed: fileLocation == null
                            ? null
                            : () async {
                                await shareInvoicePdf(
                                  fileLocation,
                                  fileName ?? invoice.invoiceReference,
                                );
                              },
                      ),
                      const SizedBox(width: 8),
                      _InvoicePdfCircleAction(
                        key: const Key('invoice-pdf-close-action'),
                        icon: Icons.close_rounded,
                        label: 'Tutup dialog export PDF',
                        backgroundColor: const Color(0xFF9F2F2D),
                        onPressed: () => Navigator.of(dialogContext).pop(),
                      ),
                    ],
                  ),
                ],
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
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String label;
  final Color backgroundColor;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Tooltip(
        message: label,
        child: IconButton(
          onPressed: onPressed,
          icon: Icon(icon, color: Colors.white, size: 18),
          style: IconButton.styleFrom(
            minimumSize: const Size(42, 42),
            maximumSize: const Size(42, 42),
            backgroundColor: backgroundColor,
            disabledBackgroundColor: const Color(0xFFE4E4E7),
            disabledForegroundColor: Colors.white,
            shape: const CircleBorder(),
          ),
        ),
      );
}
