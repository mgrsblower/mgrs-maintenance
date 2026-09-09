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
  });

  final MaintenanceGateway gateway;
  final String id;
  final String? taskId, periodId;

  @override
  State<ComponentDetailScreen> createState() => _ComponentDetailScreenState();
}

class _ComponentDetailScreenState extends State<ComponentDetailScreen> {
  late Future<Component> future;
  late Future<List<Map<String, Object?>>> futureHistory;

  @override
  void initState() {
    super.initState();
    future = Component.load(widget.gateway, widget.id);
    futureHistory = widget.gateway.fetchComponentHistory(widget.id);
  }

  void reload() => setState(() {
        future = Component.load(widget.gateway, widget.id);
        futureHistory = widget.gateway.fetchComponentHistory(widget.id);
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
                      child: CircularProgressIndicator(color: Color(0xFF147CC1)),
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
                              color: Color(0xFFDC2626),
                            ),
                            const SizedBox(height: 12),
                            Text(
                              failureMessage(snapshot.error),
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF991B1B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            ElevatedButton.icon(
                              onPressed: reload,
                              icon: const Icon(Icons.refresh_rounded, size: 18),
                              label: const Text('Coba Lagi'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF147CC1),
                                foregroundColor: Colors.white,
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
                  _buildHistoryCard(context),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
          bottomNavigationBar: _buildBottomActionBar(context, comp),
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
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: const Center(
                  child: Icon(
                    Icons.chevron_left_rounded,
                    color: Color(0xFF0F172A),
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
                    fontFamily: 'Inter',
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A),
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  'Unit MGRS • $kind',
                  style: const TextStyle(
                    fontFamily: 'Inter',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ],
        ),
        PressableScale(
          onTap: () {},
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: const Center(
              child: Icon(
                Icons.more_horiz_rounded,
                color: Color(0xFF0F172A),
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // Card 1: Identity Card
  Widget _buildIdentityCard(
    BuildContext context,
    Component comp,
  ) {
    final label = conditionDisplayLabel(comp.condition);
    final isGood = comp.condition == 'Layak Pakai' || comp.condition == 'OK';
    final isService = comp.condition == 'Service' || comp.condition == 'Rusak Berat';
    final badgeColor = isGood
        ? const Color(0xFF10B981)
        : (isService ? const Color(0xFFEF4444) : const Color(0xFFF59E0B));
    final lastCheckStr = comp.lastCheckingAt != null && comp.lastCheckingAt!.length >= 10
        ? comp.lastCheckingAt!.substring(0, 10)
        : 'Belum tercatat';
    final serviceStr = comp.lastServiceAt != null && comp.lastServiceAt!.length >= 10
        ? 'Servis: ${comp.lastServiceAt!.substring(0, 10)}'
        : 'Tercatat di MGRS';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
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
                      fontFamily: 'Inter',
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Komponen ${comp.kind} Utama',
                    style: const TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 5,
                      height: 5,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      label,
                      style: const TextStyle(
                        fontFamily: 'Inter',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
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
              border: Border(
                top: BorderSide(color: Color(0xFFF1F5F9)),
              ),
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
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        lastCheckStr,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  width: 1,
                  height: 32,
                  color: const Color(0xFFE2E8F0),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Status Layanan',
                        style: TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        serviceStr,
                        style: const TextStyle(
                          fontFamily: 'Inter',
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
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
    final dateStr = comp.lastCheckingAt != null && comp.lastCheckingAt!.length >= 10
        ? comp.lastCheckingAt!.substring(0, 10)
        : 'Belum tercatat';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
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
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              Text(
                dateStr,
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            note,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Color(0xFF334155),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.only(top: 12),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Color(0xFFF1F5F9)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFFE0E7FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.verified_outlined,
                      size: 14,
                      color: Color(0xFF4338CA),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  comp.lastCheckingAt != null
                      ? 'Pemeriksaan terakhir: $dateStr'
                      : 'Belum pernah dilakukan pemeriksaan',
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFE2E8F0)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x08000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
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
                  fontFamily: 'Inter',
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
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
                    fontFamily: 'Inter',
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
                    final after =
                        item['after'] is Map ? item['after'] as Map : null;
                    final cond = after?['condition']?.toString() ?? 'OK';
                    final actor = item['actor']?.toString() ?? 'Petugas';
                    final dotColor = cond == 'OK'
                        ? const Color(0xFF10B981)
                        : (cond == 'Service' || cond == 'Rusak Berat'
                            ? const Color(0xFFEF4444)
                            : const Color(0xFFF59E0B));

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
                                color: const Color(0xFFE2E8F0),
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
                                        fontFamily: 'Inter',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Color(0xFF0F172A),
                                      ),
                                    ),
                                    Text(
                                      dateText,
                                      style: const TextStyle(
                                        fontFamily: 'Inter',
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${conditionDisplayLabel(cond)} • $actor',
                                  style: const TextStyle(
                                    fontFamily: 'Inter',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF64748B),
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
                    child: CircularProgressIndicator(color: Color(0xFF147CC1)),
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
                      color: Color(0xFF94A3B8),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Belum ada riwayat pemeriksaan atau servis',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF64748B),
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
    final isDamaged = comp.condition != 'OK';

    return Container(
      padding: EdgeInsets.fromLTRB(
        20,
        12,
        20,
        MediaQuery.of(context).padding.bottom + 12,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
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
                  color: isDamaged
                      ? const Color(0xFFF1F5F9)
                      : const Color(0xFF147CC1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.fact_check_outlined,
                      size: 18,
                      color: isDamaged ? const Color(0xFF334155) : Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Perbarui Kondisi',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            isDamaged ? const Color(0xFF334155) : Colors.white,
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
                  color: isDamaged
                      ? const Color(0xFFDC2626)
                      : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.build_rounded,
                      size: 18,
                      color: isDamaged ? Colors.white : const Color(0xFF334155),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Catat Servis',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color:
                            isDamaged ? Colors.white : const Color(0xFF334155),
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
}
