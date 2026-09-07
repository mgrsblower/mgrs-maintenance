import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../shared/async_state_view.dart';
import '../../shared/condition_badge.dart';
import '../maintenance/checking_screen.dart';
import '../history/history_screen.dart';
import 'component.dart';

class ComponentDetailScreen extends StatefulWidget {
  const ComponentDetailScreen({
    super.key,
    required this.gateway,
    required this.id,
    this.taskId,
    this.periodId,
  });
  final MaintenanceGateway gateway;
  final String id;
  final String? taskId, periodId;
  @override
  State<ComponentDetailScreen> createState() => _ComponentDetailScreenState();
}

class _ComponentDetailScreenState extends State<ComponentDetailScreen> {
  late Future<Component> future;
  @override
  void initState() {
    super.initState();
    future = Component.load(widget.gateway, widget.id);
  }

  void reload() => setState(() {
    future = Component.load(widget.gateway, widget.id);
  });
  Future<void> record(Component c, bool service) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => CheckingScreen(
          gateway: widget.gateway,
          component: c,
          service: service,
          taskId: service ? null : widget.taskId,
          periodId: service ? null : widget.periodId,
        ),
      ),
    );
    if (mounted) reload();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Detail komponen'),
      actions: [
        IconButton(
          tooltip: 'Perbarui kondisi',
          onPressed: reload,
          icon: const Icon(Icons.refresh),
        ),
      ],
    ),
    body: AsyncStateView(
      future: future,
      retry: reload,
      builder: (Component c) => PageBody(
        children: [
          Text(c.kind, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          SelectableText(
            c.code,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          Align(
            alignment: Alignment.centerLeft,
            child: ConditionBadge(c.condition),
          ),
          const SizedBox(height: 16),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  InfoLine('Boleh digunakan', c.usable),
                  InfoLine('Gangguan fungsi', c.impairedFunction),
                  InfoLine('Catatan kondisi', c.note ?? 'Tidak ada catatan'),
                  InfoLine('Pemeriksaan terakhir', stamp(c.lastCheckingAt)),
                  InfoLine('Servis terakhir', stamp(c.lastServiceAt)),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => record(c, false),
            icon: const Icon(Icons.fact_check_outlined),
            label: Text(
              widget.taskId == null
                  ? 'Catat pemeriksaan'
                  : 'Pemeriksaan berkala',
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () => record(c, true),
            icon: const Icon(Icons.build_outlined),
            label: const Text('Catat servis'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.of(context).push<void>(
              MaterialPageRoute(
                builder: (_) => Scaffold(
                  appBar: AppBar(title: const Text('Riwayat komponen')),
                  body: HistoryScreen(
                    gateway: widget.gateway,
                    componentId: c.id,
                  ),
                ),
              ),
            ),
            child: const Text('Lihat seluruh riwayat'),
          ),
        ],
      ),
    ),
  );
}
