import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';
import '../../shared/async_state_view.dart';
import '../../shared/pressable.dart';
import '../history/history_screen.dart';
import '../maintenance/checking_screen.dart';
import 'component.dart';

class ComponentDetailScreen extends StatefulWidget {
  const ComponentDetailScreen({
    super.key,
    required this.gateway,
    required this.id,
    this.taskId,
    this.periodId,
    this.user,
    this.readOnly = false,
  });

  final MaintenanceGateway gateway;
  final String id;
  final String? taskId, periodId;
  final UserProfile? user;
  final bool readOnly;

  @override
  State<ComponentDetailScreen> createState() => _ComponentDetailScreenState();
}

class _ComponentDetailScreenState extends State<ComponentDetailScreen> {
  bool get isReadOnly => widget.readOnly || (widget.user?.isPic ?? false);
  late Future<Component> future;
  late Future<List<Map<String, Object?>>> futureHistory;
  Future<List<Map<String, Object?>>>? _orderUsageFuture;
  String? _loadedCode;

  @override
  void initState() {
    super.initState();
    future = Component.load(widget.gateway, widget.id);
    futureHistory = widget.gateway.fetchComponentHistory(widget.id);
  }

  void reload() => setState(() {
    future = Component.load(widget.gateway, widget.id);
    futureHistory = widget.gateway.fetchComponentHistory(widget.id);
    _orderUsageFuture = null;
    _loadedCode = null;
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Component>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Scaffold(
            backgroundColor: AppTokens.canvas,
            body: SafeArea(
              child: Column(
                children: [
                  _buildTopAppBar(context, 'Memuat...'),
                  const Expanded(
                    child: Center(
                      child: CircularProgressIndicator(
                        color: AppTokens.magenta,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: AppTokens.canvas,
            body: SafeArea(
              child: Column(
                children: [
                  _buildTopAppBar(context, 'Detail Komponen'),
                  Expanded(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              size: 44,
                              color: AppTokens.danger,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              failureMessage(snapshot.error),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppTokens.danger,
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: reload,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Coba Lagi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTokens.magenta,
                                foregroundColor: AppTokens.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final comp = snapshot.data!;
        if (_loadedCode != comp.code) {
          _loadedCode = comp.code;
          _orderUsageFuture = widget.gateway.fetchComponentOrderUsageHistory(
            comp.code,
          );
        }

        return Scaffold(
          backgroundColor: AppTokens.canvas,
          body: SafeArea(
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopAppBar(context, comp.kind),
                  const SizedBox(height: 16),
                  _buildIdentityCard(context, comp),
                  const SizedBox(height: 16),
                  _buildCurrentConditionCard(context, comp),
                  const SizedBox(height: 16),
                  _buildOrderUsageCard(context, comp),
                  const SizedBox(height: 16),
                  _buildHistoryCard(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          bottomNavigationBar: isReadOnly
              ? _buildReadOnlyBar(context, comp)
              : _buildBottomActionBar(context, comp),
        );
      },
    );
  }

  // Top App Bar: Back button circle + Title "Detail Komponen \n Unit MGRS • Kepala" + Ellipsis button
  Widget _buildTopAppBar(BuildContext context, String kind) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            PressableScale(
              onTap: () => Navigator.of(context).pop(),
              child: Container(
                width: AppTokens.minTouchTarget,
                height: AppTokens.minTouchTarget,
                decoration: BoxDecoration(
                  color: AppTokens.mistLight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTokens.mist),
                ),
                child: const Center(
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: AppTokens.ink,
                    size: 24,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Detail Komponen',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Unit MGRS • $kind',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.stone,
                  ),
                ),
              ],
            ),
          ],
        ),
        PressableScale(
          onTap: () {},
          child: Container(
            width: AppTokens.minTouchTarget,
            height: AppTokens.minTouchTarget,
            decoration: BoxDecoration(
              color: AppTokens.mistLight,
              shape: BoxShape.circle,
              border: Border.all(color: AppTokens.mist),
            ),
            child: const Center(
              child: Icon(
                Icons.more_horiz_rounded,
                color: AppTokens.ink,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Card 1: Identity Card
  Widget _buildIdentityCard(BuildContext context, Component comp) {
    final label = conditionDisplayLabel(comp.condition);
    final isGood = comp.condition == 'Layak Pakai' || comp.condition == 'OK';
    final isService =
        comp.condition == 'Service' || comp.condition == 'Rusak Berat';
    final badgeColor = isGood
        ? AppTokens.success
        : (isService ? AppTokens.danger : AppTokens.warning);
    final lastCheckStr =
        comp.lastCheckingAt != null && comp.lastCheckingAt!.length >= 10
        ? comp.lastCheckingAt!.substring(0, 10)
        : 'Belum tercatat';
    final serviceStr =
        comp.lastServiceAt != null && comp.lastServiceAt!.length >= 10
        ? 'Servis: ${comp.lastServiceAt!.substring(0, 10)}'
        : 'Tercatat di MGRS';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTokens.white,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        border: Border.all(color: AppTokens.mist),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    comp.code,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.ink,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Komponen ${comp.kind} Utama',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.stone,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(AppTokens.cardRadius),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: AppTokens.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.only(top: 14),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTokens.mistLight)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pemeriksaan Terakhir',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTokens.stone,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lastCheckStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTokens.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 32, color: AppTokens.mist),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Layanan',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: AppTokens.stone,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        serviceStr,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppTokens.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<Map<String, Object?>>>(
            future: _orderUsageFuture,
            builder: (context, usageSnap) {
              final usageList = usageSnap.data ?? [];
              final usageCount = usageList.length;
              final isZero = usageCount == 0;
              final badgeBg = isZero
                  ? AppTokens.mistLight
                  : (usageCount <= 5
                        ? AppTokens.successSurface
                        : (usageCount <= 15
                              ? AppTokens.warningSurface
                              : AppTokens.mistLight));
              final badgeText = isZero
                  ? AppTokens.graphite
                  : (usageCount <= 5
                        ? AppTokens.success
                        : (usageCount <= 15
                              ? AppTokens.warning
                              : AppTokens.graphite));

              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTokens.mist),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.repeat_rounded,
                          size: 16,
                          color: AppTokens.ink,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Total Pemakaian di Orderan',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.graphite,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '$usageCount kali pakai',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: badgeText,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // Card 2: Catatan Kondisi Terkini
  Widget _buildCurrentConditionCard(BuildContext context, Component comp) {
    final note = comp.note != null && comp.note!.trim().isNotEmpty
        ? comp.note!.trim()
        : 'Tidak ada catatan kondisi khusus untuk komponen ini.';
    final dateStr =
        comp.lastCheckingAt != null && comp.lastCheckingAt!.length >= 10
        ? comp.lastCheckingAt!.substring(0, 10)
        : 'Belum tercatat';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTokens.white,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        border: Border.all(color: AppTokens.mist),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Catatan Kondisi Terkini',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink,
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTokens.stone,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTokens.graphite,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: AppTokens.mistLight)),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: AppTokens.mistLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.verified_outlined,
                      size: 14,
                      color: AppTokens.graphite,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  comp.lastCheckingAt != null
                      ? 'Pemeriksaan terakhir: $dateStr'
                      : 'Belum pernah dilakukan pemeriksaan',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppTokens.stone,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Card: Riwayat Pemakaian di Orderan Sewa
  Widget _buildOrderUsageCard(BuildContext context, Component comp) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTokens.white,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        border: Border.all(color: AppTokens.mist),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      color: AppTokens.mistLight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.event_note_rounded,
                      size: 16,
                      color: AppTokens.ink,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Riwayat Pemakaian di Orderan',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.ink,
                    ),
                  ),
                ],
              ),
              FutureBuilder<List<Map<String, Object?>>>(
                future: _orderUsageFuture,
                builder: (context, snap) {
                  final count = snap.data?.length ?? 0;
                  return Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.mistLight,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '$count orderan',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.graphite,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 14),
          FutureBuilder<List<Map<String, Object?>>>(
            future: _orderUsageFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  child: Center(
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTokens.ink,
                      ),
                    ),
                  ),
                );
              }

              final items = snap.data ?? [];
              if (items.isEmpty) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    vertical: 16,
                    horizontal: 14,
                  ),
                  decoration: BoxDecoration(
                    color: AppTokens.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppTokens.mistLight),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 18,
                        color: AppTokens.stone,
                      ),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Komponen ini belum pernah dipakai pada orderan sewa.',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTokens.stone,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }

              return Column(
                children: items.map((item) {
                  final namaEvent =
                      item['nama_event']?.toString() ?? 'Sewa Blower';
                  final namaClient = item['nama_client']?.toString() ?? '-';
                  final tanggal = item['tanggal']?.toString() ?? '';
                  final dateStr = tanggal.length >= 10
                      ? tanggal.substring(0, 10)
                      : tanggal;
                  final status = item['status_orderan']?.toString() ?? '-';
                  final unitIdx = item['unit_index'];
                  final roleSlot = item['role_slot']?.toString() ?? '';
                  final isDone = status.toLowerCase() == 'selesai';

                  return Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTokens.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTokens.mist),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                namaEvent,
                                style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppTokens.ink,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: isDone
                                    ? AppTokens.successSurface
                                    : AppTokens.mistLight,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: isDone
                                      ? AppTokens.success
                                      : AppTokens.graphite,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 12,
                              color: AppTokens.stone,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                namaClient,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppTokens.graphite,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 1.5,
                              ),
                              decoration: BoxDecoration(
                                color: AppTokens.mist,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Unit $unitIdx • $roleSlot',
                                style: const TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: AppTokens.graphite,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(
                              Icons.calendar_today_rounded,
                              size: 11,
                              color: AppTokens.stone,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              dateStr,
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppTokens.stone,
                              ),
                            ),
                            if (item['orderan_id'] != null) ...[
                              const Text(
                                ' • ',
                                style: TextStyle(color: AppTokens.stone),
                              ),
                              Text(
                                '#${item['orderan_id']}',
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTokens.stone,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // Card 3: Riwayat Pemeriksaan & Servis (View Only, NO CTA button)
  Widget _buildHistoryCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTokens.white,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        border: Border.all(color: AppTokens.mist),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Riwayat Pemeriksaan & Servis',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink,
                ),
              ),
              PressableScale(
                onTap: () {
                  Navigator.of(context).push<void>(
                    MaterialPageRoute(
                      builder: (_) => Scaffold(
                        appBar: AppBar(title: const Text('Riwayat Komponen')),
                        body: HistoryScreen(
                          gateway: widget.gateway,
                          componentId: widget.id,
                        ),
                      ),
                    ),
                  );
                },
                child: const Text(
                  'Lihat Semua',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<Map<String, Object?>>>(
            future: futureHistory,
            builder: (context, histSnap) {
              final items = histSnap.data;
              if (items != null && items.isNotEmpty) {
                return Column(
                  children: items.take(3).map((item) {
                    final activity =
                        item['activity'] as String? ?? 'manual_check';
                    final title = activity == 'service'
                        ? 'Tindakan Servis'
                        : (activity == 'periodic_check'
                              ? 'Pemeriksaan Berkala'
                              : 'Pemeriksaan Manual');
                    final recordedAt = item['recordedAt']?.toString() ?? '';
                    final dateText = recordedAt.length >= 10
                        ? recordedAt.substring(0, 10)
                        : 'Baru saja';
                    final after = item['after'] is Map
                        ? item['after'] as Map
                        : null;
                    final cond = after?['condition']?.toString() ?? 'OK';
                    final actor = item['actor']?.toString() ?? 'Petugas';
                    final dotColor = cond == 'OK'
                        ? AppTokens.success
                        : (cond == 'Service' || cond == 'Rusak Berat'
                              ? AppTokens.danger
                              : AppTokens.warning);

                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  color: dotColor,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              Container(
                                width: 1.5,
                                height: 38,
                                color: AppTokens.mist,
                              ),
                            ],
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      title,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: AppTokens.ink,
                                      ),
                                    ),
                                    Text(
                                      dateText,
                                      style: const TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: AppTokens.stone,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${conditionDisplayLabel(cond)} • $actor',
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: AppTokens.stone,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                );
              }

              if (histSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: CircularProgressIndicator(color: AppTokens.magenta),
                  ),
                );
              }

              return Container(
                padding: const EdgeInsets.symmetric(vertical: 24),
                alignment: Alignment.center,
                child: const Column(
                  children: [
                    Icon(
                      Icons.history_rounded,
                      size: 32,
                      color: AppTokens.stone,
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada riwayat pemeriksaan atau servis',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.stone,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(BuildContext context, Component comp) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppTokens.white,
        border: Border(top: BorderSide(color: AppTokens.mistLight)),
      ),
      child: Row(
        children: [
          Expanded(
            child: PressableScale(
              onTap: () async {
                final res = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => CheckingScreen(
                      gateway: widget.gateway,
                      component: comp,
                      service: false,
                    ),
                  ),
                );
                if (res == true && mounted) {
                  reload();
                }
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: comp.condition != 'OK'
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF147CC1),
                  borderRadius: BorderRadius.circular(AppTokens.controlRadius),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      size: 18,
                      color: comp.condition != 'OK'
                          ? const Color(0xFF334155)
                          : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Perbarui Kondisi',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: comp.condition != 'OK'
                            ? const Color(0xFF334155)
                            : Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: PressableScale(
              onTap: () async {
                final res = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => CheckingScreen(
                      gateway: widget.gateway,
                      component: comp,
                      service: true,
                    ),
                  ),
                );
                if (res == true && mounted) {
                  reload();
                }
              },
              child: Container(
                height: 48,
                decoration: BoxDecoration(
                  color: comp.condition != 'OK'
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(AppTokens.controlRadius),
                  border: Border.all(color: AppTokens.mist),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.build_rounded,
                      size: 18,
                      color: comp.condition != 'OK'
                          ? Colors.white
                          : const Color(0xFF334155),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Catat Servis',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: comp.condition != 'OK'
                            ? Colors.white
                            : const Color(0xFF334155),
                      ),
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

  Widget _buildReadOnlyBar(BuildContext context, Component comp) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: AppTokens.white,
        border: Border(top: BorderSide(color: AppTokens.mistLight)),
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: AppTokens.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppTokens.mist),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.remove_red_eye_outlined,
                size: 16,
                color: AppTokens.stone,
              ),
              SizedBox(width: 8),
              Text(
                'Mode Pantau Status • Hanya Baca',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.stone,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
