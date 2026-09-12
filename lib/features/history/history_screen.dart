import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
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
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(
        title: Text('Riwayat', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            tooltip: 'Perbarui riwayat',
            onPressed: busy ? null : load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: load,
        color: colors.primary,
        child: PageBody(
          children: [
            Text('Catatan layanan', style: theme.textTheme.headlineSmall),
            const SizedBox(height: AppTokens.space8),
            Text(
              'Pemeriksaan dan servis terbaru tersimpan di sini.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTokens.space16),
            DropdownButtonFormField<String>(
              initialValue: activity ?? '',
              decoration: const InputDecoration(labelText: 'Jenis aktivitas'),
              items: [
                const DropdownMenuItem(
                  value: '',
                  child: Text('Semua aktivitas'),
                ),
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
            const SizedBox(height: AppTokens.space12),
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
            const SizedBox(height: AppTokens.space16),
            if (!busy && error == null && items.isEmpty)
              _stateMessage(
                context,
                Icons.inbox_outlined,
                'Belum ada riwayat yang sesuai filter.',
              ),
            ...items.map((item) => _historyItem(context, item)),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(AppTokens.space24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (error != null) ...[
              _stateMessage(
                context,
                Icons.error_outline,
                failureMessage(error),
                danger: true,
              ),
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
      ),
    );
  }

  Widget _historyItem(BuildContext context, Map<String, Object?> item) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final legacy = item['legacy'] == true;
    return Card(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: ListTile(
        minVerticalPadding: AppTokens.space12,
        title: Text(
          item['code']?.toString() ?? 'Kode tidak tercatat',
          style: theme.textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: AppTokens.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                activityLabels[item['activity']] ?? 'Aktivitas',
                style: theme.textTheme.bodyMedium,
              ),
              Text(stamp(item['recordedAt']), style: theme.textTheme.bodySmall),
              Text(
                '${item['actor'] ?? 'Petugas'}${legacy ? ' · Catatan lama' : ''}',
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        trailing: Icon(Icons.chevron_right, color: colors.onSurfaceVariant),
        onTap: () => open(item['eventId'] as String),
      ),
    );
  }

  Widget _stateMessage(
    BuildContext context,
    IconData icon,
    String message, {
    bool danger = false,
  }) {
    final theme = Theme.of(context);
    final operational =
        theme.extension<OperationalColors>() ??
        const OperationalColors(
          success: AppTokens.successSurface,
          onSuccess: AppTokens.success,
          warning: AppTokens.warningSurface,
          onWarning: AppTokens.warning,
          danger: AppTokens.dangerSurface,
          onDanger: AppTokens.danger,
        );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppTokens.space24),
      child: Row(
        children: [
          Icon(
            icon,
            color: danger
                ? operational.onDanger
                : theme.colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: AppTokens.space12),
          Expanded(child: Text(message, style: theme.textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
