import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../design_system/components/mgrs_state_view.dart';
import '../../design_system/mgrs_tokens.dart';
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
  String get activeFilterDescription {
    final filters = <String>[];
    if (activity != null) {
      filters.add('aktivitas ${activityLabels[activity] ?? activity}');
    }
    if (range != null) {
      filters.add(
        'tanggal ${dateLabel(range!.start)} sampai ${dateLabel(range!.end)} WIB',
      );
    }
    return filters.join(' dan ');
  }

  void clearFilters() {
    setState(() {
      range = null;
      activity = null;
    });
    load();
  }

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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Riwayat',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: MgrsSpacing.sm),
                  const Text(
                    'Catatan pemeriksaan dan servis, dari yang terbaru.',
                  ),
                ],
              ),
            ),
            IconButton(
              tooltip: 'Perbarui riwayat',
              constraints: const BoxConstraints.tightFor(
                width: MgrsSizes.minTouch,
                height: MgrsSizes.minTouch,
              ),
              onPressed: busy ? null : load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: MgrsSpacing.base),
        DropdownButtonFormField<String>(
          key: ValueKey(activity),
          isExpanded: true,
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
        const SizedBox(height: MgrsSpacing.md),
        ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: double.infinity,
            minHeight: MgrsSizes.minTouch,
          ),
          child: OutlinedButton(
            onPressed: busy ? null : chooseDates,
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: MgrsSpacing.sm,
              runSpacing: MgrsSpacing.xs,
              children: [
                const Icon(Icons.date_range),
                Text(
                  range == null
                      ? 'Semua tanggal, WIB'
                      : '${dateLabel(range!.start)} sampai ${dateLabel(range!.end)}',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
        if (range != null)
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
        const SizedBox(height: MgrsSpacing.base),
        if (!busy && error == null && items.isEmpty)
          MgrsStateView.empty(
            title: range == null && activity == null
                ? 'Belum ada riwayat aktivitas'
                : 'Tidak ada riwayat yang sesuai filter',
            message: range == null && activity == null
                ? 'Pemeriksaan manual, pemeriksaan berkala, dan servis akan muncul setelah dicatat.'
                : 'Tidak ada data untuk $activeFilterDescription.',
            actionLabel: range == null && activity == null
                ? 'Perbarui riwayat'
                : 'Hapus pencarian',
            onAction: range == null && activity == null ? load : clearFilters,
          ),
        ...items.map(
          (item) => Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(MgrsRadii.card),
              onTap: () => open(item['eventId'] as String),
              child: Padding(
                padding: const EdgeInsets.all(MgrsSpacing.base),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item['code']?.toString() ?? 'Kode tidak tercatat',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: MgrsSpacing.sm),
                          Text(
                            activityLabels[item['activity']] ??
                                'Aktivitas tidak tercatat',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: MgrsSpacing.xs),
                          Text(stamp(item['recordedAt'])),
                          const SizedBox(height: MgrsSpacing.xs),
                          Text(
                            '${item['actor'] ?? 'Petugas tidak tercatat'}${item['legacy'] == true ? ' · Catatan lama' : ''}',
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: MgrsSpacing.sm),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (busy && items.isEmpty)
          const MgrsStateView.loading(title: 'Memuat riwayat...'),
        if (busy && items.isNotEmpty)
          const Padding(
            padding: EdgeInsets.all(MgrsSpacing.xl),
            child: Center(child: CircularProgressIndicator()),
          ),
        if (error != null)
          MgrsStateView.error(
            title: 'Riwayat gagal dimuat',
            message: 'Periksa koneksi lalu coba lagi.',
            actionLabel: 'Coba lagi',
            onAction: () => load(more: items.isNotEmpty),
          ),
        if (!busy && cursor != null && error == null)
          OutlinedButton(
            onPressed: () => load(more: true),
            child: const Text('Muat berikutnya'),
          ),
      ],
    ),
  );
}
