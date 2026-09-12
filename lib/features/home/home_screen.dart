import 'package:flutter/material.dart';

import '../../app/gateway.dart';
import '../../shared/async_state_view.dart';
import '../scan/scan_screen.dart';

/// Tim Lapangan landing surface.
///
/// Detailed maintenance work stays in the shell destinations. This page keeps
/// the field entry focused on the primary scan action and passes the signed-in
/// user's gateway context through to the scanner.
class HomeScreen extends StatefulWidget {
  const HomeScreen({
    super.key,
    required this.gateway,
    required this.user,
    required this.onSignOut,
  });

  final MaintenanceGateway gateway;
  final UserProfile user;
  final Future<void> Function() onSignOut;

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _signingOut = false;
  Object? _error;

  Future<void> _openScanner(BuildContext context) {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ScanScreen(
          gateway: widget.gateway,
          user: widget.user,
        ),
      ),
    );
  }

  Future<void> _signOut() async {
    if (_signingOut) return;
    setState(() {
      _signingOut = true;
      _error = null;
    });
    try {
      await widget.onSignOut();
    } catch (error) {
      if (mounted) setState(() => _error = error);
    } finally {
      if (mounted) setState(() => _signingOut = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return PageBody(
      children: [
        Text('Ruang kerja Tim Lapangan', style: textTheme.headlineSmall),
        const SizedBox(height: 8),
        Text(
          widget.user.displayName,
          style: textTheme.bodyLarge,
        ),
        const SizedBox(height: 32),
        Text('Scan komponen', style: textTheme.titleLarge),
        const SizedBox(height: 8),
        Text(
          'Pindai kode komponen untuk membuka detail, pemeriksaan, dan tindakan servis yang tersedia.',
          style: textTheme.bodyMedium,
        ),
        const SizedBox(height: 20),
        FilledButton.icon(
          onPressed: () => _openScanner(context),
          icon: const Icon(Icons.qr_code_scanner),
          label: const Text('Pindai komponen'),
        ),
        if (_error != null) ...[
          const SizedBox(height: 24),
          Text(
            failureMessage(_error),
            style: textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ],
        const SizedBox(height: 32),
        TextButton.icon(
          onPressed: _signingOut ? null : _signOut,
          icon: _signingOut
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.logout),
          label: Text(_signingOut ? 'Keluar…' : 'Keluar dari akun'),
        ),
      ],
    );
  }
}
