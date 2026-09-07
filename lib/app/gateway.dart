import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';

Map<String, Object?> jsonObject(Object? value) {
  if (value is! Map) throw const FormatException('Expected object');
  return Map<String, Object?>.from(value);
}

List<Map<String, Object?>> jsonItems(Object? value) {
  if (value is! List) throw const FormatException('Expected list');
  return value.map(jsonObject).toList();
}

class UserProfile {
  const UserProfile(this.id, this.role);
  final String id;
  final String role;
  static const roles = {'Admin', 'Tim Service', 'Tim Pemasangan'};
}

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
    'invalid_input' =>
      'Periksa kembali hasil pemeriksaan dan kolom yang wajib diisi.',
    'task_already_completed' =>
      'Pemeriksaan bulan ini sudah diselesaikan oleh petugas lain.',
    'task_not_open' => 'Jadwal pemeriksaan ini belum dimulai.',
    'component_unavailable' =>
      'Komponen belum dapat dinyatakan selesai diperiksa.',
    'request_mismatch' =>
      'Periksa hasil penyimpanan sebelumnya sebelum membuat catatan baru.',
    'unavailable' => 'Fitur ini belum tersedia. Hubungi admin.',
    'network' => 'Koneksi terputus. Periksa jaringan lalu coba lagi.',
    _ => 'Data belum dapat diproses. Silakan coba lagi.',
  };
}

String failureMessage(Object? error) =>
    error is AppFailure ? error.message : const AppFailure('unknown').message;

abstract class MaintenanceGateway {
  Stream<void> get authChanges;
  Future<UserProfile?> profile();
  Future<void> signIn(String identifier, String password);
  Future<void> signOut();
  Future<Object?> rpc(String name, Map<String, Object?> params);
}

class SupabaseGateway extends MaintenanceGateway {
  SupabaseGateway(this.client);
  final SupabaseClient client;
  @override
  Stream<void> get authChanges =>
      client.auth.onAuthStateChange.map<void>((_) {});
  @override
  Future<UserProfile?> profile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final row = await client
        .from('profiles')
        .select('id,role,is_active')
        .eq('id', user.id)
        .maybeSingle()
        .timeout(const Duration(seconds: 15));
    if (client.auth.currentUser?.id != user.id) return null;
    if (row == null ||
        row['is_active'] != true ||
        !UserProfile.roles.contains(row['role'])) {
      await signOut();
      throw const AppFailure('forbidden');
    }
    return UserProfile(user.id, row['role'] as String);
  }

  @override
  Future<void> signIn(String identifier, String password) async {
    try {
      final response = await client.functions
          .invoke(
            'flutter-auth-login',
            body: {'identifier': identifier.trim(), 'password': password},
          )
          .timeout(const Duration(seconds: 20));
      final body = jsonObject(response.data);
      if (body['success'] != true) {
        throw const AppFailure('invalid_credentials');
      }
      final session = jsonObject(body['session']);
      final user = jsonObject(body['user']);
      final returnedProfile = jsonObject(body['profile']);
      if (user['id'] != returnedProfile['id'] ||
          returnedProfile['is_active'] != true ||
          !UserProfile.roles.contains(returnedProfile['role'])) {
        throw const AppFailure('forbidden');
      }
      await client.auth.setSession(
        session['refresh_token'] as String,
        accessToken: session['access_token'] as String,
      );
      if (client.auth.currentUser?.id != user['id']) {
        await signOut();
        throw const AppFailure('unauthenticated');
      }
      await profile();
    } on FunctionException {
      throw const AppFailure('invalid_credentials');
    } on TimeoutException {
      throw const AppFailure('network');
    }
  }

  @override
  Future<void> signOut() => client.auth.signOut(scope: SignOutScope.local);
  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    try {
      return await client
          .rpc(name, params: params)
          .timeout(const Duration(seconds: 20));
    } on PostgrestException catch (e) {
      if (e.message == 'unauthenticated' || e.message == 'forbidden') {
        await signOut();
      }
      if (e.code == 'PGRST202') throw const AppFailure('unavailable');
      throw AppFailure(e.message);
    } on TimeoutException {
      throw const AppFailure('network');
    }
  }
}
