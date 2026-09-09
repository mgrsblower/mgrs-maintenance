import 'package:flutter/material.dart';
import '../app/app_theme.dart';
import '../app/gateway.dart';

class PageBody extends StatelessWidget {
  const PageBody({super.key, required this.children});
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Align(
    alignment: Alignment.topCenter,
    child: ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: AppTokens.maxWidth),
      child: ListView(
        padding: const EdgeInsets.all(AppTokens.space),
        children: children,
      ),
    ),
  );
}

class AsyncStateView<T> extends StatelessWidget {
  const AsyncStateView({
    super.key,
    required this.future,
    required this.builder,
    required this.retry,
  });
  final Future<T> future;
  final Widget Function(T) builder;
  final VoidCallback retry;
  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return const Center(child: CircularProgressIndicator());
      }
      if (snapshot.hasError) {
        return PageBody(
          children: [
            const Icon(Icons.cloud_off_outlined, size: 40),
            const SizedBox(height: 16),
            Text(failureMessage(snapshot.error), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton(onPressed: retry, child: const Text('Coba lagi')),
          ],
        );
      }
      return builder(snapshot.data as T);
    },
  );
}

String stamp(Object? value) {
  final parsed = DateTime.tryParse(value?.toString() ?? '');
  if (parsed == null) return 'Belum tercatat';
  final d = parsed.toUtc().add(const Duration(hours: 7));
  return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} WIB';
}

String conditionDisplayLabel(String? condition) {
  if (condition == null || condition.trim().isEmpty) return 'Belum Diperiksa';
  final normalized = condition.trim();
  switch (normalized) {
    case 'OK':
    case 'Layak Pakai':
      return 'Layak Pakai';
    case 'Service':
    case 'Perlu Servis':
    case 'needs_service':
    case 'under_maintenance':
      return 'Perlu Servis';
    case 'Rusak Ringan':
      return 'Rusak Ringan';
    case 'Rusak Berat':
    case 'Gangguan Fungsi':
      return 'Gangguan Fungsi';
    case 'Hilang':
      return 'Unit Hilang';
    default:
      return normalized;
  }
}

String usableDisplayLabel(Object? value) {
  if (value == null) return 'Belum tercatat';
  if (value == true || value == 'true' || value == 'Ya' || value == 'ya') {
    return 'Layak Digunakan';
  }
  if (value == false || value == 'false' || value == 'Tidak' || value == 'tidak') {
    return 'Tidak Boleh Digunakan';
  }
  return value.toString();
}

String periodDisplayLabel(String? periodId) {
  if (periodId == null || periodId.isEmpty || periodId == 'current') {
    return 'Bulan Berjalan';
  }
  final parts = periodId.split('-');
  if (parts.length == 2) {
    final year = parts[0];
    final monthNum = int.tryParse(parts[1]);
    if (monthNum != null && monthNum >= 1 && monthNum <= 12) {
      const months = [
        'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
        'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
      ];
      return '${months[monthNum - 1]} $year';
    }
  }
  return periodId;
}

class InfoLine extends StatelessWidget {
  const InfoLine(this.label, this.value, {super.key});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: AppTokens.muted),
        ),
        const SizedBox(height: 4),
        Text(value),
      ],
    ),
  );
}
