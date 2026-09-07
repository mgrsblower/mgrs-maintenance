import 'dart:async';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/gateway.dart';
import '../../shared/async_state_view.dart';
import '../components/component.dart';
import '../components/component_detail_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key, required this.gateway});
  final MaintenanceGateway gateway;
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> with WidgetsBindingObserver {
  final code = TextEditingController();
  final camera = MobileScannerController(autoStart: false);
  bool scanning = false, busy = false;
  String? error;
  List<Component> choices = [];
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    code.dispose();
    unawaited(camera.dispose());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed && scanning) {
      unawaited(camera.stop());
      setState(() => scanning = false);
    }
  }

  Future<void> start() async {
    setState(() {
      scanning = true;
      error = null;
    });
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted || !scanning) return;
      try {
        await camera.start();
      } catch (_) {
        if (mounted) {
          setState(() {
            scanning = false;
            error =
                'Kamera belum dapat digunakan. Izinkan akses kamera atau masukkan kode.';
          });
        }
      }
    });
  }

  Future<void> lookup(String value) async {
    if (busy) return;
    if (value.trim().isEmpty) {
      setState(() => error = 'Masukkan kode komponen.');
      return;
    }
    setState(() {
      busy = true;
      error = null;
      choices = [];
    });
    if (scanning) {
      await camera.stop();
      if (mounted) setState(() => scanning = false);
    }
    try {
      final rows = jsonItems(
        await widget.gateway.rpc('maintenance_lookup_component', {
          'p_code': value.trim(),
        }),
      ).map(Component.new).toList();
      if (!mounted) return;
      if (rows.isEmpty) {
        setState(
          () =>
              error = 'Kode tidak ditemukan pada Kepala, Batang, atau Tabung.',
        );
      } else if (rows.length == 1) {
        await open(rows.single);
      } else {
        setState(() => choices = rows);
      }
    } catch (e) {
      if (mounted) setState(() => error = failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Future<void> open(Component c) => Navigator.of(context).push<void>(
    MaterialPageRoute(
      builder: (_) => ComponentDetailScreen(gateway: widget.gateway, id: c.id),
    ),
  );
  @override
  Widget build(BuildContext context) => PageBody(
    children: [
      Text(
        'Cek kondisi komponen',
        style: Theme.of(context).textTheme.headlineSmall,
      ),
      const SizedBox(height: 8),
      const Text(
        'Pindai stiker Kepala, Batang, atau Tabung. Melihat kondisi tidak mengubah data.',
      ),
      const SizedBox(height: 24),
      if (scanning)
        SizedBox(
          height: 280,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: MobileScanner(
              controller: camera,
              onDetect: (capture) {
                for (final barcode in capture.barcodes) {
                  final value = barcode.rawValue;
                  if (value != null && value.isNotEmpty) {
                    unawaited(lookup(value));
                    break;
                  }
                }
              },
              errorBuilder: (context, error) => const Center(
                child: Text('Kamera belum tersedia. Gunakan input kode.'),
              ),
            ),
          ),
        )
      else
        Card(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              children: [
                Icon(
                  Icons.qr_code_scanner,
                  size: 72,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: busy ? null : start,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Mulai scan'),
                ),
              ],
            ),
          ),
        ),
      if (scanning)
        TextButton(
          onPressed: () async {
            await camera.stop();
            if (mounted) setState(() => scanning = false);
          },
          child: const Text('Tutup kamera'),
        ),
      const SizedBox(height: 24),
      TextField(
        controller: code,
        enabled: !busy,
        onSubmitted: lookup,
        textInputAction: TextInputAction.search,
        decoration: const InputDecoration(
          labelText: 'Kode komponen',
          hintText: 'Masukkan kode pada stiker',
        ),
      ),
      const SizedBox(height: 12),
      OutlinedButton.icon(
        onPressed: busy ? null : () => lookup(code.text),
        icon: const Icon(Icons.search),
        label: Text(busy ? 'Mencari…' : 'Cari komponen'),
      ),
      if (error != null) ...[
        const SizedBox(height: 16),
        Text(
          error!,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
      ],
      if (choices.isNotEmpty) ...[
        const Text('Pilih komponen yang sesuai dengan stiker:'),
        for (final c in choices)
          ListTile(
            title: Text(c.code),
            subtitle: Text(c.kind),
            onTap: () => open(c),
          ),
      ],
    ],
  );
}
