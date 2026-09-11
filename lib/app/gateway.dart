import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/invoices/invoice_model.dart';
import '../features/schedule/order_model.dart';
import '../features/schedule/unit_allocation_model.dart';

Map<String, Object?> jsonObject(Object? value) {
  if (value is! Map) throw const FormatException('Expected object');
  return Map<String, Object?>.from(value);
}

List<Map<String, Object?>> jsonItems(Object? value) {
  if (value is! List) throw const FormatException('Expected list');
  return value.map(jsonObject).toList();
}

enum AdminAppMode {
  pic('Mode PIC (Order & Invoice)'),
  service('Mode Servis (Teknisi Maintenance)');

  const AdminAppMode(this.label);
  final String label;
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
      username: username ?? this.username,
    );
  }

  static const roles = {
    'Admin',
    'Tim Service',
    'Tim Pemasangan',
    'PIC Pemasangan',
  };

  bool get isAdmin => role == 'Admin';
  bool get isPic => role == 'PIC Pemasangan';
  bool get isTechnician => role == 'Tim Service' || role == 'Tim Pemasangan';
  bool get canManageOrders => isAdmin || isPic;

  String get displayName {
    if (fullName != null && fullName!.trim().isNotEmpty) {
      return fullName!.trim();
    }
    if (username != null && username!.trim().isNotEmpty) {
      return username!.trim();
    }
    if (isAdmin) return 'Admin MGRS';
    if (isPic) return 'PIC MGRS';
    return 'Petugas Maintenance';
  }

  String get initials {
    final name = displayName;
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    } else if (name.isNotEmpty) {
      return name.substring(0, name.length >= 2 ? 2 : 1).toUpperCase();
    }
    return isPic ? 'PIC' : 'PM';
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

