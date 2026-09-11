import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../shared/pressable.dart';
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
      // Default fallback for preview/testing
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
    final orderanId = _order?.id ?? widget.orderId;
    if (orderanId == null || widget.gateway == null) return;
    try {
      final inv = await widget.gateway!.fetchInvoiceByOrderanId(orderanId);
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
          _error = 'Detail orderan belum dapat dimuat. Silakan periksa koneksi lalu coba lagi.';
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Color(0xFF147CC1)),
              )
            : _error != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.error_outline_rounded,
                              size: 40, color: Color(0xFFDC2626)),
                          const SizedBox(height: 12),
                          Text(
                            _error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              color: Color(0xFF991B1B),
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadOrderDetail,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF147CC1),
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
                      Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _buildTopBar(context),
                              const SizedBox(height: 16),
                              _buildOrderHeaderCard(context),
                              const SizedBox(height: 16),
                              _buildVenueCard(context),
                              const SizedBox(height: 16),
                              if (widget.gateway != null && _order != null) ...[
                                UnitAllocationCard(
                                  gateway: widget.gateway!,
                                  order: _order!,
                                  isEditable: (widget.user?.isTechnician == true || widget.user?.isAdmin == true) &&
                                      !_order!.isCompletedOrCancelled,
                                ),
                                const SizedBox(height: 16),
                              ],
                              _buildCustomerCard(context),
                              const SizedBox(height: 16),
                              _buildEventNotesCard(context),
                              const SizedBox(height: 16),
                              _buildInvoiceCard(context),
                              const SizedBox(height: 24),
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

  // Top Bar
  Widget _buildTopBar(BuildContext context) {
    final canManage = widget.user?.canManageOrders == true &&
        _order != null &&
        !_order!.isCompletedOrCancelled;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: const BoxDecoration(
              color: Color(0xFFF1F5F9),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: Icon(
                Icons.chevron_left_rounded,
                color: Color(0xFF0F172A),
                size: 24,
              ),
            ),
          ),
        ),
        const Text(
          'Detail Orderan',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        if (canManage)
          PopupMenuButton<String>(
            icon: Container(
              width: 40,
              height: 40,
              decoration: const BoxDecoration(
                color: Color(0xFFF1F5F9),
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: Icon(
                  Icons.more_vert_rounded,
                  color: Color(0xFF0F172A),
                  size: 20,
                ),
              ),
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 4,
            offset: const Offset(0, 48),
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
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                    SizedBox(width: 10),
                    Text(
                      'Batalkan Order',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          )
        else
          const SizedBox(width: 40),
      ],
    );
  }

  // Card 1: Nama Event + Tanggal, Durasi Sewa, Jumlah Unit
  Widget _buildOrderHeaderCard(BuildContext context) {
    final order = _order;
    final displayCode = order?.displayCode ?? 'ORD-2026-088';
    final isDone = order?.statusOrderan?.toLowerCase() == 'selesai';
    final isCancelled = order?.isCancelled ?? false;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                displayCode,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                  letterSpacing: -0.4,
                ),
              ),
              if (order != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                  decoration: BoxDecoration(
                    color: isCancelled
                        ? const Color(0xFFFEF2F2)
                        : (isDone
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFEFF6FF)),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isCancelled
                          ? const Color(0xFFFECACA)
                          : (isDone
                              ? const Color(0xFFA7F3D0)
                              : const Color(0xFFBFDBFE)),
                    ),
                  ),
                  child: Text(
                    isCancelled
                        ? 'Dibatalkan'
                        : (isDone ? 'Selesai' : 'Aktif'),
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: isCancelled
                          ? const Color(0xFFDC2626)
                          : (isDone
                              ? const Color(0xFF059669)
                              : const Color(0xFF2563EB)),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Nama Event: ${order?.namaEvent ?? '-'}',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          if (isCancelled) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFEF2F2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFFECACA)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.cancel_rounded, color: Color(0xFFDC2626), size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Orderan Ini Telah Dibatalkan',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF991B1B),
                          ),
                        ),
                        if (order?.cancellationReason != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Alasan: ${order!.cancellationReason}',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 11.5,
                              color: Color(0xFFB91C1C),
                              height: 1.3,
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
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
            ),
            child: Row(
              children: [
                // Jadwal Pemasangan
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pemasangan',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        order?.tanggalPemasangan != null
                            ? order!.formattedDate
                            : 'Jadwal belum ditentukan',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 10),
                // Durasi Sewa
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Durasi Sewa',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        order?.durasiSewaText ?? '1 Hari',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF2563EB),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: const Color(0xFFE2E8F0)),
                const SizedBox(width: 10),
                // Kebutuhan Unit
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Kebutuhan',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${order?.jumlahUnit ?? 4} Unit',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card 2: Lokasi Acara + Tombol Maps
  Widget _buildVenueCard(BuildContext context) {
    final order = _order;
    final hasMaps = order?.linkGmaps != null && order!.linkGmaps!.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Lokasi Acara',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (hasMaps)
                PressableScale(
                  onTap: () async {
                    final ok = await order.launchMaps();
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Peta lokasi acara tidak dapat dibuka.'),
                        ),
                      );
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.near_me_rounded, size: 14, color: Color(0xFF2563EB)),
                        SizedBox(width: 4),
                        Text(
                          'Petunjuk Arah',
                          style: TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF2563EB),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.location_on_rounded,
                    color: Color(0xFF2563EB),
                    size: 20,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order?.alamat ?? 'Lokasi acara belum dicatat',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (hasMaps) ...[
            const SizedBox(height: 14),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final ok = await order.launchMaps();
                  if (!ok && context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Peta lokasi acara tidak dapat dibuka.'),
                      ),
                    );
                  }
                },
                icon: const Icon(Icons.map_rounded, size: 16),
                label: const Text(
                  'Buka di Google Maps',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF2563EB),
                  side: const BorderSide(color: Color(0xFFBFDBFE)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Card 3: Data Pemesan
  Widget _buildCustomerCard(BuildContext context) {
    final order = _order;
    final hasWa = order?.cleanWhatsapp.isNotEmpty == true;

    final customerName = (order?.namaClient != null && order!.namaClient!.trim().isNotEmpty)
        ? order.namaClient!.trim()
        : (order?.namaPic != null && order!.namaPic!.trim().isNotEmpty)
            ? order.namaPic!.trim()
            : 'Pemesan';
    final initial = customerName.isNotEmpty ? customerName.substring(0, 1).toUpperCase() : 'P';
    final phone = (order?.nomorWhatsapp != null && order!.nomorWhatsapp!.trim().isNotEmpty)
        ? order.nomorWhatsapp!.trim()
        : 'Nomor WhatsApp belum tersedia';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Data Pemesan',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: const Color(0xFFF1F5F9),
                child: Text(
                  initial,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customerName,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      phone,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              if (hasWa)
                PressableScale(
                  onTap: () async {
                    final ok = await order!.launchWhatsApp();
                    if (!ok && context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Tidak dapat membuka WhatsApp.'),
                        ),
                      );
                    }
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0FDF4),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFBBF7D0)),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.chat_bubble_rounded,
                        color: Color(0xFF16A34A),
                        size: 18,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Card 4: Catatan Orderan
  Widget _buildEventNotesCard(BuildContext context) {
    final note = _order?.cleanNote ?? '';
    final hasNote = note.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.edit_note_rounded,
                  size: 18, color: Color(0xFF2563EB)),
              SizedBox(width: 8),
              Text(
                'Catatan Orderan',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF1E293B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            hasNote ? note : 'Tidak ada catatan khusus untuk orderan ini.',
            style: TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontStyle: hasNote ? FontStyle.normal : FontStyle.italic,
              color: hasNote ? const Color(0xFF334155) : const Color(0xFF94A3B8),
              height: 1.5,
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
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Selesaikan Orderan?',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'Apakah event "${order.namaEvent}" sudah selesai dan unit blower siap kembali?\nStatus orderan akan diubah menjadi Selesai.',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            color: Color(0xFF475569),
            height: 1.4,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF0F172A),
            ),
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
              style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
            ),
            backgroundColor: Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failureMessage(e),
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
            ),
            backgroundColor: const Color(0xFFDC2626),
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
    final formKey = GlobalKey<FormState>();
    final inv = _invoice;
    final hasPayment = inv != null && inv.paidAmount > 0;
    final hasUnpaidInvoice = inv != null && !inv.isPaid && !inv.isCancelled;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (dialogCtx, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              titlePadding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              contentPadding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
              title: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.cancel_outlined,
                      color: Color(0xFFDC2626),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Batalkan Orderan?',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ],
              ),
              content: SingleChildScrollView(
                child: Form(
                  key: formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Event "${order.namaEvent}" (${order.displayCode}) akan dibatalkan dan dihapus dari jadwal aktif pemasangan.',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                      const SizedBox(height: 14),
                      if (hasPayment) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFFBEB),
                            borderRadius: BorderRadius.circular(12),
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
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11.5,
                                    color: Color(0xFF92400E),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ] else if (hasUnpaidInvoice) ...[
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFBFDBFE)),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                color: Color(0xFF2563EB),
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Invoice terkait (${inv.invoiceReference}) yang belum dibayar akan otomatis dibatalkan.',
                                  style: const TextStyle(
                                    fontFamily: 'Plus Jakarta Sans',
                                    fontSize: 11.5,
                                    color: Color(0xFF1E40AF),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 14),
                      ],
                      const Text(
                        'Alasan Pembatalan *',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF334155),
                        ),
                      ),
                      const SizedBox(height: 6),
                      TextFormField(
                        controller: reasonController,
                        autofocus: true,
                        maxLines: 2,
                        validator: (val) {
                          if (val == null || val.trim().length < 3) {
                            return 'Alasan pembatalan minimal 3 karakter.';
                          }
                          return null;
                        },
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Contoh: Acara dibatalkan oleh pihak klien',
                          hintStyle: const TextStyle(
                            fontFamily: 'Plus Jakarta Sans',
                            fontSize: 12,
                            color: Color(0xFF94A3B8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Kembali'),
                ),
                FilledButton(
                  onPressed: () {
                    if (formKey.currentState?.validate() == true) {
                      Navigator.pop(ctx, true);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Ya, Batalkan Order'),
                ),
              ],
            );
          },
        );
      },
    );

    if (confirmed == true && mounted) {
      final reason = reasonController.text.trim();
      final orderanIdStr = order.id;

      try {
        await widget.gateway?.cancelOrder(
          orderanIdStr,
          reason: reason,
          cancelInvoice: true,
        );
        if (!mounted) return;

        final currentNote = order.catatanOrderan ?? '';
        final cancelTag = '[BATAL: $reason]';
        final updatedNote = currentNote.isNotEmpty ? '$currentNote\n$cancelTag' : cancelTag;

        setState(() {
          _order = order.copyWith(
            statusOrderan: 'Batal',
            catatanOrderan: updatedNote,
          );
          if (_invoice != null && (!_invoice!.isPaid || _invoice!.paidAmount <= 0)) {
            _invoice = _invoice!.copyWith(paymentStatus: InvoicePaymentStatus.cancelled);
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Orderan berhasil dibatalkan.',
              style: TextStyle(fontFamily: 'Plus Jakarta Sans'),
            ),
            backgroundColor: Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failureMessage(e),
              style: const TextStyle(fontFamily: 'Plus Jakarta Sans'),
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  // Bottom Floating CTA Bar
  Widget _buildBottomCta(BuildContext context) {
    final order = _order;
    final canComplete =
        widget.user?.canManageOrders == true &&
        order != null &&
        !order.isCompletedOrCancelled;

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: Color(0xFFF1F5F9))),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: canComplete
          ? Row(
              children: [
                Expanded(
                  flex: 5,
                  child: PressableScale(
                    onTap: _markAsCompleted,
                    child: Container(
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F172A),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_rounded,
                              color: Colors.white, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'Tandai Selesai',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 6,
                  child: _buildWhatsappButton(order),
                ),
              ],
            )
          : _buildWhatsappButton(order),
    );
  }

  Widget _buildWhatsappButton(OrderanSewa? order) {
    return PressableScale(
      onTap: () async {
        if (order != null && order.cleanWhatsapp.isNotEmpty) {
          final ok = await order.launchWhatsApp();
          if (!ok && mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Tidak dapat membuka WhatsApp.'),
              ),
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
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFF16A34A),
          borderRadius: BorderRadius.circular(14),
          boxShadow: const [
            BoxShadow(
              color: Color(0x3316A34A),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.chat_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Text(
              'Hubungi Pemesan',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceCard(BuildContext context) {
    final inv = _invoice;
    final isPaid = inv?.isPaid ?? false;
    final isDp = inv?.isDp ?? false;
    final isCancelled = inv?.isCancelled ?? false;

    final statusBg = isPaid
        ? const Color(0xFFECFDF5)
        : isDp
            ? const Color(0xFFFFFBEB)
            : isCancelled
                ? const Color(0xFFF1F5F9)
                : const Color(0xFFFEF2F2);

    final statusColor = isPaid
        ? const Color(0xFF059669)
        : isDp
            ? const Color(0xFFD97706)
            : isCancelled
                ? const Color(0xFF64748B)
                : const Color(0xFFDC2626);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Invoice Terkait',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              if (inv != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    inv.paymentStatusDisplay,
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                    ),
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'Belum Ada',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            inv != null
                ? '${inv.invoiceReference} • Total: ${inv.totalAmountFormatted}${inv.remainingAmount > 0 ? " (Sisa: ${inv.remainingAmountFormatted})" : ""}'
                : 'Lihat atau terbitkan invoice resmi untuk orderan ini.',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          if (inv != null)
            Row(
              children: [
                if (!isCancelled) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        showDialog<void>(
                          context: context,
                          builder: (ctx) => QuickPaymentDialog(
                            invoice: inv,
                            gateway: widget.gateway!,
                            onPaymentUpdated: (updated) {
                              setState(() => _invoice = updated);
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.payments_outlined, size: 15),
                      label: const Text('Atur Bayar', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (ctx) => InvoiceBuilderDialog(
                          invoice: inv,
                          gateway: widget.gateway!,
                          onSaved: (saved) {
                            setState(() => _invoice = saved);
                          },
                        ),
                      );
                    },
                    icon: const Icon(Icons.receipt_long_rounded, size: 15),
                    label: const Text('Buka Invoice', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            )
          else if (widget.gateway != null && _order != null && !_order!.isCancelled)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  final order = _order!;
                  final dt = order.tanggalPemasangan ?? DateTime.now();
                  final orderanIdStr = order.orderanId ?? order.id;
                  final codeSuffix = orderanIdStr.split('-').last;
                  final y = dt.year.toString().padLeft(4, '0');
                  final m = dt.month.toString().padLeft(2, '0');
                  final d = dt.day.toString().padLeft(2, '0');
                  final ref = 'INV/$y/$m/$d-$codeSuffix';
                  final qty = order.jumlahUnit > 0 ? order.jumlahUnit : 1;
                  final days = order.rentalDays > 0 ? order.rentalDays : 1;
                  const unitPrice = 250000;
                  final subtotal = qty * unitPrice;

                  final payload = <String, Object?>{
                    'orderan_id': orderanIdStr,
                    'invoice_reference': ref,
                    'invoice_date': dt.toIso8601String().substring(0, 10),
                    'due_date': dt.add(const Duration(days: 7)).toIso8601String().substring(0, 10),
                    'product_name': order.namaEvent.isNotEmpty ? order.namaEvent : 'Sewa Mistyfan',
                    'quantity': qty,
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
                  final messenger = ScaffoldMessenger.of(context);
                  try {
                    final created = await widget.gateway!.createInvoice(payload);
                    if (mounted) {
                      setState(() => _invoice = created);
                    }
                  } catch (e) {
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text('Gagal membuat invoice: $e'), backgroundColor: const Color(0xFFDC2626)),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.add_rounded, size: 16),
                label: const Text('Terbitkan Invoice untuk Order Ini', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
                style: OutlinedButton.styleFrom(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
