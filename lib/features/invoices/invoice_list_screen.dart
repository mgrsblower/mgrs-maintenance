import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../app/gateway.dart';
import '../../shared/pressable.dart';
import 'invoice_model.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({
    super.key,
    required this.gateway,
    required this.user,
  });

  final MaintenanceGateway gateway;
  final UserProfile user;

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  final _searchController = TextEditingController();
  bool _isLoading = true;
  String? _error;
  List<InvoiceRecord> _allInvoices = [];
  String _activeFilter = 'Semua';

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
      final matchesFilter = switch (_activeFilter) {
        'Belum Lunas' => inv.isUnpaid,
        'DP' => inv.isDp,
        'Lunas' => inv.isPaid,
        _ => true,
      };

      if (!matchesFilter) return false;
      if (query.isEmpty) return true;

      final ref = inv.invoiceReference.toLowerCase();
      final client = inv.customerName.toLowerCase();
      final product = inv.productName.toLowerCase();
      return ref.contains(query) ||
          client.contains(query) ||
          product.contains(query);
    }).toList();
  }

  int get _unpaidCount => _allInvoices.where((i) => i.isUnpaid).length;
  int get _dpCount => _allInvoices.where((i) => i.isDp).length;
  int get _paidCount => _allInvoices.where((i) => i.isPaid).length;

  Future<void> _shareToWhatsApp(InvoiceRecord invoice) async {
    final cleanPhone =
        invoice.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
    var targetPhone = cleanPhone;
    if (targetPhone.startsWith('0')) {
      targetPhone = '62${targetPhone.substring(1)}';
    }

    final message = '''Halo *${invoice.customerName}*,

Berikut informasi tagihan sewa Mistyfan MGRS:
📄 *No. Invoice:* ${invoice.invoiceReference}
🎉 *Acara:* ${invoice.productName}
📅 *Tanggal:* ${invoice.formattedInvoiceDate}
📦 *Unit:* ${invoice.quantity} Unit (${invoice.rentalDays} Hari)
💰 *Total Tagihan:* ${invoice.totalAmountFormatted}
💳 *Status:* ${invoice.paymentStatus}
${invoice.remainingAmount > 0 ? '⚠️ *Sisa Pembayaran:* ${invoice.remainingAmountFormatted}\n' : ''}
Terima kasih telah menggunakan jasa MGRS Blower!''';

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
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
              child: _buildHeader(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _buildSearchBar(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
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

  // Header matching HomeScreen style
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Daftar Invoice & Tagihan',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Color(0xFF0F172A),
                letterSpacing: -0.3,
              ),
            ),
            SizedBox(height: 2),
            Text(
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

  // Search bar matching UpcomingOrdersScreen
  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
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
          hintText: 'Cari no. invoice, nama klien, atau acara...',
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
              const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    );
  }

  // Filter chips matching UpcomingOrdersScreen style exactly
  Widget _buildFilterChips() {
    final filters = [
      {'label': 'Semua', 'count': _allInvoices.length},
      {'label': 'Belum Lunas', 'count': _unpaidCount},
      {'label': 'DP', 'count': _dpCount},
      {'label': 'Lunas', 'count': _paidCount},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: filters.map((f) {
          final label = f['label'] as String;
          final count = f['count'] as int;
          final isSelected = _activeFilter == label;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PressableScale(
              onTap: () => setState(() => _activeFilter = label),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
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
          padding: const EdgeInsets.only(bottom: 10),
          child: _buildInvoiceCard(item),
        );
      },
    );
  }

  // Invoice Card matching HomeScreen._buildOrderCard design tokens
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
                          fontSize: 12,
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
          // Amount Box
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
                if (item.remainingAmount > 0)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const Text(
                        'Sisa Bayar',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.remainingAmountFormatted,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.only(top: 8),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
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
                  ],
                ),
                OutlinedButton.icon(
                  onPressed: () => _shareToWhatsApp(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF059669),
                    side: const BorderSide(color: Color(0xFFA7F3D0)),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    visualDensity: VisualDensity.compact,
                  ),
                  icon: const Icon(Icons.send_rounded, size: 13),
                  label: const Text(
                    'Kirim WA',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
