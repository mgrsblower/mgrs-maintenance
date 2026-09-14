import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../design_system/components/mgrs_state_view.dart';
import '../../design_system/mgrs_tokens.dart';
import 'create_invoice_dialog.dart';
import 'invoice_builder_dialog.dart';
import 'invoice_model.dart';
import 'quick_payment_dialog.dart';
import 'widgets/invoice_card.dart';
import 'widgets/invoice_list_shell.dart';

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
      final list = await widget.gateway.fetchInvoices(
        forceRefresh: forceRefresh,
      );
      if (!mounted) return;
      setState(() {
        _allInvoices = list;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is AppFailure
            ? e.message
            : 'Data belum dapat diproses. Silakan coba lagi.';
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
    return InvoiceListShell(
      title: widget.fromOrderanId == null
          ? 'Daftar Invoice'
          : 'Invoice #${widget.fromOrderanId}',
      sourceFilter: _sourceFilter,
      paymentFilter: _paymentFilter,
      searchController: _searchController,
      onSourceChanged: (value) => setState(() => _sourceFilter = value),
      onPaymentChanged: (value) => setState(() => _paymentFilter = value),
      onSearchChanged: (_) => setState(() {}),
      onCreate: _openCreateDialog,
      body: RefreshIndicator(
        color: MgrsColors.ink,
        onRefresh: () => _loadInvoices(forceRefresh: true),
        child: _buildContent(),
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const _InvoiceScrollableState(
        child: MgrsStateView.loading(
          key: Key('invoice-loading-state'),
          title: 'Memuat invoice...',
        ),
      );
    }

    if (_error != null) {
      return _InvoiceScrollableState(
        child: MgrsStateView.error(
          key: const Key('invoice-error-state'),
          title: 'Invoice gagal dimuat',
          message: _error,
          actionLabel: 'Muat data terbaru',
          onAction: () => _loadInvoices(forceRefresh: true),
        ),
      );
    }

    final invoices = _filteredInvoices;

    if (_allInvoices.isEmpty) {
      return _InvoiceScrollableState(
        child: MgrsStateView.empty(
          key: const Key('invoice-empty-state'),
          title: 'Belum ada invoice',
          message: 'Buat invoice pertama untuk mulai mengelola penagihan.',
          actionLabel: 'Buat Invoice',
          onAction: _openCreateDialog,
        ),
      );
    }

    if (invoices.isEmpty) {
      return _InvoiceScrollableState(
        child: MgrsStateView.noResults(
          key: const Key('invoice-no-results-state'),
          query: _searchController.text.trim().isEmpty
              ? 'filter yang dipilih'
              : _searchController.text.trim(),
          onReset: () => setState(() {
            _searchController.clear();
            _paymentFilter = null;
          }),
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
    return InvoiceCard(
      invoice: item,
      onPayment: () => _openQuickPayment(item),
      onOpen: () => _openInvoiceBuilder(item),
      onDelete: () => _confirmDeleteInvoice(item),
    );
  }

  Future<void> _confirmDeleteInvoice(InvoiceRecord item) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(
              Icons.delete_outline_rounded,
              color: Color(0xFFDC2626),
              size: 22,
            ),
            SizedBox(width: 8),
            Text(
              'Hapus Invoice?',
              style: TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        content: Text(
          'Invoice ${item.invoiceReference} (${item.customerName}) akan dihapus secara permanen.',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            color: Color(0xFF475569),
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
              backgroundColor: const Color(0xFFDC2626),
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      try {
        await widget.gateway.deleteInvoice(item.id);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice ${item.invoiceReference} berhasil dihapus.'),
            backgroundColor: const Color(0xFF059669),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadInvoices(forceRefresh: true);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e is AppFailure
                  ? e.message
                  : 'Invoice belum dapat dihapus. Silakan coba lagi.',
            ),
            backgroundColor: const Color(0xFFDC2626),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }
}

class _InvoiceScrollableState extends StatelessWidget {
  const _InvoiceScrollableState({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => ListView(
    physics: const AlwaysScrollableScrollPhysics(),
    padding: const EdgeInsets.only(bottom: MgrsSpacing.xl),
    children: [child],
  );
}
