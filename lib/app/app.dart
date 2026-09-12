import 'dart:async';
import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
import '../features/components/asset_catalog_screen.dart';
import '../features/history/history_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/home_skeleton.dart';
import '../features/home/pic_home_screen.dart';
import '../features/invoices/invoice_list_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/schedule/schedule_screen.dart';
import '../features/schedule/upcoming_orders_screen.dart';
import '../features/splash/splash_screen.dart';
import '../shared/async_state_view.dart';
import '../shared/mgrs_app_shell.dart';
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

  static bool get _isTestEnvironment {
    return WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
  }

  late bool splashCompleted = _isTestEnvironment;

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

  Future<void> _signOut() async {
    await widget.gateway.signOut();
    await reload();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    key: ValueKey(sessionRevision),
    title: 'MGRS',
    debugShowCheckedModeBanner: false,
    theme: maintenanceTheme(),
    home: !splashCompleted
        ? SplashScreen(
            onFinish: () => setState(() => splashCompleted = true),
          )
        : (user == null
            ? LoginScreen(gateway: widget.gateway, onSignedIn: reload)
            : MaintenanceHome(
                gateway: widget.gateway,
                user: user!,
                onSignOut: _signOut,
              )),
    builder: (context, child) => Stack(
      children: [
        ?child,
        if (splashCompleted && (checking || error != null))
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
                              onPressed: _signOut,
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
  const MaintenanceHome({
    super.key,
    required this.gateway,
    required this.user,
    this.onSignOut,
  });

  final MaintenanceGateway gateway;
  final UserProfile user;
  final Future<void> Function()? onSignOut;

  @override
  State<MaintenanceHome> createState() => _MaintenanceHomeState();
}

class _MaintenanceHomeState extends State<MaintenanceHome> {
  MgrsWorkspace? _workspace;
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _workspace = _safeWorkspace(widget.user.defaultWorkspace);
  }

  MgrsWorkspace? _safeWorkspace(MgrsWorkspace? candidate) {
    final allowed = widget.user.allowedWorkspaces;
    if (candidate != null && allowed.contains(candidate)) return candidate;
    final fallback = widget.user.defaultWorkspace;
    return fallback != null && allowed.contains(fallback) ? fallback : null;
  }

  void _selectWorkspace(MgrsWorkspace requestedWorkspace) {
    final nextWorkspace = _safeWorkspace(requestedWorkspace);
    if (nextWorkspace == null || nextWorkspace == _workspace) return;
    setState(() {
      _workspace = nextWorkspace;
      _selectedIndex = 0;
    });
  }

  void _selectDestination(int index) {
    if (index == _selectedIndex || index < 0 || index > 3) return;
    setState(() => _selectedIndex = index);
  }

  Future<void> _signOut() {
    return widget.onSignOut?.call() ?? widget.gateway.signOut();
  }

  Future<void> _openScanner() {
    return Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ScanScreen(
          gateway: widget.gateway,
          user: widget.user,
        ),
      ),
    );
  }

  Widget _picDestination() => switch (_selectedIndex) {
        0 => PicHomeScreen(
            gateway: widget.gateway,
            user: widget.user,
            onOpenOrdersTab: () => _selectDestination(1),
            onOpenInvoicesTab: () => _selectDestination(2),
          ),
        1 => UpcomingOrdersScreen(
            gateway: widget.gateway,
            user: widget.user,
          ),
        2 => InvoiceListScreen(
            gateway: widget.gateway,
            user: widget.user,
          ),
        3 => _ProfileDestination(
            user: widget.user,
            onSignOut: _signOut,
          ),
        _ => const SizedBox.shrink(),
      };

  Widget _fieldDestination() => switch (_selectedIndex) {
        0 => HomeScreen(
            gateway: widget.gateway,
            user: widget.user,
            onSignOut: _signOut,
          ),
        1 => ScheduleScreen(
            gateway: widget.gateway,
            user: widget.user,
          ),
        2 => AssetCatalogScreen(
            gateway: widget.gateway,
            user: widget.user,
            showBottomNav: false,
            onNavigateToTab: _selectDestination,
            onOpenScanner: _openScanner,
          ),
        3 => HistoryScreen(
            gateway: widget.gateway,
            user: widget.user,
          ),
        _ => const SizedBox.shrink(),
      };

  Widget _picShell() => MGRSAppShell(
        workspace: MgrsWorkspace.pic,
        user: widget.user,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        onWorkspaceChanged:
            widget.user.productRole == ProductRole.admin ? _selectWorkspace : null,
        child: _picDestination(),
      );

  Widget _fieldShell() => MGRSAppShell(
        workspace: MgrsWorkspace.field,
        user: widget.user,
        selectedIndex: _selectedIndex,
        onDestinationSelected: _selectDestination,
        onWorkspaceChanged:
            widget.user.productRole == ProductRole.admin ? _selectWorkspace : null,
        child: _fieldDestination(),
      );

  @override
  Widget build(BuildContext context) => switch (_workspace) {
        MgrsWorkspace.pic => _picShell(),
        MgrsWorkspace.field => _fieldShell(),
        null => const Scaffold(
            body: Center(child: Text('Akses workspace tidak tersedia.')),
          ),
      };
}

class _ProfileDestination extends StatefulWidget {
  const _ProfileDestination({
    required this.user,
    required this.onSignOut,
  });

  final UserProfile user;
  final Future<void> Function() onSignOut;

  @override
  State<_ProfileDestination> createState() => _ProfileDestinationState();
}

class _ProfileDestinationState extends State<_ProfileDestination> {
  bool _signingOut = false;
  Object? _error;

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
    final username = widget.user.username?.trim();
    return PageBody(
      children: [
        Text('Profil', style: textTheme.headlineSmall),
        const SizedBox(height: 24),
        Text(widget.user.displayName, style: textTheme.titleLarge),
        const SizedBox(height: 4),
        Text(
          widget.user.productRole?.label ?? widget.user.role,
          style: textTheme.bodyMedium,
        ),
        if (username != null && username.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text('@$username', style: textTheme.bodyMedium),
        ],
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
        FilledButton.icon(
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
