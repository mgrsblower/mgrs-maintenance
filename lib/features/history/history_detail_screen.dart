import 'package:flutter/material.dart';
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
    final value = data == null ? null : jsonObject(data);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            if (value == null)
              const Text('Tidak tercatat')
            else ...[
              InfoLine(
                'Kondisi',
                value['condition']?.toString() ?? 'Tidak tercatat',
              ),
              InfoLine(
                'Boleh digunakan',
                value['usable']?.toString() ?? 'Tidak tercatat',
              ),
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
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('Detail riwayat'),
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
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          Text(activityLabels[data['activity']] ?? 'Aktivitas'),
          const SizedBox(height: 16),
          InfoLine('Petugas', data['actor']?.toString() ?? 'Tidak tercatat'),
          InfoLine('Waktu pencatatan', stamp(data['recordedAt'])),
          if (data['periodId'] != null)
            InfoLine('Periode', data['periodId'].toString()),
          if (data['legacy'] == true)
            const Padding(
              padding: EdgeInsets.only(bottom: 16),
              child: Text(
                'Catatan dari aplikasi sebelumnya. Kondisi awal dan kecocokan identitas komponen tidak tercatat lengkap.',
              ),
            ),
          condition('Sebelum', data['before']),
          const SizedBox(height: 12),
          condition('Sesudah', data['after']),
          const SizedBox(height: 16),
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
              data['costRecorded'] == true
                  ? 'Rp ${data['cost']}'
                  : 'Belum diketahui',
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
            if (correctionError != null) Text(failureMessage(correctionError)),
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
