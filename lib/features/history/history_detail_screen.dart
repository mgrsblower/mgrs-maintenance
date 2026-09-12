import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';
import '../../shared/async_state_view.dart';
import '../components/component.dart';
import '../maintenance/checking_screen.dart';
import 'history_screen.dart';

class HistoryDetailScreen extends StatefulWidget {
  const HistoryDetailScreen({
    super.key,
    required this.gateway,
    required this.eventId,
  });
  final MaintenanceGateway gateway;
  final String eventId;
  @override
  State<HistoryDetailScreen> createState() => _HistoryDetailScreenState();
}

class _HistoryDetailScreenState extends State<HistoryDetailScreen> {
  late Future<Map<String, Object?>> future;
  bool openingCorrection = false;
  Object? correctionError;

  @override
  void initState() {
    super.initState();
    future = fetch();
  }

  Future<Map<String, Object?>> fetch() async => jsonObject(
    await widget.gateway.rpc('maintenance_get_history', {
      'p_event_id': widget.eventId,
    }),
  );

  void reload() => setState(() {
    future = fetch();
  });

  Future<void> correct(Map<String, Object?> data) async {
    setState(() {
      openingCorrection = true;
      correctionError = null;
    });
    try {
      final component = await Component.load(
        widget.gateway,
        data['componentId'] as String,
      );
      if (!mounted) return;
      await Navigator.of(context).push<void>(
        MaterialPageRoute(
          builder: (_) => CheckingScreen(
            gateway: widget.gateway,
            component: component,
            service: data['activity'] == 'service',
            correctsEventId: widget.eventId,
          ),
        ),
      );
      if (mounted) reload();
    } catch (error) {
      if (mounted) setState(() => correctionError = error);
    } finally {
      if (mounted) setState(() => openingCorrection = false);
    }
  }

  Widget condition(String title, Object? data) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final value = data == null ? null : jsonObject(data);
    return Card(
      color: colors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        side: BorderSide(color: colors.outlineVariant),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: theme.textTheme.titleMedium),
            const SizedBox(height: AppTokens.space12),
            if (value == null)
              Text('Tidak tercatat', style: theme.textTheme.bodyMedium)
            else ...[
              InfoLine(
                'Kondisi',
                conditionDisplayLabel(value['condition']?.toString()),
              ),
              InfoLine('Kelayakan pakai', usableDisplayLabel(value['usable'])),
              InfoLine(
                'Gangguan fungsi',
                value['impairedFunction']?.toString() ?? 'Tidak tercatat',
              ),
              InfoLine(
                'Catatan kondisi',
                value['note']?.toString() ?? 'Tidak tercatat',
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      appBar: AppBar(
        title: Text('Detail riwayat', style: theme.textTheme.titleLarge),
        actions: [
          IconButton(
            tooltip: 'Perbarui catatan',
            onPressed: reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: AsyncStateView(
        future: future,
        retry: reload,
        builder: (Map<String, Object?> data) => PageBody(
          children: [
            Text(
              data['code']?.toString() ?? 'Kode tidak tercatat',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: AppTokens.space8),
            _activityBadge(
              context,
              activityLabels[data['activity']] ?? 'Aktivitas',
            ),
            const SizedBox(height: AppTokens.space16),
            InfoLine('Petugas', data['actor']?.toString() ?? 'Tidak tercatat'),
            InfoLine('Waktu pencatatan', stamp(data['recordedAt'])),
            if (data['periodId'] != null)
              InfoLine(
                'Periode',
                periodDisplayLabel(data['periodId']?.toString()),
              ),
            if (data['legacy'] == true)
              _notice(
                context,
                'Catatan dari aplikasi sebelumnya. Kondisi awal dan kecocokan identitas komponen tidak tercatat lengkap.',
              ),
            condition('Sebelum', data['before']),
            const SizedBox(height: AppTokens.space12),
            condition('Sesudah', data['after']),
            const SizedBox(height: AppTokens.space16),
            if (data['activity'] == 'service') ...[
              InfoLine(
                'Masalah',
                data['problem']?.toString() ?? 'Tidak tercatat',
              ),
              InfoLine(
                'Tindakan servis',
                data['action']?.toString() ?? 'Tidak tercatat',
              ),
              InfoLine(
                'Biaya',
                data['costRecorded'] == true && data['cost'] != null
                    ? 'Rp ${data['cost']}'
                    : 'Belum dicatat',
              ),
              if (data['legacy'] == true && data['cost'] != null)
                InfoLine(
                  'Nilai pada catatan lama',
                  'Rp ${data['cost']} · belum diverifikasi',
                ),
            ],
            InfoLine(
              'Catatan aktivitas',
              data['note']?.toString() ?? 'Tidak ada catatan',
            ),
            if (data['legacy'] == false && data['componentId'] != null) ...[
              if (correctionError != null)
                _notice(context, failureMessage(correctionError), danger: true),
              OutlinedButton.icon(
                onPressed: openingCorrection ? null : () => correct(data),
                icon: const Icon(Icons.edit_note),
                label: Text(
                  openingCorrection
                      ? 'Memuat kondisi terbaru…'
                      : 'Buat catatan koreksi',
                ),
              ),
            ],
            if (data['correctsEventId'] != null) ...[
              InfoLine(
                'Alasan koreksi',
                data['correctionReason']?.toString() ?? 'Tidak tercatat',
              ),
              TextButton(
                onPressed: () => Navigator.of(context).push<void>(
                  MaterialPageRoute(
                    builder: (_) => HistoryDetailScreen(
                      gateway: widget.gateway,
                      eventId: data['correctsEventId'] as String,
                    ),
                  ),
                ),
                child: const Text('Lihat catatan yang dikoreksi'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _activityBadge(BuildContext context, String label) {
    final theme = Theme.of(context);
    final operational = theme.extension<OperationalColors>()!;
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space12,
          vertical: AppTokens.space8,
        ),
        decoration: BoxDecoration(
          color: operational.warning,
          borderRadius: BorderRadius.circular(AppTokens.badgeRadius),
        ),
        child: Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: operational.onWarning,
          ),
        ),
      ),
    );
  }

  Widget _notice(BuildContext context, String message, {bool danger = false}) {
    final theme = Theme.of(context);
    final operational = theme.extension<OperationalColors>()!;
    return Container(
      margin: const EdgeInsets.only(bottom: AppTokens.space16),
      padding: const EdgeInsets.all(AppTokens.space12),
      decoration: BoxDecoration(
        color: danger ? operational.danger : operational.warning,
        borderRadius: BorderRadius.circular(AppTokens.badgeRadius),
        border: Border.all(
          color: danger ? operational.onDanger : operational.onWarning,
        ),
      ),
      child: Text(
        message,
        style: theme.textTheme.bodyMedium?.copyWith(
          color: danger ? operational.onDanger : operational.onWarning,
        ),
      ),
    );
  }
}
