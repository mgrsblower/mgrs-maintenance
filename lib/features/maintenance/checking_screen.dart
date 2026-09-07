import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../app/gateway.dart';
import '../../shared/async_state_view.dart';
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
      const {
        'component_unavailable',
        'task_already_completed',
      }.contains((submission.error as AppFailure).code);
  String get title => widget.correctsEventId != null
      ? 'Koreksi catatan'
      : widget.service
      ? 'Catat servis'
      : widget.taskId != null
      ? 'Pemeriksaan berkala'
      : 'Catat pemeriksaan';
  String? requiredText(String? value) =>
      value == null || value.trim().isEmpty ? 'Kolom ini wajib diisi.' : null;
  Future<void> leave() async {
    if (blocked) return;
    final approved =
        !dirty ||
        await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Text('Batalkan pencatatan?'),
                content: const Text('Isian yang belum disimpan akan hilang.'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text('Lanjut isi'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text('Batalkan'),
                  ),
                ],
              ),
            ) ==
            true;
    if (approved && mounted) {
      setState(() => leaving = true);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    }
  }

  Future<void> refresh() async {
    setState(() {
      refreshing = true;
      refreshError = null;
    });
    try {
      final latest = await Component.load(widget.gateway, component.id);
      if (mounted) {
        setState(() {
          component = latest;
          submission.state = SubmissionState.idle;
          submission.error = null;
        });
      }
    } catch (e) {
      if (mounted) setState(() => refreshError = failureMessage(e));
    } finally {
      if (mounted) setState(() => refreshing = false);
    }
  }

  Future<void> save() async {
    if (blocked ||
        submission.state == SubmissionState.conflict ||
        !form.currentState!.validate()) {
      return;
    }
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Simpan hasil ini?'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InfoLine('Komponen', '${component.kind} · ${component.code}'),
              InfoLine('Kegiatan', title),
              if (widget.taskId != null)
                InfoLine(
                  'Periode',
                  widget.periodId ?? 'Sesuai tugas yang dipilih',
                ),
              InfoLine('Hasil kondisi', condition!),
              InfoLine('Boleh digunakan', usable!),
              InfoLine(
                'Catatan',
                note.text.trim().isEmpty
                    ? 'Tidak ada catatan'
                    : note.text.trim(),
              ),
              if (widget.service) ...[
                InfoLine('Masalah', problem.text.trim()),
                InfoLine('Tindakan', action.text.trim()),
              ],
              InfoLine('Ringkasan kondisi', switch (summaryAction) {
                'clear' => 'Hapus ringkasan sebelumnya',
                'replace' => summary.text.trim(),
                _ => 'Pertahankan ringkasan sebelumnya',
              }),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Periksa lagi'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;
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
      'usable': usable,
      'impairedFunction': condition == 'OK'
          ? 'Tidak Ada'
          : impaired.text.trim(),
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

  Future<void> recover() async {
    final pending = submission.recover();
    setState(() {});
    await pending;
    await finish();
  }

  Future<void> saveAsManual() async {
    final previous = submission.command;
    if (!canSaveAsManual || previous == null) return;
    final command = Map<String, Object?>.from(previous)
      ..['requestId'] = const Uuid().v4()
      ..['activity'] = 'manual_check'
      ..remove('taskId');
    submission.state = SubmissionState.idle;
    submission.error = null;
    final pending = submission.submit(command);
    setState(() {});
    await pending;
    await finish();
  }

  Future<void> finish() async {
    if (!mounted) return;
    if (submission.state == SubmissionState.succeeded) {
      setState(() => leaving = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Hasil berhasil disimpan.')));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) Navigator.pop(context);
      });
    } else {
      setState(() {});
    }
  }

  Widget field(
    String label,
    TextEditingController controller, {
    bool required = false,
    int max = 2000,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      enabled: !blocked,
      minLines: 2,
      maxLines: 4,
      maxLength: max,
      decoration: InputDecoration(labelText: label),
      validator: required ? requiredText : null,
    ),
  );
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: leaving || (!dirty && !blocked),
    onPopInvokedWithResult: (didPop, result) {
      if (!didPop) leave();
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: BackButton(onPressed: blocked ? null : leave),
      ),
      body: PageBody(
        children: [
          Text(
            '${component.kind} · ${component.code}',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Kondisi tercatat: ${component.condition}. Pilih hasil sesuai pemeriksaan saat ini.',
          ),
          if (widget.taskId != null) ...[
            const SizedBox(height: 8),
            Text(
              'Periode ${widget.periodId ?? 'dari daftar berkala'}. Pemeriksaan komponen Hilang belum menyelesaikan tugas.',
            ),
          ],
          const SizedBox(height: 24),
          Form(
            key: form,
            onChanged: () {
              dirty = true;
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (widget.correctsEventId != null) ...[
                  const Text(
                    'Koreksi menambah catatan baru. Catatan asli tetap tersimpan.',
                  ),
                  const SizedBox(height: 12),
                  field('Alasan koreksi', reason, required: true),
                ],
                if (widget.service) ...[
                  field('Masalah yang ditemukan', problem, required: true),
                  field('Tindakan servis', action, required: true),
                ],
                DropdownButtonFormField<String>(
                  initialValue: condition,
                  decoration: const InputDecoration(labelText: 'Hasil kondisi'),
                  items:
                      ['OK', 'Rusak Ringan', 'Rusak Berat', 'Service', 'Hilang']
                          .map(
                            (v) => DropdownMenuItem(value: v, child: Text(v)),
                          )
                          .toList(),
                  validator: (v) =>
                      v == null ? 'Pilih hasil pemeriksaan.' : null,
                  onChanged: blocked
                      ? null
                      : (v) => setState(() {
                          condition = v;
                          if (severe) usable = 'Tidak';
                        }),
                ),
                const SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  key: ValueKey('usable-$usable-$severe'),
                  initialValue: usable,
                  decoration: const InputDecoration(
                    labelText: 'Boleh digunakan',
                  ),
                  items: ['Ya', 'Tidak']
                      .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                      .toList(),
                  validator: (v) =>
                      v == null ? 'Tentukan kelayakan komponen.' : null,
                  onChanged: blocked || severe
                      ? null
                      : (v) => setState(() => usable = v),
                ),
                if (severe) ...[
                  const SizedBox(height: 8),
                  const Text('Kondisi ini tidak boleh digunakan.'),
                ],
                const SizedBox(height: 16),
                if (condition != null && condition != 'OK')
                  field(
                    'Fungsi yang terganggu',
                    impaired,
                    required: true,
                    max: 500,
                  ),
                field(
                  condition != null && condition != 'OK'
                      ? 'Temuan pemeriksaan (wajib)'
                      : 'Catatan pemeriksaan',
                  note,
                  required: condition != null && condition != 'OK',
                ),
                DropdownButtonFormField<String>(
                  initialValue: summaryAction,
                  decoration: const InputDecoration(
                    labelText: 'Ringkasan kondisi komponen',
                  ),
                  items: const [
                    DropdownMenuItem(
                      value: 'keep',
                      child: Text('Pertahankan catatan sebelumnya'),
                    ),
                    DropdownMenuItem(
                      value: 'replace',
                      child: Text('Ganti dengan catatan baru'),
                    ),
                    DropdownMenuItem(
                      value: 'clear',
                      child: Text('Hapus catatan sebelumnya'),
                    ),
                  ],
                  onChanged: blocked
                      ? null
                      : (v) => setState(() => summaryAction = v!),
                ),
                const SizedBox(height: 12),
                Text(
                  'Catatan sebelumnya: ${component.note ?? 'Tidak ada catatan'}',
                ),
                const SizedBox(height: 16),
                if (summaryAction == 'replace')
                  field('Ringkasan baru', summary, required: true),
                if (widget.service) ...[
                  const Text(
                    'Biaya servis belum dicatat melalui aplikasi ini.',
                  ),
                  const SizedBox(height: 16),
                ],
                if (submission.error != null) ...[
                  Text(
                    submission.state == SubmissionState.uncertain
                        ? 'Status penyimpanan belum diketahui. Periksa hasil sebelum mencoba lagi.'
                        : failureMessage(submission.error),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                if (refreshError != null) Text(refreshError!),
                if (canSaveAsManual) ...[
                  const Text(
                    'Tugas berkala tetap terbuka. Temuan ini dapat disimpan sebagai pemeriksaan manual.',
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: saveAsManual,
                    child: const Text('Simpan sebagai pemeriksaan manual'),
                  ),
                  const SizedBox(height: 12),
                ],
                if (submission.state == SubmissionState.conflict)
                  OutlinedButton(
                    onPressed: refreshing ? null : refresh,
                    child: Text(
                      refreshing ? 'Memuat kondisi…' : 'Muat kondisi terbaru',
                    ),
                  )
                else if (submission.state == SubmissionState.uncertain)
                  FilledButton(
                    onPressed: recover,
                    child: const Text('Periksa dan lanjutkan penyimpanan'),
                  )
                else
                  FilledButton(
                    onPressed: blocked ? null : save,
                    child: Text(
                      submission.state == SubmissionState.submitting
                          ? 'Menyimpan…'
                          : 'Tinjau hasil',
                    ),
                  ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
