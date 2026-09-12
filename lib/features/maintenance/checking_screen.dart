import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../app/gateway.dart';
import '../../app/app_theme.dart';
import '../../shared/pressable.dart';
import '../components/component.dart';
import 'submission_controller.dart';

class CheckingScreen extends StatefulWidget {
  const CheckingScreen({
    super.key,
    required this.gateway,
    required this.component,
    this.service = false,
    this.taskId,
    this.periodId,
    this.correctsEventId,
  });

  final MaintenanceGateway gateway;
  final Component component;
  final bool service;
  final String? taskId, periodId, correctsEventId;

  @override
  State<CheckingScreen> createState() => _CheckingScreenState();
}

class _CheckingScreenState extends State<CheckingScreen> {
  final form = GlobalKey<FormState>();
  final note = TextEditingController(),
      impaired = TextEditingController(),
      problem = TextEditingController(),
      action = TextEditingController(),
      summary = TextEditingController(),
      reason = TextEditingController();

  late Component component;
  late final SubmissionController submission;
  String? condition, usable;
  String summaryAction = 'keep';
  bool dirty = false, leaving = false, refreshing = false;
  String? refreshError;

  @override
  void initState() {
    super.initState();
    component = widget.component;
    submission = SubmissionController(widget.gateway);

    // Initial defaults
    if (!widget.service) {
      condition = 'OK'; // Default Layak Pakai
      usable = 'Ya';
    } else {
      problem.text =
          'Indikasi penurunan tekanan drastis & kebocoran paking segel tabung.';
      action.text =
          'Penggantian karet O-Ring segel baru, pembersihan drat tabung, dan tes kompresi tekanan 10 bar selama 15 menit normal.';
      condition = 'OK';
      usable = 'Ya';
    }
  }

  @override
  void dispose() {
    for (final c in [note, impaired, problem, action, summary, reason]) {
      c.dispose();
    }
    super.dispose();
  }

  bool get severe => {'Rusak Berat', 'Service', 'Hilang'}.contains(condition);
  bool get blocked => submission.locked || refreshing;
  bool get canSaveAsManual =>
      widget.taskId != null &&
      submission.state == SubmissionState.failed &&
      submission.error is AppFailure &&
      (submission.error as AppFailure).code == 'task_not_open';

  Future<void> leave() async {
    if (leaving || (!dirty && !blocked)) {
      Navigator.pop(context);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Batalkan isian?'),
        content: const Text(
          'Perubahan yang belum disimpan akan hilang jika kembali.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Tetap di sini'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Buang isian'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => leaving = true);
      Navigator.pop(context);
    }
  }

  Future<void> refresh() async {
    setState(() {
      refreshing = true;
      refreshError = null;
    });
    try {
      final latest = await Component.load(widget.gateway, component.id);
      if (!mounted) return;
      setState(() {
        component = latest;
        submission.state = SubmissionState.idle;
        submission.error = null;
      });
    } catch (e) {
      if (mounted) setState(() => refreshError = failureMessage(e));
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  Future<void> save() async {
    if (!(form.currentState?.validate() ?? false)) return;
    if (condition == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pilih status kondisi terlebih dahulu.')),
      );
      return;
    }

    if (condition != 'OK' &&
        !widget.service &&
        note.text.trim().isEmpty &&
        impaired.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Harap tuliskan catatan kendala untuk unit yang bermasalah.',
          ),
        ),
      );
      return;
    }

