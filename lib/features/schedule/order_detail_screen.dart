import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';
import '../invoices/invoice_builder_dialog.dart';
import '../invoices/invoice_model.dart';
import '../invoices/quick_payment_dialog.dart';
import 'order_model.dart';
import 'unit_allocation_card.dart';

OperationalColors _operationalColors(BuildContext context) =>
    Theme.of(context).extension<OperationalColors>() ??
    const OperationalColors(
      success: AppTokens.successSurface,
      onSuccess: AppTokens.success,
      warning: AppTokens.warningSurface,
      onWarning: AppTokens.warning,
      danger: AppTokens.dangerSurface,
      onDanger: AppTokens.danger,
    );

class OrderDetailScreen extends StatefulWidget {
  const OrderDetailScreen({
    super.key,
    this.order,
    this.orderId,
    this.gateway,
    this.user,
  });

  final OrderanSewa? order;
  final String? orderId;
  final MaintenanceGateway? gateway;
  final UserProfile? user;

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  OrderanSewa? _order;
  InvoiceRecord? _invoice;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    if (widget.order != null) {
      _order = widget.order;
    } else if (widget.orderId != null && widget.gateway != null) {
      _loadOrderDetail();
    } else {
      _order = const OrderanSewa(
        id: 'ORD-2026-088',
        namaEvent: 'Event Pertamina JCC',
        namaClient: 'PT Pertamina (Persero)',
        alamat: 'JCC Senayan, Hall B – Jakarta',
        jumlahUnit: 4,
        nomorWhatsapp: '081234567890',
        linkGmaps: 'https://maps.google.com/?q=JCC+Senayan',
      );
    }
    if (widget.gateway != null) _loadInvoice();
  }

  Future<void> _loadInvoice() async {
    if (widget.gateway == null) return;
    final primaryId = _order?.id ?? widget.orderId;
    final businessId = _order?.orderanId;
    if (primaryId == null && businessId == null) return;
    try {
      var invoice = primaryId == null
          ? null
          : await widget.gateway!.fetchInvoiceByOrderanId(primaryId);
      if (invoice == null && businessId != null && businessId != primaryId) {
        invoice = await widget.gateway!.fetchInvoiceByOrderanId(businessId);
      }
      if (mounted && invoice != null) setState(() => _invoice = invoice);
    } catch (_) {}
  }

  Future<void> _loadOrderDetail() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final fetched = await widget.gateway!.fetchOrderDetail(widget.orderId!);
      if (mounted) {
        setState(() {
          _order = fetched;
          _isLoading = false;
        });
        _loadInvoice();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _error =
              'Detail orderan belum dapat dimuat. Silakan periksa koneksi lalu coba lagi.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: SafeArea(
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _error != null
            ? _buildErrorState(context)
            : Column(
                children: [
                  Expanded(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(AppTokens.space16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildTopBar(context),
                          const SizedBox(height: AppTokens.space16),
                          _buildOrderHeaderCard(context),
                          const SizedBox(height: AppTokens.space16),
                          _buildVenueCard(context),
                          if (widget.gateway != null && _order != null) ...[
                            const SizedBox(height: AppTokens.space16),
                            UnitAllocationCard(
                              gateway: widget.gateway!,
                              order: _order!,
                              isEditable:
                                  (widget.user?.isTechnician == true ||
                                      widget.user?.isAdmin == true) &&
                                  !_order!.isCompletedOrCancelled,
                            ),
                          ],
                          const SizedBox(height: AppTokens.space16),
                          _buildCustomerCard(context),
                          const SizedBox(height: AppTokens.space16),
                          _buildEventNotesCard(context),
                          const SizedBox(height: AppTokens.space16),
                          _buildInvoiceCard(context),
                          const SizedBox(height: AppTokens.space24),
                        ],
                      ),
                    ),
                  ),
                  _buildBottomCta(context),
                ],
              ),
      ),
    );
  }

  Widget _buildErrorState(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
            const SizedBox(height: AppTokens.space12),
            Text(
              _error!,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTokens.space12),
            OutlinedButton(
              onPressed: _loadOrderDetail,
              child: const Text('Coba Lagi'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    final canManage =
        widget.user?.canManageOrders == true &&
        _order != null &&
        !_order!.isCompletedOrCancelled;
    return Row(
      children: [
        IconButton(
          tooltip: 'Kembali',
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.chevron_left_rounded),
        ),
        Expanded(
          child: Text('Detail Orderan', style: theme.textTheme.headlineSmall),
        ),
        if (canManage)
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) {
              if (value == 'cancel_order') _showCancelOrderDialog();
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'cancel_order',
                child: Row(
                  children: [
                    Icon(Icons.cancel_outlined),
                    SizedBox(width: AppTokens.space8),
                    Text('Batalkan Order'),
                  ],
                ),
              ),
            ],
          )
        else
          const SizedBox(width: AppTokens.minTouchTarget),
      ],
    );
  }

  Widget _buildOrderHeaderCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = _operationalColors(context);
    final order = _order;
    final done = order?.statusOrderan?.toLowerCase() == 'selesai';
    final cancelled = order?.isCancelled ?? false;
    final statusSurface = cancelled
        ? operational.danger
        : done
        ? operational.success
        : colors.surfaceContainer;
    final statusInk = cancelled
        ? operational.onDanger
        : done
        ? operational.onSuccess
        : colors.onSurfaceVariant;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    order?.displayCode ?? 'ORD-2026-088',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                if (order != null)
                  Chip(
                    label: Text(
                      cancelled
                          ? 'Dibatalkan'
                          : done
                          ? 'Selesai'
                          : 'Aktif',
                    ),
                    backgroundColor: statusSurface,
                    labelStyle: theme.textTheme.labelMedium?.copyWith(
                      color: statusInk,
                    ),
                    side: BorderSide(color: statusInk),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              'Nama Event: ${order?.namaEvent ?? '-'}',
              style: theme.textTheme.bodyLarge,
            ),
            if (cancelled) ...[
              const SizedBox(height: AppTokens.space12),
              _semanticBanner(
                context,
                icon: Icons.cancel_rounded,
                surface: operational.danger,
                ink: operational.onDanger,
                title: 'Orderan Ini Telah Dibatalkan',
                detail: order?.cancellationReason == null
                    ? null
                    : 'Alasan: ${order!.cancellationReason}',
              ),
            ],
            const Padding(
              padding: EdgeInsets.symmetric(vertical: AppTokens.space16),
              child: Divider(),
            ),
            Row(
              children: [
                Expanded(
                  child: _metric(
                    context,
                    'Pemasangan',
                    order?.formattedDate ?? 'Jadwal belum ditentukan',
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: _metric(
                    context,
                    'Durasi Sewa',
                    order?.durasiSewaText ?? '1 Hari',
                  ),
                ),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: _metric(
                    context,
                    'Kebutuhan',
                    '${order?.jumlahUnit ?? 4} Unit',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(BuildContext context, String label, String value) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: theme.textTheme.labelMedium),
        const SizedBox(height: AppTokens.space4),
        Text(value, style: theme.textTheme.titleMedium),
      ],
    );
  }

  Widget _buildVenueCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final order = _order;
    final hasMaps = order?.linkGmaps?.trim().isNotEmpty == true;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Lokasi Acara',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                if (hasMaps)
                  OutlinedButton.icon(
                    onPressed: () async {
                      final ok = await order!.launchMaps();
                      if (!ok && context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Peta lokasi acara tidak dapat dibuka.',
                            ),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.near_me_rounded),
                    label: const Text('Petunjuk Arah'),
                  ),
              ],
            ),
            const SizedBox(height: AppTokens.space12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.location_on_rounded, color: colors.onSurfaceVariant),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: Text(
                    order?.alamat ?? 'Lokasi acara belum dicatat',
                    style: theme.textTheme.bodyLarge,
                  ),
                ),
              ],
            ),
            if (hasMaps) ...[
              const SizedBox(height: AppTokens.space12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => order!.launchMaps(),
                  icon: const Icon(Icons.map_rounded),
                  label: const Text('Buka di Google Maps'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final order = _order;
    final hasWhatsapp = order?.cleanWhatsapp.isNotEmpty == true;
    final customerName = order?.namaClient?.trim().isNotEmpty == true
        ? order!.namaClient!.trim()
        : order?.namaPic?.trim().isNotEmpty == true
        ? order!.namaPic!.trim()
        : 'Pemesan';
    final phone = order?.nomorWhatsapp?.trim().isNotEmpty == true
        ? order!.nomorWhatsapp!.trim()
        : 'Nomor WhatsApp belum tersedia';
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Row(
          children: [
            CircleAvatar(
              backgroundColor: colors.surfaceContainer,
              child: Text(customerName.substring(0, 1).toUpperCase()),
            ),
            const SizedBox(width: AppTokens.space12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(customerName, style: theme.textTheme.titleMedium),
                  Text(phone, style: theme.textTheme.bodyMedium),
                ],
              ),
            ),
            if (hasWhatsapp)
              IconButton(
                tooltip: 'WhatsApp',
                onPressed: () => order!.launchWhatsApp(),
                icon: const Icon(Icons.chat_bubble_rounded),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventNotesCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final note = _order?.cleanNote ?? '';
    return Card(
      color: colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit_note_rounded, color: colors.onSurfaceVariant),
                const SizedBox(width: AppTokens.space8),
                Text('Catatan Orderan', style: theme.textTheme.titleMedium),
              ],
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              note.isEmpty
                  ? 'Tidak ada catatan khusus untuk orderan ini.'
                  : note,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: note.isEmpty ? colors.onSurfaceVariant : null,
                fontStyle: note.isEmpty ? FontStyle.italic : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _semanticBanner(
    BuildContext context, {
    required IconData icon,
    required Color surface,
    required Color ink,
    required String title,
    String? detail,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.space12),
      color: surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ink),
          const SizedBox(width: AppTokens.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleMedium?.copyWith(color: ink),
                ),
                if (detail != null)
                  Text(
                    detail,
                    style: theme.textTheme.bodyMedium?.copyWith(color: ink),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _markAsCompleted() async {
    final order = _order;
    if (order == null) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Selesaikan Orderan?'),
        content: Text(
          'Apakah event "${order.namaEvent}" sudah selesai dan unit blower siap kembali?\nStatus orderan akan diubah menjadi Selesai.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ya, Selesaikan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
    try {
      await widget.gateway?.updateOrderStatus(
        order.orderanId ?? order.id,
        'Selesai',
      );
      if (!mounted) return;
      setState(() => _order = order.copyWith(statusOrderan: 'Selesai'));
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Orderan berhasil ditandai selesai.')),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failureMessage(error))));
      }
    }
  }

  Future<void> _showCancelOrderDialog() async {
    final order = _order;
    if (order == null) return;

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _CancelOrderDialog(order: order, invoice: _invoice),
    );
    if (reason == null || !mounted) return;

    try {
      final orderanId = order.id.isNotEmpty
          ? order.id
          : (order.orderanId ?? widget.orderId ?? '');
      await widget.gateway?.cancelOrder(
        orderanId,
        reason: reason,
        cancelInvoice: true,
      );
      if (!mounted) return;
      final currentNote = order.catatanOrderan ?? '';
      final cancelTag = '[BATAL: $reason]';
      final updatedNote = currentNote.isNotEmpty
          ? '$currentNote\n$cancelTag'
          : cancelTag;
      setState(() {
        _order = order.copyWith(
          statusOrderan: 'Dibatalkan',
          catatanOrderan: updatedNote,
        );
        if (_invoice != null &&
            (!_invoice!.isPaid || _invoice!.paidAmount <= 0)) {
          _invoice = null;
        }
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Orderan berhasil dibatalkan dan invoice terkait telah dihapus.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(failureMessage(error))));
      }
    }
  }

  Widget _buildBottomCta(BuildContext context) {
    final order = _order;
    final canComplete =
        widget.user?.canManageOrders == true &&
        order != null &&
        !order.isCompletedOrCancelled;
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: canComplete
              ? Row(
                  children: [
                    Expanded(
                      child: FilledButton.icon(
                        onPressed: _markAsCompleted,
                        icon: const Icon(Icons.check_circle_rounded),
                        label: const Text('Tandai Selesai'),
                      ),
                    ),
                    const SizedBox(width: AppTokens.space8),
                    Expanded(child: _buildWhatsappButton(order)),
                  ],
                )
              : _buildWhatsappButton(order),
        ),
      ),
    );
  }

  Widget _buildWhatsappButton(OrderanSewa? order) {
    final colors = Theme.of(context).colorScheme;
    return OutlinedButton.icon(
      onPressed: () async {
        if (order != null && order.cleanWhatsapp.isNotEmpty) {
          final ok = await order.launchWhatsApp();
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Tidak dapat membuka WhatsApp.')),
            );
          }
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Nomor WhatsApp pemesan belum terdaftar.'),
            ),
          );
        }
      },
      icon: const Icon(Icons.chat_rounded),
      label: const Text('Hubungi Pemesan'),
      style: OutlinedButton.styleFrom(foregroundColor: colors.onSurface),
    );
  }

  Widget _buildInvoiceCard(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final operational = _operationalColors(context);
    final invoice = _invoice;
    final isPaid = invoice?.isPaid ?? false;
    final isDp = invoice?.isDp ?? false;
    final isCancelled = invoice?.isCancelled ?? false;
    final statusSurface = isPaid
        ? operational.success
        : isDp
        ? operational.warning
        : isCancelled
        ? colors.surfaceContainer
        : operational.danger;
    final statusInk = isPaid
        ? operational.onSuccess
        : isDp
        ? operational.onWarning
        : isCancelled
        ? colors.onSurfaceVariant
        : operational.onDanger;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Invoice Terkait',
                    style: theme.textTheme.titleMedium,
                  ),
                ),
                Chip(
                  label: Text(invoice?.paymentStatusDisplay ?? 'Belum Ada'),
                  backgroundColor: invoice == null
                      ? colors.surfaceContainer
                      : statusSurface,
                  labelStyle: theme.textTheme.labelMedium?.copyWith(
                    color: invoice == null
                        ? colors.onSurfaceVariant
                        : statusInk,
                  ),
                  side: BorderSide(
                    color: invoice == null ? colors.outline : statusInk,
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              invoice == null
                  ? 'Lihat atau terbitkan invoice resmi untuk orderan ini.'
                  : '${invoice.invoiceReference} • Total: ${invoice.totalAmountFormatted}${invoice.remainingAmount > 0 ? ' (Sisa: ${invoice.remainingAmountFormatted})' : ''}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTokens.space12),
            if (invoice != null)
              Row(
                children: [
                  if (!isCancelled) ...[
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: widget.gateway == null
                            ? null
                            : () => showDialog<void>(
                                context: context,
                                builder: (_) => QuickPaymentDialog(
                                  invoice: invoice,
                                  gateway: widget.gateway!,
                                  onPaymentUpdated: (updated) =>
                                      setState(() => _invoice = updated),
                                ),
                              ),
                        icon: const Icon(Icons.payments_outlined),
                        label: const Text('Atur Bayar'),
                      ),
                    ),
                    const SizedBox(width: AppTokens.space8),
                  ],
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: widget.gateway == null
                          ? null
                          : () => showDialog<void>(
                              context: context,
                              builder: (_) => InvoiceBuilderDialog(
                                invoice: invoice,
                                gateway: widget.gateway!,
                                onSaved: (saved) =>
                                    setState(() => _invoice = saved),
                              ),
                            ),
                      icon: const Icon(Icons.receipt_long_rounded),
                      label: const Text('Buka Invoice'),
                    ),
                  ),
                ],
              )
            else if (widget.gateway != null &&
                _order != null &&
                !_order!.isCancelled)
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _createInvoice,
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Terbitkan Invoice untuk Order Ini'),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _createInvoice() async {
    final order = _order;
    final gateway = widget.gateway;
    if (order == null || gateway == null) return;
    final date = order.tanggalPemasangan ?? DateTime.now();
    final orderanId = order.orderanId ?? order.id;
    final codeSuffix = orderanId.split('-').last;
    final datePrefix = date
        .toIso8601String()
        .substring(0, 10)
        .replaceAll('-', '/');
    final quantity = order.jumlahUnit > 0 ? order.jumlahUnit : 1;
    final days = order.rentalDays > 0 ? order.rentalDays : 1;
    const unitPrice = 250000;
    final subtotal = quantity * unitPrice;
    final payload = <String, Object?>{
      'orderan_id': orderanId,
      'invoice_reference': 'INV/$datePrefix-$codeSuffix',
      'invoice_date': date.toIso8601String().substring(0, 10),
      'due_date': date
          .add(const Duration(days: 7))
          .toIso8601String()
          .substring(0, 10),
      'product_name': order.namaEvent.isNotEmpty
          ? order.namaEvent
          : 'Sewa Mistyfan',
      'quantity': quantity,
      'rental_days': days,
      'unit_price': unitPrice,
      'subtotal': subtotal,
      'total_amount': subtotal * days,
      'paid_amount': 0,
      'payment_status': 'unpaid',
      'invoice_source': 'order',
      'customer_name': order.namaClient,
      'customer_phone': order.nomorWhatsapp ?? '',
    };
    try {
      final created = await gateway.createInvoice(payload);
      if (mounted) setState(() => _invoice = created);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal membuat invoice: $error')),
        );
      }
    }
  }
}

