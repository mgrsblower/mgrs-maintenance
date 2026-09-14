import 'dart:async';
import 'package:flutter/material.dart';
import '../features/auth/login_screen.dart';
import '../features/home/home_screen.dart';
import '../features/home/home_skeleton.dart';
import '../features/home/pic_home_screen.dart';
import '../features/components/asset_catalog_screen.dart';
import '../features/invoices/invoice_list_screen.dart';
import '../features/maintenance/action_center_screen.dart';
import '../features/scan/scan_screen.dart';
import '../features/schedule/upcoming_orders_screen.dart';
import '../features/splash/splash_screen.dart';
import '../design_system/components/mgrs_button.dart';
import '../design_system/mgrs_tokens.dart';
import '../shared/bottom_nav_bar.dart';
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
  bool accessActionBusy = false;
  bool reloadInProgress = false;
  bool reloadPending = false;
  String? accessActionError;
  int generation = 0, sessionRevision = 0;
  late final StreamSubscription<void> subscription;

  static bool get _isTestEnvironment {
    return WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
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
    if (reloadInProgress) {
      reloadPending = true;
      return;
    }

    reloadInProgress = true;
    final request = ++generation;
    Object? terminalError;
    setState(() {
      checking = true;
      error = null;
      accessActionError = null;
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
      terminalError = e;
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
    } finally {
      reloadInProgress = false;
      final terminalAccessState =
          terminalError is AppFailure &&
          {'forbidden', 'unauthenticated'}.contains(terminalError.code);
      final runPending = reloadPending && !terminalAccessState;
      reloadPending = false;
      if (runPending && mounted) unawaited(reload());
    }
  }

  bool get _sessionExpired =>
      error is AppFailure && (error as AppFailure).code == 'unauthenticated';

  bool get _accessDenied =>
      error is AppFailure && (error as AppFailure).code == 'forbidden';

  Future<void> _signOut() async {
    if (accessActionBusy) return;
    setState(() {
      accessActionBusy = true;
      accessActionError = null;
    });
    try {
      await widget.gateway.signOut();
      await reload();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        accessActionBusy = false;
        accessActionError =
            'Akun belum dapat dikeluarkan. Periksa koneksi lalu coba lagi.';
      });
      return;
    }
    if (mounted) setState(() => accessActionBusy = false);
  }

  void _returnToLogin() {
    setState(() {
      error = null;
      checking = false;
      user = null;
      sessionRevision++;
    });
  }

  Widget _accessState(BuildContext context) {
    final sessionExpired = _sessionExpired;
    final title = sessionExpired
        ? 'Sesi Anda telah berakhir'
        : _accessDenied
        ? 'Akses akun ditolak'
        : 'Data akun belum dapat dimuat';
    final message = sessionExpired
        ? 'Masuk kembali untuk melanjutkan pekerjaan Anda.'
        : _accessDenied
        ? 'Akun ini tidak memiliki akses ke MGRS Maintenance.'
        : const AppFailure('unknown').message;

    return ColoredBox(
      color: MgrsColors.canvas,
      child: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(MgrsSpacing.lg),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    sessionExpired
                        ? Icons.lock_clock_outlined
                        : Icons.lock_outline,
                    size: 48,
                    color: _accessDenied
                        ? MgrsColors.danger
                        : MgrsColors.action,
                  ),
                  const SizedBox(height: MgrsSpacing.lg),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: MgrsSpacing.sm),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: MgrsColors.muted),
                  ),
                  if (accessActionError != null) ...[
                    const SizedBox(height: MgrsSpacing.base),
                    Text(
                      accessActionError!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: MgrsColors.danger,
                      ),
                    ),
                  ],
                  const SizedBox(height: MgrsSpacing.xl),
                  SizedBox(
                    width: double.infinity,
                    child: sessionExpired
                        ? MgrsButton.primary(
                            label: 'Masuk kembali',
                            onPressed: _returnToLogin,
                          )
                        : _accessDenied
                        ? MgrsButton.destructive(
                            label: 'Keluar',
                            loading: accessActionBusy,
                            onPressed: _signOut,
                          )
                        : MgrsButton.primary(
                            label: 'Coba lagi',
                            onPressed: reload,
                          ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    key: ValueKey(sessionRevision),
    title: 'MGRS',
    debugShowCheckedModeBanner: false,
    theme: maintenanceTheme(),
    home: !splashCompleted
        ? SplashScreen(onFinish: () => setState(() => splashCompleted = true))
        : (user == null
              ? LoginScreen(gateway: widget.gateway, onSignedIn: reload)
              : MaintenanceHome(gateway: widget.gateway, user: user!)),
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
                    : _accessState(context),
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

class _MaintenanceHomeState extends State<MaintenanceHome>
    with SingleTickerProviderStateMixin {
  static const picNavItems = [
    AppNavItem(
      label: 'Beranda',
      activeIcon: Icons.space_dashboard_rounded,
      inactiveIcon: Icons.space_dashboard_outlined,
    ),
    AppNavItem(
      label: 'Orderan',
      activeIcon: Icons.event_note_rounded,
      inactiveIcon: Icons.event_note_outlined,
    ),
    AppNavItem(
      label: 'Invoice',
      activeIcon: Icons.receipt_long_rounded,
      inactiveIcon: Icons.receipt_long_outlined,
    ),
  ];

  AdminAppMode _adminMode = AdminAppMode.service;
  int tab = 0;
  late final PageController _pageController;
  late final AnimationController _fadeController;
  late final Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: tab);
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      value: 1.0,
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeOutCubic,
    );
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _onNavigateToTab(int index) {
    if (tab == index) return;
    setState(() => tab = index);
    _pageController.jumpToPage(index);
    _fadeController.forward(from: 0.0);
  }

  void _switchAdminMode(AdminAppMode newMode) {
    if (_adminMode == newMode) return;
    setState(() {
      _adminMode = newMode;
      tab = 0;
    });
    _pageController.jumpToPage(0);
    _fadeController.forward(from: 0.0);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          newMode == AdminAppMode.pic
              ? 'Beralih ke Mode PIC (Orderan & Invoice)'
              : 'Beralih ke Mode Servis (Teknisi Maintenance)',
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0xFF18181B),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  bool get effectiveIsPic =>
      widget.user.isPic ||
      (widget.user.isAdmin && _adminMode == AdminAppMode.pic);

  void openScannerModal() {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ScanScreen(
          gateway: widget.gateway,
          user: widget.user,
          readOnly: effectiveIsPic,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isPic = effectiveIsPic;

    final children = isPic
        ? [
            PicHomeScreen(
              gateway: widget.gateway,
              user: widget.user,
              adminMode: widget.user.isAdmin ? _adminMode : null,
              onSwitchAdminMode: widget.user.isAdmin ? _switchAdminMode : null,
              onOpenOrdersTab: () => _onNavigateToTab(1),
              onOpenInvoicesTab: () => _onNavigateToTab(2),
            ),
            UpcomingOrdersScreen(gateway: widget.gateway, user: widget.user),
            InvoiceListScreen(gateway: widget.gateway, user: widget.user),
          ]
        : [
            HomeScreen(
              gateway: widget.gateway,
              user: widget.user,
              adminMode: widget.user.isAdmin ? _adminMode : null,
              onSwitchAdminMode: widget.user.isAdmin ? _switchAdminMode : null,
              showBottomNav: false,
              onNavigateToTab: _onNavigateToTab,
              onOpenScanner: openScannerModal,
            ),
            AssetCatalogScreen(
              gateway: widget.gateway,
              showBottomNav: false,
              onNavigateToTab: _onNavigateToTab,
              onOpenScanner: openScannerModal,
            ),
            ActionCenterScreen(
              gateway: widget.gateway,
              showBottomNav: false,
              onNavigateToTab: _onNavigateToTab,
              onOpenScanner: openScannerModal,
            ),
          ];

    return Scaffold(
      backgroundColor: AppTokens.canvas,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: PageView(
          controller: _pageController,
          onPageChanged: (index) => setState(() => tab = index),
          physics: const BouncingScrollPhysics(),
          children: children,
        ),
      ),
      bottomNavigationBar: AppBottomNavBar(
        currentIndex: tab,
        onNavigateToTab: _onNavigateToTab,
        items: isPic ? picNavItems : null,
        onOpenScanner: openScannerModal,
      ),
    );
  }
}
