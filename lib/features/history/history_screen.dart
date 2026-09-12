import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../shared/async_state_view.dart';
import 'history_detail_screen.dart';

const activityLabels = {
  'manual_check': 'Pemeriksaan manual',
  'periodic_check': 'Pemeriksaan berkala',
  'service': 'Servis',
};

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({
    super.key,
    required this.gateway,
    required this.user,
    this.componentId,
  });
  final MaintenanceGateway gateway;
  final UserProfile user;
  final String? componentId;
  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen>
    with WidgetsBindingObserver {
  String? activity, cursor;
  DateTimeRange? range;
  List<Map<String, Object?>> items = [];
  bool busy = false;
  Object? error;
  int request = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) load();
  }

  String utcDay(DateTime date, {int addDays = 0}) => DateTime.utc(
    date.year,
    date.month,
    date.day + addDays,
  ).subtract(const Duration(hours: 7)).toIso8601String();

  Future<void> load({bool more = false}) async {
    final token = ++request;
    setState(() {
      busy = true;
      error = null;
      if (!more) {
        items = [];
        cursor = null;
      }
    });
    try {
      final data = jsonObject(
        await widget.gateway.rpc('maintenance_list_history', {
          'p_component_id': widget.componentId,
          'p_activity': activity,
          'p_from': range == null ? null : utcDay(range!.start),
          'p_until': range == null ? null : utcDay(range!.end, addDays: 1),
          'p_cursor': more ? cursor : null,
          'p_limit': 30,
        }),
      );
      if (!mounted || token != request) return;
      setState(() {
        items = [...items, ...jsonItems(data['items'])];
        cursor = data['nextCursor'] as String?;
      });
    } catch (e) {
      if (mounted && token == request) setState(() => error = e);
    } finally {
      if (mounted && token == request) setState(() => busy = false);
    }
  }

  Future<void> chooseDates() async {
    final today = DateTime.now().toUtc().add(const Duration(hours: 7));
    final selected = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(today.year, today.month, today.day),
      initialDateRange: range,
      helpText: 'Pilih rentang tanggal (WIB)',
      saveText: 'Terapkan',
    );
    if (selected != null && mounted) {
      range = selected;
      load();
    }
  }

  String dateLabel(DateTime d) => '${d.day}/${d.month}/${d.year}';

  Future<void> open(String id) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) =>
            HistoryDetailScreen(gateway: widget.gateway, eventId: id),
      ),
    );
    if (mounted) load();
  }

  @override
  Widget build(BuildContext context) => RefreshIndicator(
    onRefresh: load,
    child: PageBody(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Riwayat',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: 'Perbarui riwayat',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: busy ? null : load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Catatan pemeriksaan dan servis, dari yang terbaru.'),
        const SizedBox(height: 16),
        DropdownButtonFormField<String>(
          initialValue: activity ?? '',
          decoration: const InputDecoration(labelText: 'Jenis aktivitas'),
          items: [
            const DropdownMenuItem(value: '', child: Text('Semua aktivitas')),
            ...activityLabels.entries.map(
              (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
            ),
          ],
          onChanged: busy
              ? null
              : (value) {
                  activity = value == '' ? null : value;
                  load();
                },
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 48,
          child: OutlinedButton.icon(
            onPressed: busy ? null : chooseDates,
            icon: const Icon(Icons.date_range),
            label: Text(
              range == null
                  ? 'Semua tanggal · WIB'
                  : '${dateLabel(range!.start)} – ${dateLabel(range!.end)}',
            ),
          ),
        ),
        if (range != null) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton(
              onPressed: busy
                  ? null
                  : () {
                      range = null;
                      load();
                    },
              child: const Text('Hapus filter tanggal'),
            ),
          ),
        ],
        const SizedBox(height: 16),
        if (busy && items.isEmpty)
          const LoadingStateView(message: 'Memuat riwayat…'),
        if (error != null && items.isEmpty)
          ErrorStateView(
            onRetry: () => load(),
            error: error,
          ),
        if (!busy && error == null && items.isEmpty)
          const EmptyStateView(
            title: 'Belum ada riwayat',
            message: 'Belum ada catatan untuk ditampilkan.',
          ),
        ...items.map(
          (item) => HistoryEventCard(
            item: item,
            onTap: () => open(item['eventId'] as String),
          ),
        ),
        if (busy && items.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (error != null && items.isNotEmpty) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              failureMessage(error),
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
          TextButton(
            onPressed: () => load(more: true),
            child: const Text('Coba lagi'),
          ),
        ],
        if (!busy && cursor != null && error == null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: SizedBox(
              height: 48,
              child: OutlinedButton(
                onPressed: () => load(more: true),
                child: const Text('Muat berikutnya'),
              ),
            ),
          ),
      ],
    ),
  );
}

/// Dedicated card for displaying an immutable maintenance history event.
class HistoryEventCard extends StatelessWidget {
  const HistoryEventCard({
    super.key,
    required this.item,
    this.onTap,
  });

  final Map<String, Object?> item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = item['code']?.toString() ?? 'Kode tidak tercatat';
    final activity = item['activity']?.toString();
    final activityText = activityLabels[activity] ?? 'Aktivitas';
    final recordedAt = item['recordedAt'];
    final actor = item['actor']?.toString() ?? 'Petugas';
    final isLegacy = item['legacy'] == true;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      code,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      activityText,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stamp(recordedAt),
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '$actor${isLegacy ? ' · Catatan lama' : ''}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right),
            ],
          ),
        ),
      ),
    );
  }
}
