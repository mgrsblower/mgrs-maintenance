import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/schedule/order_model.dart';

Map<String, Object?> jsonObject(Object? value) {
  if (value is! Map) throw const FormatException('Expected object');
  return Map<String, Object?>.from(value);
}

List<Map<String, Object?>> jsonItems(Object? value) {
  if (value is! List) throw const FormatException('Expected list');
  return value.map(jsonObject).toList();
}

class UserProfile {
  const UserProfile(
    this.id,
    this.role, {
    this.fullName,
    this.username,
  });

  final String id;
  final String role;
  final String? fullName;
  final String? username;

  static const roles = {'Admin', 'Tim Service', 'Tim Pemasangan'};

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim();
    }
    return role == 'Admin' ? 'Admin MGRS' : 'Petugas Maintenance';
  }

  String get initials {
    final name = displayName;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
    return 'PM';
  }
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
    'ambiguous' =>
      'Ditemukan lebih dari satu komponen dengan kode tersebut. Periksa kembali nomor stiker.',
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

  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
  }) async => const [];

  Future<Map<String, Object?>> fetchTasksSummary({
    String periodId = 'current',
  }) async => const {};

  Future<List<Map<String, Object?>>> fetchComponentHistory(
    String componentId, {
    int limit = 20,
  }) async => const [];

  Future<List<OrderanSewa>> fetchUpcomingOrders({int limit = 10}) async =>
      const [];

  Future<OrderanSewa?> fetchOrderDetail(String id) async => null;
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
        .select('id,role,is_active,full_name,username')
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
    return UserProfile(
      user.id,
      row['role'] as String,
      fullName: row['full_name'] as String?,
      username: row['username'] as String?,
    );
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

  @override
  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
  }) async {
    try {
      dynamic builder = client.from('master_komponen').select();
      if (kind != null && kind.isNotEmpty && kind != 'Semua') {
        builder = builder.eq('jenis_komponen', kind);
      }
      if (query != null && query.trim().isNotEmpty) {
        final q = query.trim();
        builder = builder.or('nomor_stiker.ilike.%$q%,komponen_id.ilike.%$q%');
      }
      final res =
          await builder.order('nomor_stiker').timeout(const Duration(seconds: 15));
      if (res is List) {
        return res.map(jsonObject).toList();
      }
      return const [];
    } on PostgrestException catch (e) {
      if (e.message == 'unauthenticated' || e.message == 'forbidden') {
        await signOut();
      }
      throw AppFailure(e.message);
    } on TimeoutException {
      throw const AppFailure('network');
    }
  }

  @override
  Future<Map<String, Object?>> fetchTasksSummary({
    String periodId = 'current',
  }) async {
    final res = await rpc('maintenance_list_tasks', {
      'p_period_id': periodId,
      'p_limit': 100,
    });
    if (res is Map) {
      return jsonObject(res);
    }
    return const {};
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponentHistory(
    String componentId, {
    int limit = 20,
  }) async {
    final res = await rpc('maintenance_list_history', {
      'p_component_id': componentId,
      'p_limit': limit,
    });
    if (res is Map && res['items'] is List) {
      return (res['items'] as List).map(jsonObject).toList();
    }
    return const [];
  }

  @override
  Future<List<OrderanSewa>> fetchUpcomingOrders({int limit = 10}) async {
    try {
      final res = await client
          .from('orderan_sewa')
          .select(
            'id,orderan_id,tanggal_pemasangan,nama_event,nama_client,alamat,nomor_whatsapp,link_gmaps,nama_pic,jumlah_unit,status_orderan,catatan_orderan,created_at',
          )
          .order('tanggal_pemasangan', ascending: true)
          .limit(limit);
      return res
          .map((item) => OrderanSewa.fromJson(jsonObject(item)))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<OrderanSewa?> fetchOrderDetail(String id) async {
    try {
      final res = await client
          .from('orderan_sewa')
          .select(
            'id,orderan_id,tanggal_pemasangan,nama_event,nama_client,alamat,nomor_whatsapp,link_gmaps,nama_pic,jumlah_unit,status_orderan,catatan_orderan,created_at',
          )
          .eq('id', id)
          .maybeSingle();
      if (res != null) {
        return OrderanSewa.fromJson(jsonObject(res));
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
