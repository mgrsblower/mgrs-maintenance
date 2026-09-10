import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/gateway.dart';
import '../../shared/pressable.dart';
import 'create_invoice_dialog.dart';
import 'invoice_builder_dialog.dart';
import 'invoice_model.dart';
import 'quick_payment_dialog.dart';

enum InvoiceSourceFilter { automatic, manual }

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({
    super.key,
    required this.gateway,
    required this.user,
    this.fromOrderanId,
  });

  final MaintenanceGateway gateway;
  final UserProfile user;
  final String? fromOrderanId;

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<InvoiceRecord> _allInvoices = [];

  InvoiceSourceFilter _sourceFilter = InvoiceSourceFilter.automatic;
  InvoicePaymentStatus? _paymentFilter;

  @override
  void initState() {
    super.initState();
    _loadInvoices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInvoices({bool forceRefresh = false}) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final list =
          await widget.gateway.fetchInvoices(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _allInvoices = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = failureMessage(e);
        _isLoading = false;
      });
    }
  }

  List<InvoiceRecord> get _filteredInvoices {
    final query = _searchController.text.trim().toLowerCase();

    return _allInvoices.where((inv) {
      // 1. Source filter
      final sourceMatches = _sourceFilter == InvoiceSourceFilter.automatic
          ? inv.invoiceSource != 'manual_reimbursement'
          : inv.invoiceSource == 'manual_reimbursement';
      if (!sourceMatches) return false;

      // 2. Order ID match if opened for specific order
      if (widget.fromOrderanId != null &&
          inv.orderanId != widget.fromOrderanId) {
        return false;
      }

      // 3. Payment status filter
      if (_paymentFilter != null && inv.paymentStatus != _paymentFilter) {
        return false;
      }

      // 4. Search query
      if (query.isEmpty) return true;
      final ref = inv.invoiceReference.toLowerCase();
      final client = inv.customerName.toLowerCase();
      final product = inv.productName.toLowerCase();
      final orderId = (inv.orderanId ?? '').toLowerCase();

      return ref.contains(query) ||
          client.contains(query) ||
          product.contains(query) ||
          orderId.contains(query);
    }).toList();
  }

  List<InvoiceRecord> get _sourceInvoices {
    return _allInvoices.where((inv) {
      return _sourceFilter == InvoiceSourceFilter.automatic
          ? inv.invoiceSource != 'manual_reimbursement'
          : inv.invoiceSource == 'manual_reimbursement';
    }).toList();
  }

  int get _unpaidCount =>
      _sourceInvoices.where((i) => i.paymentStatus == InvoicePaymentStatus.unpaid).length;
  int get _partialCount =>
      _sourceInvoices.where((i) => i.paymentStatus == InvoicePaymentStatus.partial).length;
  int get _paidCount =>
      _sourceInvoices.where((i) => i.paymentStatus == InvoicePaymentStatus.paid).length;

  void _openCreateDialog() {
    showDialog<void>(
      context: context,
      builder: (ctx) => CreateInvoiceDialog(
        gateway: widget.gateway,
        onCreated: (created) {
          _loadInvoices(forceRefresh: true);
        },
      ),
    );
  }

  void _openQuickPayment(InvoiceRecord invoice) {
    showDialog<void>(
      context: context,
      builder: (ctx) => QuickPaymentDialog(
        invoice: invoice,
        gateway: widget.gateway,
        onPaymentUpdated: (updated) {
          _loadInvoices(forceRefresh: true);
        },
      ),
    );
  }

  void _openInvoiceBuilder(InvoiceRecord invoice) {
    showDialog<void>(
      context: context,
      builder: (ctx) => InvoiceBuilderDialog(
        invoice: invoice,
        gateway: widget.gateway,
        onSaved: (saved) {
          _loadInvoices(forceRefresh: true);
        },
      ),
    );
  }

  Future<void> _shareToWhatsApp(InvoiceRecord invoice) async {
    final cleanPhone =
        invoice.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    var targetPhone = cleanPhone;
    if (targetPhone.startsWith('0')) {
      targetPhone = '62${targetPhone.substring(1)}';
    }

    final message = '''Halo *${invoice.customerName.isNotEmpty ? invoice.customerName : 'Klien MGRS'}*,

Berikut rincian tagihan resmi dari *MGRS Blower*:
📄 *No. Invoice:* ${invoice.invoiceReference}
🎉 *Acara / Produk:* ${invoice.productName}
📅 *Tanggal:* ${invoice.formattedInvoiceDate}
📦 *Kuantitas:* ${invoice.quantity} Unit (${invoice.rentalDays} Hari)
💰 *Total Tagihan:* ${invoice.totalAmountFormatted}
💳 *Status:* ${invoice.paymentStatusDisplay}
${invoice.remainingAmount > 0 ? '⚠️ *Sisa Pembayaran:* ${invoice.remainingAmountFormatted}\n' : ''}
Rekening Pembayaran:
*BCA: 2302619141 a/n MADNUR*

Terima kasih telah mempercayai layanan MGRS!''';

    final uri = Uri.parse(
      targetPhone.isNotEmpty
          ? 'https://wa.me/$targetPhone?text=${Uri.encodeComponent(message)}'
          : 'whatsapp://send?text=${Uri.encodeComponent(message)}',
    );

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tidak dapat membuka WhatsApp.'),
          backgroundColor: Color(0xFFDC2626),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBFBFB),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 8),
              child: _buildHeader(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _buildCreateInvoiceButton(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _buildSourceTabs(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: _buildSearchBar(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: _buildFilterChips(),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () => _loadInvoices(forceRefresh: true),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.fromOrderanId != null
                  ? 'Invoice #${widget.fromOrderanId}'
                  : 'Daftar Invoice & Tagihan',
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Status Pembayaran Sewa Blower',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF64748B),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: const Color(0xFFF1F5F9),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
              SizedBox(width: 5),
              Text(
                'Keuangan',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF334155),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCreateInvoiceButton() {
    return SizedBox(
      width: double.infinity,
      height: 40,
      child: FilledButton.icon(
        key: const Key('invoice-create-action'),
        onPressed: _openCreateDialog,
        style: FilledButton.styleFrom(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        icon: const Icon(Icons.add_rounded, size: 18),
        label: const Text(
          'Buat invoice baru',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildSourceTabs() {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFE2E8F0),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: [
          Expanded(
            child: PressableScale(
              onTap: () => setState(() => _sourceFilter = InvoiceSourceFilter.automatic),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _sourceFilter == InvoiceSourceFilter.automatic
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _sourceFilter == InvoiceSourceFilter.automatic
                      ? const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Otomatis (Order Sewa)',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: _sourceFilter == InvoiceSourceFilter.automatic
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _sourceFilter == InvoiceSourceFilter.automatic
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: PressableScale(
              onTap: () => setState(() => _sourceFilter = InvoiceSourceFilter.manual),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 7),
                decoration: BoxDecoration(
                  color: _sourceFilter == InvoiceSourceFilter.manual
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(9),
                  boxShadow: _sourceFilter == InvoiceSourceFilter.manual
                      ? const [
                          BoxShadow(
                            color: Color(0x0A0F172A),
                            blurRadius: 4,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Manual Reimbursement',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: _sourceFilter == InvoiceSourceFilter.manual
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _sourceFilter == InvoiceSourceFilter.manual
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF64748B),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x060F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 13,
          color: Color(0xFF0F172A),
        ),
        decoration: InputDecoration(
          hintText: 'Cari no. invoice, order, atau klien...',
          hintStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            color: Color(0xFF94A3B8),
          ),
          prefixIcon: const Icon(Icons.search_rounded,
              size: 20, color: Color(0xFF64748B)),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      size: 18, color: Color(0xFF64748B)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        ),
      ),
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'Semua', 'status': null, 'count': _sourceInvoices.length},
      {
        'label': 'Belum Bayar',
        'status': InvoicePaymentStatus.unpaid,
        'count': _unpaidCount,
      },
      {
        'label': 'Sebagian',
        'status': InvoicePaymentStatus.partial,
        'count': _partialCount,
      },
      {
        'label': 'Lunas',
        'status': InvoicePaymentStatus.paid,
        'count': _paidCount,
      },
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final label = f['label'] as String;
          final status = f['status'] as InvoicePaymentStatus?;
          final count = f['count'] as int;
          final isSelected = _paymentFilter == status;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PressableScale(
              onTap: () => setState(() => _paymentFilter = status),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFE2E8F0),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w600,
                        color:
                            isSelected ? Colors.white : const Color(0xFF475569),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 1.5),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? const Color(0xFF334155)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isSelected
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: Color(0xFF147CC1)),
      );
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded,
                  size: 40, color: Color(0xFFDC2626)),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  color: Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => _loadInvoices(forceRefresh: true),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    final invoices = _filteredInvoices;

    if (invoices.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.receipt_long_outlined,
                  size: 48, color: Color(0xFF94A3B8)),
              SizedBox(height: 10),
              Text(
                'Tidak ada invoice yang sesuai.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 110),
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final item = invoices[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildInvoiceCard(item),
        );
      },
    );
  }

  Widget _buildInvoiceCard(InvoiceRecord item) {
    final statusColor = item.isPaid
        ? const Color(0xFF059669)
        : item.isDp
            ? const Color(0xFFD97706)
            : const Color(0xFFDC2626);

    final statusBg = item.isPaid
        ? const Color(0xFFECFDF5)
        : item.isDp
            ? const Color(0xFFFFFBEB)
            : const Color(0xFFFEF2F2);

    final dotColor = item.isPaid
        ? const Color(0xFF10B981)
        : item.isDp
            ? const Color(0xFFF59E0B)
            : const Color(0xFFEF4444);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A0F172A),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card: Ref & Status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: dotColor,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        item.invoiceReference,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '• ${item.quantity} Unit',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  item.paymentStatusDisplay,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            item.customerName.isNotEmpty ? item.customerName : 'Klien MGRS',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Color(0xFF0F172A),
              height: 1.4,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.productName,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          // Amount Box (Total & Sisa)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Total Tagihan',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.totalAmountFormatted,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      item.remainingAmount > 0 ? 'Sisa Bayar' : 'Status Bayar',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 10,
                        color: item.remainingAmount > 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.remainingAmount > 0
                          ? item.remainingAmountFormatted
                          : 'Lunas',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: item.remainingAmount > 0
                            ? const Color(0xFFDC2626)
                            : const Color(0xFF059669),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Date & Order ID info
          Row(
            children: [
              const Icon(
                Icons.calendar_today_rounded,
                size: 12,
                color: Color(0xFF64748B),
              ),
              const SizedBox(width: 4),
              Text(
                'Tgl: ${item.formattedInvoiceDate} (${item.rentalDays} Hari)',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  color: Color(0xFF64748B),
                ),
              ),
              if (item.orderanId != null && item.orderanId!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Text(
                  '• #${item.orderanId}',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ],
          ),
          const Divider(height: 18),
          // Action Buttons: Atur Pembayaran & Buka Invoice & WA
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  key: Key('btn-quick-payment-${item.id}'),
                  onPressed: () => _openQuickPayment(item),
                  icon: const Icon(Icons.payments_outlined, size: 14),
                  label: const Text(
                    'Atur Bayar',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: OutlinedButton.styleFrom(
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton.icon(
                  key: Key('btn-open-builder-${item.id}'),
                  onPressed: () => _openInvoiceBuilder(item),
                  icon: const Icon(Icons.receipt_long_rounded, size: 14),
                  label: const Text(
                    'Buka Invoice',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                  ),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    visualDensity: VisualDensity.compact,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                onPressed: () => _shareToWhatsApp(item),
                tooltip: 'Kirim WA',
                icon: const Icon(Icons.share_rounded, size: 18, color: Color(0xFF059669)),
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFECFDF5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