class _CancelOrderDialog extends StatefulWidget {
  const _CancelOrderDialog({required this.order, required this.invoice});

  final OrderanSewa order;
  final InvoiceRecord? invoice;

  @override
  State<_CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<_CancelOrderDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  Widget _buildBanner(
    BuildContext context, {
    required IconData icon,
    required Color surface,
    required Color ink,
    required String title,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(AppTokens.space12),
      color: surface,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: ink),
          const SizedBox(width: AppTokens.space8),
          Expanded(
            child: Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(color: ink),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final invoice = widget.invoice;
    final hasPayment = invoice != null && invoice.paidAmount > 0;
    final hasUnpaidInvoice =
        invoice != null && !invoice.isPaid && !invoice.isCancelled;
    final operational = _operationalColors(context);
    return AlertDialog(
      title: const Text('Batalkan Orderan?'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Event "${widget.order.namaEvent}" (${widget.order.displayCode}) akan dibatalkan dan dihapus dari jadwal aktif pemasangan.',
              ),
              const SizedBox(height: AppTokens.space12),
              if (hasPayment) ...[
                _buildBanner(
                  context,
                  icon: Icons.warning_amber_rounded,
                  surface: operational.warning,
                  ink: operational.onWarning,
                  title:
                      'Perhatian: Invoice memiliki pembayaran tercatat sebesar ${invoice.paidAmountFormatted}. Pastikan penyelesaian refund atau koordinasi dana dilakukan.',
                ),
                const SizedBox(height: AppTokens.space12),
              ] else if (hasUnpaidInvoice) ...[
                _buildBanner(
                  context,
                  icon: Icons.info_outline_rounded,
                  surface: Theme.of(context).colorScheme.surfaceContainer,
                  ink: Theme.of(context).colorScheme.onSurfaceVariant,
                  title:
                      'Invoice terkait (${invoice.invoiceReference}) yang belum dibayar akan otomatis dibatalkan.',
                ),
                const SizedBox(height: AppTokens.space12),
              ],
              TextFormField(
                controller: _reasonController,
                autofocus: true,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Alasan Pembatalan *',
                  hintText: 'Contoh: Acara dibatalkan oleh pihak klien',
                ),
                validator: (value) => value == null || value.trim().length < 3
                    ? 'Alasan pembatalan minimal 3 karakter.'
                    : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Kembali'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState?.validate() == true) {
              Navigator.pop(context, _reasonController.text.trim());
            }
          },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.surface,
            foregroundColor: Theme.of(context).colorScheme.error,
            side: BorderSide(color: Theme.of(context).colorScheme.error),
          ),
          child: const Text('Ya, Batalkan Order'),
        ),
      ],
    );
  }
}
