BASE: 97f559e
HEAD: b096fb1

STAT
 lib/app/app_theme.dart                  | 305 ++++++++++++++++++++++++-----
 lib/shared/async_state_view.dart        | 187 ++++++++++++++++--
 lib/shared/condition_badge.dart         |  27 ++-
 lib/shared/mgrs_app_shell.dart          |  79 ++++++++
 lib/shared/mgrs_components.dart         | 251 ++++++++++++++++++++++++
 lib/shared/pressable.dart               |  89 ++++++---
 test/widget_shared_components_test.dart | 334 ++++++++++++++++++++++++++++++++
 7 files changed, 1173 insertions(+), 99 deletions(-)

DIFF
diff --git a/lib/app/app_theme.dart b/lib/app/app_theme.dart
index 951fc56..7a6a9a2 100644
--- a/lib/app/app_theme.dart
+++ b/lib/app/app_theme.dart
@@ -1,58 +1,269 @@
 import 'package:flutter/material.dart';
 
+/// Semantic design tokens shared by every MGRS workspace.
 abstract final class AppTokens {
-  static const canvas = Color(0xFFF4F8FC),
-      primary = Color(0xFF147CC1),
-      text = Color(0xFF141820),
-      muted = Color(0xFF667085),
-      border = Color(0xFFDDE2E8),
-      danger = Color(0xFFB42318),
-      success = Color(0xFF137333),
-      warning = Color(0xFF9A6700),
-      accentLime = Color(0xFFCEF284),
-      darkSlate = Color(0xFF0F172A);
-  static const space = 16.0, radius = 12.0, maxWidth = 640.0;
+  static const canvas = Color(0xFFFFFFFF);
+  static const canvasSubtle = Color(0xFFF5F5F7);
+  static const surface = Color(0xFFFAFAFC);
+  static const surfaceStrong = Color(0xFFFFFFFF);
+  static const surfaceDark = Color(0xFF272729);
+  static const surfaceBlack = Color(0xFF1D1D1F);
+  static const ink = Color(0xFF1D1D1F);
+  static const inkOnDark = Color(0xFFFFFFFF);
+  static const inkMuted = Color(0xFF6E6E73);
+  static const divider = Color(0xFFE0E0E0);
+  static const actionBlue = Color(0xFF0066CC);
+  static const actionBlueFocus = Color(0xFF0071E3);
+  static const success = Color(0xFF2E7D32);
+  static const warning = Color(0xFF956400);
+  static const danger = Color(0xFFB42318);
+
+  static const space = 16.0;
+  static const radius = 12.0;
+  static const maxWidth = 720.0;
+
+  // Compatibility names used by screens that have not migrated to semantic
+  // tokens yet. They intentionally point at the new design roles.
+  static const primary = actionBlue;
+  static const text = ink;
+  static const muted = inkMuted;
+  static const border = divider;
 }
 
