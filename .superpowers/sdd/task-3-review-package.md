BASE: b096fb1
HEAD: 145afaa

STAT
 lib/app/app.dart                       |  367 ++++----
 lib/app/gateway.dart                   |    8 -
 lib/features/auth/login_screen.dart    |    4 +-
 lib/features/home/home_screen.dart     | 1514 ++----------------------------
 lib/features/home/pic_home_screen.dart | 1577 ++------------------------------
 test/admin_mode_switch_test.dart       |  136 ---
 test/home_screen_test.dart             |  258 ------
 test/pic_flow_test.dart                |   50 -
 test/widget_workspace_shell_test.dart  |  184 ++++
 9 files changed, 512 insertions(+), 3586 deletions(-)

DIFF
diff --git a/lib/app/app.dart b/lib/app/app.dart
index ddb1f08..6a460ce 100644
--- a/lib/app/app.dart
+++ b/lib/app/app.dart
@@ -1,24 +1,25 @@
 import 'dart:async';
 import 'package:flutter/material.dart';
 import '../features/auth/login_screen.dart';
+import '../features/components/asset_catalog_screen.dart';
+import '../features/history/history_screen.dart';
 import '../features/home/home_screen.dart';
 import '../features/home/home_skeleton.dart';
 import '../features/home/pic_home_screen.dart';
-import '../features/components/asset_catalog_screen.dart';
 import '../features/invoices/invoice_list_screen.dart';
-import '../features/maintenance/action_center_screen.dart';
 import '../features/scan/scan_screen.dart';
+import '../features/schedule/schedule_screen.dart';
 import '../features/schedule/upcoming_orders_screen.dart';
 import '../features/splash/splash_screen.dart';
 import '../shared/async_state_view.dart';
-import '../shared/bottom_nav_bar.dart';
+import '../shared/mgrs_app_shell.dart';
 import 'app_theme.dart';
 import 'gateway.dart';
 
 class MaintenanceApp extends StatefulWidget {
   const MaintenanceApp({super.key, required this.gateway});
   final MaintenanceGateway gateway;
   @override
   State<MaintenanceApp> createState() => _MaintenanceAppState();
 }
 
@@ -81,33 +82,42 @@ class _MaintenanceAppState extends State<MaintenanceApp>
         checking = false;
         if (e is AppFailure &&
             {'forbidden', 'unauthenticated'}.contains(e.code)) {
           user = null;
           sessionRevision++;
         }
       });
     }
   }
 
+  Future<void> _signOut() async {
+    await widget.gateway.signOut();
+    await reload();
+  }
+
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
-            : MaintenanceHome(gateway: widget.gateway, user: user!)),
+            : MaintenanceHome(
+                gateway: widget.gateway,
+                user: user!,
+                onSignOut: _signOut,
+              )),
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
@@ -120,261 +130,228 @@ class _MaintenanceAppState extends State<MaintenanceApp>
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
-                              onPressed: () async {
-                                await widget.gateway.signOut();
-                                await reload();
-                              },
+                              onPressed: _signOut,
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
-  const MaintenanceHome({super.key, required this.gateway, required this.user});
+  const MaintenanceHome({
+    super.key,
+    required this.gateway,
+    required this.user,
+    this.onSignOut,
+  });
+
   final MaintenanceGateway gateway;
   final UserProfile user;
+  final Future<void> Function()? onSignOut;
+
   @override
   State<MaintenanceHome> createState() => _MaintenanceHomeState();
 }
 
