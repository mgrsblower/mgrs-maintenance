import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../design_system/components/mgrs_button.dart';
import '../../design_system/components/mgrs_multiline_field.dart';
import '../../design_system/components/mgrs_status_badge.dart';
import '../../design_system/mgrs_tokens.dart';
import '../invoices/invoice_builder_dialog.dart';
import '../invoices/invoice_model.dart';
import '../invoices/quick_payment_dialog.dart';
import 'order_model.dart';
import 'unit_allocation_card.dart';

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
        tanggalPemasangan: null,
      );
    }
    if (widget.gateway != null) {
      _loadInvoice();
    }
  }

  Future<void> _loadInvoice() async {
    if (widget.gateway == null) return;
    final primaryId = _order?.id ?? widget.orderId;
    final businessId = _order?.orderanId;
    if (primaryId == null && businessId == null) return;
    try {
      var inv = primaryId != null
          ? await widget.gateway!.fetchInvoiceByOrderanId(primaryId)
          : null;
      if (inv == null && businessId != null && businessId != primaryId) {
        inv = await widget.gateway!.fetchInvoiceByOrderanId(businessId);
      }
      if (mounted && inv != null) {
        setState(() => _invoice = inv);
      }
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
              'Detail orderan belum dapat dimuat. Periksa koneksi Anda lalu coba lagi.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MgrsColors.canvas,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: MgrsColors.action),
              )
            : _error != null
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(MgrsSpacing.xl),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.error_outline_rounded,
                        size: 40,
                        color: MgrsColors.danger,
                      ),
                      const SizedBox(height: MgrsSpacing.md),
                      Text(
                        _error!,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 14,
                          color: MgrsColors.danger,
                        ),
                      ),
                      const SizedBox(height: MgrsSpacing.md),
                      ElevatedButton(
                        onPressed: _loadOrderDetail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: MgrsColors.action,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Coba Lagi'),
                      ),
                    ],
                  ),
                ),
              )
            : Column(
                children: [
                  _buildTopBar(context),
                  Expanded(
                    child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      padding: const EdgeInsets.symmetric(
                        horizontal: MgrsSpacing.md,
                        vertical: MgrsSpacing.xs,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildOrderHeaderCard(context),
                          const SizedBox(height: MgrsSpacing.sm),
                          _buildVenueCard(context),
                          const SizedBox(height: MgrsSpacing.sm),
                          if (widget.gateway != null && _order != null) ...[
                            UnitAllocationCard(
                              gateway: widget.gateway!,
                              order: _order!,
                              isEditable:
                                  (widget.user?.isTechnician == true ||
                                      widget.user?.isAdmin == true) &&
                                  !_order!.isCompletedOrCancelled,
                            ),
                            const SizedBox(height: MgrsSpacing.sm),
                          ],
                          _buildCustomerCard(context),
                          const SizedBox(height: MgrsSpacing.sm),
                          _buildEventNotesCard(context),
                          const SizedBox(height: MgrsSpacing.sm),
                          _buildInvoiceCard(context),
                          const SizedBox(height: MgrsSpacing.lg),
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

  Widget _buildTopBar(BuildContext context) {
    final canManage =
        widget.user?.canManageOrders == true &&
        _order != null &&
        !_order!.isCompletedOrCancelled;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: MgrsSpacing.md,
        vertical: MgrsSpacing.xs,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            onPressed: () => Navigator.maybePop(context),
            icon: const Icon(Icons.arrow_back),
            tooltip: 'Kembali',
            constraints: const BoxConstraints.tightFor(
              width: MgrsSizes.minTouch,
              height: MgrsSizes.minTouch,
            ),
          ),
          const Expanded(
            child: Text(
              'Detail order',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: MgrsColors.ink,
              ),
            ),
          ),
          if (canManage)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert_rounded),
              tooltip: 'Opsi order',
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MgrsRadii.control),
              ),
              onSelected: (val) {
                if (val == 'cancel_order') {
                  _showCancelOrderDialog();
                }
              },
              itemBuilder: (ctx) => [
                const PopupMenuItem<String>(
                  value: 'cancel_order',
                  child: Row(
                    children: [
                      Icon(
                        Icons.cancel_outlined,
                        color: MgrsColors.danger,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Batalkan Order',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: MgrsColors.danger,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            )
          else
            const SizedBox(width: MgrsSizes.minTouch),
        ],
      ),
    );
  }

  Widget _buildOrderHeaderCard(BuildContext context) {
    final order = _order;
    final displayCode = order?.displayCode ?? 'ORD-2026-088';
    final isDone = order?.statusOrderan?.toLowerCase() == 'selesai';
    final isCancelled = order?.isCancelled ?? false;

    final statusText = isCancelled
        ? 'Dibatalkan'
        : (isDone ? 'Selesai' : 'Aktif');
    final statusTone = isCancelled
        ? MgrsStatusTone.danger
        : (isDone ? MgrsStatusTone.success : MgrsStatusTone.warning);

    return Container(
      padding: const EdgeInsets.all(MgrsSpacing.md),
      decoration: BoxDecoration(
        color: MgrsColors.surface,
        borderRadius: BorderRadius.circular(MgrsRadii.card),
        border: Border.all(color: MgrsColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: MgrsSpacing.xs,
            runSpacing: 4,
            children: [
              Text(
                displayCode,
                style: const TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: MgrsColors.ink,
                  letterSpacing: -0.4,
                ),
              ),
              if (order != null) MgrsStatusBadge(statusText, tone: statusTone),
            ],
          ),
          const SizedBox(height: MgrsSpacing.xs),
          Text(
            order?.namaEvent ?? '-',
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MgrsColors.ink,
            ),
          ),
          if (isCancelled) ...[
            const SizedBox(height: MgrsSpacing.sm),
            Container(
              padding: const EdgeInsets.all(MgrsSpacing.sm),
              decoration: BoxDecoration(
                color: MgrsColors.dangerSoft,
                borderRadius: BorderRadius.circular(MgrsRadii.control),
                border: Border.all(
                  color: MgrsColors.danger.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.cancel_rounded,
                    color: MgrsColors.danger,
                    size: 18,
                  ),
                  const SizedBox(width: MgrsSpacing.sm),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Orderan Ini Telah Dibatalkan',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: MgrsColors.danger,
                          ),
                        ),
                        if (order?.cancellationReason != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Alasan: ${order!.cancellationReason}',
                            style: const TextStyle(
                              fontFamily: 'Inter',
                              fontSize: 11.5,
                              color: MgrsColors.ink,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: MgrsSpacing.sm),
          const Divider(height: 1, color: MgrsColors.line),
          const SizedBox(height: MgrsSpacing.sm),
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 300;
              final colPemasangan = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Pemasangan',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: MgrsColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order?.tanggalPemasangan != null
                        ? order!.formattedDate
                        : 'Jadwal belum ditentukan',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MgrsColors.ink,
                    ),
                  ),
                ],
              );
              final colDurasi = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Durasi Sewa',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: MgrsColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    order?.durasiSewaText ?? '1 Hari',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MgrsColors.action,
                    ),
                  ),
                ],
              );
              final colKebutuhan = Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Kebutuhan',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: MgrsColors.muted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${order?.jumlahUnit ?? 1} Unit',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: MgrsColors.ink,
                    ),
                  ),
                ],
              );

              if (isNarrow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    colPemasangan,
                    const SizedBox(height: MgrsSpacing.xs),
                    colDurasi,
                    const SizedBox(height: MgrsSpacing.xs),
                    colKebutuhan,
                  ],
                );
              }

              return Row(
                children: [
                  Expanded(flex: 4, child: colPemasangan),
                  Container(width: 1, height: 28, color: MgrsColors.line),
                  const SizedBox(width: MgrsSpacing.sm),
                  Expanded(flex: 3, child: colDurasi),
                  Container(width: 1, height: 28, color: MgrsColors.line),
                  const SizedBox(width: MgrsSpacing.sm),
                  Expanded(flex: 3, child: colKebutuhan),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVenueCard(BuildContext context) {
    final order = _order;
    final hasMaps =
        order?.linkGmaps != null && order!.linkGmaps!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(MgrsSpacing.md),
      decoration: BoxDecoration(
        color: MgrsColors.surface,
        borderRadius: BorderRadius.circular(MgrsRadii.card),
        border: Border.all(color: MgrsColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: MgrsSpacing.xs,
            runSpacing: 4,
            children: [
              const Text(
                'Lokasi Acara',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: MgrsColors.ink,
                ),
              ),
              if (hasMaps)
                InkWell(
                  onTap: () async {
                    final ok = await order.launchMaps();
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
                  borderRadius: BorderRadius.circular(MgrsRadii.control),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: MgrsSpacing.sm,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: MgrsColors.canvas,
                      borderRadius: BorderRadius.circular(MgrsRadii.control),
                      border: Border.all(color: MgrsColors.line),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(
                          Icons.near_me_rounded,
                          size: 14,
                          color: MgrsColors.action,
                        ),
                        SizedBox(width: 4),
                        Text(
                          'Petunjuk Arah',
                          style: TextStyle(
                            fontFamily: 'Inter',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: MgrsColors.action,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: MgrsSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: MgrsColors.canvas,
                  borderRadius: BorderRadius.circular(MgrsRadii.control),
                ),
                child: const Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: MgrsColors.action,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: MgrsSpacing.sm),
              Expanded(
                child: Text(
                  order?.alamat ?? 'Alamat lokasi belum diisi',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: MgrsColors.ink,
                    height: 1.3,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCustomerCard(BuildContext context) {
    final order = _order;
    return Container(
      padding: const EdgeInsets.all(MgrsSpacing.md),
      decoration: BoxDecoration(
        color: MgrsColors.surface,
        borderRadius: BorderRadius.circular(MgrsRadii.card),
        border: Border.all(color: MgrsColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informasi Klien & Kontak',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MgrsColors.ink,
            ),
          ),
          const SizedBox(height: MgrsSpacing.sm),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Nama Klien',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: MgrsColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order?.namaClient ?? '-',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: MgrsColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'WhatsApp',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: MgrsColors.muted,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      order?.nomorWhatsapp ?? '-',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: MgrsColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEventNotesCard(BuildContext context) {
    final note = _order?.cleanNote ?? '';
    if (note.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(MgrsSpacing.md),
      decoration: BoxDecoration(
        color: MgrsColors.surface,
        borderRadius: BorderRadius.circular(MgrsRadii.card),
        border: Border.all(color: MgrsColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Khusus Acara',
            style: TextStyle(
              fontFamily: 'Inter',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: MgrsColors.ink,
            ),
          ),
          const SizedBox(height: MgrsSpacing.xs),
          Text(
            note,
            style: const TextStyle(
              fontFamily: 'Inter',
              fontSize: 13,
              color: MgrsColors.ink,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context) {
    final inv = _invoice;
    final order = _order;
    final canManage = widget.user?.canManageOrders == true;

    return Container(
      padding: const EdgeInsets.all(MgrsSpacing.md),
      decoration: BoxDecoration(
        color: MgrsColors.surface,
        borderRadius: BorderRadius.circular(MgrsRadii.card),
        border: Border.all(color: MgrsColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: MgrsSpacing.xs,
            runSpacing: 4,
            children: [
              const Text(
                'Rincian Invoice',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: MgrsColors.ink,
                ),
              ),
              if (inv != null)
                MgrsStatusBadge(
                  inv.paymentStatusDisplay,
                  tone: inv.isPaid
                      ? MgrsStatusTone.success
                      : (inv.isCancelled
                            ? MgrsStatusTone.danger
                            : MgrsStatusTone.warning),
                ),
            ],
          ),
          const SizedBox(height: MgrsSpacing.sm),
          if (inv != null) ...[
            Text(
              inv.invoiceReference,
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: MgrsColors.ink,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Tagihan:',
                  style: TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    color: MgrsColors.muted,
                  ),
                ),
                Text(
                  inv.totalAmountFormatted,
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: MgrsColors.action,
                  ),
                ),
              ],
            ),
            if (inv.paidAmount > 0) ...[
              const SizedBox(height: 2),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Telah Dibayar:',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 12,
                      color: MgrsColors.muted,
                    ),
                  ),
                  Text(
                    inv.paidAmountFormatted,
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: MgrsColors.success,
                    ),
                  ),
                ],
              ),
            ],
            if (canManage && !inv.isPaid && !inv.isCancelled) ...[
              const SizedBox(height: MgrsSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    showDialog<void>(
                      context: context,
                      builder: (_) => QuickPaymentDialog(
                        invoice: inv,
                        gateway: widget.gateway!,
                        onPaymentUpdated: (updated) {
                          if (mounted) {
                            setState(() => _invoice = updated);
                          }
                        },
                      ),
                    );
                  },
                  child: const Text('Catat Pembayaran'),
                ),
              ),
            ],
          ] else ...[
            const Text(
              'Belum ada invoice terkait orderan ini.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: MgrsColors.muted,
              ),
            ),
            if (canManage && order != null && !order.isCancelled) ...[
              const SizedBox(height: MgrsSpacing.md),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {
                    final now = DateTime.now();
                    final y = now.year.toString().padLeft(4, '0');
                    final m = now.month.toString().padLeft(2, '0');
                    final d = now.day.toString().padLeft(2, '0');
                    final dateStr = '$y-$m-$d';
                    final qty = order.jumlahUnit > 0 ? order.jumlahUnit : 1;
                    final days = order.rentalDays > 0 ? order.rentalDays : 1;
                    final subtotal = qty * 250000 * days;

                    final newInvoice = InvoiceRecord(
                      id: 'draft-${DateTime.now().millisecondsSinceEpoch}',
                      orderanId: order.orderanId ?? order.id,
                      invoiceReference: 'INV/$y/$m/$d-${order.displayCode}',
                      invoiceDate: dateStr,
                      dueDate: dateStr,
                      productName: 'Sewa blower - ${order.namaEvent}',
                      quantity: qty,
                      rentalDays: days,
                      unitPrice: 250000,
                      subtotal: subtotal,
                      totalAmount: subtotal,
                      paidAmount: 0,
                      paymentStatus: InvoicePaymentStatus.unpaid,
                      customerName: order.namaClient ?? '',
                      customerPhone: order.nomorWhatsapp ?? '',
                    );

                    showDialog<void>(
                      context: context,
                      builder: (_) => InvoiceBuilderDialog(
                        invoice: newInvoice,
                        gateway: widget.gateway!,
                        selectedOrder: order,
                        initiallyEditing: true,
                        onSaved: (saved) {
                          if (mounted) {
                            setState(() => _invoice = saved);
                          }
                        },
                      ),
                    );
                  },
                  child: const Text('Terbitkan Invoice'),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildBottomCta(BuildContext context) {
    final order = _order;
    if (order == null || order.isCancelled) {
      return const SizedBox.shrink();
    }

    final isPast = order.statusOrderan?.toLowerCase() == 'selesai';
    final canComplete =
        !isPast &&
        (widget.user?.canManageOrders == true ||
            widget.user?.isTechnician == true ||
            widget.user?.isAdmin == true);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MgrsSpacing.md,
        vertical: MgrsSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: MgrsColors.surface,
        border: Border(top: BorderSide(color: MgrsColors.line)),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 340;

          final completeBtn = canComplete
              ? MgrsButton.primary(
                  label: 'Tandai Selesai',
                  icon: Icons.check_circle_rounded,
                  onPressed: _markAsCompleted,
                )
              : null;

          final waBtn = _buildWhatsappButton(order);

          if (completeBtn == null) {
            return waBtn;
          }

          if (isNarrow) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                completeBtn,
                const SizedBox(height: MgrsSpacing.sm),
                waBtn,
              ],
            );
          }

          return Row(
            children: [
              Expanded(child: completeBtn),
              const SizedBox(width: MgrsSpacing.sm),
              Expanded(child: waBtn),
            ],
          );
        },
      ),
    );
  }

  Widget _buildWhatsappButton(OrderanSewa? order) {
    return SizedBox(
      height: MgrsSizes.primaryButton,
      child: FilledButton.icon(
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
        icon: const Icon(Icons.chat_rounded, size: 18),
        label: const Text(
          'Hubungi Pemesan',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
          overflow: TextOverflow.ellipsis,
        ),
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF16A34A),
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MgrsRadii.control),
          ),
        ),
      ),
    );
  }

  Future<void> _markAsCompleted() async {
    final order = _order;
    if (order == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MgrsRadii.card),
        ),
        title: const Text(
          'Selesaikan order?',
          style: TextStyle(
            fontFamily: 'Inter',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: MgrsColors.ink,
          ),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Apakah event "${order.namaEvent}" (${order.displayCode}) dengan ${order.jumlahUnit} unit blower telah selesai?',
              style: const TextStyle(
                fontFamily: 'Inter',
                fontSize: 13,
                color: MgrsColors.ink,
                height: 1.4,
              ),
            ),
            const SizedBox(height: MgrsSpacing.sm),
            const Text(
              'Status order akan diubah menjadi Selesai.',
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: 12,
                color: MgrsColors.muted,
                height: 1.4,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: MgrsColors.ink),
            child: const Text('Ya, Selesaikan'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        final orderanIdStr = order.orderanId ?? order.id;
        await widget.gateway?.updateOrderStatus(orderanIdStr, 'Selesai');
        if (!mounted) return;
        setState(() {
          _order = order.copyWith(statusOrderan: 'Selesai');
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Orderan berhasil ditandai selesai.',
              style: TextStyle(fontFamily: 'Inter'),
            ),
            backgroundColor: MgrsColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Status order belum dapat diperbarui. Periksa koneksi Anda.',
              style: TextStyle(fontFamily: 'Inter'),
            ),
            backgroundColor: MgrsColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showCancelOrderDialog() async {
    final order = _order;
    if (order == null) return;

    final reasonController = TextEditingController();
    final reasonFocusNode = FocusNode();
    final inv = _invoice;
    final hasPayment = inv != null && inv.paidAmount > 0;
    final hasUnpaidInvoice =
        inv != null && !inv.isPaid && inv.paidAmount <= 0 && !inv.isCancelled;

    bool cancelInvoiceSelected = hasUnpaidInvoice;
    String? reasonError;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(MgrsRadii.card),
              ),
              titlePadding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              contentPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              title: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: MgrsColors.dangerSoft,
                      borderRadius: BorderRadius.circular(MgrsRadii.control),
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: MgrsColors.danger,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'Batalkan Orderan?',
                      style: TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: MgrsColors.ink,
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Event "${order.namaEvent}" (${order.displayCode}) akan dibatalkan dan dihapus dari jadwal aktif pemasangan.',
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 13,
                        color: MgrsColors.muted,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 10),
                    if (hasPayment) ...[
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFFBEB),
                          borderRadius: BorderRadius.circular(
                            MgrsRadii.control,
                          ),
                          border: Border.all(color: const Color(0xFFFDE68A)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.warning_amber_rounded,
                              color: Color(0xFFD97706),
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Perhatian: Invoice memiliki pembayaran tercatat sebesar ${inv.paidAmountFormatted}. Pastikan penyelesaian refund atau koordinasi dana dilakukan.',
                                style: const TextStyle(
                                  fontFamily: 'Inter',
                                  fontSize: 11.5,
                                  color: Color(0xFF92400E),
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 10),
                    ] else if (hasUnpaidInvoice) ...[
                      InkWell(
                        onTap: () {
                          setDialogState(() {
                            cancelInvoiceSelected = !cancelInvoiceSelected;
                          });
                        },
                        borderRadius: BorderRadius.circular(MgrsRadii.control),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Checkbox(
                                    value: cancelInvoiceSelected,
                                    onChanged: (val) {
                                      setDialogState(() {
                                        cancelInvoiceSelected = val ?? false;
                                      });
                                    },
                                    activeColor: MgrsColors.danger,
                                  ),
                                  const SizedBox(width: 4),
                                  const Expanded(
                                    child: Text(
                                      'Batalkan invoice yang belum dibayar',
                                      style: TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: MgrsColors.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding: const EdgeInsets.only(left: 36),
                                child: Text(
                                  'Invoice terkait (${inv.invoiceReference}) yang belum dibayar akan otomatis dibatalkan jika opsi ini aktif.',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11.5,
                                    color: MgrsColors.muted,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                    ],
                    MgrsMultilineField(
                      label: 'Alasan pembatalan *',
                      controller: reasonController,
                      focusNode: reasonFocusNode,
                      hintText: 'Contoh: Acara dibatalkan oleh pihak klien',
                      errorText: reasonError,
                      onChanged: (_) {
                        if (reasonError != null) {
                          setDialogState(() => reasonError = null);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Batal'),
                ),
                MgrsButton.destructive(
                  label: 'Ya, Batalkan Order',
                  onPressed: () {
                    final text = reasonController.text.trim();
                    if (text.length < 3) {
                      setDialogState(() {
                        reasonError = 'Alasan pembatalan minimal 3 karakter.';
                      });
                      reasonFocusNode.requestFocus();
                      return;
                    }
                    Navigator.pop(ctx, true);
                  },
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      final reason = reasonController.text.trim();
      final orderanIdStr = order.id.isNotEmpty
          ? order.id
          : (order.orderanId ?? widget.orderId ?? '');

      try {
        await widget.gateway?.cancelOrder(
          orderanIdStr,
          reason: reason,
          cancelInvoice: cancelInvoiceSelected,
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
          if (cancelInvoiceSelected &&
              _invoice != null &&
              (!_invoice!.isPaid || _invoice!.paidAmount <= 0)) {
            _invoice = null;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Orderan berhasil dibatalkan dan invoice terkait telah dihapus.',
              style: TextStyle(fontFamily: 'Inter'),
            ),
            backgroundColor: MgrsColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Orderan belum dapat dibatalkan. Periksa koneksi Anda.',
              style: TextStyle(fontFamily: 'Inter'),
            ),
            backgroundColor: MgrsColors.danger,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}