-ThemeData maintenanceTheme() => ThemeData(
-  useMaterial3: true,
-  scaffoldBackgroundColor: AppTokens.canvas,
-  colorScheme: ColorScheme.fromSeed(
-    seedColor: AppTokens.primary,
-    primary: AppTokens.primary,
-    surface: Colors.white,
-    onSurface: AppTokens.text,
+ThemeData maintenanceTheme({Brightness brightness = Brightness.light}) {
+  final isDark = brightness == Brightness.dark;
+  final scheme = ColorScheme.fromSeed(
+    seedColor: AppTokens.actionBlue,
+    brightness: brightness,
+  ).copyWith(
+    primary: isDark ? AppTokens.actionBlueFocus : AppTokens.actionBlue,
+    onPrimary: AppTokens.inkOnDark,
+    primaryContainer: isDark ? AppTokens.surfaceDark : AppTokens.canvasSubtle,
+    onPrimaryContainer: isDark ? AppTokens.inkOnDark : AppTokens.ink,
+    secondary: isDark ? AppTokens.actionBlueFocus : AppTokens.actionBlue,
+    onSecondary: AppTokens.inkOnDark,
+    surface: isDark ? AppTokens.surfaceDark : AppTokens.surface,
+    onSurface: isDark ? AppTokens.inkOnDark : AppTokens.ink,
+    surfaceContainerHighest:
+        isDark ? AppTokens.surfaceBlack : AppTokens.canvasSubtle,
+    outline: isDark ? AppTokens.inkMuted : AppTokens.divider,
     error: AppTokens.danger,
-  ),
-  appBarTheme: const AppBarTheme(
-    backgroundColor: AppTokens.canvas,
-    scrolledUnderElevation: 0,
-  ),
-  inputDecorationTheme: InputDecorationTheme(
-    filled: true,
-    fillColor: Colors.white,
-    border: OutlineInputBorder(
-      borderRadius: BorderRadius.circular(AppTokens.radius),
-      borderSide: const BorderSide(color: AppTokens.border),
-    ),
-  ),
-  filledButtonTheme: FilledButtonThemeData(
-    style: FilledButton.styleFrom(
-      minimumSize: const Size(48, 48),
+    onError: AppTokens.inkOnDark,
+  );
+  final textTheme = _textTheme(isDark);
+  final shape = RoundedRectangleBorder(
+    borderRadius: BorderRadius.circular(AppTokens.radius),
+  );
+  final fieldBorder = OutlineInputBorder(
+    borderRadius: BorderRadius.circular(AppTokens.radius),
+    borderSide: BorderSide(
+      color: isDark ? AppTokens.inkMuted : AppTokens.divider,
+    ),
+  );
+
+  return ThemeData(
+    useMaterial3: true,
+    brightness: brightness,
+    colorScheme: scheme,
+    scaffoldBackgroundColor: isDark ? AppTokens.surfaceBlack : AppTokens.canvas,
+    canvasColor: isDark ? AppTokens.surfaceBlack : AppTokens.canvas,
+    dividerColor: isDark ? AppTokens.inkMuted : AppTokens.divider,
+    focusColor: AppTokens.actionBlueFocus,
+    hoverColor: isDark
+        ? AppTokens.actionBlueFocus.withValues(alpha: .12)
+        : AppTokens.actionBlue.withValues(alpha: .08),
+    textTheme: textTheme,
+    appBarTheme: AppBarTheme(
+      backgroundColor: isDark ? AppTokens.surfaceBlack : AppTokens.canvas,
+      foregroundColor: isDark ? AppTokens.inkOnDark : AppTokens.ink,
+      scrolledUnderElevation: 0,
+      elevation: 0,
+      titleTextStyle: textTheme.titleLarge,
+    ),
+    inputDecorationTheme: InputDecorationTheme(
+      filled: true,
+      fillColor: isDark ? AppTokens.surfaceDark : AppTokens.surfaceStrong,
+      border: fieldBorder,
+      enabledBorder: fieldBorder,
+      focusedBorder: fieldBorder.copyWith(
+        borderSide: const BorderSide(color: AppTokens.actionBlueFocus, width: 2),
+      ),
+      errorBorder: fieldBorder.copyWith(
+        borderSide: const BorderSide(color: AppTokens.danger),
+      ),
+      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
+      labelStyle: TextStyle(
+        color: isDark ? AppTokens.inkOnDark : AppTokens.inkMuted,
+      ),
+    ),
+    filledButtonTheme: FilledButtonThemeData(
+      style: FilledButton.styleFrom(
+        minimumSize: const Size(48, 48),
+        backgroundColor: AppTokens.actionBlue,
+        foregroundColor: AppTokens.inkOnDark,
+        shape: shape,
+      ),
+    ),
+    elevatedButtonTheme: ElevatedButtonThemeData(
+      style: ElevatedButton.styleFrom(
+        minimumSize: const Size(48, 48),
+        backgroundColor: AppTokens.actionBlue,
+        foregroundColor: AppTokens.inkOnDark,
+        elevation: 0,
+        shape: shape,
+      ),
+    ),
+    outlinedButtonTheme: OutlinedButtonThemeData(
+      style: OutlinedButton.styleFrom(
+        minimumSize: const Size(48, 48),
+        foregroundColor: isDark ? AppTokens.inkOnDark : AppTokens.actionBlue,
+        side: const BorderSide(color: AppTokens.actionBlue),
+        shape: shape,
+      ),
+    ),
+    textButtonTheme: TextButtonThemeData(
+      style: TextButton.styleFrom(
+        minimumSize: const Size(48, 48),
+        foregroundColor:
+            isDark ? AppTokens.actionBlueFocus : AppTokens.actionBlue,
+      ),
+    ),
+    cardTheme: CardThemeData(
+      elevation: 0,
+      margin: EdgeInsets.zero,
+      color: isDark ? AppTokens.surfaceDark : AppTokens.surfaceStrong,
+      shape: shape.copyWith(
+        side: BorderSide(color: isDark ? AppTokens.inkMuted : AppTokens.divider),
+      ),
+    ),
+    chipTheme: ChipThemeData(
+      backgroundColor: isDark ? AppTokens.surfaceDark : AppTokens.canvasSubtle,
+      side: BorderSide(color: isDark ? AppTokens.inkMuted : AppTokens.divider),
       shape: RoundedRectangleBorder(
         borderRadius: BorderRadius.circular(AppTokens.radius),
       ),
+      labelStyle: textTheme.labelLarge,
+    ),
+    snackBarTheme: SnackBarThemeData(
+      backgroundColor: isDark ? AppTokens.surfaceDark : AppTokens.surfaceBlack,
+      contentTextStyle:
+          textTheme.bodyMedium?.copyWith(color: AppTokens.inkOnDark),
+      behavior: SnackBarBehavior.floating,
+      shape: shape,
+    ),
+    dialogTheme: DialogThemeData(
+      backgroundColor: isDark ? AppTokens.surfaceDark : AppTokens.surfaceStrong,
+      shape: shape,
+      titleTextStyle: textTheme.titleLarge,
+      contentTextStyle: textTheme.bodyMedium,
+    ),
+    navigationBarTheme: NavigationBarThemeData(
+      backgroundColor: isDark ? AppTokens.surfaceDark : AppTokens.canvas,
+      indicatorColor: isDark ? AppTokens.surfaceBlack : AppTokens.canvasSubtle,
+      labelTextStyle: WidgetStatePropertyAll(textTheme.labelMedium),
+      height: 80,
+    ),
+    navigationRailTheme: NavigationRailThemeData(
+      backgroundColor: isDark ? AppTokens.surfaceDark : AppTokens.canvas,
+      indicatorColor: isDark ? AppTokens.surfaceBlack : AppTokens.canvasSubtle,
+      selectedIconTheme: const IconThemeData(color: AppTokens.actionBlue),
+      selectedLabelTextStyle: const TextStyle(
+        color: AppTokens.actionBlue,
+        fontWeight: FontWeight.w600,
+      ),
+    ),
+  );
+}
+
+ThemeData maintenanceLightTheme() => maintenanceTheme();
+
+ThemeData maintenanceDarkTheme() =>
+    maintenanceTheme(brightness: Brightness.dark);
+
+TextTheme _textTheme(bool isDark) {
+  final color = isDark ? AppTokens.inkOnDark : AppTokens.ink;
+  return Typography.material2021().black.apply(
+    bodyColor: color,
+    displayColor: color,
+  ).copyWith(
+    displayLarge: TextStyle(
+      fontSize: 40,
+      height: 1.1,
+      fontWeight: FontWeight.w600,
+      letterSpacing: -1,
+      color: color,
+    ),
+    displayMedium: TextStyle(
+      fontSize: 36,
+      height: 1.1,
+      fontWeight: FontWeight.w600,
+      letterSpacing: -0.75,
+      color: color,
     ),
-  ),
-  outlinedButtonTheme: OutlinedButtonThemeData(
-    style: OutlinedButton.styleFrom(minimumSize: const Size(48, 48)),
-  ),
-  cardTheme: CardThemeData(
-    elevation: 0,
-    margin: EdgeInsets.zero,
-    shape: RoundedRectangleBorder(
-      borderRadius: BorderRadius.circular(AppTokens.radius),
-      side: const BorderSide(color: AppTokens.border),
+    displaySmall: TextStyle(
+      fontSize: 34,
+      height: 1.1,
+      fontWeight: FontWeight.w600,
+      letterSpacing: -0.5,
+      color: color,
     ),
-  ),
-);
+    headlineLarge: TextStyle(
+      fontSize: 32,
+      height: 1.15,
+      fontWeight: FontWeight.w600,
+      letterSpacing: -0.5,
+      color: color,
+    ),
+    headlineMedium: TextStyle(
+      fontSize: 30,
+      height: 1.2,
+      fontWeight: FontWeight.w600,
+      color: color,
+    ),
+    headlineSmall: TextStyle(
+      fontSize: 28,
+      height: 1.2,
+      fontWeight: FontWeight.w600,
+      color: color,
+    ),
+    titleLarge: TextStyle(
+      fontSize: 24,
+      height: 1.25,
+      fontWeight: FontWeight.w600,
+      color: color,
+    ),
+    titleMedium: TextStyle(
+      fontSize: 22,
+      height: 1.25,
+      fontWeight: FontWeight.w600,
+      color: color,
+    ),
+    titleSmall: TextStyle(
+      fontSize: 20,
+      height: 1.3,
+      fontWeight: FontWeight.w600,
+      color: color,
+    ),
+    bodyLarge: TextStyle(fontSize: 17, height: 1.4, color: color),
+    bodyMedium: TextStyle(fontSize: 16, height: 1.4, color: color),
+    bodySmall: TextStyle(fontSize: 14, height: 1.4, color: color),
+    labelLarge: TextStyle(
+      fontSize: 14,
+      height: 1.25,
+      fontWeight: FontWeight.w600,
+      color: color,
+    ),
+    labelMedium: TextStyle(
+      fontSize: 13,
+      height: 1.25,
+      fontWeight: FontWeight.w600,
+      color: isDark ? AppTokens.inkOnDark : AppTokens.inkMuted,
+    ),
+    labelSmall: TextStyle(
+      fontSize: 12,
+      height: 1.25,
+      fontWeight: FontWeight.w600,
+      color: isDark ? AppTokens.inkOnDark : AppTokens.inkMuted,
+    ),
+  );
+}
diff --git a/lib/shared/async_state_view.dart b/lib/shared/async_state_view.dart
index 5417300..446505d 100644
--- a/lib/shared/async_state_view.dart
+++ b/lib/shared/async_state_view.dart
@@ -17,45 +17,208 @@ class PageBody extends StatelessWidget {
     ),
   );
 }
 
 class AsyncStateView<T> extends StatelessWidget {
   const AsyncStateView({
     super.key,
     required this.future,
     required this.builder,
     required this.retry,
+    this.empty,
+    this.error,
+    this.permission,
+    this.conflict,
+    this.loading,
+    this.isEmpty,
   });
+
   final Future<T> future;
   final Widget Function(T) builder;
   final VoidCallback retry;
+  final Widget Function()? empty;
+  final Widget Function(Object? error)? error;
+  final Widget Function()? permission;
+  final Widget Function(Object? error)? conflict;
+  final Widget Function()? loading;
+  final bool Function(T value)? isEmpty;
+
   @override
   Widget build(BuildContext context) => FutureBuilder<T>(
     future: future,
     builder: (context, snapshot) {
       if (snapshot.connectionState != ConnectionState.done) {
-        return const Center(child: CircularProgressIndicator());
+        return loading?.call() ?? const LoadingStateView();
+      }
+      final failure = snapshot.error;
+      if (failure != null) {
+        if (_isPermissionFailure(failure)) {
+          return permission?.call() ??
+              PermissionStateView(onRetry: retry, error: failure);
+        }
+        if (_isConflictFailure(failure)) {
+          return conflict?.call(failure) ??
+              ConflictStateView(onRetry: retry, error: failure);
+        }
+        return error?.call(failure) ??
+            ErrorStateView(onRetry: retry, error: failure);
+      }
+      final value = snapshot.data;
+      if (isEmpty != null) {
+        final typedValue = value as T;
+        if (isEmpty!(typedValue)) {
+          return empty?.call() ?? const EmptyStateView();
+        }
+        return builder(typedValue);
       }
-      if (snapshot.hasError) {
-        return PageBody(
-          children: [
-            const Icon(Icons.cloud_off_outlined, size: 40),
-            const SizedBox(height: 16),
-            Text(failureMessage(snapshot.error), textAlign: TextAlign.center),
-            const SizedBox(height: 16),
-            OutlinedButton(onPressed: retry, child: const Text('Coba lagi')),
-          ],
-        );
+      if (value == null || _isEmpty(value)) {
+        return empty?.call() ?? const EmptyStateView();
       }
-      return builder(snapshot.data as T);
+      return builder(value);
     },
   );
+
+  bool _isEmpty(T value) {
+    if (value is String) return value.trim().isEmpty;
+    if (value is Iterable) return value.isEmpty;
+    if (value is Map) return value.isEmpty;
+    return false;
+  }
+
+  bool _isPermissionFailure(Object value) {
+    return value is AppFailure &&
+        {'forbidden', 'permission_denied', 'unauthenticated'}.contains(value.code);
+  }
+
+  bool _isConflictFailure(Object value) {
+    return value is AppFailure &&
+        {'conflict', 'version_conflict'}.contains(value.code);
+  }
+}
+
+class LoadingStateView extends StatelessWidget {
+  const LoadingStateView({super.key, this.message = 'Memuat data…'});
+  final String message;
+
+  @override
+  Widget build(BuildContext context) => StatePanel(
+    icon: Icons.hourglass_empty,
+    title: message,
+    showProgress: true,
+  );
+}
+
+class EmptyStateView extends StatelessWidget {
+  const EmptyStateView({
+    super.key,
+    this.title = 'Belum ada data',
+    this.message = 'Belum ada catatan untuk ditampilkan.',
+  });
+  final String title;
+  final String message;
+
+  @override
+  Widget build(BuildContext context) =>
+      StatePanel(icon: Icons.inbox_outlined, title: title, message: message);
+}
+
+class ErrorStateView extends StatelessWidget {
+  const ErrorStateView({
+    super.key,
+    required this.onRetry,
+    this.error,
+  });
+  final VoidCallback onRetry;
+  final Object? error;
+
+  @override
+  Widget build(BuildContext context) => StatePanel(
+    icon: Icons.cloud_off_outlined,
+    title: 'Data belum dapat dimuat',
+    message: failureMessage(error),
+    action: OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
+  );
+}
+
+class PermissionStateView extends StatelessWidget {
+  const PermissionStateView({
+    super.key,
+    required this.onRetry,
+    this.error,
+  });
+  final VoidCallback onRetry;
+  final Object? error;
+
+  @override
+  Widget build(BuildContext context) => StatePanel(
+    icon: Icons.lock_outline,
+    title: 'Akses tidak tersedia',
+    message: failureMessage(error),
+    action: OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
+  );
+}
+
+class ConflictStateView extends StatelessWidget {
+  const ConflictStateView({
+    super.key,
+    required this.onRetry,
+    this.error,
+  });
+  final VoidCallback onRetry;
+  final Object? error;
+
+  @override
+  Widget build(BuildContext context) => StatePanel(
+    icon: Icons.sync_problem_outlined,
+    title: 'Perubahan belum tersimpan',
+    message: failureMessage(error),
+    action: OutlinedButton(onPressed: onRetry, child: const Text('Coba lagi')),
+  );
+}
+
+class StatePanel extends StatelessWidget {
+  const StatePanel({
+    super.key,
+    required this.icon,
+    required this.title,
+    this.message,
+    this.action,
+    this.showProgress = false,
+  });
+  final IconData icon;
+  final String title;
+  final String? message;
+  final Widget? action;
+  final bool showProgress;
+
+  @override
+  Widget build(BuildContext context) => PageBody(
+    children: [
+      const SizedBox(height: 32),
+      ExcludeSemantics(child: Icon(icon, size: 40)),
+      if (showProgress) ...[
+        const SizedBox(height: 16),
+        const Center(child: CircularProgressIndicator()),
+      ],
+      const SizedBox(height: 16),
+      Text(
+        title,
+        textAlign: TextAlign.center,
+        style: Theme.of(context).textTheme.titleMedium,
+      ),
+      if (message != null) ...[
+        const SizedBox(height: 8),
+        Text(message!, textAlign: TextAlign.center),
+      ],
+      if (action != null) ...[const SizedBox(height: 16), action!],
+    ],
+  );
 }
 
 String stamp(Object? value) {
   final parsed = DateTime.tryParse(value?.toString() ?? '');
   if (parsed == null) return 'Belum tercatat';
   final d = parsed.toUtc().add(const Duration(hours: 7));
   return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} · ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')} WIB';
 }
 
 String conditionDisplayLabel(String? condition) {
diff --git a/lib/shared/condition_badge.dart b/lib/shared/condition_badge.dart
index 6473bda..274d95b 100644
--- a/lib/shared/condition_badge.dart
+++ b/lib/shared/condition_badge.dart
@@ -4,22 +4,33 @@ import '../app/app_theme.dart';
 class ConditionBadge extends StatelessWidget {
   const ConditionBadge(this.value, {super.key});
   final String value;
   @override
   Widget build(BuildContext context) {
     final color = value == 'OK'
         ? AppTokens.success
         : value == 'Rusak Ringan'
         ? AppTokens.warning
         : AppTokens.danger;
-    return Chip(
-      avatar: Icon(
-        value == 'OK' ? Icons.check_circle_outline : Icons.info_outline,
-        color: color,
-        size: 18,
+    return Tooltip(
+      excludeFromSemantics: true,
+      message: 'Kondisi: $value',
+      child: Semantics(
+        container: true,
+        excludeSemantics: true,
+        label: 'Kondisi: $value',
+        child: Chip(
+          avatar: Icon(
+            value == 'OK'
+                ? Icons.check_circle_outline
+                : Icons.info_outline,
+            color: color,
+            size: 18,
+          ),
+          label: Text(value, style: TextStyle(color: color)),
+          side: BorderSide(color: color.withValues(alpha: .3)),
+          backgroundColor: color.withValues(alpha: .06),
+        ),
       ),
-      label: Text(value, style: TextStyle(color: color)),
-      side: BorderSide(color: color.withValues(alpha: .3)),
-      backgroundColor: color.withValues(alpha: .06),
     );
   }
 }
diff --git a/lib/shared/mgrs_app_shell.dart b/lib/shared/mgrs_app_shell.dart
new file mode 100644
index 0000000..e45395f
--- /dev/null
+++ b/lib/shared/mgrs_app_shell.dart
@@ -0,0 +1,79 @@
+import 'package:flutter/material.dart';
+
+import '../app/gateway.dart';
+import 'mgrs_components.dart';
+
+/// Shared application frame for both MGRS workspaces.
+class MGRSAppShell extends StatelessWidget {
+  const MGRSAppShell({
+    super.key,
+    required this.workspace,
+    required this.user,
+    required this.selectedIndex,
+    required this.onDestinationSelected,
+    required this.child,
+    this.onWorkspaceChanged,
+  });
+
+  final MgrsWorkspace workspace;
+  final UserProfile user;
+  final int selectedIndex;
+  final ValueChanged<int> onDestinationSelected;
+  final Widget child;
+  final ValueChanged<MgrsWorkspace>? onWorkspaceChanged;
+
+  @override
+  Widget build(BuildContext context) => LayoutBuilder(
+    builder: (context, constraints) {
+      final expanded = constraints.maxWidth >= 600;
+    assert(
+      user.productRole != ProductRole.admin || onWorkspaceChanged != null,
+      'Admin workspace shells require onWorkspaceChanged',
+    );
+      final navigation = AdaptiveNavigation(
+        workspace: workspace,
+        selectedIndex: selectedIndex,
+        onDestinationSelected: onDestinationSelected,
+        useRail: expanded,
+      );
+      final content = Column(
+        crossAxisAlignment: CrossAxisAlignment.stretch,
+        children: [
+          if (user.productRole == ProductRole.admin)
+            Padding(
+              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
+              child: Align(
+                alignment: AlignmentDirectional.centerStart,
+                child: WorkspaceSwitcher(
+                  workspace: workspace,
+                  onWorkspaceChanged: onWorkspaceChanged!,
+                ),
+              ),
+            ),
+          Expanded(child: child),
+        ],
+      );
+
+      final body = SafeArea(
+        top: true,
+        bottom: false,
+        child: expanded
+            ? Row(
+                crossAxisAlignment: CrossAxisAlignment.stretch,
+                children: [navigation, Expanded(child: content)],
+              )
+            : content,
+      );
+
+      return Semantics(
+        container: true,
+        label: '${workspace.label}. Pengguna: ${user.displayName}',
+        child: Scaffold(
+          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
+          body: body,
+          bottomNavigationBar: expanded ? null : navigation,
+        ),
+      );
+    },
+  );
+}
diff --git a/lib/shared/mgrs_components.dart b/lib/shared/mgrs_components.dart
new file mode 100644
index 0000000..54cc104
--- /dev/null
+++ b/lib/shared/mgrs_components.dart
@@ -0,0 +1,251 @@
+import 'package:flutter/material.dart';
+
+import '../app/gateway.dart';
+
+/// Labels and icons that define the destination contract for each workspace.
+class MgrsDestination {
+  const MgrsDestination({
+    required this.label,
+    required this.icon,
+    required this.selectedIcon,
+  });
+
+  final String label;
+  final IconData icon;
+  final IconData selectedIcon;
+}
+
+extension MgrsWorkspacePresentation on MgrsWorkspace {
+  String get label => switch (this) {
+    MgrsWorkspace.pic => 'PIC MGRS',
+    MgrsWorkspace.field => 'Tim Lapangan',
+  };
+
+  List<MgrsDestination> get destinations => switch (this) {
+    MgrsWorkspace.pic => const [
+      MgrsDestination(
+        label: 'Beranda',
+        icon: Icons.space_dashboard_outlined,
+        selectedIcon: Icons.space_dashboard,
+      ),
+      MgrsDestination(
+        label: 'Orderan',
+        icon: Icons.event_note_outlined,
+        selectedIcon: Icons.event_note,
+      ),
+      MgrsDestination(
+        label: 'Invoice',
+        icon: Icons.receipt_long_outlined,
+        selectedIcon: Icons.receipt_long,
+      ),
+      MgrsDestination(
+        label: 'Profil',
+        icon: Icons.person_outline,
+        selectedIcon: Icons.person,
+      ),
+    ],
+    MgrsWorkspace.field => const [
+      MgrsDestination(
+        label: 'Scan',
+        icon: Icons.qr_code_scanner_outlined,
+        selectedIcon: Icons.qr_code_scanner,
+      ),
+      MgrsDestination(
+        label: 'Berkala',
+        icon: Icons.event_repeat_outlined,
+        selectedIcon: Icons.event_repeat,
+      ),
+      MgrsDestination(
+        label: 'Komponen',
+        icon: Icons.inventory_2_outlined,
+        selectedIcon: Icons.inventory_2,
+      ),
+      MgrsDestination(
+        label: 'Riwayat',
+        icon: Icons.history_outlined,
+        selectedIcon: Icons.history,
+      ),
+    ],
+  };
+}
+
+/// Native Material navigation that adapts at the compact/expanded breakpoint.
+class AdaptiveNavigation extends StatelessWidget {
+  const AdaptiveNavigation({
+    super.key,
+    required this.workspace,
+    required this.selectedIndex,
+    required this.onDestinationSelected,
+    this.useRail,
+  });
+
+  final MgrsWorkspace workspace;
+  final int selectedIndex;
+  final ValueChanged<int> onDestinationSelected;
+  /// Primarily used by a parent that already measured the available width.
+  /// When omitted, the component measures itself with [LayoutBuilder].
+  final bool? useRail;
+
+  @override
+  Widget build(BuildContext context) => LayoutBuilder(
+    builder: (context, constraints) {
+      final rail = useRail ?? constraints.maxWidth >= 600;
+      final destinations = workspace.destinations;
+      final index = selectedIndex.clamp(0, destinations.length - 1).toInt();
+      final selected = destinations[index].label;
+      final semanticsLabel =
+          '${workspace.label}, destinasi aktif: $selected';
+      final destinationList = [
+        for (final destination in destinations)
+          NavigationDestination(
+            icon: Icon(destination.icon),
+            selectedIcon: Icon(destination.selectedIcon),
+            label: destination.label,
+          ),
+      ];
+      if (rail) {
+        return Semantics(
+          container: true,
+          label: semanticsLabel,
+          child: NavigationRail(
+            selectedIndex: index,
+            onDestinationSelected: onDestinationSelected,
+            labelType: NavigationRailLabelType.all,
+            destinations: [
+              for (final destination in destinations)
+                NavigationRailDestination(
+                  icon: Icon(destination.icon),
+                  selectedIcon: Icon(destination.selectedIcon),
+                  label: Text(destination.label),
+                ),
+            ],
+          ),
+        );
+      }
+      return Semantics(
+        container: true,
+        label: semanticsLabel,
+        child: NavigationBar(
+          selectedIndex: index,
+          onDestinationSelected: onDestinationSelected,
+          destinations: destinationList,
+        ),
+      );
+    },
+  );
+}
+
+/// The admin-only workspace choice. The two labels are intentionally fixed by
+/// the product contract and do not expose legacy mode names.
+class WorkspaceSwitcher extends StatelessWidget {
+  const WorkspaceSwitcher({
+    super.key,
+    required this.workspace,
+    required this.onWorkspaceChanged,
+  });
+
+  final MgrsWorkspace workspace;
+  final ValueChanged<MgrsWorkspace> onWorkspaceChanged;
+
+  @override
+  Widget build(BuildContext context) {
+    return Semantics(
+      container: true,
+      label: 'Workspace aktif: ${workspace.label}',
+      child: SegmentedButton<MgrsWorkspace>(
+        segments: const [
+          ButtonSegment<MgrsWorkspace>(
+            value: MgrsWorkspace.pic,
+            label: Text('PIC MGRS'),
+            icon: Icon(Icons.assignment_outlined),
+          ),
+          ButtonSegment<MgrsWorkspace>(
+            value: MgrsWorkspace.field,
+            label: Text('Tim Lapangan'),
+            icon: Icon(Icons.build_outlined),
+          ),
+        ],
+        selected: {workspace},
+        onSelectionChanged: (selection) {
+          if (selection.isNotEmpty && selection.first != workspace) {
+            onWorkspaceChanged(selection.first);
+          }
+        },
+      ),
+    );
+  }
+}
+
+/// A persistent form action area that owns saving, disabled, and retry states.
+/// The form remains responsible for validation and submission semantics.
+class SaveActionBar extends StatelessWidget {
+  const SaveActionBar({
+    super.key,
+    required this.onSave,
+    this.isSubmitting = false,
+    this.isDisabled = false,
+    this.onRetry,
+    this.errorMessage,
+    this.label = 'Simpan',
+  });
+
+  final VoidCallback? onSave;
+  final bool isSubmitting;
+  final bool isDisabled;
+  final VoidCallback? onRetry;
+  final String? errorMessage;
+  final String label;
+
+  @override
+  Widget build(BuildContext context) {
+    final disabled = isDisabled || isSubmitting || onSave == null;
+    return Semantics(
+      container: true,
+      label: isSubmitting ? 'Menyimpan perubahan' : 'Aksi penyimpanan',
+        child: SafeArea(
+          top: false,
+          minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
+          child: Column(
+            crossAxisAlignment: CrossAxisAlignment.stretch,
+            children: [
+              if (errorMessage != null) ...[
+                Text(
+                  errorMessage!,
+                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
+                        color: Theme.of(context).colorScheme.error,
+                      ),
+                ),
+                const SizedBox(height: 8),
+              ],
+              Row(
+                children: [
+                  Expanded(
+                    child: FilledButton.icon(
+                      onPressed: disabled ? null : onSave,
+                      icon: isSubmitting
+                          ? const SizedBox.square(
+                              dimension: 18,
+                              child: CircularProgressIndicator(strokeWidth: 2),
+                            )
+                          : const Icon(Icons.save_outlined),
+                      label: Text(isSubmitting ? 'Menyimpan…' : label),
+                    ),
+                  ),
+                  if (onRetry != null) ...[
+                    const SizedBox(width: 12),
+                    Tooltip(
+                      message: 'Coba lagi',
+                      child: OutlinedButton(
+                        onPressed: isSubmitting ? null : onRetry,
+                        child: const Text('Coba lagi'),
+                      ),
+                    ),
+                  ],
+                ],
+              ),
+            ],
+          ),
+        ),
+    );
+  }
+}
diff --git a/lib/shared/pressable.dart b/lib/shared/pressable.dart
index 6e7cd7c..58bf043 100644
--- a/lib/shared/pressable.dart
+++ b/lib/shared/pressable.dart
@@ -1,106 +1,131 @@
 import 'package:flutter/material.dart';
 import 'package:flutter/services.dart';
 
 /// A tactile press feedback wrapper inspired by Emil Kowalski and Apple design principles.
 /// Scales down subtly (default 0.975) on touch down, triggers gentle haptic feedback,
 /// and springs back smoothly on release.
+/// Provides accessible Material press feedback for custom content.
+///
+/// Use a real Material button when the control is a button. This wrapper is
+/// intended for cards and other custom surfaces that still need tap semantics.
 class PressableScale extends StatefulWidget {
   const PressableScale({
     super.key,
     required this.child,
     this.onTap,
     this.onLongPress,
     this.pressedScale = 0.975,
     this.duration = const Duration(milliseconds: 120),
     this.curve = Curves.easeOutCubic,
     this.enabled = true,
     this.enableHaptic = true,
+    this.tooltip,
   });
 
   final Widget child;
   final VoidCallback? onTap;
   final VoidCallback? onLongPress;
   final double pressedScale;
   final Duration duration;
   final Curve curve;
   final bool enabled;
   final bool enableHaptic;
+  final String? tooltip;
 
   @override
   State<PressableScale> createState() => _PressableScaleState();
 }
 
 class _PressableScaleState extends State<PressableScale>
     with SingleTickerProviderStateMixin {
   late final AnimationController _controller;
   late final Animation<double> _scaleAnimation;
 
+  bool get _hasAction => widget.onTap != null || widget.onLongPress != null;
+  bool get _isInteractive => widget.enabled && _hasAction;
+
   @override
   void initState() {
     super.initState();
     _controller = AnimationController(
       vsync: this,
       duration: widget.duration,
       reverseDuration: widget.duration,
-      value: 0.0,
+      value: 0,
     );
     _scaleAnimation = Tween<double>(
-      begin: 1.0,
+      begin: 1,
       end: widget.pressedScale,
-    ).animate(CurvedAnimation(
-      parent: _controller,
-      curve: widget.curve,
-      reverseCurve: Curves.easeOutBack,
-    ));
+    ).animate(
+      CurvedAnimation(
+        parent: _controller,
+        curve: widget.curve,
+        reverseCurve: Curves.easeOutBack,
+      ),
+    );
   }
 
   @override
   void dispose() {
     _controller.dispose();
     super.dispose();
   }
 
   void _handleTapDown(TapDownDetails _) {
-    if (!widget.enabled || (widget.onTap == null && widget.onLongPress == null)) {
-      return;
-    }
-    if (widget.enableHaptic) {
-      HapticFeedback.lightImpact();
-    }
+    if (!_isInteractive) return;
+    if (widget.enableHaptic) HapticFeedback.lightImpact();
     _controller.forward();
   }
 
   void _handleTapUp(TapUpDetails _) {
-    if (!widget.enabled || widget.onTap == null) return;
+    if (!_isInteractive) return;
     _controller.reverse();
   }
 
   void _handleTapCancel() {
-    if (!widget.enabled || widget.onTap == null) return;
+    if (!_isInteractive) return;
     _controller.reverse();
   }
 
   @override
   Widget build(BuildContext context) {
-    if (!widget.enabled || (widget.onTap == null && widget.onLongPress == null)) {
-      return widget.child;
-    }
+    if (!_hasAction) return widget.child;
 
-    return GestureDetector(
-      behavior: HitTestBehavior.opaque,
-      onTapDown: _handleTapDown,
-      onTapUp: _handleTapUp,
-      onTapCancel: _handleTapCancel,
-      onTap: widget.onTap,
-      onLongPress: widget.onLongPress,
-      child: AnimatedBuilder(
-        animation: _scaleAnimation,
-        builder: (context, child) => Transform.scale(
-          scale: _scaleAnimation.value,
-          child: child,
-        ),
-        child: widget.child,
+    final reducedMotion =
+        MediaQuery.maybeOf(context)?.disableAnimations ?? false;
+    final visual = reducedMotion
+        ? widget.child
+        : AnimatedBuilder(
+            animation: _scaleAnimation,
+            builder: (context, child) => Transform.scale(
+              scale: _scaleAnimation.value,
+              child: child,
+            ),
+            child: widget.child,
+          );
+    final interactiveSurface = ConstrainedBox(
+      constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
+      child: Center(child: visual),
+    );
+    final material = Material(
+      type: MaterialType.transparency,
+      child: InkWell(
+        onTap: _isInteractive ? widget.onTap : null,
+        onLongPress: _isInteractive ? widget.onLongPress : null,
+        onTapDown: _isInteractive ? _handleTapDown : null,
+        onTapUp: _isInteractive ? _handleTapUp : null,
+        onTapCancel: _isInteractive ? _handleTapCancel : null,
+        child: interactiveSurface,
       ),
     );
+    final semantics = Semantics(
+      button: true,
+      enabled: _isInteractive,
+      child: material,
+    );
+    return widget.tooltip == null
+        ? semantics
+        : Tooltip(message: widget.tooltip!, child: semantics);
   }
+
 }
diff --git a/test/widget_shared_components_test.dart b/test/widget_shared_components_test.dart
new file mode 100644
index 0000000..f9fd0e6
--- /dev/null
+++ b/test/widget_shared_components_test.dart
@@ -0,0 +1,334 @@
+import 'dart:async';
+
+import 'package:flutter/material.dart';
+import 'package:flutter_test/flutter_test.dart';
+import 'package:mgrs_maintenance/app/app_theme.dart';
+import 'package:mgrs_maintenance/app/gateway.dart';
+import 'package:mgrs_maintenance/shared/async_state_view.dart';
+import 'package:mgrs_maintenance/shared/mgrs_components.dart';
+import 'package:mgrs_maintenance/shared/mgrs_app_shell.dart';
+import 'package:mgrs_maintenance/shared/pressable.dart';
+
+void main() {
+  testWidgets('theme gives primary controls a 48dp minimum', (tester) async {
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: FilledButton(onPressed: () {}, child: const Text('Simpan')),
+      ),
+    );
+
+    final size = tester.getSize(find.byType(FilledButton));
+    expect(size.height, greaterThanOrEqualTo(48));
+  });
+
+  testWidgets('theme exposes semantic light and dark roles', (tester) async {
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: const SizedBox(key: Key('theme-home')),
+      ),
+    );
+    final lightContext = tester.element(find.byKey(const Key('theme-home')));
+    expect(Theme.of(lightContext).colorScheme.primary, AppTokens.actionBlue);
+    expect(Theme.of(lightContext).scaffoldBackgroundColor, AppTokens.canvas);
+    final lightTheme = maintenanceTheme();
+    expect(lightTheme.textTheme.headlineMedium?.fontSize, 30);
+    expect(lightTheme.textTheme.headlineSmall?.fontSize, 28);
+    expect(lightTheme.textTheme.titleLarge?.fontSize, 24);
+    expect(lightTheme.textTheme.titleMedium?.fontSize, 22);
+    expect(lightTheme.textTheme.titleSmall?.fontSize, 20);
+
+    final darkTheme = maintenanceDarkTheme();
+    expect(darkTheme.brightness, Brightness.dark);
+    expect(darkTheme.colorScheme.primary, AppTokens.actionBlueFocus);
+    expect(darkTheme.scaffoldBackgroundColor, AppTokens.surfaceBlack);
+  });
+
+  testWidgets('adaptive navigation uses bar on compact and rail when expanded',
+      (tester) async {
+    var selected = -1;
+    Widget buildAt(double width) => MaterialApp(
+          theme: maintenanceTheme(),
+          home: Align(
+            alignment: Alignment.topLeft,
+            child: SizedBox(
+              width: width,
+              height: 800,
+              child: AdaptiveNavigation(
+                workspace: MgrsWorkspace.pic,
+                selectedIndex: 0,
+                onDestinationSelected: (value) => selected = value,
+              ),
+            ),
+          ),
+        );
+
+    await tester.pumpWidget(buildAt(500));
+    expect(find.byType(NavigationBar), findsOneWidget);
+    expect(find.byType(NavigationRail), findsNothing);
+    await tester.tap(find.text('Orderan'));
+    expect(selected, 1);
+
+    await tester.pumpWidget(buildAt(600));
+    expect(find.byType(NavigationRail), findsOneWidget);
+    expect(find.byType(NavigationBar), findsNothing);
+  });
+
+  testWidgets('workspace switcher presents exactly the two workspace labels',
+      (tester) async {
+    MgrsWorkspace? changed;
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: WorkspaceSwitcher(
+          workspace: MgrsWorkspace.pic,
+          onWorkspaceChanged: (value) => changed = value,
+        ),
+      ),
+    );
+
+    expect(find.text('PIC MGRS'), findsOneWidget);
+    expect(find.text('Tim Lapangan'), findsOneWidget);
+    await tester.tap(find.text('Tim Lapangan'));
+    expect(changed, MgrsWorkspace.field);
+  });
+
+  testWidgets('admin shell requires and renders its workspace switcher',
+      (tester) async {
+    const admin = UserProfile('admin', 'Admin', fullName: 'Admin MGRS');
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: MGRSAppShell(
+          workspace: MgrsWorkspace.pic,
+          user: admin,
+          selectedIndex: 0,
+          onDestinationSelected: (_) {},
+          child: const SizedBox(),
+        ),
+      ),
+    );
+    expect(tester.takeException(), isA<AssertionError>());
+
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: MGRSAppShell(
+          workspace: MgrsWorkspace.pic,
+          user: admin,
+          selectedIndex: 0,
+          onDestinationSelected: (_) {},
+          onWorkspaceChanged: (_) {},
+          child: const ColoredBox(color: Colors.white),
+        ),
+      ),
+    );
+    expect(find.byType(WorkspaceSwitcher), findsOneWidget);
+    expect(
+      find.ancestor(
+        of: find.byType(NavigationRail),
+        matching: find.byType(SafeArea),
+      ),
+      findsOneWidget,
+    );
+  });
+
+  testWidgets('async state view renders an explicit empty builder',
+      (tester) async {
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: AsyncStateView<List<String>>(
+          future: Future.value(const <String>[]),
+          retry: () {},
+          isEmpty: (value) => value.isEmpty,
+          empty: () => const Text('Tidak ada order'),
+          builder: (value) => Text(value.single),
+        ),
+      ),
+    );
+    await tester.pumpAndSettle();
+    expect(find.text('Tidak ada order'), findsOneWidget);
+  });
+
+  testWidgets('explicit empty predicate overrides compatibility inference',
+      (tester) async {
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: AsyncStateView<List<String>>(
+          future: Future.value(const <String>[]),
+          retry: () {},
+          isEmpty: (_) => false,
+          empty: () => const Text('Tidak ada order'),
+          builder: (_) => const Text('Daftar sengaja kosong'),
+        ),
+      ),
+    );
+    await tester.pumpAndSettle();
+    expect(find.text('Daftar sengaja kosong'), findsOneWidget);
+    expect(find.text('Tidak ada order'), findsNothing);
+  });
+
+  testWidgets('explicit predicate can keep a nullable null value', (tester) async {
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: AsyncStateView<String?>(
+          future: Future<String?>.value(null),
+          retry: () {},
+          isEmpty: (_) => false,
+          builder: (value) => Text(value ?? 'Nilai null dipertahankan'),
+        ),
+      ),
+    );
+    await tester.pumpAndSettle();
+    expect(find.text('Nilai null dipertahankan'), findsOneWidget);
+  });
+
+  testWidgets('async state view renders error and permission states',
+      (tester) async {
+    final permission = Completer<String>();
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: AsyncStateView<String>(
+          future: permission.future,
+          retry: () {},
+          builder: Text.new,
+        ),
+      ),
+    );
+    permission.completeError(const AppFailure('forbidden'));
+    await tester.pump();
+    await tester.pump();
+    expect(find.text('Akses tidak tersedia'), findsOneWidget);
+
+    final failure = Completer<String>();
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: AsyncStateView<String>(
+          future: failure.future,
+          retry: () {},
+          error: (error) => const Text('Coba kembali nanti'),
+          builder: Text.new,
+        ),
+      ),
+    );
+    failure.completeError(const AppFailure('network'));
+    await tester.pump();
+    await tester.pump();
+    expect(find.text('Coba kembali nanti'), findsOneWidget);
+  });
+
+  testWidgets('pressable exposes button semantics and respects reduced motion',
+      (tester) async {
+    var taps = 0;
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: MediaQuery(
+          data: const MediaQueryData(disableAnimations: true),
+          child: PressableScale(
+            onTap: () => taps++,
+            child: const Text('Tekan'),
+          ),
+        ),
+      ),
+    );
+
+    expect(find.byType(Transform), findsNothing);
+    final semantics = tester.getSemantics(find.text('Tekan'));
+    expect(semantics.flagsCollection.isButton, isTrue);
+    await tester.tap(find.text('Tekan'));
+    expect(taps, 1);
+  });
+
+  testWidgets('pressable meets the touch target without affecting passive layout',
+      (tester) async {
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: Column(
+          children: [
+            PressableScale(
+              key: const Key('interactive-pressable'),
+              onTap: () {},
+              child: const SizedBox(width: 12, height: 20),
+            ),
+            PressableScale(
+              key: const Key('passive-pressable'),
+              child: const SizedBox(width: 12, height: 20),
+            ),
+          ],
+        ),
+      ),
+    );
+    final interactiveSize =
+        tester.getSize(find.byKey(const Key('interactive-pressable')));
+    expect(interactiveSize.width, greaterThanOrEqualTo(48));
+    expect(interactiveSize.height, greaterThanOrEqualTo(48));
+    expect(
+      tester.getSize(find.byKey(const Key('passive-pressable'))),
+      const Size(12, 20),
+    );
+  });
+
+  testWidgets('disabled pressable keeps its target and disabled semantics',
+      (tester) async {
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: PressableScale(
+          key: const Key('disabled-pressable'),
+          enabled: false,
+          onTap: () {},
+          child: const SizedBox(width: 12, height: 20),
+        ),
+      ),
+    );
+    final size = tester.getSize(find.byKey(const Key('disabled-pressable')));
+    expect(size.width, greaterThanOrEqualTo(48));
+    expect(size.height, greaterThanOrEqualTo(48));
+    final semantics = tester.getSemantics(
+      find.byKey(const Key('disabled-pressable')),
+    );
+    expect(semantics.flagsCollection.isButton, isTrue);
+    expect(semantics.flagsCollection.isEnabled, isNot(isTrue));
+  });
+
+  testWidgets('save action bar owns submitting and retry presentation',
+      (tester) async {
+    var retried = false;
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: SaveActionBar(
+          onSave: () {},
+          isSubmitting: true,
+          onRetry: () => retried = true,
+          errorMessage: 'gagal',
+        ),
+      ),
+    );
+    expect(find.text('Menyimpan…'), findsOneWidget);
+    expect(find.text('Coba lagi'), findsOneWidget);
+    expect(tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
+        isNull);
+
+    await tester.pumpWidget(
+      MaterialApp(
+        theme: maintenanceTheme(),
+        home: SaveActionBar(
+          onSave: () {},
+          onRetry: () => retried = true,
+          errorMessage: 'gagal',
+        ),
+      ),
+    );
+    await tester.tap(find.text('Coba lagi'));
+    expect(retried, isTrue);
+  });
+}
