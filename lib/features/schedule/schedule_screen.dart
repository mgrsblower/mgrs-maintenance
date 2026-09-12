import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../shared/async_state_view.dart';
import '../components/component_detail_screen.dart';

class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({
    super.key,
    required this.gateway,
    required this.user,
  });
  final MaintenanceGateway gateway;
  final UserProfile user;
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
    'completed': 'Selesai diperiksa',
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
          user: widget.user,
          id: id,
          taskId: incomplete ? item['id'] as String : null,
          periodId: item['periodId'] as String,
        ),
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
                'Pemeriksaan berkala',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            ),
            IconButton(
              tooltip: 'Perbarui jadwal',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: busy ? null : load,
              icon: const Icon(Icons.refresh),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text('Sabtu keempat dan Minggu berikutnya setiap bulan.'),
        const SizedBox(height: 16),
        Row(
          children: [
            IconButton(
              tooltip: 'Bulan sebelumnya',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: busy || month == 'current' ? null : () => move(-1),
              icon: const Icon(Icons.chevron_left),
            ),
            Expanded(
              child: Text(
                month == 'current'
                    ? 'Memuat bulan berjalan…'
                    : periodDisplayLabel(month),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            IconButton(
              tooltip: 'Bulan berikutnya',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: busy || month == 'current' ? null : () => move(1),
              icon: const Icon(Icons.chevron_right),
            ),
          ],
        ),
        const SizedBox(height: 16),
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
              : (v) {
                  kind = v == '' ? null : v;
                  load();
                },
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          initialValue: status ?? '',
          decoration: const InputDecoration(labelText: 'Status pemeriksaan'),
          items: [
            const DropdownMenuItem(value: '', child: Text('Semua status')),
            ...states.entries.map(
              (e) => DropdownMenuItem(value: e.key, child: Text(e.value)),
            ),
          ],
          onChanged: busy
              ? null
              : (v) {
                  status = v == '' ? null : v;
                  load();
                },
        ),
        const SizedBox(height: 12),
        TextField(
          controller: search,
          decoration: InputDecoration(
            labelText: 'Cari kode komponen',
            suffixIcon: IconButton(
              tooltip: 'Cari komponen',
              constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              onPressed: busy ? null : load,
              icon: const Icon(Icons.search),
            ),
          ),
          textInputAction: TextInputAction.search,
          onSubmitted: busy ? null : (_) => load(),
        ),
        const SizedBox(height: 16),
        if (period != null) ...[
          InfoLine('Jadwal mulai', stamp(period!['opensAt'])),
          InfoLine('Batas pemeriksaan', stamp(period!['closesAt'])),
          if (period!['snapshotState'] == 'preview')
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Jadwal belum dimulai. Daftar komponen akan ditetapkan saat periode dibuka.',
              ),
            ),
          if (period!['snapshotState'] == 'not_generated')
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Text(
                'Daftar pemeriksaan bulan ini belum tersedia. Hubungi admin untuk memeriksa jadwal.',
              ),
            ),
          if (total != null)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                '$completed dari $total pemeriksaan selesai sesuai filter.',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
        ],
        if (busy && items.isEmpty)
          const LoadingStateView(message: 'Memuat jadwal pemeriksaan…'),
        if (error != null && items.isEmpty)
          ErrorStateView(
            onRetry: () => load(),
            error: error,
          ),
        if (!busy &&
            error == null &&
            items.isEmpty &&
            period != null &&
            period!['snapshotState'] == 'ready')
          const EmptyStateView(
            title: 'Tidak ada tugas pemeriksaan',
            message: 'Tidak ada komponen yang sesuai filter.',
          ),
        ...items.map(
          (item) => PeriodicTaskCard(
            task: item,
            onTap: () => open(item),
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

/// Dedicated card for displaying a periodic maintenance task.
/// Explicitly separates periodic task completion from physical component condition.
class PeriodicTaskCard extends StatelessWidget {
  const PeriodicTaskCard({
    super.key,
    required this.task,
    this.onTap,
  });

  final Map<String, Object?> task;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final code = task['code']?.toString() ?? '-';
    final kind = task['kind']?.toString() ?? '-';
    final rawStatus = task['status']?.toString() ?? '';
    final statusLabel =
        _ScheduleScreenState.states[rawStatus] ?? 'Status belum tersedia';
    final condition =
        task['condition']?.toString() ?? task['componentCondition']?.toString();
    final completedAt = task['completedAt'];

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
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        const SizedBox(height: 2),
                        Text(
                          kind,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _statusBadge(context, rawStatus, statusLabel),
                ],
              ),
              if (condition != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      'Kondisi: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    Text(
                      conditionDisplayLabel(condition),
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: condition.toLowerCase().contains('rusak')
                            ? theme.colorScheme.error
                            : theme.colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ],
              if (completedAt != null) ...[
                const SizedBox(height: 4),
                Text(
                  'Selesai pada: ${stamp(completedAt)}',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _statusBadge(BuildContext context, String rawStatus, String label) {
    final theme = Theme.of(context);
    final (Color bg, Color fg) = switch (rawStatus) {
      'completed' => (
        theme.colorScheme.primaryContainer,
        theme.colorScheme.onPrimaryContainer,
      ),
      'completed_late' => (
        theme.colorScheme.tertiaryContainer,
        theme.colorScheme.onTertiaryContainer,
      ),
      'overdue' => (
        theme.colorScheme.errorContainer,
        theme.colorScheme.onErrorContainer,
      ),
      'due' => (
        theme.colorScheme.secondaryContainer,
        theme.colorScheme.onSecondaryContainer,
      ),
      _ => (
        theme.colorScheme.surfaceContainerHighest,
        theme.colorScheme.onSurfaceVariant,
      ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: theme.textTheme.labelMedium?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
