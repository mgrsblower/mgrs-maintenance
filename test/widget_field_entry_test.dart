import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app_theme.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/components/asset_catalog_screen.dart';
import 'package:mgrs_maintenance/features/components/component_detail_screen.dart';
import 'package:mgrs_maintenance/features/scan/scan_screen.dart';

class _RecordingFieldGateway extends MaintenanceGateway {
  _RecordingFieldGateway();

  final List<String> maintenanceWrites = [];

  @override
  Stream<void> get authChanges => const Stream.empty();

  @override
  Future<UserProfile?> profile() async => null;

  @override
  Future<void> signIn(String identifier, String password) async {}

  @override
  Future<void> signOut() async {}

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    if (name.startsWith('maintenance_record') ||
        name.startsWith('maintenance_update') ||
        name.startsWith('maintenance_save')) {
      maintenanceWrites.add(name);
    }
    if (name == 'maintenance_get_component') {
      return {
        'id': 'comp-101',
        'code': 'KPL-001',
        'kind': 'Kepala',
        'condition': 'OK',
        'usable': 'Ya',
        'impairedFunction': 'Tidak Ada',
        'version': '1',
      };
    }
    if (name == 'maintenance_lookup_component') {
      final code = params['p_code'];
      return [
        {
          'id': 'comp-101',
          'code': code ?? 'KPL-001',
          'kind': 'Kepala',
          'condition': 'OK',
          'usable': 'Ya',
          'impairedFunction': 'Tidak Ada',
          'version': '1',
        }
      ];
    }
    return null;
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponentHistory(
    String componentId, {
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    return [];
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponentOrderUsageHistory(
    String code, {
    bool forceRefresh = false,
  }) async {
    return [];
  }
  @override
  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
    bool forceRefresh = false,
  }) async {
    return [];
  }
}

const _techUser = UserProfile(
  'tech-1',
  'Teknisi Lapangan',
  fullName: 'Budi Teknisi',
);

Widget _wrap(Widget child) {
  return MaterialApp(
    theme: maintenanceTheme(),
    home: child,
  );
}

void main() {
  testWidgets(
      'component detail exposes maintenance actions without recording on open',
      (tester) async {
    final gateway = _RecordingFieldGateway();
    await tester.pumpWidget(
      _wrap(
        ComponentDetailScreen(
          gateway: gateway,
          id: 'comp-101',
          user: _techUser,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Catat Pemeriksaan'), findsOneWidget);
    expect(find.text('Catat Servis'), findsOneWidget);
    expect(gateway.maintenanceWrites, isEmpty);

    final backBtn = find.byTooltip('Kembali');
    expect(tester.getSize(backBtn).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(backBtn).height, greaterThanOrEqualTo(48));
  });

  testWidgets(
      'manual code entry remains available when camera is unavailable',
      (tester) async {
    final gateway = _RecordingFieldGateway();
    await tester.pumpWidget(
      _wrap(
        ScanScreen(
          gateway: gateway,
          user: _techUser,
          cameraUnavailable: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Masukkan kode manual'), findsOneWidget);
    expect(find.byTooltip('Coba lagi'), findsOneWidget);

    final retryBtn = find.byTooltip('Coba lagi');
    expect(tester.getSize(retryBtn).height, greaterThanOrEqualTo(48));
  });

  testWidgets(
      'manual code entry dialog triggers component lookup',
      (tester) async {
    final gateway = _RecordingFieldGateway();
    await tester.pumpWidget(
      _wrap(
        ScanScreen(
          gateway: gateway,
          user: _techUser,
          cameraUnavailable: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Masukkan kode manual'));
    await tester.pumpAndSettle();

    expect(find.text('Kode Komponen'), findsOneWidget);
    await tester.enterText(find.byType(TextFormField), 'KPL-001');
    await tester.tap(find.text('Cari'));
    await tester.pumpAndSettle();

    expect(find.text('LAYAK PAKAI'), findsOneWidget);
    expect(find.text('KPL-001'), findsOneWidget);
  });

  testWidgets(
      'asset catalog renders empty state explicitly and provides 48dp filter button',
      (tester) async {
    final gateway = _RecordingFieldGateway();
    await tester.pumpWidget(
      _wrap(
        AssetCatalogScreen(
          gateway: gateway,
          user: _techUser,
          onNavigateToTab: (_) {},
          onOpenScanner: () {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tidak ada komponen ditemukan'), findsOneWidget);
    final filterBtn = find.byTooltip('Filter komponen');
    expect(find.byTooltip('Filter komponen'), findsOneWidget);
    expect(tester.getSize(filterBtn).width, greaterThanOrEqualTo(48));
    expect(tester.getSize(filterBtn).height, greaterThanOrEqualTo(48));
  });
}