String failureMessage(Object? error) {
  if (error != null) {
    debugPrint('[MGRS Failure] $error');
  }
  if (error is PostgrestException) {
    return error.message;
  }
  return error is AppFailure ? error.message : const AppFailure('unknown').message;
}

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

  Future<List<InvoiceRecord>> fetchInvoices({
    bool forceRefresh = false,
  }) async => const [];

  Future<InvoiceRecord> createInvoice(Map<String, Object?> payload) async =>
      throw UnimplementedError();

  Future<InvoiceRecord> saveInvoice(SaveInvoiceInput input) async =>
      throw UnimplementedError();

  Future<InvoiceRecord> updateInvoicePayment(
    String invoiceId,
    InvoicePaymentStatus status,
    num paidAmount,
  ) async =>
      throw UnimplementedError();

  Future<InvoiceRecord?> fetchInvoiceByOrderanId(String orderanId) async =>
      null;

  Future<void> deleteInvoice(String invoiceId) async {}

  Future<OrderanSewa> createOrderWithInvoice(
    Map<String, Object?> orderData,
  ) async => throw UnimplementedError();

  Future<void> updateOrderStatus(
    String orderanId,
    String status,
  ) async {}

  Future<void> cancelOrder(
    String orderanId, {
    required String reason,
    bool cancelInvoice = true,
  }) async {}

  Future<Map<String, int>> fetchComponentUsageCounts({
    bool forceRefresh = false,
  }) async => {};

  Future<void> saveOrderUnitAllocation(
    String orderanId,
    List<AllocatedUnit> units,
  ) async {}

  Future<List<Map<String, Object?>>> fetchComponentOrderUsageHistory(
    String sticker, {
    bool forceRefresh = false,
  }) async => const [];
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
    final trimmed = identifier.trim();
    if (trimmed.isEmpty || password.isEmpty) {
      throw const AppFailure('invalid_credentials');
    }
    final normalized = trimmed.toLowerCase();

    // If identifier is an email, sign in directly with Supabase Auth
    if (normalized.contains('@')) {
      try {
        await client.auth
            .signInWithPassword(email: normalized, password: password)
            .timeout(const Duration(seconds: 15));
        await profile();
        return;
      } on AuthException catch (e) {
        if (e.message.toLowerCase().contains('invalid login credentials')) {
          throw const AppFailure('invalid_credentials');
        }
        throw AppFailure(e.message);
      } on TimeoutException {
        throw const AppFailure('network');
      }
    }

    // Otherwise (username / phone), authenticate via flutter-auth-login Edge Function
    try {
      final response = await client.functions
          .invoke(
            'flutter-auth-login',
            body: {'identifier': trimmed, 'password': password},
          )
          .timeout(const Duration(seconds: 20));
      final body = jsonObject(response.data);
      if (body['success'] != true) {
        final err = body['error'];
        if (err is Map && err['code'] == 'inactive_account') {
          throw const AppFailure('forbidden');
        }
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
      );
      if (client.auth.currentUser?.id != user['id']) {
        await signOut();
        throw const AppFailure('unauthenticated');
      }
      await profile();
    } on FunctionException catch (e) {
      final details = e.details;
      if (details is Map && details['error'] is Map) {
        final errCode = details['error']['code'];
        if (errCode == 'inactive_account') {
          throw const AppFailure('forbidden');
        }
      }
      throw const AppFailure('invalid_credentials');
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        throw const AppFailure('invalid_credentials');
      }
      throw AppFailure(e.message);
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

  bool _isUuid(String str) {
    final uuidRegex = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}$',
    );
    return uuidRegex.hasMatch(str.trim());
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
      final query = client.from('orderan_sewa').select(
        'id,orderan_id,tanggal_pemasangan,nama_event,nama_client,alamat,nomor_whatsapp,link_gmaps,nama_pic,jumlah_unit,status_orderan,catatan_orderan,created_at',
      );
      final res = _isUuid(id)
          ? await query.or('id.eq.$id,orderan_id.eq.$id').maybeSingle()
          : await query.eq('orderan_id', id).maybeSingle();
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

  @override
  Future<List<InvoiceRecord>> fetchInvoices({
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'invoices:all';
    if (!forceRefresh) {
      final cached = _getFromCache<List<InvoiceRecord>>(cacheKey);
      if (cached != null) return cached;
    }
    try {
      final res = await client
          .from('invoices')
          .select()
          .order('invoice_date', ascending: false);
      final list =
          (res as List).map((item) => InvoiceRecord.fromJson(jsonObject(item))).toList();

      // Clean up orphaned unpaid invoices from cancelled orders
      final orderIds = list
          .map((inv) => inv.orderanId)
          .where((id) => id != null && id.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList();

      if (orderIds.isNotEmpty) {
        try {
          final cancelledRes = await client
              .from('orderan_sewa')
              .select('id,orderan_id')
              .eq('status_orderan', 'Dibatalkan');

          final cancelledIds = <String>{};
          for (final row in (cancelledRes as List).cast<Map<String, Object?>>()) {
            if (row['id'] != null) cancelledIds.add(row['id'].toString());
            if (row['orderan_id'] != null) cancelledIds.add(row['orderan_id'].toString());
          }

          if (cancelledIds.isNotEmpty) {
            final validList = <InvoiceRecord>[];
            for (final inv in list) {
              if (inv.orderanId != null && cancelledIds.contains(inv.orderanId)) {
                if (inv.paidAmount <= 0) {
                  // Asynchronously delete from Supabase so it won't persist
                  client.from('invoices').delete().eq('id', inv.id).catchError((_) {});
                  continue; // Exclude from display
                }
              }
              validList.add(inv);
            }
            _saveToCache(cacheKey, validList);
            return validList;
          }
        } catch (e) {
          debugPrint('[Fetch Invoices Cleanup Error] $e');
        }
      }

      _saveToCache(cacheKey, list);
      return list;
    } catch (e) {
      debugPrint('[Fetch Invoices Error] $e');
      return const [];
    }
  }

  @override
  Future<void> deleteInvoice(String invoiceId) async {
    await client.from('invoices').delete().eq('id', invoiceId);
    invalidateCache('invoices');
  }

  @override
  Future<InvoiceRecord> createInvoice(Map<String, Object?> payload) async {
    final insertPayload = <String, Object?>{...payload}
      ..remove('id')
      ..remove('created_at')
      ..remove('updated_at');
    final res = await client
        .from('invoices')
        .insert(insertPayload)
        .select()
        .single();
    invalidateCache('invoices');
    return InvoiceRecord.fromJson(jsonObject(res));
  }

  @override
  Future<InvoiceRecord> saveInvoice(SaveInvoiceInput input) async {
    final payload = <String, Object?>{
      ...input.toPayload(),
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final res = await client
        .from('invoices')
        .update(payload)
        .eq('id', input.invoiceId)
        .select()
        .single();
    invalidateCache('invoices');
    return InvoiceRecord.fromJson(jsonObject(res));
  }

  @override
  Future<InvoiceRecord> updateInvoicePayment(
    String invoiceId,
    InvoicePaymentStatus status,
    num paidAmount,
  ) async {
    final payload = <String, Object?>{
      'payment_status': status.toJson(),
      'paid_amount': paidAmount,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    };
    final res = await client
        .from('invoices')
        .update(payload)
        .eq('id', invoiceId)
        .select()
        .single();
    invalidateCache('invoices');
    return InvoiceRecord.fromJson(jsonObject(res));
  }

  @override
  Future<InvoiceRecord?> fetchInvoiceByOrderanId(String orderanId) async {
    try {
      final res = await client
          .from('invoices')
          .select()
          .eq('orderan_id', orderanId)
          .maybeSingle();
      if (res != null) {
        return InvoiceRecord.fromJson(jsonObject(res));
      }

      // If not found directly, orderanId might be UUID while invoices.orderan_id has "ORD-..."
      // or vice-versa. Look up counterpart in orderan_sewa:
      final orderQuery = client.from('orderan_sewa').select('id,orderan_id');
      final orderRes = _isUuid(orderanId)
          ? await orderQuery.eq('id', orderanId).maybeSingle()
          : await orderQuery.eq('orderan_id', orderanId).maybeSingle();

      if (orderRes != null) {
        final counterpart = _isUuid(orderanId)
            ? orderRes['orderan_id']?.toString()
            : orderRes['id']?.toString();
        if (counterpart != null && counterpart.isNotEmpty && counterpart != orderanId) {
          final fallbackRes = await client
              .from('invoices')
              .select()
              .eq('orderan_id', counterpart)
              .maybeSingle();
          if (fallbackRes != null) {
            return InvoiceRecord.fromJson(jsonObject(fallbackRes));
          }
        }
      }

      return null;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<OrderanSewa> createOrderWithInvoice(
    Map<String, Object?> orderData,
  ) async {
    // 1. Insert order into orderan_sewa
    final orderRes = await client
        .from('orderan_sewa')
        .insert(orderData)
        .select()
        .single();
    final order = OrderanSewa.fromJson(jsonObject(orderRes));

    // 2. Automatically generate and insert invoice
    try {
      final dt = order.tanggalPemasangan ?? DateTime.now();
      final orderanIdStr = order.orderanId ?? order.id;
      final codeSuffix = orderanIdStr.split('-').last;
      final yearStr = dt.year.toString().padLeft(4, '0');
      final monthStr = dt.month.toString().padLeft(2, '0');
      final dayStr = dt.day.toString().padLeft(2, '0');
      final invoiceRef = 'INV/$yearStr/$monthStr/$dayStr-$codeSuffix';
      final dueDate = dt.add(const Duration(days: 7));
      final qty = order.jumlahUnit > 0 ? order.jumlahUnit : 1;
      final days = order.rentalDays > 0 ? order.rentalDays : 1;
      const unitPrice = 250000;
      final subtotal = qty * unitPrice;
      final totalAmount = subtotal * days;

      final invoicePayload = <String, Object?>{
        'orderan_id': orderanIdStr,
        'invoice_reference': invoiceRef,
        'invoice_date': dt.toIso8601String().substring(0, 10),
        'due_date': dueDate.toIso8601String().substring(0, 10),
        'product_name':
            order.namaEvent.isNotEmpty ? order.namaEvent : 'Sewa Mistyfan',
        'customer_name': order.namaClient,
        'customer_phone': order.nomorWhatsapp ?? '',
        'quantity': qty,
        'rental_days': days,
        'unit_price': unitPrice,
        'subtotal': subtotal,
        'total_amount': totalAmount,
        'paid_amount': 0,
        'payment_status': 'unpaid',
        'invoice_source': 'order',
      };
      await client.from('invoices').insert(invoicePayload);
    } catch (e) {
      // Ignored if already auto-generated by database trigger or duplicate
      debugPrint('[Invoice Auto-Generate] Note: $e');
    }

    invalidateCache('upcoming_orders');
    invalidateCache('invoices');
    return order;
  }

  @override
  Future<void> updateOrderStatus(String orderanId, String status) async {
    final normalizedStatus =
        (status.toLowerCase() == 'batal' || status.toLowerCase() == 'cancelled')
            ? 'Dibatalkan'
            : status;
    final updatePayload = <String, Object?>{
      'status_orderan': normalizedStatus,
    };

    if (_isUuid(orderanId)) {
      await client
          .from('orderan_sewa')
          .update(updatePayload)
          .eq('id', orderanId);
    } else {
      await client
          .from('orderan_sewa')
          .update(updatePayload)
          .eq('orderan_id', orderanId);
    }

    invalidateCache('upcoming_orders');
    invalidateCache('order_detail:$orderanId');
    if (status.toLowerCase() == 'batal' ||
        status.toLowerCase() == 'cancelled' ||
        status.toLowerCase() == 'dibatalkan') {
      invalidateCache('invoices');
    }
  }

  @override
  Future<void> cancelOrder(
    String orderanId, {
    required String reason,
    bool cancelInvoice = true,
  }) async {
    String? currentNote;
    String? businessOrderId;
    String? dbUuid;
    try {
      final noteQuery = client.from('orderan_sewa').select('id,orderan_id,catatan_orderan');
      var res = _isUuid(orderanId)
          ? await noteQuery.eq('id', orderanId).maybeSingle()
          : await noteQuery.eq('orderan_id', orderanId).maybeSingle();

      if (res == null) {
        if (!_isUuid(orderanId)) {
          try {
            res = await noteQuery.eq('id', orderanId).maybeSingle();
          } catch (_) {}
        } else {
          res = await noteQuery.eq('orderan_id', orderanId).maybeSingle();
        }
      }

      if (res != null) {
        currentNote = res['catatan_orderan']?.toString();
        businessOrderId = res['orderan_id']?.toString();
        dbUuid = res['id']?.toString();
      }
    } catch (e) {
      debugPrint('[Cancel Order] Note fetch error: $e');
    }

    final trimmedReason = reason.trim();
    final cancellationTag = '[BATAL: $trimmedReason]';
    final updatedNote = currentNote != null && currentNote.trim().isNotEmpty
        ? '$currentNote\n$cancellationTag'
        : cancellationTag;

    final updatePayload = <String, Object?>{
      'status_orderan': 'Dibatalkan',
      'catatan_orderan': updatedNote,
    };

    if (dbUuid != null && dbUuid.isNotEmpty) {
      await client
          .from('orderan_sewa')
          .update(updatePayload)
          .eq('id', dbUuid);
    } else if (businessOrderId != null && businessOrderId.isNotEmpty) {
      await client
          .from('orderan_sewa')
          .update(updatePayload)
          .eq('orderan_id', businessOrderId);
    } else if (_isUuid(orderanId)) {
      await client
          .from('orderan_sewa')
          .update(updatePayload)
          .eq('id', orderanId);
    } else {
      await client
          .from('orderan_sewa')
          .update(updatePayload)
          .eq('orderan_id', orderanId);
    }

    if (cancelInvoice) {
      try {
        final idsToDelete = <String>{};
        Future<void> findInvoices(String id) async {
          final res = await client
              .from('invoices')
              .select('id,payment_status,paid_amount')
              .eq('orderan_id', id);
          for (final row in (res as List).cast<Map<String, Object?>>()) {
            final paid = num.tryParse(row['paid_amount']?.toString() ?? '0') ?? 0;
            final status = row['payment_status']?.toString().toLowerCase();
            if (paid <= 0 || status == 'unpaid') {
              final invId = row['id']?.toString();
              if (invId != null && invId.isNotEmpty) {
                idsToDelete.add(invId);
              }
            }
          }
        }

        await findInvoices(orderanId);
        if (businessOrderId != null && businessOrderId.isNotEmpty && businessOrderId != orderanId) {
          await findInvoices(businessOrderId);
        }
        if (dbUuid != null && dbUuid.isNotEmpty && dbUuid != orderanId) {
          await findInvoices(dbUuid);
        }

        for (final invId in idsToDelete) {
          await client.from('invoices').delete().eq('id', invId);
        }
      } catch (e) {
        debugPrint('[Cancel Order] Invoice delete error: $e');
      }
    }

    invalidateCache('upcoming_orders');
    invalidateCache('invoices');
    invalidateCache('order_detail:$orderanId');
    if (businessOrderId != null && businessOrderId != orderanId) {
      invalidateCache('order_detail:$businessOrderId');
    }
    if (dbUuid != null && dbUuid != orderanId) {
      invalidateCache('order_detail:$dbUuid');
    }
  }

  @override
  Future<Map<String, int>> fetchComponentUsageCounts({
    bool forceRefresh = false,
  }) async {
    const cacheKey = 'component_usage_counts';
    if (!forceRefresh) {
      final cached = _getFromCache<Map<String, int>>(cacheKey);
      if (cached != null) return cached;
    }
    try {
      final res = await client
          .from('orderan_sewa')
          .select('catatan_orderan');
      final counts = <String, int>{};
      for (final item in (res as List).cast<Map<String, Object?>>()) {
        final note = item['catatan_orderan']?.toString();
        if (note != null && note.contains('[UNIT_ALOKASI:')) {
          final units = UnitAllocationParser.parse(note);
          for (final u in units) {
            if (u.kepalaSticker != null && u.kepalaSticker!.trim().isNotEmpty) {
              final k = u.kepalaSticker!.trim();
              counts[k] = (counts[k] ?? 0) + 1;
            }
            if (u.batangSticker != null && u.batangSticker!.trim().isNotEmpty) {
              final b = u.batangSticker!.trim();
              counts[b] = (counts[b] ?? 0) + 1;
            }
            if (u.tabungSticker != null && u.tabungSticker!.trim().isNotEmpty) {
              final t = u.tabungSticker!.trim();
              counts[t] = (counts[t] ?? 0) + 1;
            }
          }
        }
      }
      _saveToCache(cacheKey, counts);
      return counts;
    } catch (e) {
      debugPrint('[Fetch Usage Counts Error] $e');
      return const {};
    }
  }

  @override
  Future<void> saveOrderUnitAllocation(
    String orderanId,
    List<AllocatedUnit> units,
  ) async {
    String? currentNote;
    String? businessOrderId;
    String? dbUuid;
    try {
      final noteQuery = client.from('orderan_sewa').select('id,orderan_id,catatan_orderan');
      var res = _isUuid(orderanId)
          ? await noteQuery.eq('id', orderanId).maybeSingle()
          : await noteQuery.eq('orderan_id', orderanId).maybeSingle();

      if (res == null) {
        if (!_isUuid(orderanId)) {
          try {
            res = await noteQuery.eq('id', orderanId).maybeSingle();
          } catch (_) {}
        } else {
          res = await noteQuery.eq('orderan_id', orderanId).maybeSingle();
        }
      }

      if (res != null) {
        currentNote = res['catatan_orderan']?.toString();
        businessOrderId = res['orderan_id']?.toString();
        dbUuid = res['id']?.toString();
      }
    } catch (e) {
      debugPrint('[Save Allocation Note Fetch Error] $e');
    }

    final updatedNote = UnitAllocationParser.updateNoteWithAllocation(currentNote, units);
    final updatePayload = {'catatan_orderan': updatedNote};

    if (dbUuid != null && dbUuid.isNotEmpty) {
      await client
          .from('orderan_sewa')
          .update(updatePayload)
          .eq('id', dbUuid);
    } else if (businessOrderId != null && businessOrderId.isNotEmpty) {
      await client
          .from('orderan_sewa')
          .update(updatePayload)
          .eq('orderan_id', businessOrderId);
    } else if (_isUuid(orderanId)) {
      await client
          .from('orderan_sewa')
          .update(updatePayload)
          .eq('id', orderanId);
    } else {
      await client
          .from('orderan_sewa')
          .update(updatePayload)
          .eq('orderan_id', orderanId);
    }

    invalidateCache('upcoming_orders');
    invalidateCache('order_detail:$orderanId');
    if (businessOrderId != null && businessOrderId != orderanId) {
      invalidateCache('order_detail:$businessOrderId');
    }
    if (dbUuid != null && dbUuid != orderanId) {
      invalidateCache('order_detail:$dbUuid');
    }
    invalidateCache('component_usage_counts');
    _cache.removeWhere((k, _) => k.startsWith('component_order_history:'));
  }

  @override
  Future<List<Map<String, Object?>>> fetchComponentOrderUsageHistory(
    String sticker, {
    bool forceRefresh = false,
  }) async {
    final cleanSticker = sticker.trim();
    if (cleanSticker.isEmpty) return const [];
    final cacheKey = 'component_order_history:$cleanSticker';
    if (!forceRefresh) {
      final cached = _getFromCache<List<Map<String, Object?>>>(cacheKey);
      if (cached != null) return cached;
    }

    try {
      final res = await client
          .from('orderan_sewa')
          .select(
            'id,orderan_id,tanggal_pemasangan,nama_event,nama_client,alamat,status_orderan,catatan_orderan,created_at',
          )
          .ilike('catatan_orderan', '%$cleanSticker%');

      final history = <Map<String, Object?>>[];
      for (final item in (res as List).cast<Map<String, Object?>>()) {
        final note = item['catatan_orderan']?.toString();
        if (note != null && note.contains('[UNIT_ALOKASI:')) {
          final units = UnitAllocationParser.parse(note);
          for (final u in units) {
            String? matchedKind;
            if (u.kepalaSticker?.trim() == cleanSticker) matchedKind = 'Kepala';
            if (u.batangSticker?.trim() == cleanSticker) matchedKind = 'Batang';
            if (u.tabungSticker?.trim() == cleanSticker) matchedKind = 'Tabung';

            if (matchedKind != null) {
              history.add({
                'orderan_id': item['orderan_id']?.toString() ?? item['id']?.toString(),
                'nama_event': item['nama_event']?.toString() ?? 'Sewa Blower',
                'nama_client': item['nama_client']?.toString() ?? '-',
                'tanggal': item['tanggal_pemasangan']?.toString() ?? item['created_at']?.toString(),
                'alamat': item['alamat']?.toString() ?? '-',
                'status_orderan': item['status_orderan']?.toString() ?? '-',
                'unit_index': u.unitIndex,
                'role_slot': matchedKind,
              });
            }
          }
        }
      }

      history.sort((a, b) {
        final dateA = a['tanggal']?.toString() ?? '';
        final dateB = b['tanggal']?.toString() ?? '';
        return dateB.compareTo(dateA);
      });

      _saveToCache(cacheKey, history);
      return history;
    } catch (e) {
      debugPrint('[Fetch Component Order Usage History Error] $e');
      return const [];
    }
  }
}
