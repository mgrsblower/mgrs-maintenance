import 'dart:async';
import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/home_skeleton.dart';
import '../features/components/asset_catalog_screen.dart';
import '../features/maintenance/action_center_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/history/history_screen.dart';
import '../shared/async_state_view.dart';
import 'app_theme.dart';
import 'gateway.dart';

class MaintenanceApp extends StatefulWidget {
  const MaintenanceApp({super.key, required this.gateway});
  final MaintenanceGateway gateway;
  @override
  State<MaintenanceApp> createState() => _MaintenanceAppState();
}

class _MaintenanceAppState extends State<MaintenanceApp>
    with WidgetsBindingObserver {
  UserProfile? user;
  Object? error;
  bool checking = true;
  int generation = 0, sessionRevision = 0;
  late final StreamSubscription<void> subscription;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    subscription = widget.gateway.authChanges.listen((_) => reload());
    unawaited(reload());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    unawaited(subscription.cancel());
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) unawaited(reload());
  }

  Future<void> reload() async {
    final request = ++generation;
    setState(() {
      checking = true;
      error = null;
    });
    try {
      final profile = await widget.gateway.profile();
      if (!mounted || generation != request) return;
      setState(() {
        if (user?.id != profile?.id || user?.role != profile?.role) {
          sessionRevision++;
        }
        user = profile;
        checking = false;
      });
    } catch (e) {
      if (!mounted || generation != request) return;
      setState(() {
        error = e;
        checking = false;
        if (e is AppFailure &&
            {'forbidden', 'unauthenticated'}.contains(e.code)) {
          user = null;
          sessionRevision++;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    key: ValueKey(sessionRevision),
    title: 'MGRS Maintenance',
    debugShowCheckedModeBanner: false,
    theme: maintenanceTheme(),
    home: user == null
        ? LoginScreen(gateway: widget.gateway, onSignedIn: reload)
        : MaintenanceHome(gateway: widget.gateway, user: user!),
    builder: (context, child) => Stack(
      children: [
        ?child,
        if (checking || error != null)
          Positioned.fill(
            child: Material(
              color: AppTokens.canvas,
              child: SafeArea(
                child: checking
                    ? (user != null
                        ? const HomeSkeletonScreen()
                        : const Center(child: CircularProgressIndicator()))
                    : PageBody(
                        children: [
                          const SizedBox(height: 48),
                          Text(
                            failureMessage(error),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: reload,
                            child: const Text('Coba lagi'),
                          ),
                          if (user != null)
                            TextButton(
                              onPressed: () async {
                                await widget.gateway.signOut();
                                await reload();
                              },
                              child: const Text('Keluar'),
                            ),
                        ],
                      ),
              ),
            ),
          ),
      ],
    ),
  );
}

class MaintenanceHome extends StatefulWidget {
  const MaintenanceHome({super.key, required this.gateway, required this.user});
  final MaintenanceGateway gateway;
  final UserProfile user;
  @override
  State<MaintenanceHome> createState() => _MaintenanceHomeState();
}

class _MaintenanceHomeState extends State<MaintenanceHome> {
  int tab = 0;

  void openScannerModal() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ScanScreen(gateway: widget.gateway),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: switch (tab) {
      0 => HomeScreen(
          gateway: widget.gateway,
          user: widget.user,
          onNavigateToTab: (index) => setState(() => tab = index),
          onOpenScanner: openScannerModal,
        ),
      1 => AssetCatalogScreen(
          gateway: widget.gateway,
          onNavigateToTab: (index) => setState(() => tab = index),
          onOpenScanner: openScannerModal,
        ),
      _ => ActionCenterScreen(
          gateway: widget.gateway,
          onNavigateToTab: (index) => setState(() => tab = index),
          onOpenScanner: openScannerModal,
        ),
    },
  );
}
