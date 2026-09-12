import 'package:flutter/material.dart';

import '../../app/gateway.dart';
import '../../shared/async_state_view.dart';
import '../schedule/order_model.dart';

/// PIC MGRS landing surface backed only by order data from the gateway.
class PicHomeScreen extends StatefulWidget {
  const PicHomeScreen({
    super.key,
    required this.gateway,
    required this.user,
    required this.onOpenOrdersTab,
    required this.onOpenInvoicesTab,
  });

  final MaintenanceGateway gateway;
  final UserProfile user;
  final VoidCallback onOpenOrdersTab;
  final VoidCallback onOpenInvoicesTab;

  @override
  State<PicHomeScreen> createState() => _PicHomeScreenState();
}

class _PicHomeScreenState extends State<PicHomeScreen> {
  late Future<List<OrderanSewa>> _orders;

  @override
  void initState() {
    super.initState();
    _orders = _loadOrders();
  }

  Future<List<OrderanSewa>> _loadOrders({bool forceRefresh = false}) async {
    final orders = await widget.gateway.fetchUpcomingOrders(
      limit: 10,
      forceRefresh: forceRefresh,
    );
    return orders.where((order) => order.isUpcoming).toList();
  }

  void _retry() {
    setState(() {
      _orders = _loadOrders(forceRefresh: true);
    });
  }

  String _orderDate(BuildContext context, DateTime date) {
    return MaterialLocalizations.of(context).formatMediumDate(date.toLocal());
  }

  Widget _orderList(BuildContext context, List<OrderanSewa> orders) {
    return Column(
      children: [
        for (var index = 0; index < orders.length; index++) ...[
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(orders[index].namaEvent),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (orders[index].namaClient case final client?
                    when client.trim().isNotEmpty)
                  Text(client.trim()),
                if (orders[index].tanggalPemasangan case final date?)
                  Text(_orderDate(context, date)),
                if (orders[index].statusOrderan case final status?
                    when status.trim().isNotEmpty)
                  Text(status.trim()),
              ],
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: widget.onOpenOrdersTab,
          ),
          if (index != orders.length - 1) const Divider(height: 1),
        ],
      ],
    );
  }

  Widget _ordersState(BuildContext context) {
    return AsyncStateView<List<OrderanSewa>>(
      future: _orders,
      retry: _retry,
      empty: () => const EmptyStateView(
        title: 'Belum ada orderan',
        message: 'Belum ada orderan yang perlu ditindaklanjuti.',
      ),
      builder: (orders) => _orderList(context, orders),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Text('Beranda PIC MGRS', style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(widget.user.displayName, style: textTheme.bodyLarge),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: widget.onOpenOrdersTab,
                icon: const Icon(Icons.event_note_outlined),
                label: const Text('Buka orderan'),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: widget.onOpenInvoicesTab,
                icon: const Icon(Icons.receipt_long_outlined),
                label: const Text('Buka invoice'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 32),
        Text('Orderan perlu ditindaklanjuti', style: textTheme.titleLarge),
        const SizedBox(height: 12),
        _ordersState(context),
      ],
    );
  }
}
