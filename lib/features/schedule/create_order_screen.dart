import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../design_system/components/mgrs_app_bar.dart';
import '../../design_system/components/mgrs_button.dart';
import '../../design_system/mgrs_tokens.dart';
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
  final _scrollController = ScrollController();
  final _eventNameController = TextEditingController();
  final _clientNameController = TextEditingController();
  final _whatsappController = TextEditingController();
  final _addressController = TextEditingController();
  final _mapsController = TextEditingController();
  final _noteController = TextEditingController();

  final _eventNameFocus = FocusNode();
  final _clientNameFocus = FocusNode();
  final _whatsappFocus = FocusNode();
  final _addressFocus = FocusNode();
  final _mapsFocus = FocusNode();
  final _noteFocus = FocusNode();

  String? _eventNameError;
  String? _clientNameError;
  String? _whatsappError;
  String? _addressError;
  String? _submitError;
  bool _showValidationBanner = false;

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

    _eventNameFocus.dispose();
    _clientNameFocus.dispose();
    _whatsappFocus.dispose();
    _addressFocus.dispose();
    _mapsFocus.dispose();
    _noteFocus.dispose();
    super.dispose();
  }

  num get _totalInvoiceAmount => _unitCount * 250000 * _rentalDays;

  String get _generatedOrderId {
    final y = _selectedDate.year.toString().padLeft(4, '0');
    final m = _selectedDate.month.toString().padLeft(2, '0');
    final d = _selectedDate.day.toString().padLeft(2, '0');
    final randomDigits = Random().nextInt(900) + 100;
    return 'ORD-$y$m$d-$randomDigits';
  }

  static String _formatDateFull(DateTime dt) {
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
    return '${days[dt.weekday - 1]}, ${dt.day} ${months[dt.month - 1]} ${dt.year}';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: MgrsColors.action,
              onPrimary: Colors.white,
              onSurface: MgrsColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  bool _validate() {
    final eventEmpty = _eventNameController.text.trim().isEmpty;
    final clientEmpty = _clientNameController.text.trim().isEmpty;
    final waEmpty = _whatsappController.text.trim().isEmpty;
    final addressEmpty = _addressController.text.trim().isEmpty;

    setState(() {
      _eventNameError = eventEmpty ? 'Nama acara wajib diisi.' : null;
      _clientNameError = clientEmpty ? 'Nama klien wajib diisi.' : null;
      _whatsappError = waEmpty ? 'Nomor WhatsApp wajib diisi.' : null;
      _addressError = addressEmpty ? 'Alamat lokasi wajib diisi.' : null;
      _showValidationBanner =
          eventEmpty || clientEmpty || waEmpty || addressEmpty;
    });

    if (eventEmpty) {
      _eventNameFocus.requestFocus();
      return false;
    }
    if (clientEmpty) {
      _clientNameFocus.requestFocus();
      return false;
    }
    if (waEmpty) {
      _whatsappFocus.requestFocus();
      return false;
    }
    if (addressEmpty) {
      _addressFocus.requestFocus();
      return false;
    }
    return true;
  }

  Future<void> _submitOrder() async {
    if (_isSubmitting) return;

    setState(() {
      _submitError = null;
    });

    if (!_validate()) return;

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

      final created = await widget.gateway.createOrderWithInvoice(payload);

      if (!mounted) return;

      final displayCode = created.displayCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Order $displayCode berhasil dibuat!',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: MgrsColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );

      setState(() {
        _isSubmitting = false;
      });

      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop(true);
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _submitError =
            'Periksa kembali isian form atau koneksi Anda, lalu coba lagi.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MgrsColors.surface,
      appBar: const MgrsDetailAppBar(
        title: 'Buat order',
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(
                  horizontal: MgrsSpacing.md,
                  vertical: MgrsSpacing.xs,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_showValidationBanner) ...[
                      _buildErrorBanner(
                        title: 'Periksa kembali isian',
                        subtitle: 'Lengkapi bagian bertanda sebelum menyimpan.',
                      ),
                      const SizedBox(height: MgrsSpacing.xs),
                    ],
                    if (_submitError != null) ...[
                      _buildErrorBanner(
                        title: 'Order belum dapat disimpan',
                        subtitle: _submitError!,
                      ),
                      const SizedBox(height: MgrsSpacing.xs),
                    ],
                    _buildSectionHeader(
                      icon: Icons.event_note_rounded,
                      title: 'Informasi Acara & Klien',
                    ),
                    _buildFormField(
                      controller: _eventNameController,
                      focusNode: _eventNameFocus,
                      label: 'Nama Acara *',
                      hint: 'Misal: Pameran Peralatan Lapangan Nusantara',
                      errorText: _eventNameError,
                      onChanged: (_) {
                        if (_eventNameError != null) {
                          setState(() => _eventNameError = null);
                        }
                      },
                    ),
                    const SizedBox(height: MgrsSpacing.xs),
                    _buildFormField(
                      controller: _clientNameController,
                      focusNode: _clientNameFocus,
                      label: 'Nama Klien *',
                      hint: 'Misal: Ibu Sarah / PT Maju Jaya',
                      errorText: _clientNameError,
                      onChanged: (_) {
                        if (_clientNameError != null) {
                          setState(() => _clientNameError = null);
                        }
                      },
                    ),
                    const SizedBox(height: MgrsSpacing.xs),
                    _buildFormField(
                      controller: _whatsappController,
                      focusNode: _whatsappFocus,
                      label: 'Nomor WhatsApp *',
                      hint: 'Contoh: 081234567890',
                      keyboardType: TextInputType.phone,
                      errorText: _whatsappError,
                      onChanged: (_) {
                        if (_whatsappError != null) {
                          setState(() => _whatsappError = null);
                        }
                      },
                    ),
                    const SizedBox(height: MgrsSpacing.xs),
                    const Divider(height: 1, color: MgrsColors.line),
                    const SizedBox(height: MgrsSpacing.xs),
                    _buildSectionHeader(
                      icon: Icons.calendar_today_rounded,
                      title: 'Jadwal & Kebutuhan Unit',
                    ),
                    _buildDatePickerField(),
                    const SizedBox(height: MgrsSpacing.sm),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final isNarrow = constraints.maxWidth < 280;
                        if (isNarrow) {
                          return Column(
                            children: [
                              _buildStepperBox(
                                title: 'Jumlah Unit',
                                value: _unitCount,
                                unitSuffix: 'Unit',
                                min: 1,
                                max: 30,
                                onChanged:
                                    (v) => setState(() => _unitCount = v),
                              ),
                              const SizedBox(height: MgrsSpacing.xs),
                              _buildStepperBox(
                                title: 'Durasi Sewa',
                                value: _rentalDays,
                                unitSuffix: 'Hari',
                                min: 1,
                                max: 14,
                                onChanged:
                                    (v) => setState(() => _rentalDays = v),
                              ),
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(
                              child: _buildStepperBox(
                                title: 'Jumlah Unit',
                                value: _unitCount,
                                unitSuffix: 'Unit',
                                min: 1,
                                max: 30,
                                onChanged:
                                    (v) => setState(() => _unitCount = v),
                              ),
                            ),
                            const SizedBox(width: MgrsSpacing.sm),
                            Expanded(
                              child: _buildStepperBox(
                                title: 'Durasi Sewa',
                                value: _rentalDays,
                                unitSuffix: 'Hari',
                                min: 1,
                                max: 14,
                                onChanged:
                                    (v) => setState(() => _rentalDays = v),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: MgrsSpacing.md),
                    const Divider(height: 1, color: MgrsColors.line),
                    const SizedBox(height: MgrsSpacing.md),
                    _buildSectionHeader(
                      icon: Icons.location_on_outlined,
                      title: 'Lokasi & Keterangan',
                    ),
                    _buildFormField(
                      controller: _addressController,
                      focusNode: _addressFocus,
                      label: 'Alamat Lokasi *',
                      hint: 'Nama gedung, jalan, nomor, patokan venue',
                      maxLines: 2,
                      errorText: _addressError,
                      onChanged: (_) {
                        if (_addressError != null) {
                          setState(() => _addressError = null);
                        }
                      },
                    ),
                    const SizedBox(height: MgrsSpacing.sm),
                    _buildFormField(
                      controller: _mapsController,
                      focusNode: _mapsFocus,
                      label: 'Link Google Maps (Opsional)',
                      hint: 'https://maps.app.goo.gl/...',
                      keyboardType: TextInputType.url,
                    ),
                    const SizedBox(height: MgrsSpacing.sm),
                    _buildFormField(
                      controller: _noteController,
                      focusNode: _noteFocus,
                      label: 'Catatan Tambahan (Opsional)',
                      hint: 'Misal: pasang sebelum jam 9 pagi, kabel 30 meter',
                      maxLines: 2,
                    ),
                    const SizedBox(height: MgrsSpacing.md),
                    _buildInvoicePreview(),
                    const SizedBox(height: MgrsSpacing.sm),
                  ],
                ),
              ),
            ),
            _buildBottomSubmitBar(),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBanner({required String title, required String subtitle}) {
    return Container(
      padding: const EdgeInsets.all(MgrsSpacing.sm + 2),
      decoration: BoxDecoration(
        color: MgrsColors.dangerSoft,
        borderRadius: BorderRadius.circular(MgrsRadii.card),
        border: Border.all(color: MgrsColors.danger.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.error_outline_rounded,
            color: MgrsColors.danger,
            size: 20,
          ),
          const SizedBox(width: MgrsSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: MgrsColors.danger,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 12,
                    color: MgrsColors.ink,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: MgrsSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 15, color: MgrsColors.muted),
          const SizedBox(width: MgrsSpacing.xs),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: MgrsColors.muted,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? errorText,
    ValueChanged<String>? onChanged,
  }) {
    final hasError = errorText != null;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: MgrsColors.ink,
          ),
        ),
        const SizedBox(height: 3),
        TextField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          maxLines: maxLines,
          onChanged: onChanged,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: MgrsColors.ink,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 12.5,
              color: MgrsColors.muted,
            ),
            errorText: errorText,
            filled: true,
            fillColor: hasError ? MgrsColors.dangerSoft : MgrsColors.canvas,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: MgrsSpacing.sm + 4,
              vertical: MgrsSpacing.sm,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MgrsRadii.control),
              borderSide: const BorderSide(color: MgrsColors.line),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MgrsRadii.control),
              borderSide: BorderSide(
                color: hasError ? MgrsColors.danger : MgrsColors.line,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MgrsRadii.control),
              borderSide: BorderSide(
                color: hasError ? MgrsColors.danger : MgrsColors.action,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MgrsRadii.control),
              borderSide: const BorderSide(color: MgrsColors.danger),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(MgrsRadii.control),
              borderSide: const BorderSide(color: MgrsColors.danger, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDatePickerField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tanggal Pemasangan *',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: MgrsColors.ink,
          ),
        ),
        const SizedBox(height: 3),
        InkWell(
          onTap: _pickDate,
          borderRadius: BorderRadius.circular(MgrsRadii.control),
          child: Container(
            padding: const EdgeInsets.symmetric(
              horizontal: MgrsSpacing.sm + 4,
              vertical: MgrsSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: MgrsColors.canvas,
              borderRadius: BorderRadius.circular(MgrsRadii.control),
              border: Border.all(color: MgrsColors.line),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.calendar_month_rounded,
                  size: 18,
                  color: MgrsColors.action,
                ),
                const SizedBox(width: MgrsSpacing.sm),
                Expanded(
                  child: Text(
                    _formatDateFull(_selectedDate),
                    style: const TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: MgrsColors.ink,
                    ),
                  ),
                ),
                const Icon(
                  Icons.edit_calendar_rounded,
                  size: 16,
                  color: MgrsColors.muted,
                ),
              ],
            ),
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: MgrsColors.ink,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: MgrsColors.canvas,
            borderRadius: BorderRadius.circular(MgrsRadii.control),
            border: Border.all(color: MgrsColors.line),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: value > min ? () => onChanged(value - 1) : null,
                borderRadius: BorderRadius.circular(MgrsRadii.control),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: value > min ? MgrsColors.surface : MgrsColors.canvas,
                    borderRadius: BorderRadius.circular(MgrsRadii.control),
                    border: Border.all(color: MgrsColors.line),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: value > min ? MgrsColors.ink : MgrsColors.muted,
                  ),
                ),
              ),
              Text(
                '$value $unitSuffix',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: MgrsColors.ink,
                ),
              ),
              InkWell(
                onTap: value < max ? () => onChanged(value + 1) : null,
                borderRadius: BorderRadius.circular(MgrsRadii.control),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: value < max ? MgrsColors.surface : MgrsColors.canvas,
                    borderRadius: BorderRadius.circular(MgrsRadii.control),
                    border: Border.all(color: MgrsColors.line),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: value < max ? MgrsColors.ink : MgrsColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInvoicePreview() {
    return Container(
      padding: const EdgeInsets.all(MgrsSpacing.sm + 4),
      decoration: BoxDecoration(
        color: MgrsColors.canvas,
        borderRadius: BorderRadius.circular(MgrsRadii.card),
        border: Border.all(color: MgrsColors.line),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Estimasi Total Tagihan',
                      style: TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: MgrsColors.muted,
                      ),
                    ),
                    Text(
                      '$_unitCount Unit × $_rentalDays Hari',
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: MgrsColors.ink,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                InvoiceRecord.formatRupiah(_totalInvoiceAmount),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: MgrsColors.action,
                ),
              ),
            ],
          ),
          const SizedBox(height: MgrsSpacing.xs),
          const Divider(height: 1, color: MgrsColors.line),
          const SizedBox(height: MgrsSpacing.xs),
          const Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                size: 14,
                color: MgrsColors.muted,
              ),
              SizedBox(width: MgrsSpacing.xs),
              Expanded(
                child: Text(
                  'Invoice otomatis diterbitkan untuk setiap order baru dan dapat dikelola pada tab Invoice.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    color: MgrsColors.muted,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomSubmitBar() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: MgrsSpacing.md,
        vertical: MgrsSpacing.sm,
      ),
      decoration: const BoxDecoration(
        color: MgrsColors.surface,
        border: Border(top: BorderSide(color: MgrsColors.line)),
      ),
      child: SizedBox(
        width: double.infinity,
        child: MgrsButton.primary(
          label: 'Simpan & terbitkan order',
          loading: _isSubmitting,
          onPressed: _isSubmitting ? null : _submitOrder,
        ),
      ),
    );
  }
}
