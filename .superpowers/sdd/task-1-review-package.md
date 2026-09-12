BASE: 9f0eaef
HEAD: 97f559e

STAT
 lib/app/app.dart                     | 45 ++++++++++++++++++++++++++++++------
 lib/app/gateway.dart                 | 33 ++++++++++++++++++++++++++
 test/unit_workspace_access_test.dart | 26 +++++++++++++++++++++
 3 files changed, 97 insertions(+), 7 deletions(-)

DIFF
diff --git a/lib/app/app.dart b/lib/app/app.dart
index 23047ba..ddb1f08 100644
--- a/lib/app/app.dart
+++ b/lib/app/app.dart
@@ -164,29 +164,34 @@ class _MaintenanceHomeState extends State<MaintenanceHome>
       activeIcon: Icons.event_note_rounded,
       inactiveIcon: Icons.event_note_outlined,
     ),
     AppNavItem(
       label: 'Invoice',
       activeIcon: Icons.receipt_long_rounded,
       inactiveIcon: Icons.receipt_long_outlined,
     ),
   ];
 
-  AdminAppMode _adminMode = AdminAppMode.service;
+  MgrsWorkspace? _workspace;
+  AdminAppMode get _adminMode =>
+      _workspace == MgrsWorkspace.pic
+          ? AdminAppMode.pic
+          : AdminAppMode.service;
   int tab = 0;
   late final PageController _pageController;
   late final AnimationController _fadeController;
   late final Animation<double> _fadeAnimation;
 
   @override
   void initState() {
     super.initState();
+    _workspace = _safeWorkspace(widget.user.defaultWorkspace);
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
@@ -198,65 +203,91 @@ class _MaintenanceHomeState extends State<MaintenanceHome>
     _pageController.dispose();
     super.dispose();
   }
 
   void _onNavigateToTab(int index) {
     if (tab == index) return;
     setState(() => tab = index);
     _pageController.jumpToPage(index);
     _fadeController.forward(from: 0.0);
   }
+  MgrsWorkspace? _safeWorkspace(MgrsWorkspace? candidate) {
+    final allowedWorkspaces = widget.user.allowedWorkspaces;
+    if (candidate != null && allowedWorkspaces.contains(candidate)) {
+      return candidate;
+    }
+    final fallback = widget.user.defaultWorkspace;
+    return fallback != null && allowedWorkspaces.contains(fallback)
+        ? fallback
+        : null;
+  }
 
