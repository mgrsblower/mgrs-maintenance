import 'dart:async';
import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
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
                    ? const Center(child: CircularProgressIndicator())
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
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: Text(['Scan', 'Berkala', 'Riwayat'][tab]),
      actions: [
        PopupMenuButton<String>(
          tooltip: 'Akun',
          onSelected: (_) async {
            await widget.gateway.signOut();
          },
          itemBuilder: (_) => [
            PopupMenuItem(enabled: false, child: Text(widget.user.role)),
            const PopupMenuItem(value: 'logout', child: Text('Keluar')),
          ],
        ),
      ],
    ),
    body: SafeArea(
      child: switch (tab) {
        0 => ScanScreen(gateway: widget.gateway),
        1 => ScheduleScreen(gateway: widget.gateway),
        _ => HistoryScreen(gateway: widget.gateway),
      },
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: tab,
      onDestinationSelected: (value) => setState(() => tab = value),
      destinations: const [
        NavigationDestination(icon: Icon(Icons.qr_code_scanner), label: 'Scan'),
        NavigationDestination(
          icon: Icon(Icons.event_available_outlined),
          label: 'Berkala',
        ),
        NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
      ],
    ),
  );
}
