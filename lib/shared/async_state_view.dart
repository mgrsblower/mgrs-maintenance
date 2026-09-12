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
    this.empty,
    this.error,
    this.permission,
    this.conflict,
    this.loading,
    this.isEmpty,
  });

  final Future<T> future;
  final Widget Function(T) builder;
  final VoidCallback retry;
  final Widget Function()? empty;
  final Widget Function(Object? error)? error;
  final Widget Function()? permission;
  final Widget Function(Object? error)? conflict;
  final Widget Function()? loading;
  final bool Function(T value)? isEmpty;

  @override
  Widget build(BuildContext context) => FutureBuilder<T>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState != ConnectionState.done) {
        return loading?.call() ?? const LoadingStateView();
      }
      final failure = snapshot.error;
      if (failure != null) {
        if (_isPermissionFailure(failure)) {
          return permission?.call() ??
              PermissionStateView(onRetry: retry, error: failure);
        }
        if (_isConflictFailure(failure)) {
          return conflict?.call(failure) ??
              ConflictStateView(onRetry: retry, error: failure);
        }
        return error?.call(failure) ??
            ErrorStateView(onRetry: retry, error: failure);
      }
      final value = snapshot.data;
      if (value == null || isEmpty?.call(value) == true || _isEmpty(value)) {
        return empty?.call() ?? const EmptyStateView();
      }
      return builder(value);
    },
  );

  bool _isEmpty(T value) {
    if (value is String) return value.trim().isEmpty;
    if (value is Iterable) return value.isEmpty;
    if (value is Map) return value.isEmpty;
    return false;
  }

  bool _isPermissionFailure(Object value) {
    return value is AppFailure &&
        {'forbidden', 'permission_denied', 'unauthenticated'}.contains(value.code);
  }

  bool _isConflictFailure(Object value) {
    return value is AppFailure &&
        {'conflict', 'version_conflict'}.contains(value.code);
  }
}

class LoadingStateView extends StatelessWidget {
  const LoadingStateView({super.key, this.message = 'Memuat data…'});
  final String message;

  @override
  Widget build(BuildContext context) => StatePanel(
    icon: Icons.hourglass_empty,
    title: message,
    showProgress: true,
  );
}

class EmptyStateView extends StatelessWidget {
  const EmptyStateView({
    super.key,
    this.title = 'Belum ada data',
    this.message = 'Belum ada catatan untuk ditampilkan.',
  });
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) =>
      StatePanel(icon: Icons.inbox_outlined, title: title, message: message);
}

class ErrorStateView extends StatelessWidget {
  const ErrorStateView({
    super.key,
    required this.onRetry,
    this.error,
  });
  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) => StatePanel(
    icon: Icons.cloud_off_outlined,
    title: 'Data belum dapat dimuat',
    message: failureMessage(error),
    action: OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
  );
}

class PermissionStateView extends StatelessWidget {
  const PermissionStateView({
    super.key,
    required this.onRetry,
    this.error,
  });
  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) => StatePanel(
    icon: Icons.lock_outline,
    title: 'Akses tidak tersedia',
    message: failureMessage(error),
    action: OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
  );
}

class ConflictStateView extends StatelessWidget {
  const ConflictStateView({
    super.key,
    required this.onRetry,
    this.error,
  });
  final VoidCallback onRetry;
  final Object? error;

  @override
  Widget build(BuildContext context) => StatePanel(
    icon: Icons.sync_problem_outlined,
    title: 'Perubahan belum tersimpan',
    message: failureMessage(error),
    action: OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
  );
}

class StatePanel extends StatelessWidget {
  const StatePanel({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.action,
    this.showProgress = false,
  });
  final IconData icon;
  final String title;
  final String? message;
  final Widget? action;
  final bool showProgress;

  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      const SizedBox(height: 32),
      Icon(icon, size: 40, semanticLabel: title),
      if (showProgress) ...[
        const SizedBox(height: 16),
        const Center(child: CircularProgressIndicator()),
      ],
      const SizedBox(height: 16),
      Text(
        title,
        textAlign: TextAlign.center,
        style: Theme.of(context).textTheme.titleMedium,
      ),
      if (message != null) ...[
        const SizedBox(height: 8),
        Text(message!, textAlign: TextAlign.center),
      ],
      if (action != null) ...[const SizedBox(height: 16), action!],
    ],
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
