import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../design_system/components/mgrs_app_bar.dart';
import '../../design_system/components/mgrs_state_view.dart';
import '../../design_system/mgrs_tokens.dart';
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
    final value = data == null ? null : jsonObject(data);
    return Container(
      decoration: BoxDecoration(
        color: MgrsColors.surface,
        borderRadius: BorderRadius.circular(MgrsRadii.card),
      ),
      padding: const EdgeInsets.all(MgrsSpacing.base),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: MgrsSpacing.md),
          if (value == null)
            const Text('Kondisi tidak tersedia pada catatan ini.')
          else ...[
            if (value['condition'] != null)
              InfoLine(
                'Kondisi',
                conditionDisplayLabel(value['condition']?.toString()),
              ),
            if (value['usable'] != null)
              InfoLine('Kelayakan pakai', usableDisplayLabel(value['usable'])),
            if (value['impairedFunction'] != null)
              InfoLine('Gangguan fungsi', value['impairedFunction'].toString()),
            if (value['note'] != null)
              InfoLine('Catatan kondisi', value['note'].toString()),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: MgrsDetailAppBar(
      title: 'Detail riwayat',
      actions: [
        MgrsAppBarAction(
          icon: Icons.refresh,
          tooltip: 'Perbarui catatan',
          onPressed: reload,
        ),
      ],
    ),
    body: FutureBuilder<Map<String, Object?>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const MgrsStateView.loading(title: 'Memuat detail riwayat...');
        }
        if (snapshot.hasError) {
          return MgrsStateView.error(
            title: 'Detail riwayat gagal dimuat',
            message: 'Periksa koneksi lalu coba lagi.',
            actionLabel: 'Coba lagi',
            onAction: reload,
          );
        }
        final data = snapshot.data!;
        final activity =
            activityLabels[data['activity']] ?? 'Aktivitas tidak tercatat';
        return PageBody(
          children: [
            Text(
              data['code']?.toString() ?? 'Kode tidak tercatat',
              style: Theme.of(
                context,
              ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: MgrsSpacing.sm),
            Text(
              activity,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: MgrsColors.ink,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: MgrsSpacing.lg),
            if (data['actor'] != null)
              InfoLine('Petugas', data['actor'].toString()),
            if (data['recordedAt'] != null)
              InfoLine('Waktu pencatatan', stamp(data['recordedAt'])),
            if (data['periodId'] != null)
              InfoLine(
                'Periode',
                periodDisplayLabel(data['periodId']?.toString()),
              ),
            if (data['legacy'] == true)
              const Padding(
                padding: EdgeInsets.only(bottom: MgrsSpacing.base),
                child: Text(
                  'Catatan dari aplikasi sebelumnya. Kondisi awal dan kecocokan identitas komponen tidak tercatat lengkap.',
                ),
              ),
            condition('Sebelum', data['before']),
            const SizedBox(height: MgrsSpacing.md),
            condition('Sesudah', data['after']),
            const SizedBox(height: MgrsSpacing.lg),
            if (data['activity'] == 'service') ...[
              if (data['problem'] != null)
                InfoLine('Masalah', data['problem'].toString()),
              if (data['action'] != null)
                InfoLine('Tindakan servis', data['action'].toString()),
              if (data['costRecorded'] == true && data['cost'] != null)
                InfoLine('Biaya', 'Rp ${data['cost']}'),
              if (data['legacy'] == true && data['cost'] != null)
                InfoLine(
                  'Nilai pada catatan lama',
                  'Rp ${data['cost']} · belum diverifikasi',
                ),
            ],
            if (data['note'] != null)
              InfoLine('Catatan aktivitas', data['note'].toString()),
            if (data['legacy'] == false && data['componentId'] != null) ...[
              if (correctionError != null)
                const Padding(
                  padding: EdgeInsets.only(bottom: MgrsSpacing.sm),
                  child: Text(
                    'Kondisi terbaru gagal dimuat. Periksa koneksi lalu coba lagi.',
                  ),
                ),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: openingCorrection ? null : () => correct(data),
                  icon: const Icon(Icons.edit_note),
                  label: Text(
                    openingCorrection
                        ? 'Memuat kondisi terbaru...'
                        : 'Buat catatan koreksi',
                  ),
                ),
              ),
            ],
            if (data['correctsEventId'] != null) ...[
              if (data['correctionReason'] != null)
                InfoLine('Alasan koreksi', data['correctionReason'].toString()),
              SizedBox(
                width: double.infinity,
                child: TextButton(
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
              ),
            ],
          ],
        );
      },
    ),
  );
}
