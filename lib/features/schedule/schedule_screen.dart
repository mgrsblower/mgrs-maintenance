import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';
import '../../shared/async_state_view.dart';
import '../components/component_detail_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key, required this.gateway});
  final MaintenanceGateway gateway;

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleScreenState extends State<ScheduleScreen>
    with WidgetsBindingObserver {
  String month = 'current';
  String? kind, status, cursor;
  final search = TextEditingController();
  Map<String, Object?>? period;
  List<Map<String, Object?>> items = [];
  int? total, completed;
  int request = 0;
  bool busy = false;
  Object? error;

  static const states = {
    'scheduled': 'Terjadwal',
    'due': 'Perlu diperiksa',
    'overdue': 'Terlambat',
    'completed': 'Selesai',
    'completed_late': 'Selesai terlambat',
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    load();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    search.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) load();
  }

  Future<void> load({bool more = false}) async {
    final token = ++request;
    setState(() {
      busy = true;
      error = null;
      if (!more) {
        items = [];
        cursor = null;
        period = null;
        total = null;
        completed = null;
      }
    });
    try {
      final data = jsonObject(
        await widget.gateway.rpc('maintenance_list_tasks', {
          'p_period_id': month,
          'p_kind': kind,
          'p_status': status,
          'p_code': search.text.trim().isEmpty ? null : search.text.trim(),
          'p_cursor': more ? cursor : null,
          'p_limit': 30,
        }),
      );
      if (!mounted || token != request) return;
      setState(() {
        period = jsonObject(data['period']);
        month = period!['id'] as String;
        items = [...items, ...jsonItems(data['items'])];
        cursor = data['nextCursor'] as String?;
        total = data['total'] as int?;
        completed = data['completed'] as int?;
      });
    } catch (e) {
      if (mounted && token == request) setState(() => error = e);
    } finally {
      if (mounted && token == request) setState(() => busy = false);
    }
  }

  void move(int delta) {
    final date = DateTime.tryParse('$month-01');
    if (date == null) return;
    final next = DateTime(date.year, date.month + delta);
    month = '${next.year}-${next.month.toString().padLeft(2, '0')}';
    load();
  }

  Future<void> open(Map<String, Object?> item) async {
    final id = item['componentId'] as String?;
    if (id == null) return;
    final incomplete =
        item['completedAt'] == null && item['status'] != 'scheduled';
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ComponentDetailScreen(
          gateway: widget.gateway,
          id: id,
          taskId: incomplete ? item['id'] as String : null,
          periodId: item['periodId'] as String,
        ),
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
      body: RefreshIndicator(
        onRefresh: load,
        color: colors.primary,
        child: PageBody(
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Pemeriksaan berkala',
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                IconButton(
                  tooltip: 'Perbarui jadwal',
                  onPressed: busy ? null : load,
                  icon: const Icon(Icons.refresh),
                ),
              ],
            ),
            const SizedBox(height: AppTokens.space8),
            Text(
              'Sabtu keempat dan Minggu berikutnya setiap bulan.',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: AppTokens.space16),
            Card(
              child: Row(
                children: [
                  IconButton(
                    tooltip: 'Bulan sebelumnya',
                    onPressed: busy || month == 'current'
                        ? null
                        : () => move(-1),
                    icon: const Icon(Icons.chevron_left),
                  ),
                  Expanded(
                    child: Text(
                      month == 'current'
                          ? 'Memuat bulan berjalan…'
                          : periodDisplayLabel(month),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    tooltip: 'Bulan berikutnya',
                    onPressed: busy || month == 'current'
                        ? null
                        : () => move(1),
                    icon: const Icon(Icons.chevron_right),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTokens.space16),
            DropdownButtonFormField<String>(
              initialValue: kind ?? '',
              decoration: const InputDecoration(labelText: 'Jenis komponen'),
              items: const [
                DropdownMenuItem(value: '', child: Text('Semua komponen')),
                DropdownMenuItem(value: 'Kepala', child: Text('Kepala')),
                DropdownMenuItem(value: 'Batang', child: Text('Batang')),
                DropdownMenuItem(value: 'Tabung', child: Text('Tabung')),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      kind = value == '' ? null : value;
                      load();
                    },
            ),
            const SizedBox(height: AppTokens.space12),
            DropdownButtonFormField<String>(
              initialValue: status ?? '',
              decoration: const InputDecoration(
                labelText: 'Status pemeriksaan',
              ),
              items: [
                const DropdownMenuItem(value: '', child: Text('Semua status')),
                ...states.entries.map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                ),
              ],
              onChanged: busy
                  ? null
                  : (value) {
                      status = value == '' ? null : value;
                      load();
                    },
            ),
            const SizedBox(height: AppTokens.space12),
            TextField(
              controller: search,
              decoration: InputDecoration(
                labelText: 'Cari kode komponen',
                suffixIcon: IconButton(
                  tooltip: 'Cari komponen',
                  onPressed: busy ? null : load,
                  icon: const Icon(Icons.search),
                ),
              ),
              textInputAction: TextInputAction.search,
              onSubmitted: busy ? null : (_) => load(),
            ),
            const SizedBox(height: AppTokens.space16),
            if (period != null) ...[
              InfoLine('Jadwal mulai', stamp(period!['opensAt'])),
              InfoLine('Batas pemeriksaan', stamp(period!['closesAt'])),
              if (period!['snapshotState'] == 'preview')
                Text(
                  'Jadwal belum dimulai. Daftar komponen akan ditetapkan saat periode dibuka.',
                  style: theme.textTheme.bodyMedium,
                ),
              if (period!['snapshotState'] == 'not_generated')
                Text(
                  'Daftar pemeriksaan bulan ini belum tersedia. Hubungi admin untuk memeriksa jadwal.',
                  style: theme.textTheme.bodyMedium,
                ),
              if (total != null)
                Text(
                  '$completed dari $total pemeriksaan selesai sesuai filter.',
                  style: theme.textTheme.titleMedium,
                ),
              if (period!['snapshotState'] == 'ready' && items.isEmpty && !busy)
                Padding(
                  padding: const EdgeInsets.symmetric(
                    vertical: AppTokens.space24,
                  ),
                  child: Text(
                    'Tidak ada komponen yang sesuai filter.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
            ],
            ...items.map(
              (item) => Card(
                child: ListTile(
                  isThreeLine: true,
                  title: Text(
                    item['code'] as String,
                    style: theme.textTheme.titleMedium,
                  ),
                  subtitle: Text(
                    '${item['kind']}\n${states[item['status']] ?? 'Status belum tersedia'}',
                    style: theme.textTheme.labelMedium,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => open(item),
                ),
              ),
            ),
            if (busy)
              const Padding(
                padding: EdgeInsets.all(AppTokens.space24),
                child: Center(child: CircularProgressIndicator()),
              ),
            if (error != null) ...[
              Text(
                failureMessage(error),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: colors.error,
                ),
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
}
