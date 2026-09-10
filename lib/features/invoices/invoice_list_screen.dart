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
      final list = await widget.gateway.fetchInvoices(forceRefresh: forceRefresh);
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
      return ref.contains(query) || client.contains(query) || product.contains(query);
    }).toList();
  }

  int get _unpaidCount => _allInvoices.where((i) => i.isUnpaid).length;
  int get _dpCount => _allInvoices.where((i) => i.isDp).length;
  int get _paidCount => _allInvoices.where((i) => i.isPaid).length;

  Future<void> _shareToWhatsApp(InvoiceRecord invoice) async {
    final cleanPhone = invoice.customerPhone.replaceAll(RegExp(r'[^0-9]'), '');
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Daftar Invoice & Tagihan',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
              child: _buildSearchBar(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
              child: _buildFilterChips(),
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

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFCBD5E1)),
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
          prefixIcon:
              const Icon(Icons.search_rounded, size: 20, color: Color(0xFF64748B)),
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

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'Semua', 'count': _allInvoices.length},
      {'label': 'Belum Lunas', 'count': _unpaidCount},
      {'label': 'DP', 'count': _dpCount},
      {'label': 'Lunas', 'count': _paidCount},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters.map((f) {
          final label = f['label'] as String;
          final count = f['count'] as int;
          final isSelected = _activeFilter == label;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: PressableScale(
              onTap: () => setState(() => _activeFilter = label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF0F172A) : Colors.white,
                  borderRadius: BorderRadius.circular(10),
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
                        fontWeight: FontWeight.w700,
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
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
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

    final statusBorder = item.isPaid
        ? const Color(0xFFA7F3D0)
        : item.isDp
            ? const Color(0xFFFDE68A)
            : const Color(0xFFFECACA);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.receipt_rounded,
                      size: 16, color: Color(0xFF147CC1)),
                  const SizedBox(width: 6),
                  Text(
                    item.invoiceReference,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: statusBorder),
                ),
                child: Text(
                  item.paymentStatus,
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
          const SizedBox(height: 12),
          Text(
            item.customerName.isNotEmpty ? item.customerName : 'Klien MGRS',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.productName,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
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
                        fontSize: 11,
                        color: Color(0xFF64748B),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      item.totalAmountFormatted,
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
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
                          fontSize: 11,
                          color: Color(0xFFDC2626),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.remainingAmountFormatted,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFFDC2626),
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tgl: ${item.formattedInvoiceDate} • ${item.quantity} Unit (${item.rentalDays} Hari)',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  color: Color(0xFF94A3B8),
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => _shareToWhatsApp(item),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF059669),
                  side: const BorderSide(color: Color(0xFFA7F3D0)),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                icon: const Icon(Icons.send_rounded, size: 14),
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
        ],
      ),
    );
  }
}
