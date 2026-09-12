import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';
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
      final list = await widget.gateway.fetchInvoices(forceRefresh: forceRefresh);
      if (!mounted) return;
      setState(() {
        _allInvoices = list;
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = failureMessage(error);
        _isLoading = false;
      });
    }
  }

  List<InvoiceRecord> get _filteredInvoices {
    final query = _searchController.text.trim().toLowerCase();
    return _allInvoices.where((invoice) {
      final sourceMatches = _sourceFilter == InvoiceSourceFilter.automatic
          ? invoice.invoiceSource != 'manual_reimbursement'
          : invoice.invoiceSource == 'manual_reimbursement';
      if (!sourceMatches) return false;
      if (widget.fromOrderanId != null && invoice.orderanId != widget.fromOrderanId) {
        return false;
      }
      if (_paymentFilter != null && invoice.paymentStatus != _paymentFilter) {
        return false;
      }
      if (query.isEmpty) return true;
      return invoice.invoiceReference.toLowerCase().contains(query) ||
          invoice.customerName.toLowerCase().contains(query) ||
          invoice.productName.toLowerCase().contains(query) ||
          (invoice.orderanId ?? '').toLowerCase().contains(query);
    }).toList();
  }

  void _openCreateDialog() {
    showDialog<void>(
      context: context,
      builder: (_) => CreateInvoiceDialog(
        gateway: widget.gateway,
        onCreated: (_) => _loadInvoices(forceRefresh: true),
      ),
    );
  }

  void _openQuickPayment(InvoiceRecord invoice) {
    showDialog<void>(
      context: context,
      builder: (_) => QuickPaymentDialog(
        invoice: invoice,
        gateway: widget.gateway,
        onPaymentUpdated: (_) => _loadInvoices(forceRefresh: true),
      ),
    );
  }

  void _openInvoiceBuilder(InvoiceRecord invoice) {
    showDialog<void>(
      context: context,
      builder: (_) => InvoiceBuilderDialog(
        invoice: invoice,
        gateway: widget.gateway,
        onSaved: (_) => _loadInvoices(forceRefresh: true),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTokens.space16, AppTokens.space16, AppTokens.space16, AppTokens.space12),
              child: _buildHeader(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTokens.space16, 0, AppTokens.space16, AppTokens.space8),
              child: _buildSourceSwitch(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTokens.space16, 0, AppTokens.space16, AppTokens.space8),
              child: _buildSearchBar(context),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppTokens.space16, 0, AppTokens.space16, AppTokens.space12),
              child: _buildStatusFilterTabs(context),
            ),
            Expanded(
              child: RefreshIndicator(
                color: colors.primary,
                onRefresh: () => _loadInvoices(forceRefresh: true),
                child: _buildContent(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.fromOrderanId != null ? 'Invoice #${widget.fromOrderanId}' : 'Daftar Invoice & Tagihan',
                style: theme.textTheme.headlineSmall,
              ),
              const SizedBox(height: AppTokens.space4),
              Text(
                'Kelola penagihan sewa blower',
                style: theme.textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppTokens.space8),
        FilledButton.icon(
          key: const Key('invoice-create-action'),
          onPressed: _openCreateDialog,
          icon: const Icon(Icons.add_rounded),
          label: const Text('Invoice'),
        ),
      ],
    );
  }

  Widget _buildSourceSwitch(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<InvoiceSourceFilter>(
        segments: const [
          ButtonSegment(
            value: InvoiceSourceFilter.automatic,
            icon: Icon(Icons.event_note_rounded),
            label: Text('Order Sewa (Otomatis)'),
          ),
          ButtonSegment(
            value: InvoiceSourceFilter.manual,
            icon: Icon(Icons.assignment_return_outlined),
            label: Text('Reimbursement Manual'),
          ),
        ],
        selected: {_sourceFilter},
        showSelectedIcon: false,
        onSelectionChanged: (selection) => setState(() => _sourceFilter = selection.first),
      ),
    );
  }

  Widget _buildSearchBar(BuildContext context) {
    return TextField(
      controller: _searchController,
      onChanged: (_) => setState(() {}),
      textInputAction: TextInputAction.search,
      decoration: InputDecoration(
        hintText: 'Cari no. invoice, order, atau klien...',
        prefixIcon: const Icon(Icons.search_rounded),
        suffixIcon: _searchController.text.isEmpty
            ? null
            : IconButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {});
                },
                icon: const Icon(Icons.clear_rounded),
                tooltip: 'Hapus pencarian',
              ),
      ),
    );
  }

  Widget _buildStatusFilterTabs(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final filters = <({String label, InvoicePaymentStatus? status})>[
      (label: 'Semua', status: null),
      (label: 'Belum Bayar', status: InvoicePaymentStatus.unpaid),
      (label: 'Sebagian', status: InvoicePaymentStatus.partial),
      (label: 'Lunas', status: InvoicePaymentStatus.paid),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          for (var index = 0; index < filters.length; index++) ...[
            ChoiceChip(
              label: Text(filters[index].label),
              selected: _paymentFilter == filters[index].status,
              onSelected: (_) => setState(() => _paymentFilter = filters[index].status),
              selectedColor: colors.secondaryContainer,
              labelStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: _paymentFilter == filters[index].status ? colors.onSecondaryContainer : colors.onSurfaceVariant,
              ),
              side: BorderSide(color: _paymentFilter == filters[index].status ? colors.secondary : colors.outline),
            ),
            if (index < filters.length - 1) const SizedBox(width: AppTokens.space8),
          ],
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 320,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(AppTokens.space24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.error_outline_rounded, size: 40, color: colors.error),
                    const SizedBox(height: AppTokens.space12),
                    Text(_error!, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium?.copyWith(color: colors.onSurfaceVariant)),
                    const SizedBox(height: AppTokens.space16),
                    OutlinedButton(onPressed: () => _loadInvoices(forceRefresh: true), child: const Text('Coba Lagi')),
                  ],
                ),
              ),
            ),
          ),
        ],
      );
    }

    final invoices = _filteredInvoices;
    if (invoices.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 320,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.receipt_long_outlined, size: 40, color: colors.outline),
                  const SizedBox(height: AppTokens.space12),
                  Text('Tidak ada invoice yang sesuai.', style: theme.textTheme.titleSmall),
                ],
              ),
            ),
          ),
        ],
      );
    }

    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(AppTokens.space16, AppTokens.space4, AppTokens.space16, 110),
      itemCount: invoices.length,
      itemBuilder: (_, index) => _buildInvoiceCard(context, invoices[index]),
    );
  }

  ({Color background, Color foreground, String label}) _paymentBadge(BuildContext context, InvoiceRecord invoice) {
    final colors = Theme.of(context).colorScheme;
    final operational = _operationalColors(context);
    if (invoice.paymentStatus == InvoicePaymentStatus.paid) {
      return (background: operational.success, foreground: operational.onSuccess, label: invoice.paymentStatusDisplay);
    }
    if (invoice.paymentStatus == InvoicePaymentStatus.partial) {
      return (background: operational.warning, foreground: operational.onWarning, label: invoice.paymentStatusDisplay);
    }
    if (invoice.paymentStatus == InvoicePaymentStatus.cancelled) {
      return (background: operational.danger, foreground: operational.onDanger, label: invoice.paymentStatusDisplay);
    }
    final dueDate = DateTime.tryParse(invoice.dueDate);
    final overdue = dueDate != null && dueDate.isBefore(DateTime.now()) && invoice.remainingAmount > 0;
    return (
      background: overdue ? operational.danger : colors.surfaceContainerHighest,
      foreground: overdue ? operational.onDanger : colors.onSurfaceVariant,
      label: overdue ? 'Jatuh Tempo' : invoice.paymentStatusDisplay,
    );
  }

  Widget _buildInvoiceCard(BuildContext context, InvoiceRecord item) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final badge = _paymentBadge(context, item);
    return Card(
      margin: const EdgeInsets.only(bottom: AppTokens.space12),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: item.invoiceReference,
                      children: [
                        TextSpan(text: ' • ${item.quantity} Unit', style: TextStyle(color: colors.onSurfaceVariant)),
                      ],
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.labelLarge,
                  ),
                ),
                const SizedBox(width: AppTokens.space8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTokens.space8, vertical: AppTokens.space4),
                  decoration: BoxDecoration(color: badge.background, borderRadius: BorderRadius.circular(AppTokens.badgeRadius)),
                  child: Text(badge.label, style: theme.textTheme.labelSmall?.copyWith(color: badge.foreground, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space12),
            Text(item.customerName.isNotEmpty ? item.customerName : 'Klien MGRS', style: theme.textTheme.titleMedium),
            const SizedBox(height: AppTokens.space4),
            Text(item.productName, style: theme.textTheme.bodySmall?.copyWith(color: colors.onSurfaceVariant)),
            const SizedBox(height: AppTokens.space12),
            const Divider(),
            const SizedBox(height: AppTokens.space8),
            Row(
              children: [
                Expanded(
                  child: Text.rich(
                    TextSpan(
                      text: 'Total\n',
                      children: [TextSpan(text: item.totalAmountFormatted, style: theme.textTheme.labelLarge)],
                    ),
                    style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                  ),
                ),
                Text.rich(
                  TextSpan(
                    text: item.remainingAmount > 0 ? 'Sisa\n' : 'Status\n',
                    children: [
                      TextSpan(
                        text: item.remainingAmount > 0 ? item.remainingAmountFormatted : 'Lunas',
                        style: theme.textTheme.labelLarge?.copyWith(
                          color: item.remainingAmount > 0 ? badge.foreground : operationalOnSuccess(context),
                        ),
                      ),
                    ],
                  ),
                  textAlign: TextAlign.right,
                  style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              '${item.formattedInvoiceDate} (${item.rentalDays} Hari)${item.orderanId != null && item.orderanId!.isNotEmpty ? ' • #${item.orderanId}' : ''}',
              style: theme.textTheme.labelSmall?.copyWith(color: colors.onSurfaceVariant),
            ),
            const SizedBox(height: AppTokens.space12),
            Wrap(
              spacing: AppTokens.space8,
              runSpacing: AppTokens.space8,
              children: [
                OutlinedButton(
                  key: Key('btn-quick-payment-${item.id}'),
                  onPressed: () => _openQuickPayment(item),
                  child: const Text('Atur Bayar'),
                ),
                OutlinedButton(
                  key: Key('btn-open-builder-${item.id}'),
                  onPressed: () => _openInvoiceBuilder(item),
                  child: const Text('Buka Invoice'),
                ),
                IconButton(
                  key: Key('btn-delete-invoice-${item.id}'),
                  onPressed: () => _confirmDeleteInvoice(item),
                  icon: Icon(Icons.delete_outline_rounded, color: colors.error),
                  tooltip: 'Hapus Invoice',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color operationalOnSuccess(BuildContext context) => _operationalColors(context).onSuccess;

  Future<void> _confirmDeleteInvoice(InvoiceRecord item) async {
    final colors = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Hapus Invoice?'),
        content: Text('Invoice ${item.invoiceReference} (${item.customerName}) akan dihapus secara permanen.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            style: FilledButton.styleFrom(backgroundColor: colors.error),
            child: const Text('Ya, Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    try {
      await widget.gateway.deleteInvoice(item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice ${item.invoiceReference} berhasil dihapus.')));
      _loadInvoices(forceRefresh: true);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(failureMessage(error))));
    }
  }
}