-class _MaintenanceHomeState extends State<MaintenanceHome>
-    with SingleTickerProviderStateMixin {
-  static const picNavItems = [
-    AppNavItem(
-      label: 'Beranda',
-      activeIcon: Icons.space_dashboard_rounded,
-      inactiveIcon: Icons.space_dashboard_outlined,
-    ),
-    AppNavItem(
-      label: 'Orderan',
-      activeIcon: Icons.event_note_rounded,
-      inactiveIcon: Icons.event_note_outlined,
-    ),
-    AppNavItem(
-      label: 'Invoice',
-      activeIcon: Icons.receipt_long_rounded,
-      inactiveIcon: Icons.receipt_long_outlined,
-    ),
-  ];
-
+class _MaintenanceHomeState extends State<MaintenanceHome> {
   MgrsWorkspace? _workspace;
-  AdminAppMode get _adminMode =>
-      _workspace == MgrsWorkspace.pic
-          ? AdminAppMode.pic
-          : AdminAppMode.service;
-  int tab = 0;
-  late final PageController _pageController;
-  late final AnimationController _fadeController;
-  late final Animation<double> _fadeAnimation;
+  int _selectedIndex = 0;
 
   @override
   void initState() {
     super.initState();
     _workspace = _safeWorkspace(widget.user.defaultWorkspace);
-    _pageController = PageController(initialPage: tab);
-    _fadeController = AnimationController(
-      vsync: this,
-      duration: const Duration(milliseconds: 220),
-      value: 1.0,
-    );
-    _fadeAnimation = CurvedAnimation(
-      parent: _fadeController,
-      curve: Curves.easeOutCubic,
-    );
   }
 
-  @override
-  void dispose() {
-    _fadeController.dispose();
-    _pageController.dispose();
-    super.dispose();
-  }
-
-  void _onNavigateToTab(int index) {
-    if (tab == index) return;
-    setState(() => tab = index);
-    _pageController.jumpToPage(index);
-    _fadeController.forward(from: 0.0);
-  }
   MgrsWorkspace? _safeWorkspace(MgrsWorkspace? candidate) {
-    final allowedWorkspaces = widget.user.allowedWorkspaces;
-    if (candidate != null && allowedWorkspaces.contains(candidate)) {
-      return candidate;
-    }
+    final allowed = widget.user.allowedWorkspaces;
+    if (candidate != null && allowed.contains(candidate)) return candidate;
     final fallback = widget.user.defaultWorkspace;
-    return fallback != null && allowedWorkspaces.contains(fallback)
-        ? fallback
-        : null;
+    return fallback != null && allowed.contains(fallback) ? fallback : null;
   }
 
   void _selectWorkspace(MgrsWorkspace requestedWorkspace) {
     final nextWorkspace = _safeWorkspace(requestedWorkspace);
-    if (nextWorkspace == null || _workspace == nextWorkspace) return;
+    if (nextWorkspace == null || nextWorkspace == _workspace) return;
     setState(() {
       _workspace = nextWorkspace;
-      tab = 0;
+      _selectedIndex = 0;
     });
-    _pageController.jumpToPage(0);
-    _fadeController.forward(from: 0.0);
-    ScaffoldMessenger.of(context).showSnackBar(
-      SnackBar(
-        content: Text(
-          nextWorkspace == MgrsWorkspace.pic
-              ? 'Beralih ke Mode PIC (Orderan & Invoice)'
-              : 'Beralih ke Mode Servis (Teknisi Maintenance)',
-          style: const TextStyle(
-            fontFamily: 'Plus Jakarta Sans',
-            fontWeight: FontWeight.w600,
-          ),
-        ),
-        backgroundColor: const Color(0xFF18181B),
-        behavior: SnackBarBehavior.floating,
-        duration: const Duration(seconds: 2),
-      ),
-    );
   }
 
-  void _switchAdminMode(AdminAppMode newMode) {
-    _selectWorkspace(
-      newMode == AdminAppMode.pic ? MgrsWorkspace.pic : MgrsWorkspace.field,
-    );
+  void _selectDestination(int index) {
+    if (index == _selectedIndex || index < 0 || index > 3) return;
+    setState(() => _selectedIndex = index);
   }
 
+  Future<void> _signOut() {
+    return widget.onSignOut?.call() ?? widget.gateway.signOut();
+  }
 
-  bool get effectiveIsPic =>
-      _workspace == MgrsWorkspace.pic &&
-      widget.user.allowedWorkspaces.contains(MgrsWorkspace.pic);
-
-  bool get _hasWorkspaceAccess =>
-      _workspace != null && widget.user.allowedWorkspaces.contains(_workspace);
-
-  void openScannerModal() {
-    Navigator.of(context).push<void>(
+  Future<void> _openScanner() {
+    return Navigator.of(context).push<void>(
       MaterialPageRoute(
         builder: (_) => ScanScreen(
           gateway: widget.gateway,
           user: widget.user,
-          readOnly: effectiveIsPic,
         ),
       ),
     );
   }
 
-  @override
-  Widget build(BuildContext context) {
-    if (!_hasWorkspaceAccess) {
-      return const Scaffold(
-        body: Center(child: Text('Akses workspace tidak tersedia.')),
+  Widget _picDestination() => switch (_selectedIndex) {
+        0 => PicHomeScreen(
+            gateway: widget.gateway,
+            user: widget.user,
+            onOpenOrdersTab: () => _selectDestination(1),
+            onOpenInvoicesTab: () => _selectDestination(2),
+          ),
+        1 => UpcomingOrdersScreen(
+            gateway: widget.gateway,
+            user: widget.user,
+          ),
+        2 => InvoiceListScreen(
+            gateway: widget.gateway,
+            user: widget.user,
+          ),
+        3 => _ProfileDestination(
+            user: widget.user,
+            onSignOut: _signOut,
+          ),
+        _ => const SizedBox.shrink(),
+      };
+
+  Widget _fieldDestination() => switch (_selectedIndex) {
+        0 => HomeScreen(
+            gateway: widget.gateway,
+            user: widget.user,
+            onSignOut: _signOut,
+          ),
+        1 => ScheduleScreen(gateway: widget.gateway),
+        2 => AssetCatalogScreen(
+            gateway: widget.gateway,
+            showBottomNav: false,
+            onNavigateToTab: _selectDestination,
+            onOpenScanner: _openScanner,
+          ),
+        3 => HistoryScreen(gateway: widget.gateway),
+        _ => const SizedBox.shrink(),
+      };
+
+  Widget _picShell() => MGRSAppShell(
+        workspace: MgrsWorkspace.pic,
+        user: widget.user,
+        selectedIndex: _selectedIndex,
+        onDestinationSelected: _selectDestination,
+        onWorkspaceChanged:
+            widget.user.productRole == ProductRole.admin ? _selectWorkspace : null,
+        child: _picDestination(),
       );
-    }
-    final isPic = effectiveIsPic;
-    final bottomInset = MediaQuery.paddingOf(context).bottom;
-    final scrimHeight = 98.0 + bottomInset;
 
-    final children = isPic
-        ? [
-            PicHomeScreen(
-              gateway: widget.gateway,
-              user: widget.user,
-              adminMode: widget.user.isAdmin ? _adminMode : null,
-              onSwitchAdminMode:
-                  widget.user.isAdmin ? _switchAdminMode : null,
-              onOpenOrdersTab: () => _onNavigateToTab(1),
-              onOpenInvoicesTab: () => _onNavigateToTab(2),
-            ),
-            UpcomingOrdersScreen(
-              gateway: widget.gateway,
-              user: widget.user,
-            ),
-            InvoiceListScreen(
-              gateway: widget.gateway,
-              user: widget.user,
-            ),
-          ]
-        : [
-            HomeScreen(
-              gateway: widget.gateway,
-              user: widget.user,
-              adminMode: widget.user.isAdmin ? _adminMode : null,
-              onSwitchAdminMode:
-                  widget.user.isAdmin ? _switchAdminMode : null,
-              showBottomNav: false,
-              onNavigateToTab: _onNavigateToTab,
-              onOpenScanner: openScannerModal,
-            ),
-            AssetCatalogScreen(
-              gateway: widget.gateway,
-              showBottomNav: false,
-              onNavigateToTab: _onNavigateToTab,
-              onOpenScanner: openScannerModal,
-            ),
-            ActionCenterScreen(
-              gateway: widget.gateway,
-              showBottomNav: false,
-              onNavigateToTab: _onNavigateToTab,
-              onOpenScanner: openScannerModal,
-            ),
-          ];
+  Widget _fieldShell() => MGRSAppShell(
+        workspace: MgrsWorkspace.field,
+        user: widget.user,
+        selectedIndex: _selectedIndex,
+        onDestinationSelected: _selectDestination,
+        onWorkspaceChanged:
+            widget.user.productRole == ProductRole.admin ? _selectWorkspace : null,
+        child: _fieldDestination(),
+      );
 
-    return Scaffold(
-      extendBody: true,
-      backgroundColor: const Color(0xFFFBFBFB),
-      body: Stack(
-        children: [
-          FadeTransition(
-            opacity: _fadeAnimation,
-            child: PageView(
-              controller: _pageController,
-              onPageChanged: (index) => setState(() => tab = index),
-              physics: const BouncingScrollPhysics(),
-              children: children,
-            ),
+  @override
+  Widget build(BuildContext context) => switch (_workspace) {
+        MgrsWorkspace.pic => _picShell(),
+        MgrsWorkspace.field => _fieldShell(),
+        null => const Scaffold(
+            body: Center(child: Text('Akses workspace tidak tersedia.')),
           ),
-          // Native iOS style bottom gradient scrim (fades content softly beneath floating navbar)
-          Positioned(
-            left: 0,
-            right: 0,
-            bottom: 0,
-            height: scrimHeight,
-            child: IgnorePointer(
-              child: Container(
-                decoration: BoxDecoration(
-                  gradient: LinearGradient(
-                    begin: Alignment.bottomCenter,
-                    end: Alignment.topCenter,
-                    colors: [
-                      const Color(0xFFFBFBFB).withValues(alpha: 0.96),
-                      const Color(0xFFFBFBFB).withValues(alpha: 0.65),
-                      const Color(0xFFFBFBFB).withValues(alpha: 0.0),
-                    ],
-                    stops: const [0.0, 0.50, 1.0],
-                  ),
-                ),
-              ),
+      };
+}
+
+class _ProfileDestination extends StatefulWidget {
+  const _ProfileDestination({
+    required this.user,
+    required this.onSignOut,
+  });
+
+  final UserProfile user;
+  final Future<void> Function() onSignOut;
+
+  @override
+  State<_ProfileDestination> createState() => _ProfileDestinationState();
+}
+
+class _ProfileDestinationState extends State<_ProfileDestination> {
+  bool _signingOut = false;
+  Object? _error;
+
+  Future<void> _signOut() async {
+    if (_signingOut) return;
+    setState(() {
+      _signingOut = true;
+      _error = null;
+    });
+    try {
+      await widget.onSignOut();
+    } catch (error) {
+      if (mounted) setState(() => _error = error);
+    } finally {
+      if (mounted) setState(() => _signingOut = false);
+    }
+  }
+
+  @override
+  Widget build(BuildContext context) {
+    final textTheme = Theme.of(context).textTheme;
+    final username = widget.user.username?.trim();
+    return PageBody(
+      children: [
+        Text('Profil', style: textTheme.headlineSmall),
+        const SizedBox(height: 24),
+        Text(widget.user.displayName, style: textTheme.titleLarge),
+        const SizedBox(height: 4),
+        Text(
+          widget.user.productRole?.label ?? widget.user.role,
+          style: textTheme.bodyMedium,
+        ),
+        if (username != null && username.isNotEmpty) ...[
+          const SizedBox(height: 4),
+          Text('@$username', style: textTheme.bodyMedium),
+        ],
+        if (_error != null) ...[
+          const SizedBox(height: 24),
+          Text(
+            failureMessage(_error),
+            style: textTheme.bodyMedium?.copyWith(
+              color: Theme.of(context).colorScheme.error,
             ),
           ),
         ],
-      ),
-      bottomNavigationBar: AppBottomNavBar(
-        currentIndex: tab,
-        onNavigateToTab: _onNavigateToTab,
-        items: isPic ? picNavItems : null,
-        onOpenScanner: openScannerModal,
-      ),
+        const SizedBox(height: 32),
+        FilledButton.icon(
+          onPressed: _signingOut ? null : _signOut,
+          icon: _signingOut
+              ? const SizedBox.square(
+                  dimension: 18,
+                  child: CircularProgressIndicator(strokeWidth: 2),
+                )
+              : const Icon(Icons.logout),
+          label: Text(_signingOut ? 'Keluar…' : 'Keluar dari akun'),
+        ),
+      ],
     );
   }
 }
diff --git a/lib/app/gateway.dart b/lib/app/gateway.dart
index 23ed220..3f62d66 100644
--- a/lib/app/gateway.dart
+++ b/lib/app/gateway.dart
@@ -20,28 +20,20 @@ enum MgrsWorkspace { pic, field }
 enum ProductRole { admin, picMgrs, timLapangan }
 
 extension ProductRoleLabel on ProductRole {
   String get label => switch (this) {
     ProductRole.admin => 'Admin',
     ProductRole.picMgrs => 'PIC MGRS',
     ProductRole.timLapangan => 'Tim Lapangan',
   };
 }
 
-enum AdminAppMode {
-  pic('Mode PIC (Order & Invoice)'),
-  service('Mode Servis (Teknisi Maintenance)');
-
-  const AdminAppMode(this.label);
-  final String label;
-}
-
 class UserProfile {
   const UserProfile(
     this.id,
     this.role, {
     this.fullName,
     this.username,
   });
 
   final String id;
   final String role;
diff --git a/lib/features/auth/login_screen.dart b/lib/features/auth/login_screen.dart
index 60af893..7f92c97 100644
--- a/lib/features/auth/login_screen.dart
+++ b/lib/features/auth/login_screen.dart
@@ -5,21 +5,21 @@ import '../../app/gateway.dart';
 import '../../shared/pressable.dart';
 
 class LoginScreen extends StatefulWidget {
   const LoginScreen({
     super.key,
     required this.gateway,
     required this.onSignedIn,
   });
 
   final MaintenanceGateway gateway;
-  final VoidCallback onSignedIn;
+  final Future<void> Function() onSignedIn;
 
   @override
   State<LoginScreen> createState() => _LoginScreenState();
 }
 
 class _LoginScreenState extends State<LoginScreen> {
   final form = GlobalKey<FormState>();
   final identifier = TextEditingController();
   final password = TextEditingController();
 
@@ -74,21 +74,21 @@ class _LoginScreenState extends State<LoginScreen> {
     setState(() {
       busy = true;
       error = null;
     });
 
     try {
       await widget.gateway.signIn(identifier.text.trim(), password.text);
       _triggerSuccess?.fire();
       // Allow user to briefly enjoy the success celebration animation
       await Future.delayed(const Duration(milliseconds: 1400));
-      if (mounted) widget.onSignedIn();
+      if (mounted) await widget.onSignedIn();
     } catch (e) {
       _triggerFail?.fire();
       if (mounted) setState(() => error = failureMessage(e));
     } finally {
       if (mounted) setState(() => busy = false);
     }
   }
 
   void _onTogglePasswordVisibility() {
     setState(() {
diff --git a/lib/features/home/home_screen.dart b/lib/features/home/home_screen.dart
index 36fec30..ee42d01 100644
--- a/lib/features/home/home_screen.dart
+++ b/lib/features/home/home_screen.dart
@@ -1,1483 +1,105 @@
-import 'dart:math' as math;
 import 'package:flutter/material.dart';
-import '../../app/gateway.dart';
-import '../../shared/bottom_nav_bar.dart';
-import '../../shared/pressable.dart';
-import '../schedule/order_detail_screen.dart';
-import '../schedule/order_model.dart';
-import '../schedule/upcoming_orders_screen.dart';
 
+import '../../app/gateway.dart';
+import '../../shared/async_state_view.dart';
+import '../scan/scan_screen.dart';
+
+/// Tim Lapangan landing surface.
+///
+/// Detailed maintenance work stays in the shell destinations. This page keeps
+/// the field entry focused on the primary scan action and passes the signed-in
+/// user's gateway context through to the scanner.
 class HomeScreen extends StatefulWidget {
   const HomeScreen({
     super.key,
     required this.gateway,
     required this.user,
-    required this.onNavigateToTab,
-    required this.onOpenScanner,
-    this.adminMode,
-    this.onSwitchAdminMode,
-    this.showBottomNav = true,
+    required this.onSignOut,
   });
 
   final MaintenanceGateway gateway;
   final UserProfile user;
-  final void Function(int tabIndex) onNavigateToTab;
-  final VoidCallback onOpenScanner;
-  final AdminAppMode? adminMode;
-  final ValueChanged<AdminAppMode>? onSwitchAdminMode;
-  final bool showBottomNav;
+  final Future<void> Function() onSignOut;
 
   @override
   State<HomeScreen> createState() => _HomeScreenState();
 }
 
-class _HomeScreenState extends State<HomeScreen>
-    with AutomaticKeepAliveClientMixin {
-  int _operatingCount = 0;
-  int _serviceCount = 0;
-  int _problemCount = 0;
-  int _totalMonitored = 0;
-  String _countdownDays = '0';
-  List<OrderanSewa> _upcomingOrders = [];
-  bool _loading = true;
-
-  @override
-  bool get wantKeepAlive => true;
+class _HomeScreenState extends State<HomeScreen> {
+  bool _signingOut = false;
+  Object? _error;
 
-  @override
-  void initState() {
-    super.initState();
-    _loadMetrics();
+  Future<void> _openScanner(BuildContext context) {
+    return Navigator.of(context).push<void>(
+      MaterialPageRoute(
+        builder: (_) => ScanScreen(
+          gateway: widget.gateway,
+          user: widget.user,
+        ),
+      ),
+    );
   }
 
-  Future<void> _loadMetrics({bool forceRefresh = false}) async {
-    setState(() => _loading = true);
+  Future<void> _signOut() async {
+    if (_signingOut) return;
+    setState(() {
+      _signingOut = true;
+      _error = null;
+    });
     try {
-      final list =
-          await widget.gateway.fetchComponents(forceRefresh: forceRefresh);
-      if (!mounted) return;
-      int ok = 0;
-      int service = 0;
-      int problem = 0;
-      for (final item in list) {
-        final cond = (item['kondisi'] ?? item['condition'] ?? 'OK').toString();
-        if (cond == 'OK') {
-          ok++;
-        } else if (cond == 'Service' || cond == 'Rusak Ringan') {
-          service++;
-        } else {
-          problem++;
-        }
-      }
-
-      String countdown = '0';
-      try {
-        final tasks = await widget.gateway
-            .fetchTasksSummary(forceRefresh: forceRefresh);
-        if (tasks.isNotEmpty) {
-          final period = tasks['period'];
-          if (period is Map) {
-            final opensAtStr = period['opensAt']?.toString();
-            if (opensAtStr != null) {
-              final opensAt = DateTime.tryParse(opensAtStr);
-              if (opensAt != null) {
-                final now = DateTime.now();
-                final diff = opensAt.difference(now).inDays;
-                countdown = diff > 0 ? '$diff' : '0';
-              }
-            }
-          }
-        }
-      } catch (_) {}
-
-      List<OrderanSewa> upcoming = [];
-      try {
-        final all = await widget.gateway
-            .fetchUpcomingOrders(limit: 20, forceRefresh: forceRefresh);
-        upcoming = all.where((o) => o.isUpcoming).take(5).toList();
-      } catch (_) {}
-
-      setState(() {
-        _operatingCount = ok;
-        _serviceCount = service;
-        _problemCount = problem;
-        _totalMonitored = list.length;
-        _countdownDays = countdown;
-        _upcomingOrders = upcoming;
-        _loading = false;
-      });
-    } catch (_) {
-      if (mounted) setState(() => _loading = false);
+      await widget.onSignOut();
+    } catch (error) {
+      if (mounted) setState(() => _error = error);
+    } finally {
+      if (mounted) setState(() => _signingOut = false);
     }
   }
 
   @override
   Widget build(BuildContext context) {
-    super.build(context);
-    return Scaffold(
-      backgroundColor: const Color(0xFFFBFBFB),
-      body: SafeArea(
-        bottom: false,
-        child: Column(
-          children: [
-            Expanded(
-              child: RefreshIndicator(
-                onRefresh: () => _loadMetrics(forceRefresh: true),
-                color: const Color(0xFF2563EB),
-                child: SingleChildScrollView(
-                  physics: const AlwaysScrollableScrollPhysics(
-                    parent: BouncingScrollPhysics(),
-                  ),
-                  child: Padding(
-                    padding: const EdgeInsets.symmetric(horizontal: 20),
-                    child: Column(
-                      crossAxisAlignment: CrossAxisAlignment.stretch,
-                      children: [
-                        const SizedBox(height: 10),
-                        _buildUserHeader(context),
-                        const SizedBox(height: 14),
-                        _buildWeeklyProgressBento(context),
-                        const SizedBox(height: 20),
-                        _buildUnitStatusSection(context),
-                        const SizedBox(height: 20),
-                        _buildUpcomingOrdersSection(context),
-                        const SizedBox(height: 110), // Spacing for floating navbar
-                      ],
-                    ),
-                  ),
-                ),
-              ),
-            ),
-          ],
-        ),
-      ),
-      bottomNavigationBar: widget.showBottomNav
-          ? AppBottomNavBar(
-              currentIndex: 0,
-              onNavigateToTab: widget.onNavigateToTab,
-              onOpenScanner: widget.onOpenScanner,
-            )
-          : null,
-    );
-  }
-
-  // 1. User Header: Avatar "SR" + "Selamat Pagi! Salman Alfarras" + Bell Icon
-  Widget _buildUserHeader(BuildContext context) {
-    return Row(
-      mainAxisAlignment: MainAxisAlignment.spaceBetween,
+    final textTheme = Theme.of(context).textTheme;
+    return PageBody(
       children: [
-        Expanded(
-          child: PressableScale(
-            onTap: () => _showUserProfileBottomSheet(context),
-            child: Row(
-              children: [
-                Container(
-                  width: 44,
-                  height: 44,
-                  decoration: const BoxDecoration(
-                    color: Color(0xFFE2E8F0),
-                    shape: BoxShape.circle,
-                  ),
-                  child: Center(
-                    child: Text(
-                      widget.user.initials,
-                      style: const TextStyle(
-                        fontFamily: 'Plus Jakarta Sans',
-                        fontSize: 15,
-                        fontWeight: FontWeight.w700,
-                        color: Color(0xFF334155),
-                      ),
-                    ),
-                  ),
-                ),
-                const SizedBox(width: 12),
-                Expanded(
-                  child: Column(
-                    crossAxisAlignment: CrossAxisAlignment.start,
-                    children: [
-                      Row(
-                        children: [
-                          const Text(
-                            'Selamat Pagi!',
-                            style: TextStyle(
-                              fontFamily: 'Plus Jakarta Sans',
-                              fontSize: 13,
-                              fontWeight: FontWeight.w500,
-                              color: Color(0xFF64748B),
-                            ),
-                          ),
-                          const SizedBox(width: 4),
-                          const Icon(
-                            Icons.keyboard_arrow_down_rounded,
-                            size: 16,
-                            color: Color(0xFF94A3B8),
-                          ),
-                        ],
-                      ),
-                      const SizedBox(height: 2),
-                      Text(
-                        widget.user.displayName,
-                        maxLines: 1,
-                        overflow: TextOverflow.ellipsis,
-                        style: const TextStyle(
-                          fontFamily: 'Plus Jakarta Sans',
-                          fontSize: 17,
-                          fontWeight: FontWeight.w700,
-                          color: Color(0xFF0F172A),
-                          letterSpacing: -0.3,
-                        ),
-                      ),
-                    ],
-                  ),
-                ),
-              ],
-            ),
-          ),
+        Text('Ruang kerja Tim Lapangan', style: textTheme.headlineSmall),
+        const SizedBox(height: 8),
+        Text(
+          widget.user.displayName,
+          style: textTheme.bodyLarge,
         ),
-        const SizedBox(width: 12),
-        PressableScale(
-          onTap: () {},
-          child: Container(
-            width: 40,
-            height: 40,
-            decoration: BoxDecoration(
-              color: const Color(0xFFF1F5F9),
-              shape: BoxShape.circle,
-              border: Border.all(color: const Color(0xFFE2E8F0)),
-            ),
-            child: const Center(
-              child: Icon(
-                Icons.notifications_none_rounded,
-                color: Color(0xFF334155),
-                size: 20,
-              ),
-            ),
-          ),
+        const SizedBox(height: 32),
+        Text('Scan komponen', style: textTheme.titleLarge),
+        const SizedBox(height: 8),
+        Text(
+          'Pindai kode komponen untuk membuka detail, pemeriksaan, dan tindakan servis yang tersedia.',
+          style: textTheme.bodyMedium,
         ),
-      ],
-    );
-  }
-
-  void _showUserProfileBottomSheet(BuildContext context) {
-    showModalBottomSheet<void>(
-      context: context,
-      isScrollControlled: true,
-      backgroundColor: Colors.transparent,
-      builder: (sheetContext) {
-        return Container(
-          decoration: const BoxDecoration(
-            color: Colors.white,
-            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
-          ),
-          padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
-          child: Column(
-            mainAxisSize: MainAxisSize.min,
-            children: [
-              // Drag Handle
-              Container(
-                width: 40,
-                height: 4,
-                decoration: BoxDecoration(
-                  color: const Color(0xFFCBD5E1),
-                  borderRadius: BorderRadius.circular(2),
-                ),
-              ),
-              const SizedBox(height: 18),
-
-              // Sheet Header
-              Row(
-                mainAxisAlignment: MainAxisAlignment.spaceBetween,
-                children: [
-                  const Text(
-                    'Profil Pengguna',
-                    style: TextStyle(
-                      fontFamily: 'Plus Jakarta Sans',
-                      fontSize: 16,
-                      fontWeight: FontWeight.w800,
-                      color: Color(0xFF0F172A),
-                    ),
-                  ),
-                  IconButton(
-                    onPressed: () => Navigator.of(sheetContext).pop(),
-                    icon: const Icon(Icons.close_rounded,
-                        size: 20, color: Color(0xFF64748B)),
-                    padding: EdgeInsets.zero,
-                    constraints: const BoxConstraints(),
-                  ),
-                ],
-              ),
-              const SizedBox(height: 18),
-
-              // User Info Card
-              Container(
-                padding: const EdgeInsets.all(16),
-                decoration: BoxDecoration(
-                  color: const Color(0xFFF8FAFC),
-                  borderRadius: BorderRadius.circular(18),
-                  border: Border.all(color: const Color(0xFFE2E8F0)),
-                ),
-                child: Row(
-                  children: [
-                    Container(
-                      width: 52,
-                      height: 52,
-                      decoration: BoxDecoration(
-                        color: const Color(0xFF1C3E66),
-                        shape: BoxShape.circle,
-                        boxShadow: [
-                          BoxShadow(
-                            color: const Color(0xFF1C3E66).withValues(alpha: 0.25),
-                            blurRadius: 10,
-                            offset: const Offset(0, 4),
-                          ),
-                        ],
-                      ),
-                      child: Center(
-                        child: Text(
-                          widget.user.initials,
-                          style: const TextStyle(
-                            fontFamily: 'Plus Jakarta Sans',
-                            fontSize: 18,
-                            fontWeight: FontWeight.w800,
-                            color: Colors.white,
-                          ),
-                        ),
-                      ),
-                    ),
-                    const SizedBox(width: 14),
-                    Expanded(
-                      child: Column(
-                        crossAxisAlignment: CrossAxisAlignment.start,
-                        children: [
-                          Text(
-                            widget.user.displayName,
-                            style: const TextStyle(
-                              fontFamily: 'Plus Jakarta Sans',
-                              fontSize: 15,
-                              fontWeight: FontWeight.w700,
-                              color: Color(0xFF0F172A),
-                            ),
-                          ),
-                          const SizedBox(height: 4),
-                          Row(
-                            children: [
-                              Container(
-                                padding: const EdgeInsets.symmetric(
-                                    horizontal: 8, vertical: 2),
-                                decoration: BoxDecoration(
-                                  color: const Color(0xFFEFF6FF),
-                                  borderRadius: BorderRadius.circular(6),
-                                  border: Border.all(color: const Color(0xFFBFDBFE)),
-                                ),
-                                child: Text(
-                                  widget.user.role,
-                                  style: const TextStyle(
-                                    fontFamily: 'Plus Jakarta Sans',
-                                    fontSize: 11,
-                                    fontWeight: FontWeight.w700,
-                                    color: Color(0xFF2563EB),
-                                  ),
-                                ),
-                              ),
-                              if (widget.user.username != null) ...[
-                                const SizedBox(width: 8),
-                                Expanded(
-                                  child: Text(
-                                    '@${widget.user.username}',
-                                    maxLines: 1,
-                                    overflow: TextOverflow.ellipsis,
-                                    style: const TextStyle(
-                                      fontFamily: 'Plus Jakarta Sans',
-                                      fontSize: 12,
-                                      fontWeight: FontWeight.w500,
-                                      color: Color(0xFF64748B),
-                                    ),
-                                  ),
-                                ),
-                              ],
-                            ],
-                          ),
-                        ],
-                      ),
-                    ),
-                  ],
-                ),
-              ),
-              const SizedBox(height: 14),
-
-              // Status Box
-              Container(
-                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
-                decoration: BoxDecoration(
-                  color: const Color(0xFFF1F5F9),
-                  borderRadius: BorderRadius.circular(12),
-                ),
-                child: Row(
-                  children: [
-                    const Icon(Icons.check_circle_rounded,
-                        size: 15, color: Color(0xFF16A34A)),
-                    const SizedBox(width: 8),
-                    Text(
-                      widget.user.isAdmin
-                          ? 'Sistem MGRS • Akun Administrator'
-                          : 'Sistem MGRS • Terhubung',
-                      style: const TextStyle(
-                        fontFamily: 'Plus Jakarta Sans',
-                        fontSize: 12,
-                        fontWeight: FontWeight.w600,
-                        color: Color(0xFF334155),
-                      ),
-                    ),
-                  ],
-                ),
-              ),
-
-              // Mode Tampilan Operasional (Admin Only)
-              if (widget.user.isAdmin && widget.onSwitchAdminMode != null) ...[
-                const SizedBox(height: 14),
-                Container(
-                  padding: const EdgeInsets.all(14),
-                  decoration: BoxDecoration(
-                    color: const Color(0xFFF8FAFC),
-                    borderRadius: BorderRadius.circular(14),
-                    border: Border.all(color: const Color(0xFFE2E8F0)),
-                  ),
-                  child: Column(
-                    crossAxisAlignment: CrossAxisAlignment.start,
-                    children: [
-                      const Row(
-                        children: [
-                          Icon(Icons.admin_panel_settings_rounded,
-                              size: 16, color: Color(0xFF0F172A)),
-                          SizedBox(width: 6),
-                          Text(
-                            'Mode Tampilan (Khusus Admin)',
-                            style: TextStyle(
-                              fontFamily: 'Plus Jakarta Sans',
-                              fontSize: 12.5,
-                              fontWeight: FontWeight.w700,
-                              color: Color(0xFF0F172A),
-                            ),
-                          ),
-                        ],
-                      ),
-                      const SizedBox(height: 5),
-                      const Text(
-                        'Pilih peran tampilan operasional yang ingin Anda akses:',
-                        style: TextStyle(
-                          fontFamily: 'Plus Jakarta Sans',
-                          fontSize: 11,
-                          color: Color(0xFF64748B),
-                        ),
-                      ),
-                      const SizedBox(height: 10),
-                      Container(
-                        height: 38,
-                        padding: const EdgeInsets.all(3),
-                        decoration: BoxDecoration(
-                          color: const Color(0xFFE2E8F0),
-                          borderRadius: BorderRadius.circular(10),
-                        ),
-                        child: Row(
-                          children: [
-                            Expanded(
-                              child: PressableScale(
-                                onTap: () {
-                                  Navigator.of(sheetContext).pop();
-                                  widget.onSwitchAdminMode!(AdminAppMode.pic);
-                                },
-                                child: Container(
-                                  decoration: BoxDecoration(
-                                    color: widget.adminMode == AdminAppMode.pic
-                                        ? Colors.white
-                                        : Colors.transparent,
-                                    borderRadius: BorderRadius.circular(8),
-                                    boxShadow: widget.adminMode == AdminAppMode.pic
-                                        ? const [
-                                            BoxShadow(
-                                              color: Color(0x10000000),
-                                              blurRadius: 4,
-                                              offset: Offset(0, 1),
-                                            ),
-                                          ]
-                                        : null,
-                                  ),
-                                  alignment: Alignment.center,
-                                  child: Row(
-                                    mainAxisAlignment: MainAxisAlignment.center,
-                                    children: [
-                                      Icon(
-                                        Icons.event_note_rounded,
-                                        size: 14,
-                                        color: widget.adminMode == AdminAppMode.pic
-                                            ? const Color(0xFF0F172A)
-                                            : const Color(0xFF64748B),
-                                      ),
-                                      const SizedBox(width: 5),
-                                      Text(
-                                        'Mode PIC',
-                                        style: TextStyle(
-                                          fontFamily: 'Plus Jakarta Sans',
-                                          fontSize: 11.5,
-                                          fontWeight: widget.adminMode == AdminAppMode.pic
-                                              ? FontWeight.w700
-                                              : FontWeight.w500,
-                                          color: widget.adminMode == AdminAppMode.pic
-                                              ? const Color(0xFF0F172A)
-                                              : const Color(0xFF64748B),
-                                        ),
-                                      ),
-                                    ],
-                                  ),
-                                ),
-                              ),
-                            ),
-                            Expanded(
-                              child: PressableScale(
-                                onTap: () {
-                                  Navigator.of(sheetContext).pop();
-                                  widget.onSwitchAdminMode!(AdminAppMode.service);
-                                },
-                                child: Container(
-                                  decoration: BoxDecoration(
-                                    color: widget.adminMode == AdminAppMode.service
-                                        ? Colors.white
-                                        : Colors.transparent,
-                                    borderRadius: BorderRadius.circular(8),
-                                    boxShadow: widget.adminMode == AdminAppMode.service
-                                        ? const [
-                                            BoxShadow(
-                                              color: Color(0x10000000),
-                                              blurRadius: 4,
-                                              offset: Offset(0, 1),
-                                            ),
-                                          ]
-                                        : null,
-                                  ),
-                                  alignment: Alignment.center,
-                                  child: Row(
-                                    mainAxisAlignment: MainAxisAlignment.center,
-                                    children: [
-                                      Icon(
-                                        Icons.build_rounded,
-                                        size: 14,
-                                        color: widget.adminMode == AdminAppMode.service
-                                            ? const Color(0xFF0F172A)
-                                            : const Color(0xFF64748B),
-                                      ),
-                                      const SizedBox(width: 5),
-                                      Text(
-                                        'Mode Servis',
-                                        style: TextStyle(
-                                          fontFamily: 'Plus Jakarta Sans',
-                                          fontSize: 11.5,
-                                          fontWeight: widget.adminMode == AdminAppMode.service
-                                              ? FontWeight.w700
-                                              : FontWeight.w500,
-                                          color: widget.adminMode == AdminAppMode.service
-                                              ? const Color(0xFF0F172A)
-                                              : const Color(0xFF64748B),
-                                        ),
-                                      ),
-                                    ],
-                                  ),
-                                ),
-                              ),
-                            ),
-                          ],
-                        ),
-                      ),
-                    ],
-                  ),
-                ),
-              ],
-              const SizedBox(height: 18),
-
-              // Logout Button
-              PressableScale(
-                onTap: () => _confirmLogout(context, sheetContext),
-                child: Container(
-                  width: double.infinity,
-                  height: 48,
-                  decoration: BoxDecoration(
-                    color: const Color(0xFFFEF2F2),
-                    borderRadius: BorderRadius.circular(14),
-                    border: Border.all(color: const Color(0xFFFECACA)),
-                  ),
-                  child: const Row(
-                    mainAxisAlignment: MainAxisAlignment.center,
-                    children: [
-                      Icon(Icons.logout_rounded,
-                          color: Color(0xFFDC2626), size: 18),
-                      SizedBox(width: 8),
-                      Text(
-                        'Keluar dari Akun',
-                        style: TextStyle(
-                          fontFamily: 'Plus Jakarta Sans',
-                          fontSize: 14,
-                          fontWeight: FontWeight.w700,
-                          color: Color(0xFFDC2626),
-                        ),
-                      ),
-                    ],
-                  ),
-                ),
-              ),
-            ],
-          ),
-        );
-      },
-    );
-  }
-
-  void _confirmLogout(BuildContext screenContext, BuildContext sheetContext) {
-    showDialog<void>(
-      context: screenContext,
-      builder: (dialogCtx) => AlertDialog(
-        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
-        title: const Text(
-          'Konfirmasi Keluar',
-          style: TextStyle(
-            fontFamily: 'Plus Jakarta Sans',
-            fontWeight: FontWeight.w800,
-            fontSize: 18,
-          ),
-        ),
-        content: const Text(
-          'Apakah Anda yakin ingin keluar dari akun MGRS?',
-          style: TextStyle(
-            fontFamily: 'Plus Jakarta Sans',
-            fontSize: 14,
-            color: Color(0xFF475569),
-          ),
+        const SizedBox(height: 20),
+        FilledButton.icon(
+          onPressed: () => _openScanner(context),
+          icon: const Icon(Icons.qr_code_scanner),
+          label: const Text('Pindai komponen'),
         ),
-        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
-        actions: [
-          TextButton(
-            onPressed: () => Navigator.of(dialogCtx).pop(),
-            child: const Text(
-              'Batal',
-              style: TextStyle(
-                fontFamily: 'Plus Jakarta Sans',
-                fontWeight: FontWeight.w600,
-                color: Color(0xFF64748B),
-              ),
-            ),
-          ),
-          FilledButton(
-            onPressed: () async {
-              Navigator.of(dialogCtx).pop();
-              Navigator.of(sheetContext).pop();
-              await widget.gateway.signOut();
-            },
-            style: FilledButton.styleFrom(
-              backgroundColor: const Color(0xFFDC2626),
-              shape: RoundedRectangleBorder(
-                  borderRadius: BorderRadius.circular(10)),
-            ),
-            child: const Text(
-              'Ya, Keluar',
-              style: TextStyle(
-                fontFamily: 'Plus Jakarta Sans',
-                fontWeight: FontWeight.w700,
-              ),
-            ),
-          ),
-        ],
-      ),
-    );
-  }
-
-  // 2. Bento Card: Lime #CEF284 + "Pengingat!" chip + "Pengecekan Unit Berkala" + Circular Progress "6 Hari Lagi"
-  Widget _buildWeeklyProgressBento(BuildContext context) {
-    return Container(
-      decoration: BoxDecoration(
-        color: const Color(0xFFCEF284),
-        borderRadius: BorderRadius.circular(18),
-        border: Border.all(color: const Color(0xFFBCE66E), width: 1.2),
-      ),
-      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
-      child: Row(
-        mainAxisAlignment: MainAxisAlignment.spaceBetween,
-        children: [
-          Expanded(
-            child: Column(
-              crossAxisAlignment: CrossAxisAlignment.start,
-              children: [
-                Container(
-                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
-                  decoration: BoxDecoration(
-                    color: Colors.white,
-                    borderRadius: BorderRadius.circular(20),
-                  ),
-                  child: const Row(
-                    mainAxisSize: MainAxisSize.min,
-                    children: [
-                      Icon(Icons.auto_awesome, size: 12, color: Color(0xFF22380E)),
-                      SizedBox(width: 5),
-                      Text(
-                        'Pengingat!',
-                        style: TextStyle(
-                          fontFamily: 'Inter',
-                          fontSize: 11,
-                          fontWeight: FontWeight.w600,
-                          color: Color(0xFF22380E),
-                        ),
-                      ),
-                    ],
-                  ),
-                ),
-                const SizedBox(height: 10),
-                const Text(
-                  'Pengecekan Unit\nBerkala',
-                  style: TextStyle(
-                    fontFamily: 'Inter',
-                    fontSize: 19,
-                    fontWeight: FontWeight.w800,
-                    color: Color(0xFF1A330E),
-                    height: 1.25,
-                    letterSpacing: -0.4,
-                  ),
-                ),
-              ],
-            ),
-          ),
-          // Circular Progress Widget
-          SizedBox(
-            width: 86,
-            height: 86,
-            child: Stack(
-              alignment: Alignment.center,
-              children: [
-                CustomPaint(
-                  size: const Size(86, 86),
-                  painter: _CircularCountdownPainter(),
-                ),
-                Column(
-                  mainAxisAlignment: MainAxisAlignment.center,
-                  children: [
-                    Text(
-                      _countdownDays,
-                      style: const TextStyle(
-                        fontFamily: 'Inter',
-                        fontSize: 22,
-                        fontWeight: FontWeight.w800,
-                        color: Color(0xFF1B350F),
-                        height: 1.0,
-                      ),
-                    ),
-                    const SizedBox(height: 2),
-                    const Text(
-                      'Hari Lagi',
-                      style: TextStyle(
-                        fontFamily: 'Inter',
-                        fontSize: 9,
-                        fontWeight: FontWeight.w700,
-                        color: Color(0xFF527032),
-                      ),
-                    ),
-                  ],
-                ),
-              ],
+        if (_error != null) ...[
+          const SizedBox(height: 24),
+          Text(
+            failureMessage(_error),
+            style: textTheme.bodyMedium?.copyWith(
+              color: Theme.of(context).colorScheme.error,
             ),
           ),
         ],
-      ),
-    );
-  }
-
-  // 3. Status Unit Blower (Total 24 mesin aktif dipantau + Live Data badge + 3 gradient cards)
-  Widget _buildUnitStatusSection(BuildContext context) {
-    return Column(
-      crossAxisAlignment: CrossAxisAlignment.start,
-      children: [
-        Row(
-          mainAxisAlignment: MainAxisAlignment.spaceBetween,
-          children: [
-            Expanded(
-              child: Column(
-                crossAxisAlignment: CrossAxisAlignment.start,
-                children: [
-                  const Text(
-                    'Status Unit Blower',
-                    style: TextStyle(
-                      fontFamily: 'Plus Jakarta Sans',
-                      fontSize: 16,
-                      fontWeight: FontWeight.w700,
-                      color: Color(0xFF0F172A),
-                      letterSpacing: -0.3,
-                    ),
-                  ),
-                  const SizedBox(height: 2),
-                  Text(
-                    _totalMonitored == 0 && !_loading
-                        ? 'Belum ada unit terdata'
-                        : 'Total $_totalMonitored mesin aktif dipantau',
-                    maxLines: 1,
-                    overflow: TextOverflow.ellipsis,
-                    style: const TextStyle(
-                      fontFamily: 'Plus Jakarta Sans',
-                      fontSize: 11,
-                      fontWeight: FontWeight.w500,
-                      color: Color(0xFF64748B),
-                    ),
-                  ),
-                ],
-              ),
-            ),
-            const SizedBox(width: 8),
-            Container(
-              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
-              decoration: BoxDecoration(
-                color: const Color(0xFFF1F5F9),
-                borderRadius: BorderRadius.circular(20),
-              ),
-              child: const Row(
-                mainAxisSize: MainAxisSize.min,
-                children: [
-                  CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
-                  SizedBox(width: 5),
-                  Text(
-                    'Data Terkini',
-                    style: TextStyle(
-                      fontFamily: 'Plus Jakarta Sans',
-                      fontSize: 10,
-                      fontWeight: FontWeight.w600,
-                      color: Color(0xFF334155),
-                    ),
-                  ),
-                ],
-              ),
-            ),
-          ],
-        ),
-        const SizedBox(height: 12),
-        // 3 Vibrant Solid Status Cards
-        Row(
-          children: [
-            // Card 1: Beroperasi (Vibrant Emerald Solid)
-            Expanded(
-              child: _buildGradientStatusCard(
-                icon: Icons.check_rounded,
-                percentage: _totalMonitored > 0
-                    ? '${((_operatingCount / _totalMonitored) * 100).round()}%'
-                    : '0%',
-                count: '$_operatingCount',
-                title: 'Beroperasi',
-                subtitle: 'Kondisi prima',
-                solidColor: const Color(0xFF059669),
-              ),
-            ),
-            const SizedBox(width: 10),
-            // Card 2: Perlu Servis (Vibrant Amber Solid)
-            Expanded(
-              child: _buildGradientStatusCard(
-                icon: Icons.build_rounded,
-                percentage: _totalMonitored > 0
-                    ? '${((_serviceCount / _totalMonitored) * 100).round()}%'
-                    : '0%',
-                count: '$_serviceCount',
-                title: 'Perlu Servis',
-                subtitle: 'Jadwal dekat',
-                solidColor: const Color(0xFFD97706),
-              ),
-            ),
-            const SizedBox(width: 10),
-            // Card 3: Kendala (Vibrant Rose Solid)
-            Expanded(
-              child: _buildGradientStatusCard(
-                icon: Icons.warning_amber_rounded,
-                percentage: _totalMonitored > 0
-                    ? '${((_problemCount / _totalMonitored) * 100).round()}%'
-                    : '0%',
-                count: '$_problemCount',
-                title: 'Kendala',
-                subtitle: 'Cek fisik',
-                solidColor: const Color(0xFFE11D48),
-              ),
-            ),
-          ],
-        ),
-      ],
-    );
-  }
-
-  Widget _buildGradientStatusCard({
-    required IconData icon,
-    required String percentage,
-    required String count,
-    required String title,
-    required String subtitle,
-    required Color solidColor,
-  }) {
-    return PressableScale(
-      child: Container(
-        height: 120,
-        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
-        decoration: BoxDecoration(
-          color: solidColor,
-          borderRadius: BorderRadius.circular(16),
-          boxShadow: [
-            BoxShadow(
-              color: solidColor.withValues(alpha: 0.28),
-              blurRadius: 10,
-              offset: const Offset(0, 4),
-            ),
-          ],
-        ),
-        child: Column(
-          crossAxisAlignment: CrossAxisAlignment.start,
-          mainAxisAlignment: MainAxisAlignment.spaceBetween,
-          children: [
-            Row(
-              mainAxisAlignment: MainAxisAlignment.spaceBetween,
-              children: [
-                Container(
-                  width: 28,
-                  height: 28,
-                  decoration: BoxDecoration(
-                    color: Colors.white.withValues(alpha: 0.22),
-                    borderRadius: BorderRadius.circular(8),
-                  ),
-                  child: Icon(icon, color: Colors.white, size: 15),
-                ),
-                Container(
-                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
-                  decoration: BoxDecoration(
-                    color: Colors.white.withValues(alpha: 0.24),
-                    borderRadius: BorderRadius.circular(12),
-                  ),
-                  child: Text(
-                    percentage,
-                    style: const TextStyle(
-                      fontFamily: 'Inter',
-                      fontSize: 10,
-                      fontWeight: FontWeight.w700,
-                      color: Colors.white,
-                    ),
-                  ),
-                ),
-              ],
-            ),
-            Column(
-              crossAxisAlignment: CrossAxisAlignment.start,
-              children: [
-                Text(
-                  count,
-                  style: const TextStyle(
-                    fontFamily: 'Inter',
-                    fontSize: 22,
-                    fontWeight: FontWeight.w800,
-                    color: Colors.white,
-                    height: 1.1,
-                  ),
-                ),
-                const SizedBox(height: 3),
-                Text(
-                  title,
-                  maxLines: 1,
-                  overflow: TextOverflow.ellipsis,
-                  style: const TextStyle(
-                    fontFamily: 'Plus Jakarta Sans',
-                    fontSize: 11.5,
-                    fontWeight: FontWeight.w700,
-                    color: Colors.white,
-                  ),
-                ),
-                const SizedBox(height: 1),
-                Text(
-                  subtitle,
-                  maxLines: 1,
-                  overflow: TextOverflow.ellipsis,
-                  style: TextStyle(
-                    fontFamily: 'Plus Jakarta Sans',
-                    fontSize: 9.5,
-                    fontWeight: FontWeight.w500,
-                    color: Colors.white.withValues(alpha: 0.85),
-                  ),
-                ),
-              ],
-            ),
-          ],
-        ),
-      ),
-    );
-  }
-
-  // 4. Orderan Mendatang (Section title + dynamic count badge + "Lihat Semua" + dynamic Order Cards)
-  Widget _buildUpcomingOrdersSection(BuildContext context) {
-    return Column(
-      crossAxisAlignment: CrossAxisAlignment.start,
-      children: [
-        Row(
-          mainAxisAlignment: MainAxisAlignment.spaceBetween,
-          children: [
-            Expanded(
-              child: Row(
-                children: [
-                  const Flexible(
-                    child: Text(
-                      'Orderan Mendatang',
-                      maxLines: 1,
-                      overflow: TextOverflow.ellipsis,
-                      style: TextStyle(
-                        fontFamily: 'Inter',
-                        fontSize: 16,
-                        fontWeight: FontWeight.w700,
-                        color: Color(0xFF0F172A),
-                        letterSpacing: -0.3,
-                      ),
-                    ),
-                  ),
-                  const SizedBox(width: 8),
-                  Container(
-                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
-                    decoration: BoxDecoration(
-                      color: const Color(0xFFF1F5F9),
-                      borderRadius: BorderRadius.circular(20),
-                    ),
-                    child: Text(
-                      '${_upcomingOrders.length}',
-                      style: const TextStyle(
-                        fontFamily: 'Inter',
-                        fontSize: 11,
-                        fontWeight: FontWeight.w700,
-                        color: Color(0xFF475569),
-                      ),
-                    ),
-                  ),
-                ],
-              ),
-            ),
-            const SizedBox(width: 8),
-            GestureDetector(
-              onTap: () {
-                Navigator.of(context).push<void>(
-                  MaterialPageRoute(
-                    builder: (_) => UpcomingOrdersScreen(
-                      gateway: widget.gateway,
-                      user: widget.user,
-                    ),
-                  ),
-                );
-              },
-              child: const Text(
-                'Lihat Semua',
-                style: TextStyle(
-                  fontFamily: 'Inter',
-                  fontSize: 12,
-                  fontWeight: FontWeight.w600,
-                  color: Color(0xFF2563EB),
-                ),
-              ),
-            ),
-          ],
+        const SizedBox(height: 32),
+        TextButton.icon(
+          onPressed: _signingOut ? null : _signOut,
+          icon: _signingOut
+              ? const SizedBox.square(
+                  dimension: 18,
+                  child: CircularProgressIndicator(strokeWidth: 2),
+                )
+              : const Icon(Icons.logout),
+          label: Text(_signingOut ? 'Keluar…' : 'Keluar dari akun'),
         ),
-        const SizedBox(height: 12),
-        if (_upcomingOrders.isNotEmpty) ...[
-          ..._upcomingOrders.take(3).map((order) {
-            return _buildOrderCard(context, order);
-          }),
-        ] else ...[
-          Container(
-            width: double.infinity,
-            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
-            decoration: BoxDecoration(
-              color: const Color(0xFFF8FAFC),
-              borderRadius: BorderRadius.circular(18),
-              border: Border.all(color: const Color(0xFFE2E8F0)),
-            ),
-            child: const Column(
-              children: [
-                Icon(Icons.event_available_rounded,
-                    size: 32, color: Color(0xFF94A3B8)),
-                SizedBox(height: 8),
-                Text(
-                  'Tidak ada orderan mendatang saat ini',
-                  style: TextStyle(
-                    fontFamily: 'Plus Jakarta Sans',
-                    fontSize: 13,
-                    fontWeight: FontWeight.w700,
-                    color: Color(0xFF334155),
-                  ),
-                ),
-                SizedBox(height: 2),
-                Text(
-                  'Jadwal pemasangan diperbarui otomatis saat ada orderan baru.',
-                  textAlign: TextAlign.center,
-                  style: TextStyle(
-                    fontFamily: 'Plus Jakarta Sans',
-                    fontSize: 11,
-                    color: Color(0xFF64748B),
-                  ),
-                ),
-              ],
-            ),
-          ),
-        ],
       ],
     );
   }
-
-  Widget _buildOrderCard(BuildContext context, OrderanSewa order) {
-    final hasMaps =
-        order.linkGmaps != null && order.linkGmaps!.trim().isNotEmpty;
-    final hasWa = order.cleanWhatsapp.isNotEmpty;
-
-    final isPast = order.isPast;
-    final String statusText;
-    final Color statusBg;
-    final Color statusBorder;
-    final Color statusColor;
-    final Color dotColor;
-
-    if (isPast) {
-      statusText = order.isCompletedOrCancelled
-          ? (order.statusOrderan ?? 'Selesai')
-          : 'Selesai / Lewat';
-      statusBg = const Color(0xFFF1F5F9);
-      statusBorder = const Color(0xFFCBD5E1);
-      statusColor = const Color(0xFF475569);
-      dotColor = const Color(0xFF94A3B8);
-    } else {
-      statusText =
-          (order.statusOrderan != null && order.statusOrderan!.isNotEmpty)
-              ? order.statusOrderan!
-              : 'Terjadwal';
-      statusBg = const Color(0xFFECFDF5);
-      statusBorder = const Color(0xFFA7F3D0);
-      statusColor = const Color(0xFF059669);
-      dotColor = const Color(0xFF10B981);
-    }
-
-    return Padding(
-      padding: const EdgeInsets.only(bottom: 10),
-      child: PressableScale(
-        onTap: () {
-          Navigator.of(context).push<void>(
-            MaterialPageRoute(
-              builder: (_) => OrderDetailScreen(
-                order: order,
-                gateway: widget.gateway,
-                user: widget.user,
-              ),
-            ),
-          );
-        },
-        child: Container(
-          padding: const EdgeInsets.all(16),
-          decoration: BoxDecoration(
-            color: Colors.white,
-            borderRadius: BorderRadius.circular(18),
-            border: Border.all(color: const Color(0xFFE2E8F0)),
-            boxShadow: const [
-              BoxShadow(
-                color: Color(0x06000000),
-                blurRadius: 8,
-                offset: Offset(0, 2),
-              ),
-            ],
-          ),
-          child: Column(
-            crossAxisAlignment: CrossAxisAlignment.start,
-            children: [
-              // 1. Header: [ ● ORD-XXX • 10 Unit (1 Hari) ]  ...  [ Terjadwal ]
-              Row(
-                mainAxisAlignment: MainAxisAlignment.spaceBetween,
-                children: [
-                  Expanded(
-                    child: Row(
-                      children: [
-                        Container(
-                          width: 7,
-                          height: 7,
-                          decoration: BoxDecoration(
-                            color: dotColor,
-                            borderRadius: BorderRadius.circular(2),
-                          ),
-                        ),
-                        const SizedBox(width: 6),
-                        Expanded(
-                          child: Text.rich(
-                            TextSpan(
-                              text: order.displayCode,
-                              style: const TextStyle(
-                                fontFamily: 'Plus Jakarta Sans',
-                                fontSize: 12,
-                                fontWeight: FontWeight.w700,
-                                color: Color(0xFF0F172A),
-                              ),
-                              children: [
-                                const TextSpan(
-                                  text: ' • ',
-                                  style: TextStyle(
-                                    fontWeight: FontWeight.normal,
-                                    color: Color(0xFF94A3B8),
-                                  ),
-                                ),
-                                TextSpan(
-                                  text: '${order.jumlahUnit} Unit',
-                                  style: const TextStyle(
-                                    fontWeight: FontWeight.w600,
-                                    color: Color(0xFF475569),
-                                  ),
-                                ),
-                                TextSpan(
-                                  text: ' (${order.durasiSewaText})',
-                                  style: const TextStyle(
-                                    fontWeight: FontWeight.w500,
-                                    color: Color(0xFF64748B),
-                                  ),
-                                ),
-                              ],
-                            ),
-                            maxLines: 1,
-                            overflow: TextOverflow.ellipsis,
-                          ),
-                        ),
-                      ],
-                    ),
-                  ),
-                  const SizedBox(width: 8),
-                  Container(
-                    padding:
-                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
-                    decoration: BoxDecoration(
-                      color: statusBg,
-                      borderRadius: BorderRadius.circular(8),
-                      border: Border.all(color: statusBorder),
-                    ),
-                    child: Text(
-                      statusText,
-                      style: TextStyle(
-                        fontFamily: 'Plus Jakarta Sans',
-                        fontSize: 10.5,
-                        fontWeight: FontWeight.w700,
-                        color: statusColor,
-                      ),
-                    ),
-                  ),
-                ],
-              ),
-              const SizedBox(height: 10),
-
-              // 2. Body: Nama Event (Bold)
-              Text(
-                order.namaEvent,
-                style: const TextStyle(
-                  fontFamily: 'Plus Jakarta Sans',
-                  fontSize: 15,
-                  fontWeight: FontWeight.w800,
-                  color: Color(0xFF0F172A),
-                  letterSpacing: -0.2,
-                ),
-              ),
-
-              // Detail Klien
-              if (order.namaClient != null && order.namaClient!.isNotEmpty) ...[
-                const SizedBox(height: 3),
-                Text(
-                  'Klien: ${order.namaClient}${order.nomorWhatsapp != null && order.nomorWhatsapp!.isNotEmpty ? ' • ${order.nomorWhatsapp}' : ''}',
-                  maxLines: 1,
-                  overflow: TextOverflow.ellipsis,
-                  style: const TextStyle(
-                    fontFamily: 'Plus Jakarta Sans',
-                    fontSize: 11.5,
-                    fontWeight: FontWeight.w500,
-                    color: Color(0xFF64748B),
-                  ),
-                ),
-              ],
-
-              // Alamat Venue
-              if (order.alamat != null && order.alamat!.isNotEmpty) ...[
-                const SizedBox(height: 4),
-                Row(
-                  crossAxisAlignment: CrossAxisAlignment.start,
-                  children: [
-                    const Icon(Icons.location_on_outlined,
-                        size: 14, color: Color(0xFF64748B)),
-                    const SizedBox(width: 4),
-                    Expanded(
-                      child: Text(
-                        order.alamat!,
-                        maxLines: 2,
-                        overflow: TextOverflow.ellipsis,
-                        style: const TextStyle(
-                          fontFamily: 'Plus Jakarta Sans',
-                          fontSize: 11.5,
-                          color: Color(0xFF64748B),
-                          height: 1.35,
-                        ),
-                      ),
-                    ),
-                  ],
-                ),
-              ],
-
-              const SizedBox(height: 10),
-
-              // 3. Footer: [ Kamis, 10 Sep 2026 ]  ...  [ Maps ] [ WA ]
-              Container(
-                padding: const EdgeInsets.only(top: 8),
-                decoration: const BoxDecoration(
-                  border: Border(
-                    top: BorderSide(color: Color(0xFFF1F5F9)),
-                  ),
-                ),
-                child: Row(
-                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
-                  children: [
-                    Expanded(
-                      child: Row(
-                        mainAxisSize: MainAxisSize.min,
-                        children: [
-                          const Icon(
-                            Icons.calendar_today_rounded,
-                            size: 12,
-                            color: Color(0xFF64748B),
-                          ),
-                          const SizedBox(width: 6),
-                          Expanded(
-                            child: Text(
-                              order.dayDateYear,
-                              maxLines: 1,
-                              overflow: TextOverflow.ellipsis,
-                              style: const TextStyle(
-                                fontFamily: 'Plus Jakarta Sans',
-                                fontSize: 11.5,
-                                fontWeight: FontWeight.w600,
-                                color: Color(0xFF475569),
-                              ),
-                            ),
-                          ),
-                        ],
-                      ),
-                    ),
-                    const SizedBox(width: 8),
-                    Row(
-                      mainAxisSize: MainAxisSize.min,
-                      children: [
-                        if (hasMaps)
-                          PressableScale(
-                            onTap: () => order.launchMaps(),
-                            child: Container(
-                              padding: const EdgeInsets.symmetric(
-                                  horizontal: 9, vertical: 4),
-                              decoration: BoxDecoration(
-                                color: const Color(0xFFEFF6FF),
-                                borderRadius: BorderRadius.circular(8),
-                                border:
-                                    Border.all(color: const Color(0xFFBFDBFE)),
-                              ),
-                              child: const Row(
-                                children: [
-                                  Icon(Icons.near_me_rounded,
-                                      size: 12, color: Color(0xFF2563EB)),
-                                  SizedBox(width: 4),
-                                  Text(
-                                    'Maps',
-                                    style: TextStyle(
-                                      fontFamily: 'Plus Jakarta Sans',
-                                      fontSize: 10.5,
-                                      fontWeight: FontWeight.w700,
-                                      color: Color(0xFF2563EB),
-                                    ),
-                                  ),
-                                ],
-                              ),
-                            ),
-                          ),
-                        if (hasMaps && hasWa) const SizedBox(width: 6),
-                        if (hasWa)
-                          PressableScale(
-                            onTap: () => order.launchWhatsApp(),
-                            child: Container(
-                              padding: const EdgeInsets.symmetric(
-                                  horizontal: 9, vertical: 4),
-                              decoration: BoxDecoration(
-                                color: const Color(0xFFF0FDF4),
-                                borderRadius: BorderRadius.circular(8),
-                                border:
-                                    Border.all(color: const Color(0xFFBBF7D0)),
-                              ),
-                              child: const Row(
-                                children: [
-                                  Icon(Icons.chat_rounded,
-                                      size: 12, color: Color(0xFF16A34A)),
-                                  SizedBox(width: 4),
-                                  Text(
-                                    'WA',
-                                    style: TextStyle(
-                                      fontFamily: 'Plus Jakarta Sans',
-                                      fontSize: 10.5,
-                                      fontWeight: FontWeight.w700,
-                                      color: Color(0xFF16A34A),
-                                    ),
-                                  ),
-                                ],
-                              ),
-                            ),
-                          ),
-                        if (!hasMaps && !hasWa)
-                          const Icon(Icons.chevron_right_rounded,
-                              size: 18, color: Color(0xFF94A3B8)),
-                      ],
-                    ),
-                  ],
-                ),
-              ),
-            ],
-          ),
-        ),
-      ),
-    );
-  }
-}
-
-// Custom Painter for countdown circular ring in Bento Card
-class _CircularCountdownPainter extends CustomPainter {
-  @override
-  void paint(Canvas canvas, Size size) {
-    final center = Offset(size.width / 2, size.height / 2);
-
-    // Background track ring
-    final trackPaint = Paint()
-      ..color = Colors.white
-      ..style = PaintingStyle.stroke
-      ..strokeWidth = 10;
-    canvas.drawCircle(center, 35, trackPaint);
-
-    // Inner filled circle with opacity
-    final innerPaint = Paint()
-      ..color = Colors.white.withValues(alpha: 0.45)
-      ..style = PaintingStyle.fill;
-    canvas.drawCircle(center, 25, innerPaint);
-
-    // Inner border stroke
-    final innerStroke = Paint()
-      ..color = const Color(0xFFCEF284)
-      ..style = PaintingStyle.stroke
-      ..strokeWidth = 3;
-    canvas.drawCircle(center, 25, innerStroke);
-
-    // Progress Arc #78C423
-    final progressPaint = Paint()
-      ..color = const Color(0xFF78C423)
-      ..style = PaintingStyle.stroke
-      ..strokeWidth = 10
-      ..strokeCap = StrokeCap.round;
-
-    // Draw arc ~ 270 degrees
-    canvas.drawArc(
-      Rect.fromCircle(center: center, radius: 35),
-      -math.pi / 2,
-      math.pi * 1.5,
-      false,
-      progressPaint,
-    );
-  }
-
-  @override
-  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
 }
diff --git a/lib/features/home/pic_home_screen.dart b/lib/features/home/pic_home_screen.dart
index 12227f6..97cffbc 100644
--- a/lib/features/home/pic_home_screen.dart
+++ b/lib/features/home/pic_home_screen.dart
@@ -1,1554 +1,149 @@
-import 'dart:math' as math;
 import 'package:flutter/material.dart';
+
 import '../../app/gateway.dart';
-import '../../shared/pressable.dart';
-import '../schedule/order_detail_screen.dart';
+import '../../shared/async_state_view.dart';
 import '../schedule/order_model.dart';
 
+/// PIC MGRS landing surface backed only by order data from the gateway.
 class PicHomeScreen extends StatefulWidget {
   const PicHomeScreen({
     super.key,
     required this.gateway,
     required this.user,
     required this.onOpenOrdersTab,
     required this.onOpenInvoicesTab,
-    this.adminMode,
-    this.onSwitchAdminMode,
   });
 
   final MaintenanceGateway gateway;
   final UserProfile user;
   final VoidCallback onOpenOrdersTab;
   final VoidCallback onOpenInvoicesTab;
-  final AdminAppMode? adminMode;
-  final ValueChanged<AdminAppMode>? onSwitchAdminMode;
 
   @override
   State<PicHomeScreen> createState() => _PicHomeScreenState();
 }
 
 class _PicHomeScreenState extends State<PicHomeScreen> {
-  bool _isLoading = true;
-  String? _error;
-  List<OrderanSewa> _allOrders = [];
-  List<OrderanSewa> _upcomingOrders = [];
-  List<OrderanSewa> _pastOrders = [];
+  late Future<List<OrderanSewa>> _orders;
 
   @override
   void initState() {
     super.initState();
-    _loadData();
-  }
-
-  Future<void> _loadData({bool forceRefresh = false}) async {
-    setState(() {
-      _isLoading = true;
-      _error = null;
-    });
-
-    try {
-      final allOrders = await widget.gateway
-          .fetchUpcomingOrders(limit: 50, forceRefresh: forceRefresh);
-
-      if (!mounted) return;
-
-      setState(() {
-        _allOrders = allOrders;
-        _upcomingOrders = allOrders.where((o) => o.isUpcoming).toList();
-        _pastOrders = allOrders.where((o) => o.isPast).toList();
-        _isLoading = false;
-      });
-    } catch (e) {
-      if (!mounted) return;
-      setState(() {
-        _error = failureMessage(e);
-        _isLoading = false;
-      });
-    }
-  }
-
-  int get _thisMonthOrdersCount {
-    try {
-      final list = _allOrders;
-      if (list.isEmpty) return 0;
-      final now = DateTime.now();
-      var count = 0;
-      for (var i = 0; i < list.length; i++) {
-        final dt = list[i].tanggalPemasangan;
-        if (dt != null && dt.year == now.year && dt.month == now.month) {
-          count++;
-        }
-      }
-      return count;
-    } catch (_) {
-      return 0;
-    }
-  }
-
-  int get _todayOrdersCount {
-    try {
-      final list = _upcomingOrders;
-      if (list.isEmpty) return 0;
-      final now = DateTime.now();
-      var count = 0;
-      for (var i = 0; i < list.length; i++) {
-        final dt = list[i].tanggalPemasangan;
-        if (dt != null &&
-            dt.year == now.year &&
-            dt.month == now.month &&
-            dt.day == now.day) {
-          count++;
-        }
-      }
-      return count;
-    } catch (_) {
-      return 0;
-    }
-  }
-
-  int get _totalOrdersCount {
-    try {
-      return _allOrders.length;
-    } catch (_) {
-      return 0;
-    }
-  }
-
-  int get _upcomingCount {
-    try {
-      return _upcomingOrders.length;
-    } catch (_) {
-      return 0;
-    }
-  }
-
-  int get _pastCount {
-    try {
-      return _pastOrders.length;
-    } catch (_) {
-      return 0;
-    }
-  }
-
-  String _getGreeting() {
-    final hour = DateTime.now().hour;
-    if (hour < 11) return 'Selamat Pagi!';
-    if (hour < 15) return 'Selamat Siang!';
-    if (hour < 18) return 'Selamat Sore!';
-    return 'Selamat Malam!';
-  }
-
-  static String _formatMonthName(DateTime dt) {
-    const months = [
-      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
-      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
-    ];
-    return '${months[dt.month - 1]} ${dt.year}';
+    _orders = _loadOrders();
   }
 
-  void _showUserProfileBottomSheet(BuildContext context) {
-    showModalBottomSheet<void>(
-      context: context,
-      isScrollControlled: true,
-      backgroundColor: Colors.white,
-      shape: const RoundedRectangleBorder(
-        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
-      ),
-      builder: (sheetContext) {
-        return SafeArea(
-          child: Padding(
-            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
-            child: Column(
-              mainAxisSize: MainAxisSize.min,
-              children: [
-                // Drag Handle
-                Container(
-                  width: 36,
-                  height: 4,
-                  decoration: BoxDecoration(
-                    color: const Color(0xFFCBD5E1),
-                    borderRadius: BorderRadius.circular(2),
-                  ),
-                ),
-                const SizedBox(height: 18),
-
-                // User Info Card
-                Container(
-                  padding:
-                      const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
-                  decoration: BoxDecoration(
-                    color: const Color(0xFFF8FAFC),
-                    borderRadius: BorderRadius.circular(16),
-                    border: Border.all(color: const Color(0xFFE2E8F0)),
-                  ),
-                  child: Row(
-                    children: [
-                      Container(
-                        width: 52,
-                        height: 52,
-                        decoration: BoxDecoration(
-                          color: const Color(0xFF1C3E66),
-                          shape: BoxShape.circle,
-                          boxShadow: [
-                            BoxShadow(
-                              color: const Color(0xFF1C3E66)
-                                  .withValues(alpha: 0.25),
-                              blurRadius: 10,
-                              offset: const Offset(0, 4),
-                            ),
-                          ],
-                        ),
-                        child: Center(
-                          child: Text(
-                            widget.user.initials,
-                            style: const TextStyle(
-                              fontFamily: 'Plus Jakarta Sans',
-                              fontSize: 18,
-                              fontWeight: FontWeight.w800,
-                              color: Colors.white,
-                            ),
-                          ),
-                        ),
-                      ),
-                      const SizedBox(width: 14),
-                      Expanded(
-                        child: Column(
-                          crossAxisAlignment: CrossAxisAlignment.start,
-                          children: [
-                            Text(
-                              widget.user.displayName,
-                              style: const TextStyle(
-                                fontFamily: 'Plus Jakarta Sans',
-                                fontSize: 15,
-                                fontWeight: FontWeight.w700,
-                                color: Color(0xFF0F172A),
-                              ),
-                            ),
-                            const SizedBox(height: 4),
-                            Row(
-                              children: [
-                                Container(
-                                  padding: const EdgeInsets.symmetric(
-                                      horizontal: 8, vertical: 2),
-                                  decoration: BoxDecoration(
-                                    color: const Color(0xFFEFF6FF),
-                                    borderRadius: BorderRadius.circular(6),
-                                    border: Border.all(
-                                        color: const Color(0xFFBFDBFE)),
-                                  ),
-                                  child: Text(
-                                    widget.user.role,
-                                    style: const TextStyle(
-                                      fontFamily: 'Plus Jakarta Sans',
-                                      fontSize: 11,
-                                      fontWeight: FontWeight.w700,
-                                      color: Color(0xFF2563EB),
-                                    ),
-                                  ),
-                                ),
-                                if (widget.user.username != null) ...[
-                                  const SizedBox(width: 8),
-                                  Expanded(
-                                    child: Text(
-                                      '@${widget.user.username}',
-                                      maxLines: 1,
-                                      overflow: TextOverflow.ellipsis,
-                                      style: const TextStyle(
-                                        fontFamily: 'Plus Jakarta Sans',
-                                        fontSize: 12,
-                                        fontWeight: FontWeight.w500,
-                                        color: Color(0xFF64748B),
-                                      ),
-                                    ),
-                                  ),
-                                ],
-                              ],
-                            ),
-                          ],
-                        ),
-                      ),
-                    ],
-                  ),
-                ),
-                const SizedBox(height: 14),
-
-                // Status Box
-                Container(
-                  padding:
-                      const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
-                  decoration: BoxDecoration(
-                    color: const Color(0xFFF1F5F9),
-                    borderRadius: BorderRadius.circular(12),
-                  ),
-                  child: Row(
-                    children: [
-                      const Icon(Icons.check_circle_rounded,
-                          size: 15, color: Color(0xFF16A34A)),
-                      const SizedBox(width: 8),
-                      Text(
-                        widget.user.isAdmin
-                            ? 'Sistem MGRS • Akun Administrator'
-                            : 'Sistem MGRS • Terhubung (Mode PIC)',
-                        style: const TextStyle(
-                          fontFamily: 'Plus Jakarta Sans',
-                          fontSize: 12,
-                          fontWeight: FontWeight.w600,
-                          color: Color(0xFF334155),
-                        ),
-                      ),
-                    ],
-                  ),
-                ),
-
-                // Mode Tampilan Operasional (Admin Only)
-                if (widget.user.isAdmin && widget.onSwitchAdminMode != null) ...[
-                  const SizedBox(height: 14),
-                  Container(
-                    padding: const EdgeInsets.all(14),
-                    decoration: BoxDecoration(
-                      color: const Color(0xFFF8FAFC),
-                      borderRadius: BorderRadius.circular(14),
-                      border: Border.all(color: const Color(0xFFE2E8F0)),
-                    ),
-                    child: Column(
-                      crossAxisAlignment: CrossAxisAlignment.start,
-                      children: [
-                        const Row(
-                          children: [
-                            Icon(Icons.admin_panel_settings_rounded,
-                                size: 16, color: Color(0xFF0F172A)),
-                            SizedBox(width: 6),
-                            Text(
-                              'Mode Tampilan (Khusus Admin)',
-                              style: TextStyle(
-                                fontFamily: 'Plus Jakarta Sans',
-                                fontSize: 12.5,
-                                fontWeight: FontWeight.w700,
-                                color: Color(0xFF0F172A),
-                              ),
-                            ),
-                          ],
-                        ),
-                        const SizedBox(height: 5),
-                        const Text(
-                          'Pilih peran tampilan operasional yang ingin Anda akses:',
-                          style: TextStyle(
-                            fontFamily: 'Plus Jakarta Sans',
-                            fontSize: 11,
-                            color: Color(0xFF64748B),
-                          ),
-                        ),
-                        const SizedBox(height: 10),
-                        Container(
-                          height: 38,
-                          padding: const EdgeInsets.all(3),
-                          decoration: BoxDecoration(
-                            color: const Color(0xFFE2E8F0),
-                            borderRadius: BorderRadius.circular(10),
-                          ),
-                          child: Row(
-                            children: [
-                              Expanded(
-                                child: PressableScale(
-                                  onTap: () {
-                                    Navigator.of(sheetContext).pop();
-                                    widget.onSwitchAdminMode!(AdminAppMode.pic);
-                                  },
-                                  child: Container(
-                                    decoration: BoxDecoration(
-                                      color: widget.adminMode == AdminAppMode.pic
-                                          ? Colors.white
-                                          : Colors.transparent,
-                                      borderRadius: BorderRadius.circular(8),
-                                      boxShadow: widget.adminMode == AdminAppMode.pic
-                                          ? const [
-                                              BoxShadow(
-                                                color: Color(0x10000000),
-                                                blurRadius: 4,
-                                                offset: Offset(0, 1),
-                                              ),
-                                            ]
-                                          : null,
-                                    ),
-                                    alignment: Alignment.center,
-                                    child: Row(
-                                      mainAxisAlignment: MainAxisAlignment.center,
-                                      children: [
-                                        Icon(
-                                          Icons.event_note_rounded,
-                                          size: 14,
-                                          color: widget.adminMode == AdminAppMode.pic
-                                              ? const Color(0xFF0F172A)
-                                              : const Color(0xFF64748B),
-                                        ),
-                                        const SizedBox(width: 5),
-                                        Text(
-                                          'Mode PIC',
-                                          style: TextStyle(
-                                            fontFamily: 'Plus Jakarta Sans',
-                                            fontSize: 11.5,
-                                            fontWeight: widget.adminMode == AdminAppMode.pic
-                                                ? FontWeight.w700
-                                                : FontWeight.w500,
-                                            color: widget.adminMode == AdminAppMode.pic
-                                                ? const Color(0xFF0F172A)
-                                                : const Color(0xFF64748B),
-                                          ),
-                                        ),
-                                      ],
-                                    ),
-                                  ),
-                                ),
-                              ),
-                              Expanded(
-                                child: PressableScale(
-                                  onTap: () {
-                                    Navigator.of(sheetContext).pop();
-                                    widget.onSwitchAdminMode!(AdminAppMode.service);
-                                  },
-                                  child: Container(
-                                    decoration: BoxDecoration(
-                                      color: widget.adminMode == AdminAppMode.service
-                                          ? Colors.white
-                                          : Colors.transparent,
-                                      borderRadius: BorderRadius.circular(8),
-                                      boxShadow: widget.adminMode == AdminAppMode.service
-                                          ? const [
-                                              BoxShadow(
-                                                color: Color(0x10000000),
-                                                blurRadius: 4,
-                                                offset: Offset(0, 1),
-                                              ),
-                                            ]
-                                          : null,
-                                    ),
-                                    alignment: Alignment.center,
-                                    child: Row(
-                                      mainAxisAlignment: MainAxisAlignment.center,
-                                      children: [
-                                        Icon(
-                                          Icons.build_rounded,
-                                          size: 14,
-                                          color: widget.adminMode == AdminAppMode.service
-                                              ? const Color(0xFF0F172A)
-                                              : const Color(0xFF64748B),
-                                        ),
-                                        const SizedBox(width: 5),
-                                        Text(
-                                          'Mode Servis',
-                                          style: TextStyle(
-                                            fontFamily: 'Plus Jakarta Sans',
-                                            fontSize: 11.5,
-                                            fontWeight: widget.adminMode == AdminAppMode.service
-                                                ? FontWeight.w700
-                                                : FontWeight.w500,
-                                            color: widget.adminMode == AdminAppMode.service
-                                                ? const Color(0xFF0F172A)
-                                                : const Color(0xFF64748B),
-                                          ),
-                                        ),
-                                      ],
-                                    ),
-                                  ),
-                                ),
-                              ),
-                            ],
-                          ),
-                        ),
-                      ],
-                    ),
-                  ),
-                ],
-                const SizedBox(height: 18),
-
-                // Logout Button
-                PressableScale(
-                  onTap: () => _confirmLogout(context, sheetContext),
-                  child: Container(
-                    width: double.infinity,
-                    height: 48,
-                    decoration: BoxDecoration(
-                      color: const Color(0xFFFEF2F2),
-                      borderRadius: BorderRadius.circular(14),
-                      border: Border.all(color: const Color(0xFFFECACA)),
-                    ),
-                    child: const Row(
-                      mainAxisAlignment: MainAxisAlignment.center,
-                      children: [
-                        Icon(Icons.logout_rounded,
-                            color: Color(0xFFDC2626), size: 18),
-                        SizedBox(width: 8),
-                        Text(
-                          'Keluar dari Akun',
-                          style: TextStyle(
-                            fontFamily: 'Plus Jakarta Sans',
-                            fontSize: 14,
-                            fontWeight: FontWeight.w700,
-                            color: Color(0xFFDC2626),
-                          ),
-                        ),
-                      ],
-                    ),
-                  ),
-                ),
-              ],
-            ),
-          ),
-        );
-      },
+  Future<List<OrderanSewa>> _loadOrders({bool forceRefresh = false}) async {
+    final orders = await widget.gateway.fetchUpcomingOrders(
+      limit: 10,
+      forceRefresh: forceRefresh,
     );
+    return orders.where((order) => order.isUpcoming).toList();
   }
 
-  void _confirmLogout(BuildContext screenContext, BuildContext sheetContext) {
-    showDialog<void>(
-      context: screenContext,
-      builder: (dialogCtx) => AlertDialog(
-        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
-        title: const Text(
-          'Konfirmasi Keluar',
-          style: TextStyle(
-            fontFamily: 'Plus Jakarta Sans',
-            fontWeight: FontWeight.w800,
-            fontSize: 18,
-          ),
-        ),
-        content: const Text(
-          'Apakah Anda yakin ingin keluar dari akun MGRS?',
-          style: TextStyle(
-            fontFamily: 'Plus Jakarta Sans',
-            fontSize: 14,
-            color: Color(0xFF475569),
-          ),
-        ),
-        actionsPadding:
-            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
-        actions: [
-          TextButton(
-            onPressed: () => Navigator.of(dialogCtx).pop(),
-            child: const Text(
-              'Batal',
-              style: TextStyle(
-                fontFamily: 'Plus Jakarta Sans',
-                fontWeight: FontWeight.w600,
-                color: Color(0xFF64748B),
-              ),
-            ),
-          ),
-          FilledButton(
-            onPressed: () async {
-              Navigator.of(dialogCtx).pop();
-              Navigator.of(sheetContext).pop();
-              await widget.gateway.signOut();
-            },
-            style: FilledButton.styleFrom(
-              backgroundColor: const Color(0xFFDC2626),
-              shape: RoundedRectangleBorder(
-                  borderRadius: BorderRadius.circular(10)),
-            ),
-            child: const Text(
-              'Ya, Keluar',
-              style: TextStyle(
-                fontFamily: 'Plus Jakarta Sans',
-                fontWeight: FontWeight.w700,
-              ),
-            ),
-          ),
-        ],
-      ),
-    );
+  void _retry() {
+    setState(() {
+      _orders = _loadOrders(forceRefresh: true);
+    });
   }
 
-  @override
-  Widget build(BuildContext context) {
-    return Scaffold(
-      backgroundColor: const Color(0xFFFBFBFB),
-      body: SafeArea(
-        child: RefreshIndicator(
-          onRefresh: () => _loadData(forceRefresh: true),
-          child: CustomScrollView(
-            physics: const AlwaysScrollableScrollPhysics(),
-            slivers: [
-              SliverToBoxAdapter(
-                child: Padding(
-                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 12),
-                  child: _buildUserHeader(context),
-                ),
-              ),
-              if (_isLoading)
-                const SliverFillRemaining(
-                  child: Center(
-                    child: CircularProgressIndicator(color: Color(0xFF147CC1)),
-                  ),
-                )
-              else if (_error != null)
-                SliverFillRemaining(
-                  child: Center(
-                    child: Padding(
-                      padding: const EdgeInsets.all(24),
-                      child: Column(
-                        mainAxisSize: MainAxisSize.min,
-                        children: [
-                          const Icon(Icons.error_outline_rounded,
-                              size: 48, color: Color(0xFFDC2626)),
-                          const SizedBox(height: 12),
-                          Text(
-                            _error!,
-                            textAlign: TextAlign.center,
-                            style: const TextStyle(
-                              fontFamily: 'Plus Jakarta Sans',
-                              fontSize: 14,
-                              color: Color(0xFF64748B),
-                            ),
-                          ),
-                          const SizedBox(height: 16),
-                          FilledButton(
-                            onPressed: () => _loadData(forceRefresh: true),
-                            style: FilledButton.styleFrom(
-                              backgroundColor: const Color(0xFF147CC1),
-                            ),
-                            child: const Text('Coba Lagi'),
-                          ),
-                        ],
-                      ),
-                    ),
-                  ),
-                )
-              else ...[
-                SliverToBoxAdapter(
-                  child: Padding(
-                    padding: const EdgeInsets.symmetric(horizontal: 20),
-                    child: Column(
-                      crossAxisAlignment: CrossAxisAlignment.start,
-                      children: [
-                        _buildCreateOrderBento(context),
-                        const SizedBox(height: 20),
-                        _buildSummaryStatusSection(context),
-                        const SizedBox(height: 24),
-                        _buildUpcomingOrdersHeader(context),
-                        const SizedBox(height: 12),
-                      ],
-                    ),
-                  ),
-                ),
-                _buildUpcomingOrdersList(context),
-                const SliverToBoxAdapter(
-                  child: SizedBox(height: 110), // Spacing for floating navbar
-                ),
-              ],
-            ],
-          ),
-        ),
-      ),
-    );
+  String _orderDate(BuildContext context, DateTime date) {
+    return MaterialLocalizations.of(context).formatMediumDate(date.toLocal());
   }
 
-  // 1. User Header: Avatar initials + "Selamat Pagi! Name" + Bell Icon (matching HomeScreen)
-  Widget _buildUserHeader(BuildContext context) {
-    return Row(
-      mainAxisAlignment: MainAxisAlignment.spaceBetween,
+  Widget _orderList(BuildContext context, List<OrderanSewa> orders) {
+    return Column(
       children: [
-        Expanded(
-          child: PressableScale(
-            onTap: () => _showUserProfileBottomSheet(context),
-            child: Row(
-              children: [
-                Container(
-                  width: 44,
-                  height: 44,
-                  decoration: const BoxDecoration(
-                    color: Color(0xFFE2E8F0),
-                    shape: BoxShape.circle,
-                  ),
-                  child: Center(
-                    child: Text(
-                      widget.user.initials,
-                      style: const TextStyle(
-                        fontFamily: 'Plus Jakarta Sans',
-                        fontSize: 15,
-                        fontWeight: FontWeight.w700,
-                        color: Color(0xFF334155),
-                      ),
-                    ),
-                  ),
-                ),
-                const SizedBox(width: 12),
-                Expanded(
-                  child: Column(
-                    crossAxisAlignment: CrossAxisAlignment.start,
-                    children: [
-                      Row(
-                        children: [
-                          Text(
-                            _getGreeting(),
-                            style: const TextStyle(
-                              fontFamily: 'Plus Jakarta Sans',
-                              fontSize: 13,
-                              fontWeight: FontWeight.w500,
-                              color: Color(0xFF64748B),
-                            ),
-                          ),
-                          const SizedBox(width: 4),
-                          const Icon(
-                            Icons.keyboard_arrow_down_rounded,
-                            size: 16,
-                            color: Color(0xFF94A3B8),
-                          ),
-                        ],
-                      ),
-                      const SizedBox(height: 2),
-                      Text(
-                        widget.user.displayName,
-                        maxLines: 1,
-                        overflow: TextOverflow.ellipsis,
-                        style: const TextStyle(
-                          fontFamily: 'Plus Jakarta Sans',
-                          fontSize: 17,
-                          fontWeight: FontWeight.w700,
-                          color: Color(0xFF0F172A),
-                          letterSpacing: -0.3,
-                        ),
-                      ),
-                    ],
-                  ),
-                ),
-              ],
-            ),
-          ),
-        ),
-        const SizedBox(width: 12),
-        PressableScale(
-          onTap: () {},
-          child: Container(
-            width: 40,
-            height: 40,
-            decoration: BoxDecoration(
-              color: const Color(0xFFF1F5F9),
-              shape: BoxShape.circle,
-              border: Border.all(color: const Color(0xFFE2E8F0)),
-            ),
-            child: const Center(
-              child: Icon(
-                Icons.notifications_none_rounded,
-                color: Color(0xFF334155),
-                size: 20,
-              ),
-            ),
-          ),
-        ),
-      ],
-    );
-  }
-
-  // 2. Bento Hero Card: Total orderan bulan ini dengan Progress Ring (identik dengan HomeScreen)
-  Widget _buildCreateOrderBento(BuildContext context) {
-    return Container(
-      decoration: BoxDecoration(
-        color: const Color(0xFFCEF284),
-        borderRadius: BorderRadius.circular(18),
-        border: Border.all(color: const Color(0xFFBCE66E), width: 1.2),
-      ),
-      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
-      child: Row(
-        mainAxisAlignment: MainAxisAlignment.spaceBetween,
-        children: [
-          Expanded(
-            child: Column(
+        for (var index = 0; index < orders.length; index++) ...[
+          ListTile(
+            contentPadding: EdgeInsets.zero,
+            title: Text(orders[index].namaEvent),
+            subtitle: Column(
               crossAxisAlignment: CrossAxisAlignment.start,
               children: [
-                Container(
-                  padding:
-                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
-                  decoration: BoxDecoration(
-                    color: Colors.white,
-                    borderRadius: BorderRadius.circular(20),
-                  ),
-                  child: Row(
-                    mainAxisSize: MainAxisSize.min,
-                    children: [
-                      const Icon(Icons.auto_awesome,
-                          size: 12, color: Color(0xFF22380E)),
-                      const SizedBox(width: 5),
-                      Text(
-                        _formatMonthName(DateTime.now()),
-                        style: const TextStyle(
-                          fontFamily: 'Inter',
-                          fontSize: 11,
-                          fontWeight: FontWeight.w600,
-                          color: Color(0xFF22380E),
-                        ),
-                      ),
-                    ],
-                  ),
-                ),
-                const SizedBox(height: 10),
-                const Text(
-                  'Total Orderan\nBulan Ini',
-                  style: TextStyle(
-                    fontFamily: 'Inter',
-                    fontSize: 19,
-                    fontWeight: FontWeight.w800,
-                    color: Color(0xFF1A330E),
-                    height: 1.25,
-                    letterSpacing: -0.4,
-                  ),
-                ),
-              ],
-            ),
-          ),
-          // Circular Progress Ring Widget identik dengan HomeScreen
-          SizedBox(
-            width: 86,
-            height: 86,
-            child: Stack(
-              alignment: Alignment.center,
-              children: [
-                CustomPaint(
-                  size: const Size(86, 86),
-                  painter: _CircularProgressRingPainter(),
-                ),
-                Column(
-                  mainAxisAlignment: MainAxisAlignment.center,
-                  children: [
-                    Text(
-                      '$_thisMonthOrdersCount',
-                      style: const TextStyle(
-                        fontFamily: 'Inter',
-                        fontSize: 22,
-                        fontWeight: FontWeight.w800,
-                        color: Color(0xFF1B350F),
-                        height: 1.0,
-                      ),
-                    ),
-                    const SizedBox(height: 2),
-                    const Text(
-                      'Orderan',
-                      style: TextStyle(
-                        fontFamily: 'Inter',
-                        fontSize: 9,
-                        fontWeight: FontWeight.w700,
-                        color: Color(0xFF527032),
-                      ),
-                    ),
-                  ],
-                ),
+                if (orders[index].namaClient case final client?
+                    when client.trim().isNotEmpty)
+                  Text(client.trim()),
+                if (orders[index].tanggalPemasangan case final date?)
+                  Text(_orderDate(context, date)),
+                if (orders[index].statusOrderan case final status?
+                    when status.trim().isNotEmpty)
+                  Text(status.trim()),
               ],
             ),
+            trailing: const Icon(Icons.chevron_right),
+            onTap: widget.onOpenOrdersTab,
           ),
+          if (index != orders.length - 1) const Divider(height: 1),
         ],
-      ),
-    );
-  }
-
-  // 3. Status Section: 3 Ringkasan Order (Total Order, Akan Datang, Selesai)
-  Widget _buildSummaryStatusSection(BuildContext context) {
-    return Column(
-      crossAxisAlignment: CrossAxisAlignment.start,
-      children: [
-        Row(
-          mainAxisAlignment: MainAxisAlignment.spaceBetween,
-          children: [
-            Expanded(
-              child: Column(
-                crossAxisAlignment: CrossAxisAlignment.start,
-                children: [
-                  const Text(
-                    'Ringkasan Orderan',
-                    style: TextStyle(
-                      fontFamily: 'Plus Jakarta Sans',
-                      fontSize: 16,
-                      fontWeight: FontWeight.w700,
-                      color: Color(0xFF0F172A),
-                      letterSpacing: -0.3,
-                    ),
-                  ),
-                  const SizedBox(height: 2),
-                  Text(
-                    _totalOrdersCount == 0 && !_isLoading
-                        ? 'Belum ada data orderan'
-                        : 'Total $_totalOrdersCount orderan tercatat di sistem',
-                    maxLines: 1,
-                    overflow: TextOverflow.ellipsis,
-                    style: const TextStyle(
-                      fontFamily: 'Plus Jakarta Sans',
-                      fontSize: 11,
-                      fontWeight: FontWeight.w500,
-                      color: Color(0xFF64748B),
-                    ),
-                  ),
-                ],
-              ),
-            ),
-            const SizedBox(width: 8),
-            Container(
-              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
-              decoration: BoxDecoration(
-                color: const Color(0xFFF1F5F9),
-                borderRadius: BorderRadius.circular(20),
-              ),
-              child: const Row(
-                mainAxisSize: MainAxisSize.min,
-                children: [
-                  CircleAvatar(radius: 3, backgroundColor: Color(0xFF10B981)),
-                  SizedBox(width: 5),
-                  Text(
-                    'Data Terkini',
-                    style: TextStyle(
-                      fontFamily: 'Plus Jakarta Sans',
-                      fontSize: 10,
-                      fontWeight: FontWeight.w600,
-                      color: Color(0xFF334155),
-                    ),
-                  ),
-                ],
-              ),
-            ),
-          ],
-        ),
-        const SizedBox(height: 12),
-        // 3 Vibrant Solid Status Cards: Total Order, Akan Datang, Selesai (style identik HomeScreen)
-        Row(
-          children: [
-            // Card 1: Total Order (Blue Solid)
-            Expanded(
-              child: _buildGradientStatusCard(
-                icon: Icons.assignment_outlined,
-                percentage: '100%',
-                count: '$_totalOrdersCount',
-                title: 'Total Order',
-                subtitle: 'Semua riwayat',
-                solidColor: const Color(0xFF147CC1),
-                onTap: widget.onOpenOrdersTab,
-              ),
-            ),
-            const SizedBox(width: 10),
-            // Card 2: Akan Datang (Amber Solid)
-            Expanded(
-              child: _buildGradientStatusCard(
-                icon: Icons.event_available_rounded,
-                percentage: _totalOrdersCount > 0
-                    ? '${((_upcomingCount / _totalOrdersCount) * 100).round()}%'
-                    : '0%',
-                count: '$_upcomingCount',
-                title: 'Akan Datang',
-                subtitle: '$_todayOrdersCount hari ini',
-                solidColor: const Color(0xFFD97706),
-                onTap: widget.onOpenOrdersTab,
-              ),
-            ),
-            const SizedBox(width: 10),
-            // Card 3: Selesai (Emerald Solid)
-            Expanded(
-              child: _buildGradientStatusCard(
-                icon: Icons.check_circle_outline_rounded,
-                percentage: _totalOrdersCount > 0
-                    ? '${((_pastCount / _totalOrdersCount) * 100).round()}%'
-                    : '0%',
-                count: '$_pastCount',
-                title: 'Selesai',
-                subtitle: 'Event beres',
-                solidColor: const Color(0xFF059669),
-                onTap: widget.onOpenOrdersTab,
-              ),
-            ),
-          ],
-        ),
       ],
     );
   }
 
-  Widget _buildGradientStatusCard({
-    required IconData icon,
-    required String percentage,
-    required String count,
-    required String title,
-    required String subtitle,
-    required Color solidColor,
-    required VoidCallback onTap,
-  }) {
-    return PressableScale(
-      onTap: onTap,
-      child: Container(
-        height: 120,
-        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 11),
-        decoration: BoxDecoration(
-          color: solidColor,
-          borderRadius: BorderRadius.circular(16),
-          boxShadow: [
-            BoxShadow(
-              color: solidColor.withValues(alpha: 0.28),
-              blurRadius: 10,
-              offset: const Offset(0, 4),
-            ),
-          ],
-        ),
-        child: Column(
-          crossAxisAlignment: CrossAxisAlignment.start,
-          mainAxisAlignment: MainAxisAlignment.spaceBetween,
-          children: [
-            Row(
-              mainAxisAlignment: MainAxisAlignment.spaceBetween,
-              children: [
-                Container(
-                  width: 28,
-                  height: 28,
-                  decoration: BoxDecoration(
-                    color: Colors.white.withValues(alpha: 0.22),
-                    borderRadius: BorderRadius.circular(8),
-                  ),
-                  child: Icon(icon, color: Colors.white, size: 15),
-                ),
-                Container(
-                  padding:
-                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
-                  decoration: BoxDecoration(
-                    color: Colors.white.withValues(alpha: 0.24),
-                    borderRadius: BorderRadius.circular(12),
-                  ),
-                  child: Text(
-                    percentage,
-                    style: const TextStyle(
-                      fontFamily: 'Inter',
-                      fontSize: 10,
-                      fontWeight: FontWeight.w700,
-                      color: Colors.white,
-                    ),
-                  ),
-                ),
-              ],
-            ),
-            Column(
-              crossAxisAlignment: CrossAxisAlignment.start,
-              children: [
-                Text(
-                  count,
-                  style: const TextStyle(
-                    fontFamily: 'Inter',
-                    fontSize: 22,
-                    fontWeight: FontWeight.w800,
-                    color: Colors.white,
-                    height: 1.1,
-                  ),
-                ),
-                const SizedBox(height: 3),
-                Text(
-                  title,
-                  maxLines: 1,
-                  overflow: TextOverflow.ellipsis,
-                  style: const TextStyle(
-                    fontFamily: 'Plus Jakarta Sans',
-                    fontSize: 11.5,
-                    fontWeight: FontWeight.w700,
-                    color: Colors.white,
-                  ),
-                ),
-                const SizedBox(height: 1),
-                Text(
-                  subtitle,
-                  maxLines: 1,
-                  overflow: TextOverflow.ellipsis,
-                  style: TextStyle(
-                    fontFamily: 'Plus Jakarta Sans',
-                    fontSize: 9.5,
-                    fontWeight: FontWeight.w500,
-                    color: Colors.white.withValues(alpha: 0.85),
-                  ),
-                ),
-              ],
-            ),
-          ],
-        ),
-      ),
-    );
-  }
-
-  // 4. Orderan Mendatang Header (matching HomeScreen)
-  Widget _buildUpcomingOrdersHeader(BuildContext context) {
-    return Row(
-      mainAxisAlignment: MainAxisAlignment.spaceBetween,
-      children: [
-        Expanded(
-          child: Row(
+  Widget _ordersState(BuildContext context) {
+    return FutureBuilder<List<OrderanSewa>>(
+      future: _orders,
+      builder: (context, snapshot) {
+        if (snapshot.connectionState != ConnectionState.done) {
+          return const Padding(
+            padding: EdgeInsets.symmetric(vertical: 32),
+            child: Center(child: CircularProgressIndicator()),
+          );
+        }
+        if (snapshot.hasError) {
+          return Column(
+            crossAxisAlignment: CrossAxisAlignment.stretch,
             children: [
-              const Flexible(
-                child: Text(
-                  'Orderan Mendatang',
-                  maxLines: 1,
-                  overflow: TextOverflow.ellipsis,
-                  style: TextStyle(
-                    fontFamily: 'Inter',
-                    fontSize: 16,
-                    fontWeight: FontWeight.w700,
-                    color: Color(0xFF0F172A),
-                    letterSpacing: -0.3,
-                  ),
-                ),
-              ),
-              const SizedBox(width: 8),
-              Container(
-                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
-                decoration: BoxDecoration(
-                  color: const Color(0xFFF1F5F9),
-                  borderRadius: BorderRadius.circular(20),
-                ),
-                child: Text(
-                  '$_upcomingCount',
-                  style: const TextStyle(
-                    fontFamily: 'Inter',
-                    fontSize: 11,
-                    fontWeight: FontWeight.w700,
-                    color: Color(0xFF475569),
-                  ),
-                ),
+              Text(failureMessage(snapshot.error)),
+              const SizedBox(height: 12),
+              OutlinedButton(
+                onPressed: _retry,
+                child: const Text('Coba lagi'),
               ),
             ],
-          ),
-        ),
-        const SizedBox(width: 8),
-        GestureDetector(
-          onTap: widget.onOpenOrdersTab,
-          child: const Text(
-            'Lihat Semua',
-            style: TextStyle(
-              fontFamily: 'Inter',
-              fontSize: 12,
-              fontWeight: FontWeight.w600,
-              color: Color(0xFF2563EB),
-            ),
-          ),
-        ),
-      ],
-    );
-  }
-
-  // 5. Order Cards List (matching HomeScreen._buildOrderCard)
-  Widget _buildUpcomingOrdersList(BuildContext context) {
-    final list = _upcomingOrders;
-    if (list.isEmpty) {
-      return SliverToBoxAdapter(
-        child: Padding(
-          padding: const EdgeInsets.symmetric(horizontal: 20),
-          child: Container(
-            width: double.infinity,
-            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
-            decoration: BoxDecoration(
-              color: const Color(0xFFF8FAFC),
-              borderRadius: BorderRadius.circular(18),
-              border: Border.all(color: const Color(0xFFE2E8F0)),
-            ),
-            child: const Column(
-              children: [
-                Icon(Icons.event_available_rounded,
-                    size: 32, color: Color(0xFF94A3B8)),
-                SizedBox(height: 8),
-                Text(
-                  'Tidak ada orderan mendatang saat ini',
-                  style: TextStyle(
-                    fontFamily: 'Plus Jakarta Sans',
-                    fontSize: 13,
-                    fontWeight: FontWeight.w700,
-                    color: Color(0xFF334155),
-                  ),
-                ),
-                SizedBox(height: 2),
-                Text(
-                  'Jadwal pemasangan diperbarui otomatis saat ada orderan baru.',
-                  textAlign: TextAlign.center,
-                  style: TextStyle(
-                    fontFamily: 'Plus Jakarta Sans',
-                    fontSize: 11,
-                    color: Color(0xFF64748B),
-                  ),
-                ),
-              ],
-            ),
-          ),
-        ),
-      );
-    }
-
-    final displayList = list.take(4).toList();
-
-    return SliverPadding(
-      padding: const EdgeInsets.symmetric(horizontal: 20),
-      sliver: SliverList(
-        delegate: SliverChildBuilderDelegate(
-          (context, index) {
-            final order = displayList[index];
-            return Padding(
-              padding: const EdgeInsets.only(bottom: 10),
-              child: _buildOrderCard(context, order),
-            );
-          },
-          childCount: displayList.length,
-        ),
-      ),
+          );
+        }
+        final orders = snapshot.data ?? const <OrderanSewa>[];
+        if (orders.isEmpty) {
+          return const Text('Belum ada orderan yang perlu ditindaklanjuti.');
+        }
+        return _orderList(context, orders);
+      },
     );
   }
 
-  Widget _buildOrderCard(BuildContext context, OrderanSewa order) {
-    final hasMaps =
-        order.linkGmaps != null && order.linkGmaps!.trim().isNotEmpty;
-    final hasWa = order.cleanWhatsapp.isNotEmpty;
-
-    final isPast = order.isPast;
-    final String statusText;
-    final Color statusBg;
-    final Color statusBorder;
-    final Color statusColor;
-    final Color dotColor;
-
-    if (order.isCancelled) {
-      statusText = 'Dibatalkan';
-      statusBg = const Color(0xFFFEF2F2);
-      statusBorder = const Color(0xFFFECACA);
-      statusColor = const Color(0xFFDC2626);
-      dotColor = const Color(0xFFEF4444);
-    } else if (isPast) {
-      statusText = order.isCompletedOrCancelled
-          ? (order.statusOrderan ?? 'Selesai')
-          : 'Selesai / Lewat';
-      statusBg = const Color(0xFFF1F5F9);
-      statusBorder = const Color(0xFFCBD5E1);
-      statusColor = const Color(0xFF475569);
-      dotColor = const Color(0xFF94A3B8);
-    } else {
-      statusText =
-          (order.statusOrderan != null && order.statusOrderan!.isNotEmpty)
-              ? order.statusOrderan!
-              : 'Terjadwal';
-      statusBg = const Color(0xFFECFDF5);
-      statusBorder = const Color(0xFFA7F3D0);
-      statusColor = const Color(0xFF059669);
-      dotColor = const Color(0xFF10B981);
-    }
-
-    return PressableScale(
-      onTap: () {
-        Navigator.of(context).push<void>(
-          MaterialPageRoute(
-            builder: (_) => OrderDetailScreen(
-              order: order,
-              gateway: widget.gateway,
-              user: widget.user,
-            ),
-          ),
-        );
-      },
-      child: Container(
-        padding: const EdgeInsets.all(16),
-        decoration: BoxDecoration(
-          color: Colors.white,
-          borderRadius: BorderRadius.circular(18),
-          border: Border.all(color: const Color(0xFFE2E8F0)),
-          boxShadow: const [
-            BoxShadow(
-              color: Color(0x0A0F172A),
-              blurRadius: 8,
-              offset: Offset(0, 2),
-            ),
-          ],
-        ),
-        child: Column(
-          crossAxisAlignment: CrossAxisAlignment.start,
+  @override
+  Widget build(BuildContext context) {
+    final textTheme = Theme.of(context).textTheme;
+    return PageBody(
+      children: [
+        Text('Beranda PIC MGRS', style: textTheme.headlineSmall),
+        const SizedBox(height: 8),
+        Text(widget.user.displayName, style: textTheme.bodyLarge),
+        const SizedBox(height: 24),
+        Row(
           children: [
-            // 1. Header: [ ● ORD-XXX • 10 Unit (1 Hari) ]  ...  [ Terjadwal ]
-            Row(
-              mainAxisAlignment: MainAxisAlignment.spaceBetween,
-              children: [
-                Flexible(
-                  child: Row(
-                    mainAxisSize: MainAxisSize.min,
-                    children: [
-                      Container(
-                        width: 7,
-                        height: 7,
-                        decoration: BoxDecoration(
-                          color: dotColor,
-                          borderRadius: BorderRadius.circular(2),
-                        ),
-                      ),
-                      const SizedBox(width: 6),
-                      Flexible(
-                        child: Text(
-                          order.displayCode,
-                          maxLines: 1,
-                          overflow: TextOverflow.ellipsis,
-                          style: const TextStyle(
-                            fontFamily: 'Plus Jakarta Sans',
-                            fontSize: 12,
-                            fontWeight: FontWeight.w700,
-                            color: Color(0xFF0F172A),
-                          ),
-                        ),
-                      ),
-                      const SizedBox(width: 4),
-                      const Text(
-                        '• ',
-                        style: TextStyle(
-                          fontFamily: 'Plus Jakarta Sans',
-                          fontSize: 11,
-                          color: Color(0xFF94A3B8),
-                        ),
-                      ),
-                      Text(
-                        '${order.jumlahUnit} Unit',
-                        style: const TextStyle(
-                          fontFamily: 'Plus Jakarta Sans',
-                          fontSize: 11,
-                          fontWeight: FontWeight.w600,
-                          color: Color(0xFF475569),
-                        ),
-                      ),
-                      Text(
-                        ' (${order.durasiSewaText})',
-                        style: const TextStyle(
-                          fontFamily: 'Plus Jakarta Sans',
-                          fontSize: 11,
-                          fontWeight: FontWeight.w500,
-                          color: Color(0xFF64748B),
-                        ),
-                      ),
-                    ],
-                  ),
-                ),
-                const SizedBox(width: 8),
-                Container(
-                  padding:
-                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
-                  decoration: BoxDecoration(
-                    color: statusBg,
-                    borderRadius: BorderRadius.circular(8),
-                    border: Border.all(color: statusBorder),
-                  ),
-                  child: Text(
-                    statusText,
-                    style: TextStyle(
-                      fontFamily: 'Plus Jakarta Sans',
-                      fontSize: 10.5,
-                      fontWeight: FontWeight.w700,
-                      color: statusColor,
-                    ),
-                  ),
-                ),
-              ],
-            ),
-            const SizedBox(height: 10),
-
-            // 2. Body: Nama Event (Bold)
-            Text(
-              order.namaEvent,
-              style: const TextStyle(
-                fontFamily: 'Plus Jakarta Sans',
-                fontSize: 15,
-                fontWeight: FontWeight.w800,
-                color: Color(0xFF0F172A),
-                letterSpacing: -0.2,
+            Expanded(
+              child: FilledButton.icon(
+                onPressed: widget.onOpenOrdersTab,
+                icon: const Icon(Icons.event_note_outlined),
+                label: const Text('Buka orderan'),
               ),
             ),
-
-            // Detail Klien jika ada
-            if (order.namaClient != null && order.namaClient!.isNotEmpty) ...[
-              const SizedBox(height: 3),
-              Text(
-                'Klien: ${order.namaClient}${order.nomorWhatsapp != null && order.nomorWhatsapp!.isNotEmpty ? ' • ${order.nomorWhatsapp}' : ''}',
-                maxLines: 1,
-                overflow: TextOverflow.ellipsis,
-                style: const TextStyle(
-                  fontFamily: 'Plus Jakarta Sans',
-                  fontSize: 11.5,
-                  fontWeight: FontWeight.w500,
-                  color: Color(0xFF64748B),
-                ),
-              ),
-            ],
-
-            // Alamat Venue
-            if (order.alamat != null && order.alamat!.isNotEmpty) ...[
-              const SizedBox(height: 4),
-              Row(
-                crossAxisAlignment: CrossAxisAlignment.start,
-                children: [
-                  const Icon(Icons.location_on_outlined,
-                      size: 14, color: Color(0xFF64748B)),
-                  const SizedBox(width: 4),
-                  Expanded(
-                    child: Text(
-                      order.alamat!,
-                      maxLines: 2,
-                      overflow: TextOverflow.ellipsis,
-                      style: const TextStyle(
-                        fontFamily: 'Plus Jakarta Sans',
-                        fontSize: 11.5,
-                        color: Color(0xFF64748B),
-                        height: 1.35,
-                      ),
-                    ),
-                  ),
-                ],
-              ),
-            ],
-
-            const SizedBox(height: 10),
-
-            // 3. Footer: [ Kamis, 10 Sep 2026 ]  ...  [ Maps ] [ WA ]
-            Container(
-              padding: const EdgeInsets.only(top: 8),
-              decoration: const BoxDecoration(
-                border: Border(
-                  top: BorderSide(color: Color(0xFFF1F5F9)),
-                ),
-              ),
-              child: Row(
-                mainAxisAlignment: MainAxisAlignment.spaceBetween,
-                children: [
-                  Expanded(
-                    child: Row(
-                      mainAxisSize: MainAxisSize.min,
-                      children: [
-                        const Icon(
-                          Icons.calendar_today_rounded,
-                          size: 12,
-                          color: Color(0xFF64748B),
-                        ),
-                        const SizedBox(width: 6),
-                        Expanded(
-                          child: Text(
-                            order.dayDateYear,
-                            maxLines: 1,
-                            overflow: TextOverflow.ellipsis,
-                            style: const TextStyle(
-                              fontFamily: 'Plus Jakarta Sans',
-                              fontSize: 11.5,
-                              fontWeight: FontWeight.w600,
-                              color: Color(0xFF475569),
-                            ),
-                          ),
-                        ),
-                      ],
-                    ),
-                  ),
-                  const SizedBox(width: 8),
-                  Row(
-                    mainAxisSize: MainAxisSize.min,
-                    children: [
-                      if (hasMaps)
-                        PressableScale(
-                          onTap: () => order.launchMaps(),
-                          child: Container(
-                            padding: const EdgeInsets.symmetric(
-                                horizontal: 9, vertical: 4),
-                            decoration: BoxDecoration(
-                              color: const Color(0xFFEFF6FF),
-                              borderRadius: BorderRadius.circular(8),
-                              border:
-                                  Border.all(color: const Color(0xFFBFDBFE)),
-                            ),
-                            child: const Row(
-                              children: [
-                                Icon(Icons.near_me_rounded,
-                                    size: 12, color: Color(0xFF2563EB)),
-                                SizedBox(width: 4),
-                                Text(
-                                  'Maps',
-                                  style: TextStyle(
-                                    fontFamily: 'Plus Jakarta Sans',
-                                    fontSize: 10.5,
-                                    fontWeight: FontWeight.w700,
-                                    color: Color(0xFF2563EB),
-                                  ),
-                                ),
-                              ],
-                            ),
-                          ),
-                        ),
-                      if (hasMaps && hasWa) const SizedBox(width: 6),
-                      if (hasWa)
-                        PressableScale(
-                          onTap: () => order.launchWhatsApp(),
-                          child: Container(
-                            padding: const EdgeInsets.symmetric(
-                                horizontal: 9, vertical: 4),
-                            decoration: BoxDecoration(
-                              color: const Color(0xFFF0FDF4),
-                              borderRadius: BorderRadius.circular(8),
-                              border:
-                                  Border.all(color: const Color(0xFFBBF7D0)),
-                            ),
-                            child: const Row(
-                              children: [
-                                Icon(Icons.chat_rounded,
-                                    size: 12, color: Color(0xFF16A34A)),
-                                SizedBox(width: 4),
-                                Text(
-                                  'WA',
-                                  style: TextStyle(
-                                    fontFamily: 'Plus Jakarta Sans',
-                                    fontSize: 10.5,
-                                    fontWeight: FontWeight.w700,
-                                    color: Color(0xFF16A34A),
-                                  ),
-                                ),
-                              ],
-                            ),
-                          ),
-                        ),
-                      if (!hasMaps && !hasWa)
-                        const Icon(Icons.chevron_right_rounded,
-                            size: 18, color: Color(0xFF94A3B8)),
-                    ],
-                  ),
-                ],
+            const SizedBox(width: 12),
+            Expanded(
+              child: OutlinedButton.icon(
+                onPressed: widget.onOpenInvoicesTab,
+                icon: const Icon(Icons.receipt_long_outlined),
+                label: const Text('Buka invoice'),
               ),
             ),
           ],
         ),
-      ),
-    );
-  }
-}
-
-class _CircularProgressRingPainter extends CustomPainter {
-  @override
-  void paint(Canvas canvas, Size size) {
-    final center = Offset(size.width / 2, size.height / 2);
-
-    // Background track ring
-    final trackPaint = Paint()
-      ..color = Colors.white
-      ..style = PaintingStyle.stroke
-      ..strokeWidth = 10;
-    canvas.drawCircle(center, 35, trackPaint);
-
-    // Inner filled circle with opacity
-    final innerPaint = Paint()
-      ..color = Colors.white.withValues(alpha: 0.45)
-      ..style = PaintingStyle.fill;
-    canvas.drawCircle(center, 25, innerPaint);
-
-    // Inner border stroke
-    final innerStroke = Paint()
-      ..color = const Color(0xFFCEF284)
-      ..style = PaintingStyle.stroke
-      ..strokeWidth = 3;
-    canvas.drawCircle(center, 25, innerStroke);
-
-    // Progress Arc #78C423
-    final progressPaint = Paint()
-      ..color = const Color(0xFF78C423)
-      ..style = PaintingStyle.stroke
-      ..strokeWidth = 10
-      ..strokeCap = StrokeCap.round;
-
-    // Draw arc ~ 270 degrees
-    canvas.drawArc(
-      Rect.fromCircle(center: center, radius: 35),
-      -math.pi / 2,
-      math.pi * 1.5,
-      false,
-      progressPaint,
+        const SizedBox(height: 32),
+        Text('Orderan perlu ditindaklanjuti', style: textTheme.titleLarge),
+        const SizedBox(height: 12),
+        _ordersState(context),
+      ],
     );
   }
-
-  @override
-  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
 }
diff --git a/test/admin_mode_switch_test.dart b/test/admin_mode_switch_test.dart
deleted file mode 100644
index 5569752..0000000
--- a/test/admin_mode_switch_test.dart
+++ /dev/null
@@ -1,136 +0,0 @@
-import 'package:flutter/material.dart';
-import 'package:flutter_test/flutter_test.dart';
-import 'package:mgrs_maintenance/app/app.dart';
-import 'package:mgrs_maintenance/app/gateway.dart';
-import 'package:mgrs_maintenance/features/invoices/invoice_model.dart';
-import 'package:mgrs_maintenance/features/schedule/order_model.dart';
-
-class MockAdminGateway extends MaintenanceGateway {
-  @override
-  Stream<void> get authChanges => const Stream.empty();
-
-  @override
-  Future<UserProfile?> profile() async =>
-      const UserProfile('admin-1', 'Admin', fullName: 'Super Administrator');
-
-  @override
-  Future<void> signIn(String identifier, String password) async {}
-
-  @override
-  Future<void> signOut() async {}
-
-  @override
-  Future<Object?> rpc(String name, Map<String, Object?> params) async => null;
-
-  @override
-  Future<List<Map<String, Object?>>> fetchComponents({
-    String? kind,
-    String? query,
-    String? condition,
-    bool forceRefresh = false,
-  }) async {
-    return [
-      {'kode_aset': 'BLW-01', 'nama_komponen': 'Blower Fan Unit 01', 'kondisi': 'OK'},
-      {'kode_aset': 'PMP-02', 'nama_komponen': 'Water Pump 02', 'kondisi': 'Service'},
-    ];
-  }
-
-  @override
-  Future<List<OrderanSewa>> fetchUpcomingOrders({
-    int limit = 10,
-    bool forceRefresh = false,
-  }) async {
-    return [
-      OrderanSewa(
-        id: 'ord-1',
-        namaEvent: 'Konser Musik Solo',
-        namaClient: 'Bpk Joko',
-        alamat: 'Stadion Manahan',
-        tanggalPemasangan: DateTime.now(),
-        statusOrderan: 'Terjadwal',
-      ),
-    ];
-  }
-
-  @override
-  Future<List<InvoiceRecord>> fetchInvoices({
-    String? orderanId,
-    InvoicePaymentStatus? status,
-    String? source,
-    bool forceRefresh = false,
-  }) async {
-    return [];
-  }
-
-  @override
-  Future<Map<String, Object?>> fetchTasksSummary({
-    String? periodId,
-    bool forceRefresh = false,
-  }) async => {'total': 2, 'completed': 1};
-
-  @override
-  Future<List<Map<String, Object?>>> fetchComponentHistory(
-    String componentId, {
-    int limit = 20,
-    bool forceRefresh = false,
-  }) async => [];
-}
-
-void main() {
-  testWidgets('Admin user can switch between Mode PIC and Mode Servis safely via profile sheet',
-      (WidgetTester tester) async {
-    final gateway = MockAdminGateway();
-    const adminUser = UserProfile(
-      'admin-1',
-      'Admin',
-      fullName: 'Super Administrator',
-      username: 'admin',
-    );
-
-    await tester.pumpWidget(
-      MaterialApp(
-        home: MaintenanceHome(
-          gateway: gateway,
-          user: adminUser,
-        ),
-      ),
-    );
-    await tester.pumpAndSettle();
-
-    // 1. Initial default state for Admin is Mode Servis (Maintenance Technician flow)
-    expect(find.text('Aset'), findsOneWidget);
-    expect(find.text('Servis'), findsOneWidget);
-
-    // 2. Tap profile avatar in header to open profile sheet
-    final avatarFinder = find.text('SA'); // Initials of Super Administrator
-    expect(avatarFinder, findsOneWidget);
-    await tester.tap(avatarFinder);
-    await tester.pumpAndSettle();
-
-    // 3. Verify Mode Tampilan (Khusus Admin) section is present in sheet
-    expect(find.text('Mode Tampilan (Khusus Admin)'), findsOneWidget);
-    expect(find.text('Mode PIC'), findsOneWidget);
-    expect(find.text('Mode Servis'), findsOneWidget);
-
-    // 4. Tap "Mode PIC" to switch to PIC order & invoice flow
-    await tester.tap(find.text('Mode PIC'));
-    await tester.pumpAndSettle();
-
-    // 5. Verify now switched to PIC Mode
-    expect(find.text('Orderan'), findsWidgets);
-    expect(find.text('Invoice'), findsWidgets);
-    expect(find.text('Total Orderan\nBulan Ini'), findsOneWidget);
-
-    // 6. Tap avatar in PIC header to switch back to Servis
-    await tester.tap(find.text('SA'));
-    await tester.pumpAndSettle();
-
-    expect(find.text('Mode Tampilan (Khusus Admin)'), findsOneWidget);
-    await tester.tap(find.text('Mode Servis'));
-    await tester.pumpAndSettle();
-
-    // 7. Verify back to Mode Servis
-    expect(find.text('Aset'), findsOneWidget);
-    expect(find.text('Servis'), findsOneWidget);
-  });
-}
diff --git a/test/home_screen_test.dart b/test/home_screen_test.dart
deleted file mode 100644
index 5473ff8..0000000
--- a/test/home_screen_test.dart
+++ /dev/null
@@ -1,258 +0,0 @@
-import 'package:flutter/material.dart';
-import 'package:flutter_test/flutter_test.dart';
-import 'package:mgrs_maintenance/app/app.dart';
-import 'package:mgrs_maintenance/app/gateway.dart';
-import 'package:mgrs_maintenance/features/home/home_screen.dart';
-import 'package:mgrs_maintenance/features/schedule/order_model.dart';
-import 'package:mgrs_maintenance/shared/bottom_nav_bar.dart';
-
-class SignedInGateway extends MaintenanceGateway {
-  @override
-  Stream<void> get authChanges => const Stream.empty();
-  @override
-  Future<UserProfile?> profile() async =>
-      const UserProfile('u-1', 'Tim Service', fullName: 'Salman Alfarras');
-  @override
-  Future<void> signIn(String identifier, String password) async {}
-  @override
-  Future<void> signOut() async {}
-  @override
-  Future<Object?> rpc(String name, Map<String, Object?> params) async => null;
-
-  @override
-  Future<List<Map<String, Object?>>> fetchComponents({
-    String? kind,
-    String? query,
-    String? condition,
-    bool forceRefresh = false,
-  }) async {
-    return List.generate(
-      24,
-      (i) => {
-        'id': 'c-$i',
-        'nomor_stiker': 'KPL-$i',
-        'jenis_komponen': 'Kepala',
-        'kondisi': i == 0 ? 'Service' : (i == 1 ? 'Rusak Berat' : 'OK'),
-      },
-    );
-  }
-
-  @override
-  Future<Map<String, Object?>> fetchTasksSummary({
-    String? periodId,
-    bool forceRefresh = false,
-  }) async {
-    return {
-      'total': 24,
-      'completed': 19,
-      'period': {
-        'opensAt': DateTime.now().add(const Duration(days: 6, hours: 1)).toIso8601String(),
-      },
-    };
-  }
-
-  @override
-  Future<List<OrderanSewa>> fetchUpcomingOrders({
-    int limit = 10,
-    bool forceRefresh = false,
-  }) async {
-    return [
-      OrderanSewa(
-        id: 'ORD-2026-088',
-        namaEvent: 'Pemasangan Panggung Event Pertamina',
-        alamat: 'JCC Senayan, Hall B - Jakarta',
-        jumlahUnit: 4,
-        namaPic: 'Dian Wulandari',
-        nomorWhatsapp: '081234567890',
-        linkGmaps: 'https://maps.google.com/?q=JCC+Senayan',
-        tanggalPemasangan: DateTime.now().add(const Duration(days: 1)),
-      ),
-      OrderanSewa(
-        id: 'ORD-2026-092',
-        namaEvent: 'Instalasi Outdoor Festival Musik',
-        alamat: 'Lapangan Brigif, Cimahi',
-        jumlahUnit: 2,
-        namaPic: 'Budi Santoso',
-        nomorWhatsapp: '089876543210',
-        tanggalPemasangan: DateTime.now().add(const Duration(days: 2)),
-      ),
-    ];
-  }
-}
-
-void main() {
-  testWidgets('HomeScreen renders exact Paper layout components', (tester) async {
-    final gateway = SignedInGateway();
-    const user = UserProfile('u-1', 'Tim Service', fullName: 'Salman Alfarras');
-
-    await tester.pumpWidget(
-      MaterialApp(
-        home: HomeScreen(
-          gateway: gateway,
-          user: user,
-          onNavigateToTab: (_) {},
-          onOpenScanner: () {},
-        ),
-      ),
-    );
-    await tester.pumpAndSettle();
-
-    expect(find.text('Selamat Pagi!'), findsOneWidget);
-    expect(find.text('Salman Alfarras'), findsOneWidget);
-    expect(find.text('Pengingat!'), findsOneWidget);
-    expect(find.text('Pengecekan Unit\nBerkala'), findsOneWidget);
-    expect(find.text('6'), findsOneWidget);
-    expect(find.text('Hari Lagi'), findsOneWidget);
-    expect(find.text('Status Unit Blower'), findsOneWidget);
-    expect(find.text('Total 24 mesin aktif dipantau'), findsOneWidget);
-    expect(find.text('Beroperasi'), findsOneWidget);
-    expect(find.text('Perlu Servis'), findsOneWidget);
-    expect(find.text('Kendala'), findsOneWidget);
-    expect(find.text('Orderan Mendatang'), findsOneWidget);
-    expect(find.text('Pemasangan Panggung Event Pertamina'), findsOneWidget);
-    expect(find.text('Instalasi Outdoor Festival Musik'), findsOneWidget);
-    expect(find.text('Beranda'), findsOneWidget);
-  });
-
-  testWidgets('MaintenanceHome contains Paper bottom bar navigation', (
-    tester,
-  ) async {
-    final gateway = SignedInGateway();
-    const user = UserProfile('u-1', 'Tim Service');
-
-    await tester.pumpWidget(
-      MaterialApp(
-        home: MaintenanceHome(gateway: gateway, user: user),
-      ),
-    );
-    await tester.pumpAndSettle();
-
-    expect(find.text('Beranda'), findsOneWidget);
-    expect(find.text('Aset'), findsOneWidget);
-    expect(find.text('Servis'), findsOneWidget);
-
-    // Tapping 'Aset' animates to page 1
-    await tester.tap(find.text('Aset'));
-    await tester.pumpAndSettle();
-    expect(find.text('Komponen MGRS'), findsOneWidget);
-
-    // Tapping 'Servis' animates to page 2
-    final servisTab = find.descendant(
-      of: find.byType(AppBottomNavBar),
-      matching: find.text('Servis'),
-    );
-    await tester.tap(servisTab);
-    await tester.pumpAndSettle();
-    expect(find.text('Pusat Tindakan'), findsOneWidget);
-
-    // Dragging / scrubbing navbar back to Beranda
-    await tester.drag(servisTab, const Offset(-200, 0));
-    await tester.pumpAndSettle();
-    expect(find.text('Beranda'), findsOneWidget);
-  });
-
-  testWidgets('HomeScreen displays dynamic user profile fullName and initials', (
-    tester,
-  ) async {
-    final gateway = SignedInGateway();
-    const user = UserProfile(
-      'u-2',
-      'Tim Service',
-      fullName: 'Budi Santoso',
-      username: 'budi_s',
-    );
-
-    await tester.pumpWidget(
-      MaterialApp(
-        home: HomeScreen(
-          gateway: gateway,
-          user: user,
-          onNavigateToTab: (_) {},
-          onOpenScanner: () {},
-        ),
-      ),
-    );
-    await tester.pumpAndSettle();
-
-    expect(find.text('Budi Santoso'), findsOneWidget);
-    expect(find.text('BS'), findsOneWidget);
-  });
-
-  testWidgets('HomeScreen renders orders with very long address without horizontal overflow', (
-    tester,
-  ) async {
-    final gateway = SignedInGateway();
-    // Simulate narrow mobile screen (360x740)
-    tester.view.physicalSize = const Size(360, 740);
-    tester.view.devicePixelRatio = 1.0;
-    addTearDown(() {
-      tester.view.resetPhysicalSize();
-      tester.view.resetDevicePixelRatio();
-    });
-
-    const user = UserProfile(
-      'u-3',
-      'Tim Service',
-      fullName: 'Muhammad Dzaki Al-Fatih Pratama Kusuma Atmaja',
-    );
-
-    await tester.pumpWidget(
-      MaterialApp(
-        home: HomeScreen(
-          gateway: gateway,
-          user: user,
-          onNavigateToTab: (_) {},
-          onOpenScanner: () {},
-        ),
-      ),
-    );
-    await tester.pumpAndSettle();
-
-    // Verify no RenderFlex overflow exception occurred
-    expect(tester.takeException(), isNull);
-    expect(find.byType(HomeScreen), findsOneWidget);
-  });
-
-  testWidgets(
-      'Tapping user header opens profile bottom sheet with logout option',
-      (tester) async {
-    final gateway = SignedInGateway();
-    const user = UserProfile(
-      'u-4',
-      'Tim Service',
-      fullName: 'Ahmad Dahlan',
-      username: 'ahmad_d',
-    );
-
-    await tester.pumpWidget(
-      MaterialApp(
-        home: HomeScreen(
-          gateway: gateway,
-          user: user,
-          onNavigateToTab: (_) {},
-          onOpenScanner: () {},
-        ),
-      ),
-    );
-    await tester.pumpAndSettle();
-
-    // Tap user header
-    await tester.tap(find.text('Ahmad Dahlan'));
-    await tester.pumpAndSettle();
-
-    // Verify bottom sheet opened
-    expect(find.text('Profil Pengguna'), findsOneWidget);
-    expect(find.text('Tim Service'), findsWidgets);
-    expect(find.text('@ahmad_d'), findsOneWidget);
-    expect(find.text('Keluar dari Akun'), findsOneWidget);
-
-    // Tap Keluar dari Akun
-    await tester.tap(find.text('Keluar dari Akun'));
-    await tester.pumpAndSettle();
-
-    // Verify confirmation dialog
-    expect(find.text('Konfirmasi Keluar'), findsOneWidget);
-    expect(find.text('Ya, Keluar'), findsOneWidget);
-  });
-}
-
diff --git a/test/pic_flow_test.dart b/test/pic_flow_test.dart
index c738678..b28ea3e 100644
--- a/test/pic_flow_test.dart
+++ b/test/pic_flow_test.dart
@@ -1,17 +1,15 @@
 import 'package:flutter/material.dart';
 import 'package:flutter_test/flutter_test.dart';
-import 'package:mgrs_maintenance/app/app.dart';
 import 'package:mgrs_maintenance/app/gateway.dart';
 import 'package:mgrs_maintenance/features/components/component.dart';
 import 'package:mgrs_maintenance/features/components/component_detail_screen.dart';
-import 'package:mgrs_maintenance/features/home/pic_home_screen.dart';
 import 'package:mgrs_maintenance/features/invoices/invoice_list_screen.dart';
 import 'package:mgrs_maintenance/features/invoices/invoice_builder_dialog.dart';
 import 'package:mgrs_maintenance/features/invoices/invoice_model.dart';
 import 'package:mgrs_maintenance/features/scan/scan_screen.dart';
 import 'package:mgrs_maintenance/features/schedule/order_model.dart';
 import 'package:mgrs_maintenance/features/schedule/upcoming_orders_screen.dart';
 
 class MockPicGateway extends MaintenanceGateway {
   final List<OrderanSewa> orders = [
     OrderanSewa(
@@ -331,68 +329,20 @@ void main() {
         Key('btn-share-whatsapp'),
         Key('btn-quick-payment'),
         Key('btn-close-dialog'),
       ]) {
         final buttonRect = tester.getRect(find.byKey(key));
         expect(buttonRect.left, greaterThanOrEqualTo(dialogRect.left));
         expect(buttonRect.right, lessThanOrEqualTo(dialogRect.right));
       }
     });
 
-    testWidgets('renders PIC Dashboard with Beranda, Orderan, Invoice tabs', (
-      tester,
-    ) async {
-      final gateway = MockPicGateway();
-      const picUser = UserProfile('pic-1', 'PIC Pemasangan', fullName: 'Budi');
-
-      await tester.pumpWidget(
-        MaterialApp(
-          home: MaintenanceHome(gateway: gateway, user: picUser),
-        ),
-      );
-      await tester.pumpAndSettle();
-
-      // PIC dashboard tabs should be present
-      expect(find.text('Beranda'), findsWidgets);
-      expect(find.text('Orderan'), findsWidgets);
-      expect(find.text('Invoice'), findsWidgets);
-
-      // Verify QR scanner button IS shown for PIC
-      expect(find.byIcon(Icons.qr_code_scanner_rounded), findsOneWidget);
-    });
-
-    testWidgets('PicHomeScreen shows event summary and quick action button', (
-      tester,
-    ) async {
-      final gateway = MockPicGateway();
-      const picUser = UserProfile('pic-1', 'PIC Pemasangan', fullName: 'Budi');
-
-      await tester.pumpWidget(
-        MaterialApp(
-          home: Scaffold(
-            body: PicHomeScreen(
-              gateway: gateway,
-              user: picUser,
-              onOpenOrdersTab: () {},
-              onOpenInvoicesTab: () {},
-            ),
-          ),
-        ),
-      );
-      await tester.pumpAndSettle();
-
-      expect(find.text('Total Orderan\nBulan Ini'), findsOneWidget);
-      expect(find.text('Total Order'), findsOneWidget);
-      expect(find.text('Akan Datang'), findsOneWidget);
-      expect(find.text('Selesai'), findsOneWidget);
-      expect(find.text('Pameran Otomotif Akbar'), findsOneWidget);
-    });
 
     testWidgets('InvoiceListScreen filters invoices by status', (tester) async {
       final gateway = MockPicGateway();
       const picUser = UserProfile('pic-1', 'PIC Pemasangan', fullName: 'Budi');
 
       await tester.pumpWidget(
         MaterialApp(
           home: Scaffold(
             body: InvoiceListScreen(gateway: gateway, user: picUser),
           ),
diff --git a/test/widget_workspace_shell_test.dart b/test/widget_workspace_shell_test.dart
new file mode 100644
index 0000000..f5fe372
--- /dev/null
+++ b/test/widget_workspace_shell_test.dart
@@ -0,0 +1,184 @@
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:mgrs_maintenance/app/app.dart';
+import 'package:mgrs_maintenance/app/app_theme.dart';
+import 'package:mgrs_maintenance/app/gateway.dart';
+import 'package:mgrs_maintenance/features/components/asset_catalog_screen.dart';
+import 'package:mgrs_maintenance/features/invoices/invoice_list_screen.dart';
+
+class _ShellGateway extends MaintenanceGateway {
+  _ShellGateway({this.currentProfile});
+
+  UserProfile? currentProfile;
+  int signOutCalls = 0;
+
+  @override
+  Stream<void> get authChanges => const Stream.empty();
+
+  @override
+  Future<UserProfile?> profile() async => currentProfile;
+
+  @override
+  Future<void> signIn(String identifier, String password) async {}
+
+  @override
+  Future<void> signOut() async {
+    signOutCalls++;
+    currentProfile = null;
+  }
+
+  @override
+  Future<Object?> rpc(String name, Map<String, Object?> params) async {
+    if (name == 'maintenance_list_tasks') {
+      return <String, Object?>{
+        'period': <String, Object?>{
+          'id': '2026-09',
+          'opensAt': null,
+          'closesAt': null,
+          'snapshotState': 'ready',
+        },
+        'items': <Object?>[],
+        'nextCursor': null,
+        'total': 0,
+        'completed': 0,
+      };
+    }
+    if (name == 'maintenance_list_history') {
+      return <String, Object?>{
+        'items': <Object?>[],
+        'nextCursor': null,
+      };
+    }
+    return null;
+  }
+}
+
+Widget _testShell({
+  required MaintenanceGateway gateway,
+  required UserProfile user,
+}) {
+  return MaterialApp(
+    theme: maintenanceTheme(),
+    home: MaintenanceHome(gateway: gateway, user: user),
+  );
+}
+
+int _selectedDestination(WidgetTester tester) {
+  final bottomNavigation = find.byType(NavigationBar);
+  if (bottomNavigation.evaluate().isNotEmpty) {
+    return tester.widget<NavigationBar>(bottomNavigation).selectedIndex;
+  }
+  return tester.widget<NavigationRail>(find.byType(NavigationRail)).selectedIndex!;
+}
+
+void main() {
+  testWidgets('PIC shell exposes only PIC destinations', (tester) async {
+    final gateway = _ShellGateway();
+    const user = UserProfile('pic-1', 'PIC Pemasangan', fullName: 'PIC MGRS');
+
+    await tester.pumpWidget(_testShell(gateway: gateway, user: user));
+    await tester.pumpAndSettle();
+
+    expect(find.text('Beranda'), findsOneWidget);
+    expect(find.text('Orderan'), findsOneWidget);
+    expect(find.text('Invoice'), findsOneWidget);
+    expect(find.text('Profil'), findsOneWidget);
+    expect(find.text('Berkala'), findsNothing);
+    expect(find.text('Komponen'), findsNothing);
+    expect(find.text('Riwayat'), findsNothing);
+    expect(find.text('Belum ada orderan yang perlu ditindaklanjuti.'), findsOneWidget);
+    expect(find.text('Total Orderan\nBulan Ini'), findsNothing);
+    expect(find.text('Live Data'), findsNothing);
+
+    await tester.tap(find.text('Invoice'));
+    await tester.pumpAndSettle();
+    final invoiceScreen = tester.widget<InvoiceListScreen>(
+      find.byType(InvoiceListScreen),
+    );
+    expect(identical(invoiceScreen.gateway, gateway), isTrue);
+    expect(invoiceScreen.user, same(user));
+  });
+
+  testWidgets('field shell exposes only field destinations', (tester) async {
+    final gateway = _ShellGateway();
+    const user = UserProfile(
+      'field-1',
+      'Tim Service',
+      fullName: 'Petugas Lapangan',
+    );
+
+    await tester.pumpWidget(_testShell(gateway: gateway, user: user));
+    await tester.pumpAndSettle();
+
+    expect(find.text('Scan'), findsOneWidget);
+    expect(find.text('Berkala'), findsOneWidget);
+    expect(find.text('Komponen'), findsOneWidget);
+    expect(find.text('Riwayat'), findsOneWidget);
+    expect(find.text('Orderan'), findsNothing);
+    expect(find.text('Invoice'), findsNothing);
+    expect(find.text('Pindai komponen'), findsOneWidget);
+    expect(find.text('Pengingat!'), findsNothing);
+    expect(find.textContaining('mesin aktif dipantau'), findsNothing);
+
+    await tester.tap(find.text('Komponen'));
+    await tester.pumpAndSettle();
+    final componentsScreen = tester.widget<AssetCatalogScreen>(
+      find.byType(AssetCatalogScreen),
+    );
+    expect(identical(componentsScreen.gateway, gateway), isTrue);
+  });
+
+  testWidgets('Admin switcher exposes two workspaces and resets destination', (
+    tester,
+  ) async {
+    final gateway = _ShellGateway();
+    const user = UserProfile('admin-1', 'Admin', fullName: 'Administrator');
+
+    await tester.pumpWidget(_testShell(gateway: gateway, user: user));
+    await tester.pumpAndSettle();
+
+    expect(find.text('PIC MGRS'), findsOneWidget);
+    expect(find.text('Tim Lapangan'), findsOneWidget);
+    expect(find.text('Tim Service'), findsNothing);
+
+    await tester.tap(find.text('Riwayat'));
+    await tester.pumpAndSettle();
+    expect(_selectedDestination(tester), 3);
+
+    await tester.tap(find.text('PIC MGRS'));
+    await tester.pumpAndSettle();
+    expect(_selectedDestination(tester), 0);
+    expect(find.text('Orderan'), findsOneWidget);
+    expect(find.text('Berkala'), findsNothing);
+
+    await tester.tap(find.text('Invoice'));
+    await tester.pumpAndSettle();
+    expect(_selectedDestination(tester), 2);
+
+    await tester.tap(find.text('Tim Lapangan'));
+    await tester.pumpAndSettle();
+    expect(_selectedDestination(tester), 0);
+    expect(find.text('Berkala'), findsOneWidget);
+    expect(find.text('Invoice'), findsNothing);
+  });
+
+  testWidgets('logout reloads the root session into the login screen', (
+    tester,
+  ) async {
+    const user = UserProfile(
+      'field-2',
+      'Tim Service',
+      fullName: 'Petugas Lapangan',
+    );
+    final gateway = _ShellGateway(currentProfile: user);
+
+    await tester.pumpWidget(MaintenanceApp(gateway: gateway));
+    await tester.pumpAndSettle();
+
+    await tester.tap(find.text('Keluar dari akun'));
+    await tester.pumpAndSettle();
+
+    expect(gateway.signOutCalls, 1);
+    expect(find.text('Email / Akun MGRS'), findsOneWidget);
+  });
+}
