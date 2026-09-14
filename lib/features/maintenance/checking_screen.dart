import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

import '../../app/gateway.dart';
import '../../design_system/components/mgrs_app_bar.dart';
import '../../design_system/components/mgrs_button.dart';
import '../../design_system/components/mgrs_multiline_field.dart';
import '../../design_system/components/mgrs_status_badge.dart';
import '../../design_system/mgrs_tokens.dart';
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
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  final _impaired = TextEditingController();
  final _problem = TextEditingController();
  final _action = TextEditingController();
  final _summary = TextEditingController();
  final _reason = TextEditingController();
  final _problemFocus = FocusNode();
  final _actionFocus = FocusNode();
  final _noteFocus = FocusNode();
  final _impairedFocus = FocusNode();
  final _reasonFocus = FocusNode();

  late Component _component;
  late final SubmissionController _submission;
  String? _condition;
  String? _usable;
  String _summaryAction = 'keep';
  bool _dirty = false;
  bool _leaving = false;
  bool _refreshing = false;
  bool _showValidation = false;
  bool _refreshFailed = false;

  bool get _blocked => _submission.locked || _refreshing ||
      _submission.state == SubmissionState.conflict;
  bool get _isProblemCondition => _condition != null && _condition != 'OK';

  @override
  void initState() {
    super.initState();
    _component = widget.component;
    _submission = SubmissionController(widget.gateway);
    if (!widget.service) {
      _condition = 'OK';
      _usable = 'Ya';
    }
  }

  @override
  void dispose() {
    for (final controller in [_note, _impaired, _problem, _action, _summary, _reason]) {
      controller.dispose();
    }
    _problemFocus.dispose();
    _actionFocus.dispose();
    _noteFocus.dispose();
    _impairedFocus.dispose();
    _reasonFocus.dispose();
    super.dispose();
  }

  void _changed([String? _]) {
    if (!_dirty) setState(() => _dirty = true);
  }

  Future<void> _leave() async {
    if (_leaving || (!_dirty && !_blocked)) {
      if (mounted) Navigator.maybePop(context);
      return;
    }
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Batalkan isian?'),
        content: const Text('Perubahan yang belum disimpan akan hilang jika kembali.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Tetap di sini'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Buang isian'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) {
      setState(() => _leaving = true);
      Navigator.maybePop(context);
    }
  }

  bool _validate() {
    final missingProblem = widget.service && _problem.text.trim().isEmpty;
    final missingAction = widget.service && _action.text.trim().isEmpty;
    final missingCondition = _condition == null;
    final missingNote = _isProblemCondition && _note.text.trim().isEmpty;
    final missingImpaired = _isProblemCondition && _impaired.text.trim().isEmpty;
    final missingReason =
        widget.correctsEventId != null && _reason.text.trim().isEmpty;
    setState(() => _showValidation = missingProblem || missingAction ||
        missingCondition || missingNote || missingImpaired || missingReason);
    if (missingProblem) {
      _problemFocus.requestFocus();
    } else if (missingAction) {
      _actionFocus.requestFocus();
    } else if (missingNote) {
      _noteFocus.requestFocus();
    } else if (missingImpaired) {
      _impairedFocus.requestFocus();
    } else if (missingReason) {
      _reasonFocus.requestFocus();
    }
    return !_showValidation;
  }

  Future<void> _save() async {
    if (_blocked || !_validate()) return;
    final command = <String, Object?>{
      'requestId': const Uuid().v4(),
      'componentId': _component.id,
      'expectedVersion': _component.version,
      'activity': widget.service
          ? 'service'
          : widget.taskId != null
              ? 'periodic_check'
              : 'manual_check',
      'condition': _condition,
      'usable': _usable ?? (_condition == 'OK' ? 'Ya' : 'Tidak'),
      'impairedFunction': _condition == 'OK'
          ? 'Tidak Ada'
          : (_impaired.text.trim().isEmpty ? 'Tidak Ada' : _impaired.text.trim()),
      'eventNote': _note.text.trim(),
      'summaryAction': _summaryAction,
      if (_summaryAction == 'replace') 'summaryText': _summary.text.trim(),
      if (widget.taskId != null) 'taskId': widget.taskId,
      if (widget.service) ...{
        'problem': _problem.text.trim(),
        'action': _action.text.trim(),
      },
      if (widget.correctsEventId != null) ...{
        'correctsEventId': widget.correctsEventId,
        'correctionReason': _reason.text.trim(),
      },
    };
    final pending = _submission.submit(command);
    setState(() {});
    await pending;
    await _finish();
  }

  Future<void> _recover() async {
    if (_blocked && _submission.state != SubmissionState.uncertain) return;
    final pending = _submission.recover();
    setState(() {});
    await pending;
    await _finish();
  }

  Future<void> _refresh() async {
    setState(() {
      _refreshing = true;
      _refreshFailed = false;
    });
    try {
      final latest = await Component.load(widget.gateway, _component.id);
      if (!mounted) return;
      setState(() {
        _component = latest;
        _submission.state = SubmissionState.idle;
        _submission.error = null;
      });
    } catch (_) {
      if (mounted) setState(() => _refreshFailed = true);
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Future<void> _finish() async {
    if (!mounted) return;
    if (_submission.state != SubmissionState.succeeded) {
      setState(() {});
      return;
    }
    setState(() => _leaving = true);
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (sheetContext) => _SuccessSheet(
        title: widget.service ? 'Laporan servis tersimpan' : 'Pemeriksaan tersimpan',
        body: widget.service
            ? 'Catatan perbaikan dan kondisi terbaru komponen sudah diperbarui.'
            : 'Hasil pemeriksaan rutin sudah disimpan ke sistem MGRS.',
        onFinish: () => Navigator.pop(sheetContext),
      ),
    );
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    return PopScope(
      canPop: _leaving || (!_dirty && !_blocked),
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _leave();
      },
      child: Scaffold(
        backgroundColor: MgrsColors.canvas,
        appBar: MgrsDetailAppBar(
          title: widget.service ? 'Catat servis' : 'Perbarui kondisi',
          onBack: _blocked ? () {} : _leave,
        ),
        body: SafeArea(
          top: false,
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: MgrsSizes.maxContentWidth),
              child: Form(
                key: _formKey,
                child: ListView(
                  padding: EdgeInsets.fromLTRB(20, 20, 20, 24 + keyboard),
                  children: [
                    _identity(),
                    const SizedBox(height: MgrsSpacing.lg),
                    if (_showValidation) ...[
                      _message(
                        title: 'Periksa kembali isian',
                        body: 'Lengkapi bagian bertanda sebelum menyimpan.',
                        tone: MgrsStatusTone.danger,
                      ),
                      const SizedBox(height: MgrsSpacing.base),
                    ],
                    if (widget.service) _serviceFields() else _checkingFields(),
                    if (widget.correctsEventId != null) ...[
                      const SizedBox(height: MgrsSpacing.base),
                      MgrsMultilineField(
                        label: 'Alasan koreksi *',
                        controller: _reason,
                        focusNode: _reasonFocus,
                        onChanged: _changed,
                        errorText: _showValidation && _reason.text.trim().isEmpty
                            ? 'Tuliskan alasan koreksi.'
                            : null,
                      ),
                    ],
                    if (_submission.state != SubmissionState.idle &&
                        _submission.state != SubmissionState.submitting &&
                        _submission.state != SubmissionState.succeeded) ...[
                      const SizedBox(height: MgrsSpacing.base),
                      _submissionMessage(),
                    ],
                    if (_refreshFailed) ...[
                      const SizedBox(height: MgrsSpacing.base),
                      _message(
                        title: 'Data terbaru belum dapat dimuat',
                        body: 'Draft tetap aman. Periksa koneksi, lalu coba lagi.',
                        tone: MgrsStatusTone.danger,
                      ),
                    ],
                    const SizedBox(height: MgrsSpacing.xl),
                    _primaryAction(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _identity() => _section(
        title: _component.code,
        child: Wrap(
          spacing: MgrsSpacing.sm,
          runSpacing: MgrsSpacing.sm,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(_component.kind),
            MgrsStatusBadge(_component.condition),
            MgrsStatusBadge(_component.usable == 'Ya' ? 'Layak Pakai' : 'Tidak Layak'),
          ],
        ),
      );

  Widget _checkingFields() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _section(
            title: 'Kondisi komponen',
            child: _conditionChoices(),
          ),
          const SizedBox(height: MgrsSpacing.base),
          MgrsMultilineField(
            label: _isProblemCondition
                ? 'Catatan pemeriksaan *'
                : 'Catatan pemeriksaan · opsional',
            controller: _note,
            focusNode: _noteFocus,
            onChanged: _changed,
            errorText: _showValidation && _isProblemCondition &&
                    _note.text.trim().isEmpty
                ? 'Jelaskan kendala yang ditemukan.'
                : null,
          ),
          if (_isProblemCondition) ...[
            const SizedBox(height: MgrsSpacing.base),
            MgrsMultilineField(
              label: 'Fungsi yang terganggu *',
              controller: _impaired,
              focusNode: _impairedFocus,
              onChanged: _changed,
              errorText: _showValidation && _impaired.text.trim().isEmpty
                  ? 'Jelaskan fungsi yang terganggu.'
                  : null,
            ),
          ],
        ],
      );

  Widget _serviceFields() => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          MgrsMultilineField(
            label: 'Masalah / kendala fisik *',
            controller: _problem,
            focusNode: _problemFocus,
            onChanged: _changed,
            errorText: _showValidation && _problem.text.trim().isEmpty
                ? 'Jelaskan masalah yang ditemukan.'
                : null,
          ),
          const SizedBox(height: MgrsSpacing.base),
          MgrsMultilineField(
            label: 'Tindakan perbaikan *',
            controller: _action,
            focusNode: _actionFocus,
            onChanged: _changed,
            errorText: _showValidation && _action.text.trim().isEmpty
                ? 'Tuliskan tindakan servis yang dilakukan.'
                : null,
          ),
          const SizedBox(height: MgrsSpacing.base),
          _section(
            title: 'Kondisi setelah servis',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _conditionChoices(),
                if (_showValidation && _condition == null) ...[
                  const SizedBox(height: MgrsSpacing.sm),
                  const Text(
                    'Kondisi setelah servis belum dipilih',
                    style: TextStyle(color: MgrsColors.danger, fontWeight: FontWeight.w700),
                  ),
                  const Text(
                    'Pilih Layak pakai atau Perlu servis lanjutan.',
                    style: TextStyle(color: MgrsColors.danger),
                  ),
                ],
              ],
            ),
          ),
          if (_isProblemCondition) ...[
            const SizedBox(height: MgrsSpacing.base),
            MgrsMultilineField(
              label: 'Catatan kondisi setelah servis *',
              controller: _note,
              focusNode: _noteFocus,
              onChanged: _changed,
              errorText: _showValidation && _note.text.trim().isEmpty
                  ? 'Jelaskan kondisi setelah servis.'
                  : null,
            ),
            const SizedBox(height: MgrsSpacing.base),
            MgrsMultilineField(
              label: 'Fungsi yang masih terganggu *',
              controller: _impaired,
              focusNode: _impairedFocus,
              onChanged: _changed,
              errorText: _showValidation && _impaired.text.trim().isEmpty
                  ? 'Jelaskan fungsi yang masih terganggu.'
                  : null,
            ),
          ],
        ],
      );

  Widget _conditionChoices() => Wrap(
        spacing: MgrsSpacing.sm,
        runSpacing: MgrsSpacing.sm,
        children: widget.service
            ? [
                _choice('Layak pakai', 'OK', 'Ya'),
                _choice('Perlu servis lanjutan', 'Service', 'Tidak'),
              ]
            : [
                _choice('Layak pakai', 'OK', 'Ya'),
                _choice('Rusak ringan', 'Rusak Ringan', 'Ya'),
                _choice('Rusak berat', 'Rusak Berat', 'Tidak'),
              ],
      );

  Widget _choice(String label, String value, String usable) => ConstrainedBox(
        constraints: const BoxConstraints(minHeight: MgrsSizes.minTouch),
        child: ChoiceChip(
          label: Text(label),
          selected: _condition == value,
          onSelected: _blocked
              ? null
              : (_) => setState(() {
                    _condition = value;
                    _usable = usable;
                    _dirty = true;
                    _showValidation = false;
                  }),
        ),
      );

  Widget _submissionMessage() {
    return switch (_submission.state) {
      SubmissionState.conflict => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _message(
              title: 'Data telah diperbarui petugas lain',
              body: 'Muat kondisi terbaru sebelum menyimpan kembali. Draft catatan Anda tetap aman.',
              tone: MgrsStatusTone.warning,
            ),
            const SizedBox(height: MgrsSpacing.md),
            MgrsButton.neutral(
              label: 'Muat data terbaru',
              loading: _refreshing,
              onPressed: _refreshing ? null : _refresh,
            ),
          ],
        ),
      SubmissionState.uncertain => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _message(
              title: 'Status penyimpanan belum diketahui',
              body: 'Periksa status sebelum mencoba menyimpan kembali.',
              tone: MgrsStatusTone.warning,
            ),
            const SizedBox(height: MgrsSpacing.md),
            MgrsButton.neutral(
              label: 'Periksa status penyimpanan',
              onPressed: _recover,
            ),
          ],
        ),
      SubmissionState.failed => _message(
          title: 'Data belum dapat disimpan',
          body: 'Periksa kembali isian, lalu coba simpan lagi.',
          tone: MgrsStatusTone.danger,
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _primaryAction() {
    final submitting = _submission.state == SubmissionState.submitting;
    return MgrsButton.primary(
      label: widget.service ? 'Simpan laporan servis' : 'Simpan pemeriksaan',
      loading: submitting,
      onPressed: _blocked ? null : _save,
    );
  }

  Widget _section({required String title, required Widget child}) => DecoratedBox(
        decoration: BoxDecoration(
          color: MgrsColors.surface,
          border: Border.all(color: MgrsColors.line),
          borderRadius: BorderRadius.circular(MgrsRadii.compact),
        ),
        child: Padding(
          padding: const EdgeInsets.all(MgrsSpacing.base),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: MgrsSpacing.md),
              child,
            ],
          ),
        ),
      );

  Widget _message({
    required String title,
    required String body,
    required MgrsStatusTone tone,
  }) => _section(
        title: title,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MgrsStatusBadge(
              tone == MgrsStatusTone.danger ? 'Perlu diperiksa' : 'Perhatian',
              tone: tone,
            ),
            const SizedBox(height: MgrsSpacing.sm),
            Text(body),
          ],
        ),
      );
}

class _SuccessSheet extends StatelessWidget {
  const _SuccessSheet({
    required this.title,
    required this.body,
    required this.onFinish,
  });

  final String title;
  final String body;
  final VoidCallback onFinish;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(
          MgrsSpacing.lg,
          MgrsSpacing.xl,
          MgrsSpacing.lg,
          MgrsSpacing.xl + MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const MgrsStatusBadge('Tersimpan', tone: MgrsStatusTone.success),
            const SizedBox(height: MgrsSpacing.base),
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: MgrsSpacing.sm),
            Text(body),
            const SizedBox(height: MgrsSpacing.xl),
            MgrsButton.primary(label: 'Selesai', onPressed: onFinish),
          ],
        ),
      );
}