    if (widget.service &&
        (problem.text.trim().isEmpty || action.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Harap isi deskripsi kendala dan tindakan servis.'),
        ),
      );
      return;
    }

    final command = <String, Object?>{
      'requestId': const Uuid().v4(),
      'componentId': component.id,
      'expectedVersion': component.version,
      'activity': widget.service
          ? 'service'
          : widget.taskId != null
          ? 'periodic_check'
          : 'manual_check',
      'condition': condition,
      'usable': usable ?? (severe ? 'Tidak' : 'Ya'),
      'impairedFunction': condition == 'OK'
          ? 'Tidak Ada'
          : (impaired.text.trim().isEmpty ? 'Tidak Ada' : impaired.text.trim()),
      'eventNote': note.text.trim(),
      'summaryAction': summaryAction,
      if (summaryAction == 'replace') 'summaryText': summary.text.trim(),
      if (widget.taskId != null) 'taskId': widget.taskId,
      if (widget.service) ...{
        'problem': problem.text.trim(),
        'action': action.text.trim(),
      },
      if (widget.correctsEventId != null) ...{
        'correctsEventId': widget.correctsEventId,
        'correctionReason': reason.text.trim(),
      },
    };
    final pending = submission.submit(command);
    setState(() {});
    await pending;
    await finish();
  }

  Future<void> finish() async {
    if (!mounted) return;
    if (submission.state == SubmissionState.succeeded) {
      setState(() => leaving = true);
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        barrierColor: Colors.black54,
        builder: (sheetContext) => _buildSuccessBottomSheet(sheetContext),
      );
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: leaving || (!dirty && !blocked),
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) leave();
      },
      child: Scaffold(
        backgroundColor: AppTokens.porcelain,
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                    20,
                    12,
                    20,
                    MediaQuery.viewInsetsOf(context).bottom + 24,
                  ),
                  child: Form(
                    key: form,
                    onChanged: () => dirty = true,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildTopBar(context),
                        const SizedBox(height: 16),
                        _buildComponentIdentityCard(context),
                        const SizedBox(height: 16),
                        if (!widget.service) ...[
                          _buildUpdateKondisiSection(context),
                          const SizedBox(height: 16),
                          _buildNotesSection(context),
                        ] else ...[
                          _buildServisFormFields(context),
                        ],
                        if (submission.error != null) ...[
                          const SizedBox(height: 16),
                          _buildSubmissionErrorBanner(context),
                        ],
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
              _buildBottomSubmitBar(context),
            ],
          ),
        ),
      ),
    );
  }

  // Top App Bar
  Widget _buildTopBar(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            PressableScale(
              onTap: blocked ? null : leave,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: AppTokens.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTokens.mistLight),
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
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.service ? 'Catat Servis' : 'Perbarui Kondisi',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTokens.ink,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  widget.service
                      ? 'Tindakan Perbaikan Fisik Unit'
                      : 'Pemeriksaan Rutin & Berkala',
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
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: widget.service
                ? AppTokens.mistLight
                : AppTokens.successSurface,
            borderRadius: BorderRadius.circular(AppTokens.badgeRadius),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 3,
                backgroundColor: widget.service
                    ? AppTokens.magenta
                    : AppTokens.success,
              ),
              const SizedBox(width: AppTokens.space4),
              Text(
                widget.service ? 'Perbaikan' : 'Rutin',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: widget.service ? AppTokens.magenta : AppTokens.success,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Component Identity Card
  Widget _buildComponentIdentityCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppTokens.space16),
      decoration: BoxDecoration(
        color: AppTokens.white,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        border: Border.all(color: AppTokens.mistLight),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: widget.service
                      ? AppTokens.dangerSurface
                      : AppTokens.mistLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Icon(
                    widget.service
                        ? Icons.build_circle_outlined
                        : Icons.check_circle_outline,
                    color: widget.service
                        ? AppTokens.danger
                        : AppTokens.magenta,
                    size: 22,
                  ),
                ),
              ),
              const SizedBox(width: AppTokens.space12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    component.code,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.ink,
                    ),
                  ),
                  const SizedBox(height: AppTokens.space4),
                  Text(
                    'Komponen ${component.kind} Utama • MGRS',
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
          if (!widget.service)
            PressableScale(
              onTap: blocked ? null : () => Navigator.pop(context),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: AppTokens.mistLight,
                  borderRadius: BorderRadius.circular(AppTokens.badgeRadius),
                  border: Border.all(color: AppTokens.mistLight),
                ),
                child: const Text(
                  'Ganti',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.graphite,
                  ),
                ),
              ),
            )
          else
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTokens.dangerSurface,
                borderRadius: BorderRadius.circular(AppTokens.badgeRadius),
              ),
              child: const Text(
                'Rusak',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.danger,
                ),
              ),
            ),
        ],
      ),
    );
  }

  // Update Kondisi Radio Cards Section
  Widget _buildUpdateKondisiSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTokens.white,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        border: Border.all(color: AppTokens.mistLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Status Kondisi Hasil Cek *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTokens.ink,
                ),
              ),
              Text(
                'Wajib Diisi',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  color: AppTokens.magenta,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTokens.space12),
          // Option 1: Layak Pakai
          _buildConditionRadioCard(
            title: 'Layak Pakai',
            description: 'Fisik prima & fungsi normal untuk operasi',
            value: 'OK',
            selected: condition == 'OK',
            activeBorderColor: AppTokens.success,
            activeBgColor: AppTokens.successSurface,
            dotColor: AppTokens.success,
            onSelect: () => setState(() {
              condition = 'OK';
              usable = 'Ya';
            }),
          ),
          const SizedBox(height: AppTokens.space8),
          // Option 2: Perlu Servis
          _buildConditionRadioCard(
            title: 'Perlu Servis',
            description: 'Ada keausan minor, butuh pelumasan / kalibrasi',
            value: 'Rusak Ringan',
            selected:
                condition == 'Rusak Ringan' || condition == 'Perlu Servis',
            activeBorderColor: AppTokens.warning,
            activeBgColor: AppTokens.warningSurface,
            dotColor: AppTokens.warning,
            onSelect: () => setState(() {
              condition = 'Rusak Ringan';
              usable = 'Ya';
            }),
          ),
          const SizedBox(height: AppTokens.space8),
          // Option 3: Gangguan Fungsi
          _buildConditionRadioCard(
            title: 'Gangguan Fungsi',
            description: 'Bocor / rusak berat, tidak boleh dipasang',
            value: 'Rusak Berat',
            selected: condition == 'Rusak Berat',
            activeBorderColor: AppTokens.danger,
            activeBgColor: AppTokens.dangerSurface,
            dotColor: AppTokens.danger,
            onSelect: () => setState(() {
              condition = 'Rusak Berat';
              usable = 'Tidak';
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildConditionRadioCard({
    required String title,
    required String description,
    required String value,
    required bool selected,
    required Color activeBorderColor,
    required Color activeBgColor,
    required Color dotColor,
    required VoidCallback onSelect,
  }) {
    return PressableScale(
      onTap: blocked ? null : onSelect,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? activeBgColor : AppTokens.white,
          borderRadius: BorderRadius.circular(AppTokens.controlRadius),
          border: Border.all(
            color: selected ? activeBorderColor : AppTokens.mistLight,
            width: selected ? 1.8 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? activeBorderColor : Colors.transparent,
                border: Border.all(
                  color: selected ? activeBorderColor : AppTokens.mist,
                  width: 2,
                ),
              ),
              child: selected
                  ? const Center(
                      child: Icon(
                        Icons.check,
                        size: 14,
                        color: AppTokens.white,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.ink,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.stone,
                    ),
                  ),
                ],
              ),
            ),
            CircleAvatar(radius: 3.5, backgroundColor: dotColor),
          ],
        ),
      ),
    );
  }

  // Notes Section
  Widget _buildNotesSection(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTokens.white,
        borderRadius: BorderRadius.circular(AppTokens.cardRadius),
        border: Border.all(color: AppTokens.mistLight),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Catatan Pemeriksaan (Opsional)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: AppTokens.ink,
            ),
          ),
          const SizedBox(height: AppTokens.space12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTokens.porcelain,
              borderRadius: BorderRadius.circular(AppTokens.controlRadius),
              border: Border.all(color: AppTokens.mistLight),
            ),
            child: TextField(
              controller: note,
              maxLines: 4,
              style: const TextStyle(
                fontSize: 13,
                color: AppTokens.graphite,
                height: 1.45,
              ),
              decoration: const InputDecoration(
                hintText:
                    'Kondisi katup & konektor bersih, segel utuh tanpa indikasi keausan mekanis, siap digunakan.',
                hintStyle: TextStyle(fontSize: 13, color: AppTokens.mist),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
                filled: false,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Servis Form Fields
  Widget _buildServisFormFields(BuildContext context) {
    return Column(
      children: [
        // 1. Masalah / Kendala Fisik
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: AppTokens.white,
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            border: Border.all(color: AppTokens.mistLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Masalah / Kendala Fisik *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.ink,
                    ),
                  ),
                  Text(
                    'Wajib Diisi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.magenta,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTokens.porcelain,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppTokens.mistLight),
                ),
                child: TextField(
                  controller: problem,
                  maxLines: 3,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTokens.graphite,
                    height: 1.45,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Tuliskan kerusakan atau gejala masalah...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 2. Tindakan Perbaikan
        Container(
          padding: const EdgeInsets.all(AppTokens.space16),
          decoration: BoxDecoration(
            color: AppTokens.white,
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            border: Border.all(color: AppTokens.mistLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tindakan Perbaikan yang Dilakukan *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.ink,
                    ),
                  ),
                  Text(
                    'Wajib Diisi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.magenta,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppTokens.space12),
              Container(
                padding: const EdgeInsets.all(AppTokens.space12),
                decoration: BoxDecoration(
                  color: AppTokens.porcelain,
                  borderRadius: BorderRadius.circular(AppTokens.controlRadius),
                  border: Border.all(color: AppTokens.mistLight),
                ),
                child: TextField(
                  controller: action,
                  maxLines: 4,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppTokens.graphite,
                    height: 1.45,
                  ),
                  decoration: const InputDecoration(
                    hintText: 'Tuliskan penanganan teknis yang dilakukan...',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                    filled: false,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // 3. Kondisi Hasil Setelah Servis
        Container(
          padding: const EdgeInsets.all(AppTokens.space16),
          decoration: BoxDecoration(
            color: AppTokens.white,
            borderRadius: BorderRadius.circular(AppTokens.cardRadius),
            border: Border.all(color: AppTokens.mistLight),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Kondisi Hasil Setelah Servis *',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.ink,
                    ),
                  ),
                  Text(
                    'Wajib Diisi',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.magenta,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Option A: Layak Pakai
              _buildConditionRadioCard(
                title: 'Layak Pakai (Selesai & Siap Pakai)',
                description: 'Perbaikan sukses, unit kembali normal',
                value: 'OK',
                selected: condition == 'OK',
                activeBorderColor: AppTokens.success,
                activeBgColor: AppTokens.successSurface,
                dotColor: AppTokens.success,
                onSelect: () => setState(() {
                  condition = 'OK';
                  usable = 'Ya';
                }),
              ),
              const SizedBox(height: 10),
              // Option B: Masih Perlu Servis Lanjutan
              _buildConditionRadioCard(
                title: 'Masih Perlu Servis Lanjutan',
                description: 'Belum tuntas, menunggu sparepart',
                value: 'Rusak Ringan',
                selected: condition == 'Rusak Ringan',
                activeBorderColor: AppTokens.warning,
                activeBgColor: AppTokens.warningSurface,
                dotColor: AppTokens.warning,
                onSelect: () => setState(() {
                  condition = 'Rusak Ringan';
                  usable = 'Tidak';
                }),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Submit action
  Widget _buildBottomSubmitBar(BuildContext context) {
    final isSubmitting = submission.state == SubmissionState.submitting;

    return Container(
      padding: const EdgeInsets.fromLTRB(0, 10, 0, 24),
      decoration: const BoxDecoration(
        color: AppTokens.white,
        border: Border(top: BorderSide(color: AppTokens.mistLight)),
      ),
      child: SizedBox(
        width: double.infinity,
        height: 50,
        child: PressableScale(
          onTap: blocked ? null : save,
          child: Container(
            decoration: BoxDecoration(
              color: blocked ? AppTokens.mist : AppTokens.magenta,
              borderRadius: BorderRadius.circular(AppTokens.controlRadius),
              boxShadow: blocked
                  ? null
                  : [
                      BoxShadow(
                        color: AppTokens.magenta.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: Offset(0, 3),
                      ),
                    ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isSubmitting)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: AppTokens.white,
                    ),
                  )
                else
                  Icon(
                    widget.service ? Icons.build_rounded : Icons.check_rounded,
                    color: AppTokens.white,
                    size: 18,
                  ),
                const SizedBox(width: 8),
                Text(
                  isSubmitting
                      ? 'Menyimpan…'
                      : widget.service
                      ? 'Simpan & Selesaikan Servis'
                      : 'Simpan & Selesaikan Tugas',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppTokens.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSubmissionErrorBanner(BuildContext context) {
    final err = submission.error;
    final isConflict = submission.state == SubmissionState.conflict;
    final isUncertain = submission.state == SubmissionState.uncertain;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTokens.dangerSurface,
        borderRadius: BorderRadius.circular(AppTokens.badgeRadius),
        border: Border.all(color: AppTokens.dangerSurface),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.error_outline_rounded,
                color: AppTokens.danger,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  isConflict
                      ? 'Konflik Data Pembaruan'
                      : isUncertain
                      ? 'Koneksi Terputus / Tidak Stabil'
                      : 'Gagal Menyimpan Data',
                  style: const TextStyle(
                    color: AppTokens.danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            failureMessage(err),
            style: const TextStyle(
              color: AppTokens.danger,
              fontSize: 12,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              if (isConflict)
                OutlinedButton.icon(
                  onPressed: refreshing ? null : refresh,
                  icon: const Icon(Icons.refresh_rounded, size: 16),
                  label: const Text(
                    'Perbarui Data Unit',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppTokens.danger,
                    side: const BorderSide(color: AppTokens.dangerSurface),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTokens.badgeRadius,
                      ),
                    ),
                  ),
                )
              else
                ElevatedButton.icon(
                  onPressed: blocked
                      ? null
                      : (isUncertain ? submission.recover : save),
                  icon: const Icon(
                    Icons.replay_rounded,
                    size: 16,
                    color: AppTokens.white,
                  ),
                  label: const Text(
                    'Coba Kirim Ulang',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.danger,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                        AppTokens.badgeRadius,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessBottomSheet(BuildContext ctx) {
    final isService = widget.service;
    final isOk = condition == 'OK';

    return Container(
      decoration: const BoxDecoration(
        color: AppTokens.white,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTokens.cardRadius),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(ctx).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTokens.mistLight,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTokens.successSurface,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: AppTokens.success.withValues(alpha: 0.2),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.check_circle_rounded,
                color: AppTokens.success,
                size: 36,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            isService ? 'Laporan Servis Berhasil!' : 'Pemeriksaan Berhasil!',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              color: AppTokens.ink,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isService
                ? 'Catatan perbaikan telah disimpan dan status unit berhasil diperbarui.'
                : 'Pemeriksaan rutin telah berhasil disimpan ke sistem MGRS.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTokens.stone,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTokens.porcelain,
              borderRadius: BorderRadius.circular(AppTokens.controlRadius),
              border: Border.all(color: AppTokens.mistLight),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Unit Komponen',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.stone,
                      ),
                    ),
                    Text(
                      '${component.code} (${component.kind})',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink,
                      ),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Divider(height: 1, color: AppTokens.mistLight),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Status Kelayakan',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.stone,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: isOk
                            ? AppTokens.successSurface
                            : (condition == 'Rusak Ringan'
                                  ? AppTokens.warningSurface
                                  : AppTokens.dangerSurface),
                        borderRadius: BorderRadius.circular(
                          AppTokens.badgeRadius,
                        ),
                      ),
                      child: Text(
                        isOk
                            ? 'Layak Pakai (OK)'
                            : (condition == 'Rusak Ringan'
                                  ? 'Perlu Servis'
                                  : (condition ?? 'Perlu Tindakan')),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: isOk
                              ? AppTokens.success
                              : (condition == 'Rusak Ringan'
                                    ? AppTokens.warning
                                    : AppTokens.danger),
                        ),
                      ),
                    ),
                  ],
                ),
                if (isService && action.text.trim().isNotEmpty) ...[
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8),
                    child: Divider(height: 1, color: AppTokens.mistLight),
                  ),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Tindakan',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.stone,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Text(
                          action.text.trim(),
                          textAlign: TextAlign.end,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppTokens.graphite,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(ctx),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTokens.magenta,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTokens.controlRadius),
                ),
              ),
              child: const Text(
                'Selesai & Kembali',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
