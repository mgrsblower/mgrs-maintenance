import 'package:flutter/material.dart';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAFAFA),
      body: SafeArea(
        child: Column(
          children: [
            // Header with integrated "+ Invoice" action
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
              child: _buildHeader(context),
            ),
            // Slim Source Switcher (Order Sewa vs Reimbursement)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildSourceSwitch(),
            ),
            // Flat Hairline Search
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: _buildSearchBar(),
            ),
            // 100% Full-Width Segmented Status Filter (No Horizontal Scroll, No Count)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
              child: _buildStatusFilterTabs(),
            ),
            // Main List
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFF18181B),
                onRefresh: () => _loadInvoices(forceRefresh: true),
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Header: Clean title + compact "+ Invoice" button
  Widget _buildHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.center,
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
                color: Color(0xFF18181B),
                letterSpacing: -0.3,
              ),
            ),
            const SizedBox(height: 2),
            const Text(
              'Kelola penagihan sewa blower',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Color(0xFF71717A),
              ),
            ),
          ],
        ),
        PressableScale(
          onTap: _openCreateDialog,
          child: Container(
            key: const Key('invoice-create-action'),
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: const Color(0xFF18181B),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, size: 16, color: Colors.white),
                SizedBox(width: 4),
                Text(
                  'Invoice',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Slim Segmented Source Toggle (Order Sewa vs Reimbursement)
  Widget _buildSourceSwitch() {
    return Container(
      height: 34,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PressableScale(
              onTap: () =>
                  setState(() => _sourceFilter = InvoiceSourceFilter.automatic),
              child: Container(
                decoration: BoxDecoration(
                  color: _sourceFilter == InvoiceSourceFilter.automatic
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _sourceFilter == InvoiceSourceFilter.automatic
                      ? const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Order Sewa (Otomatis)',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: _sourceFilter == InvoiceSourceFilter.automatic
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _sourceFilter == InvoiceSourceFilter.automatic
                        ? const Color(0xFF18181B)
                        : const Color(0xFF71717A),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: PressableScale(
              onTap: () =>
                  setState(() => _sourceFilter = InvoiceSourceFilter.manual),
              child: Container(
                decoration: BoxDecoration(
                  color: _sourceFilter == InvoiceSourceFilter.manual
                      ? Colors.white
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: _sourceFilter == InvoiceSourceFilter.manual
                      ? const [
                          BoxShadow(
                            color: Color(0x0A000000),
                            blurRadius: 3,
                            offset: Offset(0, 1),
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: Text(
                  'Reimbursement Manual',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: _sourceFilter == InvoiceSourceFilter.manual
                        ? FontWeight.w700
                        : FontWeight.w500,
                    color: _sourceFilter == InvoiceSourceFilter.manual
                        ? const Color(0xFF18181B)
                        : const Color(0xFF71717A),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Flat hairline search input
  Widget _buildSearchBar() {
    return Container(
      height: 38,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (_) => setState(() {}),
        style: const TextStyle(
          fontFamily: 'Plus Jakarta Sans',
          fontSize: 12.5,
          color: Color(0xFF18181B),
        ),
        decoration: InputDecoration(
          isDense: true,
          hintText: 'Cari no. invoice, order, atau klien...',
          hintStyle: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12.5,
            color: Color(0xFFA1A1AA),
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            size: 18,
            color: Color(0xFF71717A),
          ),
          prefixIconConstraints: const BoxConstraints(minWidth: 36),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded,
                      size: 16, color: Color(0xFF71717A)),
                  onPressed: () {
                    _searchController.clear();
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 10),
        ),
      ),
    );
  }

  // 100% Fit Width Status Filter (No Count, No Scroll)
  Widget _buildStatusFilterTabs() {
    final tabs = [
      {'label': 'Semua', 'status': null},
      {'label': 'Belum Bayar', 'status': InvoicePaymentStatus.unpaid},
      {'label': 'Sebagian', 'status': InvoicePaymentStatus.partial},
      {'label': 'Lunas', 'status': InvoicePaymentStatus.paid},
    ];

    return Container(
      height: 34,
      padding: const EdgeInsets.all(2),
      decoration: BoxDecoration(
        color: const Color(0xFFF4F4F5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Row(
        children: tabs.map((tab) {
          final label = tab['label'] as String;
          final status = tab['status'] as InvoicePaymentStatus?;
          final isSelected = _paymentFilter == status;

          return Expanded(
            child: PressableScale(
              onTap: () => setState(() => _paymentFilter = status),
              child: Container(
                decoration: BoxDecoration(
                  color: isSelected ? const Color(0xFF18181B) : Colors.transparent,
                  borderRadius: BorderRadius.circular(6),
                ),
                alignment: Alignment.center,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11.5,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    color: isSelected ? Colors.white : const Color(0xFF71717A),
                  ),
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
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: Color(0xFF18181B),
        ),
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
                  size: 36, color: Color(0xFF9F2F2D)),
              const SizedBox(height: 10),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13,
                  color: Color(0xFF71717A),
                ),
              ),
              const SizedBox(height: 14),
              FilledButton(
                onPressed: () => _loadInvoices(forceRefresh: true),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF18181B),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
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
                  size: 40, color: Color(0xFFA1A1AA)),
              SizedBox(height: 10),
              Text(
                'Tidak ada invoice yang sesuai.',
                style: TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF71717A),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 2, 16, 110),
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

  // Bento-style crisp minimalist invoice card
  Widget _buildInvoiceCard(InvoiceRecord item) {
    // Pastel status badge colors matching minimalist-ui guidelines:
    // Pale Red: #FDEBEC / Text: #9F2F2D
    // Pale Yellow: #FBF3DB / Text: #956400
    // Pale Green: #EDF3EC / Text: #346538
    final (statusBg, statusText) = switch (item.paymentStatus) {
      InvoicePaymentStatus.paid => (const Color(0xFFEDF3EC), const Color(0xFF346538)),
      InvoicePaymentStatus.partial => (const Color(0xFFFBF3DB), const Color(0xFF956400)),
      InvoicePaymentStatus.unpaid => (const Color(0xFFFDEBEC), const Color(0xFF9F2F2D)),
    };

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE4E4E7)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Reference & Pastel Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        item.invoiceReference,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF18181B),
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '• ${item.quantity} Unit',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF71717A),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2.5),
                decoration: BoxDecoration(
                  color: statusBg,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  item.paymentStatusDisplay,
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: statusText,
                    letterSpacing: 0.2,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Client name & Event
          Text(
            item.customerName.isNotEmpty ? item.customerName : 'Klien MGRS',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 14.5,
              fontWeight: FontWeight.w700,
              color: Color(0xFF18181B),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.productName,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Color(0xFF71717A),
            ),
          ),
          const SizedBox(height: 10),
          // Hairline divider
          const Divider(height: 1, color: Color(0xFFF4F4F5)),
          const SizedBox(height: 8),
          // Amount Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Text(
                    'Total: ',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11.5,
                      color: Color(0xFF71717A),
                    ),
                  ),
                  Text(
                    item.totalAmountFormatted,
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: Color(0xFF18181B),
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  Text(
                    item.remainingAmount > 0 ? 'Sisa: ' : 'Status: ',
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11.5,
                      color: Color(0xFF71717A),
                    ),
                  ),
                  Text(
                    item.remainingAmount > 0
                        ? item.remainingAmountFormatted
                        : 'Lunas',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: item.remainingAmount > 0
                          ? const Color(0xFF9F2F2D)
                          : const Color(0xFF346538),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Date & Order ID info
          Text(
            '${item.formattedInvoiceDate} (${item.rentalDays} Hari)${item.orderanId != null && item.orderanId!.isNotEmpty ? " • #${item.orderanId}" : ""}',
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              color: Color(0xFFA1A1AA),
            ),
          ),
          const SizedBox(height: 10),
          // Action Buttons: Atur Bayar & Buka Invoice & WA
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  key: Key('btn-quick-payment-${item.id}'),
                  onPressed: () => _openQuickPayment(item),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF18181B),
                    side: const BorderSide(color: Color(0xFFE4E4E7)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 7),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text(
                    'Atur Bayar',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: FilledButton(
                  key: Key('btn-open-builder-${item.id}'),
                  onPressed: () => _openInvoiceBuilder(item),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF18181B),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    visualDensity: VisualDensity.compact,
                  ),
                  child: const Text(
                    'Buka Invoice',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
}
