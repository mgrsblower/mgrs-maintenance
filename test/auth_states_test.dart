import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mgrs_maintenance/app/app.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/features/auth/login_screen.dart';

class AuthGateway extends MaintenanceGateway {
  AuthGateway({this.profileResult, this.profileError, this.signInError});

  UserProfile? profileResult;
  Object? profileError;
  Object? signInError;
  Object? signOutError;
  bool emitAuthOnProfileError = false;
  final authController = StreamController<void>.broadcast();
  Completer<void>? signInCompleter;
  int signInCalls = 0;
  int signOutCalls = 0;

  @override
  Stream<void> get authChanges => authController.stream;

  @override
  Future<UserProfile?> profile() async {
    if (profileError case final error?) {
      if (emitAuthOnProfileError) authController.add(null);
      throw error;
    }
    return profileResult;
  }

  @override
  Future<void> signIn(String identifier, String password) async {
    signInCalls++;
    if (signInCompleter case final completer?) await completer.future;
    if (signInError case final error?) throw error;
  }

  @override
  Future<void> signOut() async {
    signOutCalls++;
    if (signOutError case final error?) throw error;
    profileError = null;
    profileResult = null;
  }

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async => null;

  Future<void> dispose() => authController.close();
}

void main() {
  testWidgets('login validates empty credentials with approved copy', (
    tester,
  ) async {
    final gateway = AuthGateway();
    addTearDown(gateway.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(gateway: gateway, onSignedIn: () {}),
      ),
    );

    expect(find.text('Masuk ke MGRS'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump();
    expect(find.text('Masukkan email atau username.'), findsOneWidget);
    expect(find.text('Masukkan kata sandi.'), findsOneWidget);
    expect(gateway.signInCalls, 0);
  });

  testWidgets('failed sign-in keeps values and masks technical exceptions', (
    tester,
  ) async {
    final gateway = AuthGateway(signInError: StateError('database details'));
    addTearDown(gateway.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(gateway: gateway, onSignedIn: () {}),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'operator');
    await tester.enterText(find.byType(TextFormField).last, 'rahasia');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump();

    expect(
      find.text('Data belum dapat diproses. Silakan coba lagi.'),
      findsOneWidget,
    );
    expect(find.textContaining('StateError'), findsNothing);
    expect(find.textContaining('database details'), findsNothing);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller
          ?.text,
      'operator',
    );
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).last)
          .controller
          ?.text,
      'rahasia',
    );
  });

  testWidgets('invalid credentials use safe user-facing copy', (tester) async {
    final gateway = AuthGateway(
      signInError: const AppFailure('invalid_credentials'),
    );
    addTearDown(gateway.dispose);
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(gateway: gateway, onSignedIn: () {}),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'operator');
    await tester.enterText(find.byType(TextFormField).last, 'salah');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump();
    expect(find.text('Akun atau kata sandi tidak sesuai.'), findsOneWidget);
  });

  testWidgets('loading disables duplicate login submission', (tester) async {
    final gateway = AuthGateway()..signInCompleter = Completer<void>();
    addTearDown(gateway.dispose);
    var signedIn = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(gateway: gateway, onSignedIn: () => signedIn++),
      ),
    );

    await tester.enterText(find.byType(TextFormField).first, 'operator');
    await tester.enterText(find.byType(TextFormField).last, 'rahasia');
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk'));
    await tester.pump();
    expect(find.bySemanticsLabel('Sedang memproses Masuk'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );
    await tester.tap(find.byType(FilledButton));
    expect(gateway.signInCalls, 1);
    gateway.signInCompleter!.complete();
    await tester.pump();
    expect(signedIn, 1);
  });

  testWidgets('session expiry offers explicit login recovery', (tester) async {
    final gateway = AuthGateway(
      profileResult: const UserProfile('user-1', 'Tim Service'),
      profileError: const AppFailure('unauthenticated'),
    );
    addTearDown(gateway.dispose);
    await tester.pumpWidget(MaintenanceApp(gateway: gateway));
    await tester.pumpAndSettle();

    expect(find.text('Sesi Anda telah berakhir'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Masuk kembali'), findsOneWidget);
    await tester.tap(find.widgetWithText(FilledButton, 'Masuk kembali'));
    await tester.pump();
    expect(find.text('Masuk ke MGRS'), findsOneWidget);
  });

  testWidgets('forbidden access survives the sign-out auth event race', (
    tester,
  ) async {
    final gateway = AuthGateway(
      profileResult: const UserProfile('user-1', 'Tim Service'),
      profileError: const AppFailure('forbidden'),
    )..emitAuthOnProfileError = true;
    addTearDown(gateway.dispose);
    await tester.pumpWidget(MaintenanceApp(gateway: gateway));
    await tester.pumpAndSettle();

    expect(find.text('Akses akun ditolak'), findsOneWidget);
    expect(find.widgetWithText(FilledButton, 'Keluar'), findsOneWidget);
  });

  testWidgets('failed forbidden sign out remains recoverable', (tester) async {
    final gateway = AuthGateway(profileError: const AppFailure('forbidden'))
      ..signOutError = StateError('provider details');
    addTearDown(gateway.dispose);
    await tester.pumpWidget(MaintenanceApp(gateway: gateway));
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Keluar'));
    await tester.pump();
    expect(
      find.text(
        'Akun belum dapat dikeluarkan. Periksa koneksi lalu coba lagi.',
      ),
      findsOneWidget,
    );
    expect(find.textContaining('provider details'), findsNothing);
    expect(find.widgetWithText(FilledButton, 'Keluar'), findsOneWidget);
  });

  testWidgets('forbidden access offers sign out and masks raw exception', (
    tester,
  ) async {
    final gateway = AuthGateway(
      profileResult: const UserProfile('user-1', 'Tim Service'),
      profileError: const AppFailure('forbidden'),
    );
    addTearDown(gateway.dispose);
    await tester.pumpWidget(MaintenanceApp(gateway: gateway));
    await tester.pumpAndSettle();

    expect(find.text('Akses akun ditolak'), findsOneWidget);
    expect(find.textContaining('AppFailure'), findsNothing);
    await tester.tap(find.widgetWithText(FilledButton, 'Keluar'));
    await tester.pumpAndSettle();
    expect(gateway.signOutCalls, 1);
    expect(find.text('Masuk ke MGRS'), findsOneWidget);
  });
}
