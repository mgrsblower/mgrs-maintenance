import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../design_system/components/mgrs_app_bar.dart';
import '../../design_system/components/mgrs_state_view.dart';
import '../../design_system/components/mgrs_status_badge.dart';
import '../../design_system/mgrs_tokens.dart';
import '../../shared/async_state_view.dart' show conditionDisplayLabel;
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
          return const Scaffold(
            backgroundColor: MgrsColors.canvas,
            appBar: MgrsDetailAppBar(title: 'Detail Komponen'),
            body: MgrsStateView.loading(title: 'Memuat detail komponen...'),
          );
        }

        if (snapshot.hasError || !snapshot.hasData) {
          return Scaffold(
            backgroundColor: MgrsColors.canvas,
            appBar: const MgrsDetailAppBar(title: 'Detail Komponen'),
            body: MgrsStateView.error(
              title: 'Detail komponen gagal dimuat',
              message: 'Periksa koneksi, lalu muat data terbaru.',
              actionLabel: 'Muat data terbaru',
              onAction: reload,
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
          backgroundColor: MgrsColors.canvas,
          appBar: const MgrsDetailAppBar(title: 'Detail Komponen'),
          body: SafeArea(
            top: false,
            bottom: false,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(
                MgrsSpacing.lg,
                MgrsSpacing.md,
                MgrsSpacing.lg,
                MgrsSpacing.xl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    comp.kind,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: MgrsColors.muted),
                  ),
                  const SizedBox(height: MgrsSpacing.md),
                  _buildIdentityCard(context, comp),
                  const SizedBox(height: MgrsSpacing.base),
                  _buildCurrentConditionCard(context, comp),
                  const SizedBox(height: MgrsSpacing.base),
                  _buildOrderUsageCard(context, comp),
                  const SizedBox(height: MgrsSpacing.base),
                  _buildHistoryCard(context),
                  const SizedBox(height: MgrsSpacing.xl),
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

  // Card 1: Identity Card
  Widget _buildIdentityCard(BuildContext context, Component comp) {
    final label = conditionDisplayLabel(comp.condition);
    final lastCheck = comp.lastCheckingAt;
    final lastService = comp.lastServiceAt;

    return Container(
      padding: const EdgeInsets.all(MgrsSpacing.lg),
      decoration: BoxDecoration(
        color: MgrsColors.surface,
        borderRadius: BorderRadius.circular(MgrsRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            comp.code,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: MgrsColors.ink,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: MgrsSpacing.sm),
          MgrsStatusBadge(label),
          const SizedBox(height: MgrsSpacing.base),
          const Divider(height: 1, color: MgrsColors.line),
          const SizedBox(height: MgrsSpacing.base),
          _detailValue(context, 'Jenis komponen', comp.kind),
          if (lastCheck != null && lastCheck.isNotEmpty) ...[
            const SizedBox(height: MgrsSpacing.md),
            _detailValue(
              context,
              'Pemeriksaan terakhir',
              lastCheck.length >= 10 ? lastCheck.substring(0, 10) : lastCheck,
            ),
          ],
          if (lastService != null && lastService.isNotEmpty) ...[
            const SizedBox(height: MgrsSpacing.md),
            _detailValue(
              context,
              'Servis terakhir',
              lastService.length >= 10
                  ? lastService.substring(0, 10)
                  : lastService,
            ),
          ],
        ],
      ),
    );
  }

  Widget _detailValue(BuildContext context, String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(color: MgrsColors.muted),
        ),
        const SizedBox(height: MgrsSpacing.xs),
        Text(
          value,
          style: Theme.of(context).textTheme.bodyLarge?.copyWith(
            color: MgrsColors.ink,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  // Card 2: Catatan Kondisi Terkini
  Widget _buildCurrentConditionCard(BuildContext context, Component comp) {
    final note = comp.note?.trim();
    final date = comp.lastCheckingAt;
    return Container(
      padding: const EdgeInsets.all(MgrsSpacing.lg),
      decoration: BoxDecoration(
        color: MgrsColors.surface,
        borderRadius: BorderRadius.circular(MgrsRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Catatan Kondisi Terkini',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: MgrsColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MgrsSpacing.md),
          Text(
            note != null && note.isNotEmpty
                ? note
                : 'Tidak ada catatan kondisi khusus untuk komponen ini.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: note != null && note.isNotEmpty
                  ? MgrsColors.ink
                  : MgrsColors.muted,
            ),
          ),
          if (date != null && date.isNotEmpty) ...[
            const SizedBox(height: MgrsSpacing.md),
            Text(
              'Pemeriksaan terakhir: ${date.length >= 10 ? date.substring(0, 10) : date}',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: MgrsColors.muted),
            ),
          ],
        ],
      ),
    );
  }

  // Card: Riwayat Pemakaian di Orderan Sewa
  Widget _buildOrderUsageCard(BuildContext context, Component comp) {
    return Container(
      padding: const EdgeInsets.all(MgrsSpacing.lg),
      decoration: BoxDecoration(
        color: MgrsColors.surface,
        borderRadius: BorderRadius.circular(MgrsRadii.card),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Riwayat Pemakaian di Orderan',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: MgrsColors.ink,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: MgrsSpacing.base),
          FutureBuilder<List<Map<String, Object?>>>(
            future: _orderUsageFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(strokeWidth: 2.5),
                );
              }
              if (snap.hasError) {
                return Text(
                  'Riwayat pemakaian belum dapat dimuat.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: MgrsColors.danger),
                );
              }
              final items = snap.data ?? const [];
              if (items.isEmpty) {
                return Text(
                  'Belum ada riwayat pemakaian yang tersimpan.',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: MgrsColors.muted),
                );
              }
              return Column(
                children: items
                    .map((item) {
                      final event = item['nama_event']?.toString();
                      final client = item['nama_client']?.toString();
                      final status = item['status_orderan']?.toString();
                      final date = item['tanggal']?.toString();
                      final unit = item['unit_index'];
                      final role = item['role_slot']?.toString();
                      return Padding(
                        padding: const EdgeInsets.only(
                          bottom: MgrsSpacing.base,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (event != null && event.isNotEmpty)
                              Text(
                                event,
                                style: Theme.of(context).textTheme.titleSmall
                                    ?.copyWith(
                                      color: MgrsColors.ink,
                                      fontWeight: FontWeight.w600,
                                    ),
                              ),
                            if (status != null && status.isNotEmpty) ...[
                              const SizedBox(height: MgrsSpacing.sm),
                              MgrsStatusBadge(status),
                            ],
                            if (client != null && client.isNotEmpty) ...[
                              const SizedBox(height: MgrsSpacing.sm),
                              _detailValue(context, 'Klien', client),
                            ],
                            if (unit != null ||
                                (role != null && role.isNotEmpty)) ...[
                              const SizedBox(height: MgrsSpacing.sm),
                              _detailValue(
                                context,
                                'Penempatan',
                                [
                                  if (unit != null) 'Unit $unit',
                                  if (role != null && role.isNotEmpty) role,
                                ].join(' · '),
                              ),
                            ],
                            if (date != null && date.isNotEmpty) ...[
                              const SizedBox(height: MgrsSpacing.sm),
                              _detailValue(
                                context,
                                'Tanggal',
                                date.length >= 10
                                    ? date.substring(0, 10)
                                    : date,
                              ),
                            ],
                            if (item['orderan_id'] != null) ...[
                              const SizedBox(height: MgrsSpacing.sm),
                              _detailValue(
                                context,
                                'ID orderan',
                                item['orderan_id'].toString(),
                              ),
                            ],
                            const SizedBox(height: MgrsSpacing.base),
                            const Divider(height: 1, color: MgrsColors.line),
                          ],
                        ),
                      );
                    })
                    .toList(growable: false),
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
        color: MgrsColors.surface,
        borderRadius: BorderRadius.circular(MgrsRadii.card),
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
                    color: MgrsColors.operational,
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
                    final recordedAt = item['recordedAt']?.toString();
                    final dateText =
                        recordedAt != null && recordedAt.length >= 10
                        ? recordedAt.substring(0, 10)
                        : recordedAt;
                    final after = item['after'] is Map
                        ? item['after'] as Map
                        : null;
                    final cond = after?['condition']?.toString();
                    final actor = item['actor']?.toString();
                    final dotColor = cond == null
                        ? MgrsColors.muted
                        : (cond == 'OK'
                              ? MgrsColors.success
                              : (cond == 'Service' || cond == 'Rusak Berat'
                                    ? MgrsColors.danger
                                    : MgrsColors.warning));

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
                                    if (dateText != null && dateText.isNotEmpty)
                                      Flexible(
                                        child: Text(
                                          dateText,
                                          textAlign: TextAlign.end,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: MgrsColors.muted,
                                              ),
                                        ),
                                      ),
                                  ],
                                ),
                                const SizedBox(height: 2),
                                if (cond != null || actor != null) ...[
                                  const SizedBox(height: MgrsSpacing.xs),
                                  Text(
                                    [
                                      if (cond != null)
                                        conditionDisplayLabel(cond),
                                      if (actor != null && actor.isNotEmpty)
                                        actor,
                                    ].join(' · '),
                                    style: Theme.of(context).textTheme.bodySmall
                                        ?.copyWith(color: MgrsColors.muted),
                                  ),
                                ],
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
                        fontFamily: 'Inter',
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
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDamaged
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
                        fontFamily: 'Inter',
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isDamaged
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
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFF1F5F9))),
      ),
      child: Container(
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Center(
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.remove_red_eye_outlined,
                size: 16,
                color: Color(0xFF64748B),
              ),
              SizedBox(width: 8),
              Text(
                'Mode Pantau Status • Hanya Baca',
                style: TextStyle(
                  fontFamily: 'Inter',
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