-  void _switchAdminMode(AdminAppMode newMode) {
-    if (_adminMode == newMode) return;
+  void _selectWorkspace(MgrsWorkspace requestedWorkspace) {
+    final nextWorkspace = _safeWorkspace(requestedWorkspace);
+    if (nextWorkspace == null || _workspace == nextWorkspace) return;
     setState(() {
-      _adminMode = newMode;
+      _workspace = nextWorkspace;
       tab = 0;
     });
     _pageController.jumpToPage(0);
     _fadeController.forward(from: 0.0);
     ScaffoldMessenger.of(context).showSnackBar(
       SnackBar(
         content: Text(
-          newMode == AdminAppMode.pic
+          nextWorkspace == MgrsWorkspace.pic
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
 
+  void _switchAdminMode(AdminAppMode newMode) {
+    _selectWorkspace(
+      newMode == AdminAppMode.pic ? MgrsWorkspace.pic : MgrsWorkspace.field,
+    );
+  }
+
+
   bool get effectiveIsPic =>
-      widget.user.isPic ||
-      (widget.user.isAdmin && _adminMode == AdminAppMode.pic);
+      _workspace == MgrsWorkspace.pic &&
+      widget.user.allowedWorkspaces.contains(MgrsWorkspace.pic);
+
+  bool get _hasWorkspaceAccess =>
+      _workspace != null && widget.user.allowedWorkspaces.contains(_workspace);
 
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
+    if (!_hasWorkspaceAccess) {
+      return const Scaffold(
+        body: Center(child: Text('Akses workspace tidak tersedia.')),
+      );
+    }
     final isPic = effectiveIsPic;
     final bottomInset = MediaQuery.paddingOf(context).bottom;
     final scrimHeight = 98.0 + bottomInset;
 
     final children = isPic
         ? [
             PicHomeScreen(
               gateway: widget.gateway,
               user: widget.user,
               adminMode: widget.user.isAdmin ? _adminMode : null,
diff --git a/lib/app/gateway.dart b/lib/app/gateway.dart
index a6b806a..23ed220 100644
--- a/lib/app/gateway.dart
+++ b/lib/app/gateway.dart
@@ -8,20 +8,32 @@ import '../features/schedule/unit_allocation_model.dart';
 Map<String, Object?> jsonObject(Object? value) {
   if (value is! Map) throw const FormatException('Expected object');
   return Map<String, Object?>.from(value);
 }
 
 List<Map<String, Object?>> jsonItems(Object? value) {
   if (value is! List) throw const FormatException('Expected list');
   return value.map(jsonObject).toList();
 }
 
+enum MgrsWorkspace { pic, field }
+
+enum ProductRole { admin, picMgrs, timLapangan }
+
+extension ProductRoleLabel on ProductRole {
+  String get label => switch (this) {
+    ProductRole.admin => 'Admin',
+    ProductRole.picMgrs => 'PIC MGRS',
+    ProductRole.timLapangan => 'Tim Lapangan',
+  };
+}
+
 enum AdminAppMode {
   pic('Mode PIC (Order & Invoice)'),
   service('Mode Servis (Teknisi Maintenance)');
 
   const AdminAppMode(this.label);
   final String label;
 }
 
 class UserProfile {
   const UserProfile(
@@ -29,20 +41,40 @@ class UserProfile {
     this.role, {
     this.fullName,
     this.username,
   });
 
   final String id;
   final String role;
   final String? fullName;
   final String? username;
 
+  ProductRole? get productRole => switch (role) {
+    'Admin' => ProductRole.admin,
+    'PIC Pemasangan' => ProductRole.picMgrs,
+    'Tim Service' || 'Tim Pemasangan' => ProductRole.timLapangan,
+    _ => null,
+  };
+
+  Set<MgrsWorkspace> get allowedWorkspaces => switch (productRole) {
+    ProductRole.admin => {MgrsWorkspace.pic, MgrsWorkspace.field},
+    ProductRole.picMgrs => {MgrsWorkspace.pic},
+    ProductRole.timLapangan => {MgrsWorkspace.field},
+    null => const <MgrsWorkspace>{},
+  };
+
+  MgrsWorkspace? get defaultWorkspace => switch (productRole) {
+    ProductRole.admin || ProductRole.timLapangan => MgrsWorkspace.field,
+    ProductRole.picMgrs => MgrsWorkspace.pic,
+    null => null,
+  };
+
   UserProfile copyWith({
     String? id,
     String? role,
     String? fullName,
     String? username,
   }) {
     return UserProfile(
       id ?? this.id,
       role ?? this.role,
       fullName: fullName ?? this.fullName,
@@ -79,20 +111,21 @@ class UserProfile {
     final parts = name.trim().split(RegExp(r'\s+'));
     if (parts.length >= 2) {
       return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
     } else if (name.isNotEmpty) {
       return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
     }
     return isPic ? 'PIC' : 'PM';
   }
 }
 
+
 class AppFailure implements Exception {
   const AppFailure(this.code);
   final String code;
   String get message => switch (code) {
     'invalid_credentials' => 'Akun atau kata sandi tidak sesuai.',
     'forbidden' => 'Akun ini tidak memiliki akses maintenance.',
     'unauthenticated' => 'Sesi berakhir. Silakan masuk kembali.',
     'conflict' =>
       'Kondisi sudah diperbarui. Periksa data terbaru sebelum menyimpan kembali.',
     'not_found' => 'Komponen tidak ditemukan. Periksa kembali kodenya.',
diff --git a/test/unit_workspace_access_test.dart b/test/unit_workspace_access_test.dart
new file mode 100644
index 0000000..b5f177b
--- /dev/null
+++ b/test/unit_workspace_access_test.dart
@@ -0,0 +1,26 @@
+import 'package:flutter_test/flutter_test.dart';
+import 'package:mgrs_maintenance/app/gateway.dart';
+
+void main() {
+  test('admin can use exactly two product workspaces', () {
+    const user = UserProfile('1', 'Admin');
+    expect(user.allowedWorkspaces, {
+      MgrsWorkspace.pic,
+      MgrsWorkspace.field,
+    });
+  });
+
+  test('legacy field roles resolve to Tim Lapangan without rewriting raw role', () {
+    const user = UserProfile('1', 'Tim Service');
+    expect(user.role, 'Tim Service');
+    expect(user.productRole, ProductRole.timLapangan);
+    expect(user.allowedWorkspaces, {MgrsWorkspace.field});
+  });
+
+  test('PIC MGRS cannot enter Tim Lapangan workspace', () {
+    const user = UserProfile('1', 'PIC Pemasangan');
+    expect(user.productRole, ProductRole.picMgrs);
+    expect(user.allowedWorkspaces, {MgrsWorkspace.pic});
+    expect(user.defaultWorkspace, MgrsWorkspace.pic);
+  });
+}
