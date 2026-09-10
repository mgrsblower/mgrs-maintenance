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

class _CacheEntry<T> {
  _CacheEntry(this.data, this.expiresAt);
  final T data;
  final DateTime expiresAt;
  bool get isValid => DateTime.now().isBefore(expiresAt);
}

abstract class MaintenanceGateway {
  Stream<void> get authChanges;
  Future<UserProfile?> profile();
  Future<void> signIn(String identifier, String password);
  Future<void> signOut();
  Future<Object?> rpc(String name, Map<String, Object?> params);

  void invalidateCache([String? prefix]) {}

  Future<List<Map<String, Object?>>> fetchComponents({
    String? kind,
    String? query,
    bool forceRefresh = false,
  }) async => const [];

  Future<Map<String, Object?>> fetchTasksSummary({
    String periodId = 'current',
    bool forceRefresh = false,
  }) async => const {};

  Future<List<Map<String, Object?>>> fetchComponentHistory(
    String componentId, {
    int limit = 20,
    bool forceRefresh = false,
  }) async => const [];

  Future<List<OrderanSewa>> fetchUpcomingOrders({
    int limit = 10,
    bool forceRefresh = false,
  }) async => const [];

  Future<OrderanSewa?> fetchOrderDetail(
    String id, {
    bool forceRefresh = false,
  }) async => null;
}

class SupabaseGateway extends MaintenanceGateway {
  SupabaseGateway(this.client);
  final SupabaseClient client;

  static const Duration defaultTtl = Duration(minutes: 5);
  final Map<String, _CacheEntry<dynamic>> _cache = {};

  @override
  void invalidateCache([String? prefix]) {
    if (prefix == null) {
      _cache.clear();
    } else {
      _cache.removeWhere((key, _) => key.startsWith(prefix));
    }
  }

  T? _getFromCache<T>(String key) {
    final entry = _cache[key];
    if (entry != null && entry.isValid && entry.data is T) {
      return entry.data as T;
    }
    _cache.remove(key);
    return null;
  }

  void _saveToCache<T>(String key, T data, [Duration ttl = defaultTtl]) {
    _cache[key] = _CacheEntry(data, DateTime.now().add(ttl));
  }

  @override
  Stream<void> get authChanges =>
      client.auth.onAuthStateChange.map<void>((_) {});
  @override
  Future<UserProfile?> profile() async {
    final user = client.auth.currentUser;
    if (user == null) return null;
    final row = await client
        .from('profiles')
        .select('id,role,full_name,username')
        .eq('id', user.id)
        .maybeSingle();
    final role = (row?['role'] ?? '').toString();
    if (!UserProfile.roles.contains(role)) {
      await signOut();
      throw const AppFailure('forbidden');
    }
    return UserProfile(
      user.id,
      role,
      fullName: (row?['full_name'] ?? '').toString(),
      username: (row?['username'] ?? '').toString(),
    );
  }

  @override
  Future<void> signIn(String identifier, String password) async {
    final normalized = identifier.trim().toLowerCase();
    String? email;
    if (normalized.contains('@')) {
      email = normalized;
    } else {
      final rows = await client
          .from('profiles')
          .select('email')
          .eq('username', normalized)
          .limit(1);
      if (rows.isNotEmpty) {
        email = (rows.first['email'] ?? '').toString();
      }
    }
    if (email == null || email.isEmpty) {
      throw const AppFailure('invalid_credentials');
    }
    try {
      await client.auth.signInWithPassword(email: email, password: password);
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw const AppFailure('invalid_credentials');
      }
      throw AppFailure(e.message);
    } on FunctionException {
      throw const AppFailure('invalid_credentials');
    } on TimeoutException {
      throw const AppFailure('network');
    }
  }

  @override
  Future<void> signOut() {
    invalidateCache();
    return client.auth.signOut(scope: SignOutScope.local);
  }

  @override
  Future<Object?> rpc(String name, Map<String, Object?> params) async {
    try {
      final res = await client
          .rpc(name, params: params)
          .timeout(const Duration(seconds: 20));
      if (name.contains('submit') ||
          name.contains('update') ||
          name.contains('insert') ||
          name.contains('delete')) {
        invalidateCache();
      }
      return res;
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
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'components:${kind ?? ''}:${query ?? ''}';
    if (!forceRefresh) {
      final cached = _getFromCache<List<Map<String, Object?>>>(cacheKey);
      if (cached != null) return cached;
    }
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
        final items = res.map(jsonObject).toList();
        _saveToCache(cacheKey, items);
        return items;
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
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'tasks_summary:$periodId';
    if (!forceRefresh) {
      final cached = _getFromCache<Map<String, Object?>>(cacheKey);
      if (cached != null) return cached;
    }
    final res = await rpc('maintenance_list_tasks', {
      'p_period_id': periodId,
      'p_limit': 100,
    });
    if (res is Map) {
      final map = jsonObject(res);
      _saveToCache(cacheKey, map);
      return map;
    }
    return const {};
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponentHistory(
    String componentId, {
    int limit = 20,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'component_history:$componentId:$limit';
    if (!forceRefresh) {
      final cached = _getFromCache<List<Map<String, Object?>>>(cacheKey);
      if (cached != null) return cached;
    }
    final res = await rpc('maintenance_list_history', {
      'p_component_id': componentId,
      'p_limit': limit,
    });
    if (res is Map && res['items'] is List) {
      final list = (res['items'] as List).map(jsonObject).toList();
      _saveToCache(cacheKey, list);
      return list;
    }
    return const [];
  }

  @override
  Future<List<OrderanSewa>> fetchUpcomingOrders({
    int limit = 10,
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'upcoming_orders:$limit';
    if (!forceRefresh) {
      final cached = _getFromCache<List<OrderanSewa>>(cacheKey);
      if (cached != null) return cached;
    }
    try {
      final res = await client
          .from('orderan_sewa')
          .select(
            'id,orderan_id,tanggal_pemasangan,nama_event,nama_client,alamat,nomor_whatsapp,link_gmaps,nama_pic,jumlah_unit,status_orderan,catatan_orderan,created_at',
          )
          .order('tanggal_pemasangan', ascending: true)
          .limit(limit);
      final list = res
          .map((item) => OrderanSewa.fromJson(jsonObject(item)))
          .toList();
      _saveToCache(cacheKey, list);
      return list;
    } catch (_) {
      return const [];
    }
  }

  @override
  Future<OrderanSewa?> fetchOrderDetail(
    String id, {
    bool forceRefresh = false,
  }) async {
    final cacheKey = 'order_detail:$id';
    if (!forceRefresh) {
      final cached = _getFromCache<OrderanSewa>(cacheKey);
      if (cached != null) return cached;
    }
    try {
      final res = await client
          .from('orderan_sewa')
          .select(
            'id,orderan_id,tanggal_pemasangan,nama_event,nama_client,alamat,nomor_whatsapp,link_gmaps,nama_pic,jumlah_unit,status_orderan,catatan_orderan,created_at',
          )
          .eq('id', id)
          .maybeSingle();
      if (res != null) {
        final order = OrderanSewa.fromJson(jsonObject(res));
        _saveToCache(cacheKey, order);
        return order;
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}
