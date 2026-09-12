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
  const HistoryScreen({super.key, required this.gateway, this.componentId});
  final MaintenanceGateway gateway;
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
        OutlinedButton.icon(
          onPressed: busy ? null : chooseDates,
          icon: const Icon(Icons.date_range),
          label: Text(
            range == null
                ? 'Semua tanggal · WIB'
                : '${dateLabel(range!.start)} – ${dateLabel(range!.end)}',
          ),
        ),
        if (range != null)
          TextButton(
            onPressed: busy
                ? null
                : () {
                    range = null;
                    load();
                  },
            child: const Text('Hapus filter tanggal'),
          ),
        const SizedBox(height: 16),
        if (!busy && error == null && items.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('Belum ada riwayat yang sesuai filter.'),
          ),
        ...items.map(
          (item) => Card(
            child: ListTile(
              title: Text(item['code']?.toString() ?? 'Kode tidak tercatat'),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(activityLabels[item['activity']] ?? 'Aktivitas'),
                    Text(stamp(item['recordedAt'])),
                    Text(
                      '${item['actor'] ?? 'Petugas'}${item['legacy'] == true ? ' · Catatan lama' : ''}',
                    ),
                  ],
                ),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => open(item['eventId'] as String),
            ),
          ),
        ),
        if (busy)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (error != null) ...[
          Text(failureMessage(error)),
          TextButton(
            onPressed: () => load(more: items.isNotEmpty),
            child: const Text('Coba lagi'),
          ),
        ],
        if (!busy && cursor != null && error == null)
          OutlinedButton(
            onPressed: () => load(more: true),
            child: const Text('Muat berikutnya'),
          ),
      ],
    ),
  );
}
