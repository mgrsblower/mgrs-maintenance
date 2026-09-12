import 'dart:math';
import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../shared/pressable.dart';
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

  static String _formatDateFull(DateTime dt) {
    const days = [
      'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
    ];
    const months = [
      'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
      'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
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
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF147CC1),
              onPrimary: Colors.white,
              onSurface: Color(0xFF0F172A),
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
          content: Text(
            'Orderan $orderanId dan Invoice berhasil dibuat!',
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          backgroundColor: const Color(0xFF059669),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal membuat orderan: $e'),
          backgroundColor: const Color(0xFFDC2626),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            _buildTopBar(context),
            const Divider(height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
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
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Harap isi nama acara'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _buildFormField(
                        controller: _clientNameController,
                        label: 'Nama Klien / Penyelenggara *',
                        hint: 'Misal: Ibu Sarah / PT Maju Jaya',
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Harap isi nama klien'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _buildFormField(
                        controller: _whatsappController,
                        label: 'Nomor WhatsApp Klien *',
                        hint: 'Contoh: 08123456789',
                        keyboardType: TextInputType.phone,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Harap isi nomor WhatsApp klien'
                            : null,
                      ),

                      const SizedBox(height: 24),
                      const Divider(
                          height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 20),

                      _buildSectionHeader(
                        icon: Icons.calendar_today_rounded,
                        title: 'Jadwal & Kebutuhan Unit',
                      ),
                      _buildDatePickerField(),
                      const SizedBox(height: 14),
                      Row(
                        children: [
                          Expanded(
                            child: _buildStepperBox(
                              title: 'Jumlah Unit',
                              value: _unitCount,
                              unitSuffix: 'Unit',
                              min: 1,
                              max: 30,
                              onChanged: (v) => setState(() => _unitCount = v),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildStepperBox(
                              title: 'Durasi Sewa',
                              value: _rentalDays,
                              unitSuffix: 'Hari',
                              min: 1,
                              max: 14,
                              onChanged: (v) => setState(() => _rentalDays = v),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      const Divider(
                          height: 1, thickness: 1, color: Color(0xFFF1F5F9)),
                      const SizedBox(height: 20),

                      _buildSectionHeader(
                        icon: Icons.location_on_outlined,
                        title: 'Lokasi & Keterangan',
                      ),
                      _buildFormField(
                        controller: _addressController,
                        label: 'Alamat Lengkap Lokasi *',
                        hint: 'Nama gedung, jalan, nomor, patokan venue',
                        maxLines: 2,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Harap isi alamat lokasi'
                            : null,
                      ),
                      const SizedBox(height: 14),
                      _buildFormField(
                        controller: _mapsController,
                        label: 'Link Google Maps (Opsional)',
                        hint: 'https://maps.app.goo.gl/...',
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 14),
                      _buildFormField(
                        controller: _noteController,
                        label: 'Catatan Tambahan (Opsional)',
                        hint: 'Misal: pasang sebelum jam 9 pagi, kabel panjang',
                        maxLines: 2,
                      ),

                      const SizedBox(height: 24),
                      _buildInvoicePreview(),
                      const SizedBox(height: 12),
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

  // Top Bar clean and native
  Widget _buildTopBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              PressableScale(
                onTap: () => Navigator.of(context).pop(),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFFE2E8F0)),
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.chevron_left_rounded,
                      color: Color(0xFF0F172A),
                      size: 22,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Input Orderan Sewa',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  Text(
                    'Jadwal Acara & Terbit Invoice',
                    style: TextStyle(
                      fontFamily: 'Plus Jakarta Sans',
                      fontSize: 11.5,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 3,
                  backgroundColor: Color(0xFF2563EB),
                ),
                SizedBox(width: 5),
                Text(
                  'PIC Order',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF2563EB),
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
    String? caption,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 15, color: const Color(0xFF64748B)),
          const SizedBox(width: 6),
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
              color: Color(0xFF64748B),
            ),
          ),
          if (caption != null) ...[
            const Spacer(),
            Text(
              caption,
              style: const TextStyle(
                fontFamily: 'Plus Jakarta Sans',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Color(0xFF2563EB),
              ),
            ),
          ],
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLines: maxLines,
          validator: validator,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 13,
              color: Color(0xFF94A3B8),
            ),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF147CC1), width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFEF4444)),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFFEF4444), width: 1.5),
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
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        PressableScale(
          onTap: _pickDate,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.calendar_today_rounded,
                        size: 16, color: Color(0xFF147CC1)),
                    const SizedBox(width: 10),
                    Text(
                      _formatDateFull(_selectedDate),
                      style: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.arrow_drop_down_rounded,
                    color: Color(0xFF64748B)),
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
            fontSize: 12.5,
            fontWeight: FontWeight.w700,
            color: Color(0xFF334155),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE2E8F0)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: value > min ? () => onChanged(value - 1) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: value > min ? Colors.white : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: value > min
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              Text(
                '$value $unitSuffix',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: value < max ? () => onChanged(value + 1) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: value < max ? Colors.white : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: const Color(0xFFE2E8F0),
                    ),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: value < max
                        ? const Color(0xFF0F172A)
                        : const Color(0xFF94A3B8),
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
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.receipt_long_rounded,
                      size: 17,
                      color: Color(0xFF147CC1),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Estimasi Total Tagihan',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF64748B),
                        ),
                      ),
                      Text(
                        '$_unitCount Unit × $_rentalDays Hari',
                        style: const TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                InvoiceRecord.formatRupiah(_totalInvoiceAmount),
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF147CC1),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          const Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  size: 13, color: Color(0xFF94A3B8)),
              SizedBox(width: 6),
              Expanded(
                child: Text(
                  'Invoice resmi otomatis terbit dan masuk ke tab Invoice.',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 10.5,
                    color: Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // Bottom Submit Button Bar
  Widget _buildBottomSubmitBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE2E8F0))),
        boxShadow: [
          BoxShadow(
            color: Color(0x080F172A),
            blurRadius: 10,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SizedBox(
        width: double.infinity,
        height: 48,
        child: FilledButton(
          onPressed: _isSubmitting ? null : _submitOrder,
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF147CC1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
          ),
          child: _isSubmitting
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text(
                  'Simpan & Terbitkan Orderan',
                  style: TextStyle(
                    fontFamily: 'Plus Jakarta Sans',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
