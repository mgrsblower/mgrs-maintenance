import 'dart:math';
import 'package:flutter/material.dart';
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
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Input Orderan Sewa Baru',
          style: TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        iconTheme: const IconThemeData(color: Color(0xFF0F172A)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: const Color(0xFFE2E8F0), height: 1),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionHeader(
                  title: 'Informasi Acara & Klien',
                  icon: Icons.event_rounded,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _eventNameController,
                  label: 'Nama Acara / Event',
                  hint: 'Misal: Pernikahan Budi & Ani, Konser Musik',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Harap isi nama acara' : null,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _clientNameController,
                  label: 'Nama Klien / Penyelenggara',
                  hint: 'Misal: Ibu Sarah / PT Maju Jaya',
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Harap isi nama klien' : null,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _whatsappController,
                  label: 'Nomor WhatsApp Klien',
                  hint: 'Contoh: 08123456789',
                  keyboardType: TextInputType.phone,
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Harap isi nomor WhatsApp klien'
                      : null,
                ),
                const SizedBox(height: 24),
                _buildSectionHeader(
                  title: 'Jadwal & Kebutuhan Unit',
                  icon: Icons.calendar_month_rounded,
                ),
                const SizedBox(height: 12),
                // Date picker trigger
                InkWell(
                  onTap: _pickDate,
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFCBD5E1)),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Tanggal Pemasangan',
                              style: TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _formatDateFull(_selectedDate),
                              style: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                        const Icon(Icons.calendar_today_rounded,
                            color: Color(0xFF147CC1), size: 20),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _buildStepperBox(
                        title: 'Jumlah Unit Blower',
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
                _buildSectionHeader(
                  title: 'Lokasi & Alamat Venue',
                  icon: Icons.pin_drop_rounded,
                ),
                const SizedBox(height: 12),
                _buildTextField(
                  controller: _addressController,
                  label: 'Alamat Lengkap Lokasi',
                  hint: 'Nama gedung, jalan, nomor, patokan venue',
                  maxLines: 2,
                  validator: (v) =>
                      v == null || v.trim().isEmpty ? 'Harap isi alamat lokasi' : null,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _mapsController,
                  label: 'Link Google Maps (Opsional)',
                  hint: 'https://maps.app.goo.gl/...',
                  keyboardType: TextInputType.url,
                ),
                const SizedBox(height: 14),
                _buildTextField(
                  controller: _noteController,
                  label: 'Catatan Tambahan (Opsional)',
                  hint: 'Misal: pasang sebelum jam 9 pagi, minta kabel panjang',
                  maxLines: 2,
                ),
                const SizedBox(height: 24),
                // Automatic invoice preview card
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEFF6FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFBFDBFE)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: const [
                          Icon(Icons.receipt_rounded,
                              size: 18, color: Color(0xFF1D4ED8)),
                          SizedBox(width: 8),
                          Text(
                            'Estimasi Tagihan Invoice Otomatis',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF1E3A8A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$_unitCount Unit × $_rentalDays Hari (Rp 250.000/unit/hari)',
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              color: Color(0xFF475569),
                            ),
                          ),
                          Text(
                            InvoiceRecord.formatRupiah(_totalInvoiceAmount),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        '*Invoice resmi dengan status Belum Lunas akan terbit otomatis saat disimpan.',
                        style: TextStyle(
                          fontFamily: 'Plus Jakarta Sans',
                          fontSize: 10,
                          color: Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isSubmitting ? null : _submitOrder,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF147CC1),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
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
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader({required String title, required IconData icon}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: const Color(0xFF147CC1)),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Plus Jakarta Sans',
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
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
            fontSize: 12,
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
            fontSize: 14,
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
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: Color(0xFF147CC1), width: 1.8),
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
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFCBD5E1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Plus Jakarta Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              InkWell(
                onTap: value > min ? () => onChanged(value - 1) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: value > min
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.remove_rounded,
                    size: 18,
                    color: value > min
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
              Text(
                '$value $unitSuffix',
                style: const TextStyle(
                  fontFamily: 'Plus Jakarta Sans',
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF0F172A),
                ),
              ),
              InkWell(
                onTap: value < max ? () => onChanged(value + 1) : null,
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: value < max
                        ? const Color(0xFFF1F5F9)
                        : const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.add_rounded,
                    size: 18,
                    color: value < max
                        ? const Color(0xFF0F172A)
                        : const Color(0xFFCBD5E1),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
