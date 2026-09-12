import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';
import '../invoices/invoice_model.dart';

class CreateOrderScreen extends StatefulWidget {
  const CreateOrderScreen({
    super.key,
    required this.gateway,
    required this.user,
  });

  final MaintenanceGateway gateway;
  final UserProfile user;

  @override
  State<CreateOrderScreen> createState() => _CreateOrderScreenState();
}

class _CreateOrderScreenState extends State<CreateOrderScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapsController = TextEditingController();
  final _noteController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  int _rentalDays = 1;
  int _unitCount = 1;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _eventNameController.dispose();
    _clientNameController.dispose();
    _whatsappController.dispose();
    _addressController.dispose();
    _mapsController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  num get _totalInvoiceAmount => _unitCount * 250000 * _rentalDays;

  String get _generatedOrderId {
    final y = _selectedDate.year.toString().padLeft(4, '0');
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    return 'ORD-$y$m$d-${Random().nextInt(900) + 100}';
  }

  static String _formatDateFull(DateTime date) {
    const days = [
      'Senin',
      'Selasa',
      'Rabu',
      'Kamis',
      'Jumat',
      'Sabtu',
      'Minggu',
    ];
    const months = [
      'Januari',
      'Februari',
      'Maret',
      'April',
      'Mei',
      'Juni',
      'Juli',
      'Agustus',
      'September',
      'Oktober',
      'November',
      'Desember',
    ];
    return '${days[date.weekday - 1]}, ${date.day} ${months[date.month - 1]} ${date.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  Future<void> _submitOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSubmitting = true);
    try {
      final y = _selectedDate.year.toString().padLeft(4, '0');
      final m = _selectedDate.month.toString().padLeft(2, '0');
      final d = _selectedDate.day.toString().padLeft(2, '0');
      final dateStr = '$y-$m-$d';
      final rawNote = _noteController.text.trim();
      final composedNote =
          '$rawNote [SEWA_HARI:$_rentalDays] [TGL_EVENT:$dateStr]'.trim();
      final orderanId = _generatedOrderId;
      final payload = <String, Object?>{
        'orderan_id': orderanId,
        'tanggal_pemasangan': dateStr,
        'nama_event': _eventNameController.text.trim(),
        'nama_client': _clientNameController.text.trim(),
        'alamat': _addressController.text.trim(),
        'nomor_whatsapp': _whatsappController.text.trim(),
        'link_gmaps': _mapsController.text.trim(),
        'jumlah_unit': _unitCount,
        'catatan_orderan': composedNote,
        'status_orderan': 'Terjadwal',
      };
      await widget.gateway.createOrderWithInvoice(payload);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Orderan $orderanId dan Invoice berhasil dibuat!'),
        ),
      );
      Navigator.of(context).pop(true);
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat orderan: $error'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Scaffold(
      backgroundColor: colors.surfaceContainerLow,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            const Divider(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppTokens.space16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSectionHeader(
                        icon: Icons.event_note_rounded,
                        title: 'Informasi Acara & Klien',
                        caption: 'Wajib Diisi',
                      ),
                      _buildFormField(
                        controller: _eventNameController,
                        label: 'Nama Acara / Event *',
                        hint: 'Misal: Pernikahan Budi & Ani, Konser Musik',
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Harap isi nama acara'
                            : null,
                      ),
                      _spacer(),
                      _buildFormField(
                        controller: _clientNameController,
                        label: 'Nama Klien / Penyelenggara *',
                        hint: 'Misal: Ibu Sarah / PT Maju Jaya',
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Harap isi nama klien'
                            : null,
                      ),
                      _spacer(),
                      _buildFormField(
                        controller: _whatsappController,
                        label: 'Nomor WhatsApp Klien *',
                        hint: 'Contoh: 08123456789',
                        keyboardType: TextInputType.phone,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Harap isi nomor WhatsApp klien'
                            : null,
                      ),
                      _sectionGap(),
                      _buildSectionHeader(
                        icon: Icons.calendar_today_rounded,
                        title: 'Jadwal & Kebutuhan Unit',
                      ),
                      _buildDatePickerField(),
                      _spacer(),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStepperBox(
                              title: 'Jumlah Unit',
                              value: _unitCount,
                              unitSuffix: 'Unit',
                              min: 1,
                              max: 30,
                              onChanged: (value) =>
                                  setState(() => _unitCount = value),
                            ),
                          ),
                          const SizedBox(width: AppTokens.space12),
                          Expanded(
                            child: _buildStepperBox(
                              title: 'Durasi Sewa',
                              value: _rentalDays,
                              unitSuffix: 'Hari',
                              min: 1,
                              max: 14,
                              onChanged: (value) =>
                                  setState(() => _rentalDays = value),
                            ),
                          ),
                        ],
                      ),
                      _sectionGap(),
                      _buildSectionHeader(
                        icon: Icons.location_on_outlined,
                        title: 'Lokasi & Keterangan',
                      ),
                      _buildFormField(
                        controller: _addressController,
                        label: 'Alamat Lengkap Lokasi *',
                        hint: 'Nama gedung, jalan, nomor, patokan venue',
                        maxLines: 3,
                        validator: (value) =>
                            value == null || value.trim().isEmpty
                            ? 'Harap isi alamat lokasi'
                            : null,
                      ),
                      _spacer(),
                      _buildFormField(
                        controller: _mapsController,
                        label: 'Link Google Maps (Opsional)',
                        hint: 'https://maps.app.goo.gl/...',
                        keyboardType: TextInputType.url,
                      ),
                      _spacer(),
                      _buildFormField(
                        controller: _noteController,
                        label: 'Catatan Tambahan (Opsional)',
                        hint: 'Misal: pasang sebelum jam 9 pagi, kabel panjang',
                        maxLines: 3,
                      ),
                      _sectionGap(),
                      _buildInvoicePreview(context),
                      const SizedBox(height: AppTokens.space12),
                    ],
                  ),
                ),
              ),
            ),
            _buildBottomSubmitBar(context),
          ],
        ),
      ),
    );
  }

  SizedBox _spacer() => const SizedBox(height: AppTokens.space12);
  SizedBox _sectionGap() => const SizedBox(height: AppTokens.space24);

  Widget _buildTopBar(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.all(AppTokens.space8),
      child: Row(
        children: [
          IconButton(
            tooltip: 'Kembali',
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(Icons.chevron_left_rounded),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Input Orderan Sewa', style: theme.textTheme.titleLarge),
                Text(
                  'Jadwal Acara & Terbit Invoice',
                  style: theme.textTheme.labelMedium,
                ),
              ],
            ),
          ),
          Chip(
            avatar: Icon(
              Icons.circle,
              size: AppTokens.space8,
              color: colors.primary,
            ),
            label: const Text('PIC Order'),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    String? caption,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTokens.space12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.onSurfaceVariant),
          const SizedBox(width: AppTokens.space8),
          Expanded(child: Text(title, style: theme.textTheme.titleMedium)),
          if (caption != null)
            Text(
              caption,
              style: theme.textTheme.labelMedium?.copyWith(
                color: colors.primary,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(labelText: label, hintText: hint),
    );
  }

  Widget _buildDatePickerField() {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Tanggal Pemasangan *', style: theme.textTheme.labelLarge),
        const SizedBox(height: AppTokens.space8),
        OutlinedButton.icon(
          onPressed: _pickDate,
          icon: const Icon(Icons.calendar_today_rounded),
          label: Align(
            alignment: Alignment.centerLeft,
            child: Text(_formatDateFull(_selectedDate)),
          ),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(AppTokens.minTouchTarget),
            alignment: Alignment.centerLeft,
          ),
        ),
      ],
    );
  }

  Widget _buildStepperBox({
    required String title,
    required int value,
    required String unitSuffix,
    required int min,
    required int max,
    required ValueChanged<int> onChanged,
  }) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelLarge),
        const SizedBox(height: AppTokens.space8),
        Card(
          child: Row(
            children: [
              IconButton(
                tooltip: 'Kurangi $title',
                onPressed: value > min ? () => onChanged(value - 1) : null,
                icon: const Icon(Icons.remove_rounded),
              ),
              Expanded(
                child: Text(
                  '$value $unitSuffix',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium,
                ),
              ),
              IconButton(
                tooltip: 'Tambah $title',
                onPressed: value < max ? () => onChanged(value + 1) : null,
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicePreview(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    return Card(
      color: colors.surfaceContainer,
      child: Padding(
        padding: const EdgeInsets.all(AppTokens.space16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(Icons.receipt_long_rounded, color: colors.primary),
                const SizedBox(width: AppTokens.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Estimasi Total Tagihan',
                        style: theme.textTheme.labelMedium,
                      ),
                      Text(
                        '$_unitCount Unit × $_rentalDays Hari',
                        style: theme.textTheme.titleMedium,
                      ),
                    ],
                  ),
                ),
                Text(
                  InvoiceRecord.formatRupiah(_totalInvoiceAmount),
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.primary,
                  ),
                ),
              ],
            ),
            const Divider(height: AppTokens.space24),
            Row(
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: colors.onSurfaceVariant,
                ),
                const SizedBox(width: AppTokens.space8),
                Expanded(
                  child: Text(
                    'Invoice resmi otomatis terbit dan masuk ke tab Invoice.',
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomSubmitBar(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.all(AppTokens.space16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _isSubmitting ? null : _submitOrder,
              child: _isSubmitting
                  ? const SizedBox.square(
                      dimension: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan & Terbitkan Orderan'),
            ),
          ),
        ),
      ),
    );
  }
}
