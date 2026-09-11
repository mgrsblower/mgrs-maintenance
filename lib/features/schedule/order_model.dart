import 'package:url_launcher/url_launcher.dart';
import 'unit_allocation_model.dart';

class OrderanSewa {
  const OrderanSewa({
    required this.id,
    this.orderanId,
    required this.namaEvent,
    this.namaClient,
    this.alamat,
    this.jumlahUnit = 0,
    this.namaPic,
    this.nomorWhatsapp,
    this.linkGmaps,
    this.tanggalPemasangan,
    this.statusOrderan,
    this.catatanOrderan,
    this.createdAt,
  });

  final String id;
  final String? orderanId;
  final String namaEvent;
  final String? namaClient;
  final String? alamat;
  final int jumlahUnit;
  final String? namaPic;
  final String? nomorWhatsapp;
  final String? linkGmaps;
  final DateTime? tanggalPemasangan;
  final String? statusOrderan;
  final String? catatanOrderan;
  final DateTime? createdAt;

  factory OrderanSewa.fromJson(Map<String, Object?> json) {
    int parsedUnits = 0;
    final unitVal = json['jumlah_unit'];
    if (unitVal is int) {
      parsedUnits = unitVal;
    } else if (unitVal != null) {
      parsedUnits = int.tryParse(unitVal.toString()) ?? 0;
    }

    DateTime? parseDate(Object? val) {
      if (val == null) return null;
      if (val is DateTime) return val;
      return DateTime.tryParse(val.toString());
    }

    return OrderanSewa(
      id: (json['id'] ?? '').toString(),
      orderanId: json['orderan_id']?.toString(),
      namaEvent: (json['nama_event'] ?? 'Orderan Tanpa Nama').toString(),
      namaClient: json['nama_client']?.toString(),
      alamat: json['alamat']?.toString(),
      jumlahUnit: parsedUnits,
      namaPic: json['nama_pic']?.toString(),
      nomorWhatsapp: json['nomor_whatsapp']?.toString(),
      linkGmaps: json['link_gmaps']?.toString(),
      tanggalPemasangan: parseDate(json['tanggal_pemasangan']),
      statusOrderan: json['status_orderan']?.toString(),
      catatanOrderan: json['catatan_orderan']?.toString(),
      createdAt: parseDate(json['created_at']),
    );
  }

  OrderanSewa copyWith({
    String? id,
    String? orderanId,
    String? namaEvent,
    String? namaClient,
    String? alamat,
    int? jumlahUnit,
    String? namaPic,
    String? nomorWhatsapp,
    String? linkGmaps,
    DateTime? tanggalPemasangan,
    String? statusOrderan,
    String? catatanOrderan,
    DateTime? createdAt,
  }) {
    return OrderanSewa(
      id: id ?? this.id,
      orderanId: orderanId ?? this.orderanId,
      namaEvent: namaEvent ?? this.namaEvent,
      namaClient: namaClient ?? this.namaClient,
      alamat: alamat ?? this.alamat,
      jumlahUnit: jumlahUnit ?? this.jumlahUnit,
      namaPic: namaPic ?? this.namaPic,
      nomorWhatsapp: nomorWhatsapp ?? this.nomorWhatsapp,
      linkGmaps: linkGmaps ?? this.linkGmaps,
      tanggalPemasangan: tanggalPemasangan ?? this.tanggalPemasangan,
      statusOrderan: statusOrderan ?? this.statusOrderan,
      catatanOrderan: catatanOrderan ?? this.catatanOrderan,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  static final _rentalDaysPattern = RegExp(r'\[SEWA_HARI:(\d+)\]', caseSensitive: false);
  static final _eventDatePattern = RegExp(r'\[TGL_EVENT:(\d{4}-\d{2}-\d{2})\]', caseSensitive: false);
  static final _cancellationPattern = RegExp(r'\[BATAL:\s*([^\]]+)\]', caseSensitive: false);
  static final _unitAllocationPattern = RegExp(r'\[UNIT_ALOKASI:\s*[^\]]+\]', caseSensitive: false);

  /// Rental duration in days extracted from [catatanOrderan] metadata tag `[SEWA_HARI:N]`, defaults to 1.
  int get rentalDays {
    final note = catatanOrderan ?? '';
    final match = _rentalDaysPattern.firstMatch(note);
    if (match != null) {
      final days = int.tryParse(match.group(1) ?? '1');
      if (days != null && days > 0) return days;
    }
    return 1;
  }

  /// Human-readable duration string (e.g. "1 Hari", "3 Hari").
  String get durasiSewaText => '$rentalDays Hari';

  /// Actual event date extracted from `[TGL_EVENT:YYYY-MM-DD]` if available.
  DateTime? get eventDate {
    final note = catatanOrderan ?? '';
    final match = _eventDatePattern.firstMatch(note);
    if (match != null) {
      final str = match.group(1);
      if (str != null) return DateTime.tryParse(str);
    }
    return null;
  }

  /// Check if the order is cancelled by status.
  bool get isCancelled {
    final s = (statusOrderan ?? '').trim().toLowerCase();
    return s == 'batal' || s == 'cancelled' || s == 'dibatalkan';
  }

  /// Cancellation reason extracted from metadata tag `[BATAL:...]` in [catatanOrderan].
  String? get cancellationReason {
    final note = catatanOrderan ?? '';
    final match = _cancellationPattern.firstMatch(note);
    if (match != null) {
      final reason = match.group(1)?.trim();
      if (reason != null && reason.isNotEmpty) return reason;
    }
    return null;
  }

  /// Allocated blower units parsed from [catatanOrderan].
  List<AllocatedUnit> get allocatedUnits =>
      UnitAllocationParser.parse(catatanOrderan, totalUnits: jumlahUnit);

  /// Check if the order is completed or cancelled by status.
  bool get isCompletedOrCancelled {
    final s = (statusOrderan ?? '').trim().toLowerCase();
    return s == 'selesai' || s == 'batal' || s == 'cancelled' || s == 'completed' || s == 'dibatalkan';
  }

  /// Check if the event or installation date has passed today.
  bool get isDatePassed {
    if (tanggalPemasangan == null) return false;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dt = tanggalPemasangan!.toLocal();
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    final endDay = itemDay.add(Duration(days: rentalDays > 0 ? rentalDays - 1 : 0));
    return endDay.isBefore(today);
  }

  /// Whether this order is upcoming (not yet passed and not completed/cancelled).
  bool get isUpcoming => !isCompletedOrCancelled && !isDatePassed;

  /// Whether this order is past/completed.
  bool get isPast => isCompletedOrCancelled || isDatePassed;

  /// Clean user note without `[SEWA_HARI:...]`, `[TGL_EVENT:...]`, `[BATAL:...]`, and `[UNIT_ALOKASI:...]` tags.
  String get cleanNote {
    final note = catatanOrderan ?? '';
    return note
        .replaceAll(_rentalDaysPattern, '')
        .replaceAll(_eventDatePattern, '')
        .replaceAll(_cancellationPattern, '')
        .replaceAll(_unitAllocationPattern, '')
        .trim();
  }

  /// Formatted order code, preferring [orderanId] (e.g. ORD-20260909-088) or falling back to [id].
  String get displayCode {
    if (orderanId != null && orderanId!.trim().isNotEmpty) {
      return orderanId!.trim();
    }
    if (id.isEmpty) return 'ORD-2026-088';
    if (id.startsWith('ORD-')) return id;
    if (id.length > 8) {
      return 'ORD-${id.substring(0, 8).toUpperCase()}';
    }
    return 'ORD-${id.toUpperCase()}';
  }

  String get cleanWhatsapp {
    if (nomorWhatsapp == null) return '';
    var clean = nomorWhatsapp!.replaceAll(RegExp(r'[^0-9]'), '');
    if (clean.startsWith('0')) {
      clean = '62${clean.substring(1)}';
    } else if (!clean.startsWith('62') && clean.isNotEmpty) {
      clean = '62$clean';
    }
    return clean;
  }

  String get whatsappUrl {
    final clean = cleanWhatsapp;
    if (clean.isEmpty) return '';
    final msg = Uri.encodeComponent(
      'Halo ${namaPic ?? ''}, saya dari Tim Lapangan MGRS terkait pemasangan untuk acara *$namaEvent*.'
          .trim(),
    );
    return 'https://wa.me/$clean?text=$msg';
  }

  String get formattedDate {
    if (tanggalPemasangan == null) return 'Jadwal belum ditentukan';
    final dt = tanggalPemasangan!.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = itemDay.difference(today).inDays;

    String prefix = '';
    if (diffDays == 0) {
      prefix = 'Hari Ini, ';
    } else if (diffDays == 1) {
      prefix = 'Besok, ';
    }

    return '$prefix$dayName, ${dt.day} $monthName ${dt.year}';
  }

  String get shortDate {
    if (tanggalPemasangan == null) return 'Belum dijadwalkan';
    final dt = tanggalPemasangan!.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    final monthName = months[dt.month - 1];

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final itemDay = DateTime(dt.year, dt.month, dt.day);
    final diffDays = itemDay.difference(today).inDays;

    if (diffDays == 0) return 'Hari Ini';
    if (diffDays == 1) return 'Besok';
    return '${dt.day} $monthName';
  }

  /// Formatted date in format: Hari, DD MMM YYYY (e.g. Kamis, 10 Sep 2026)
  String get dayDateYear {
    if (tanggalPemasangan == null) return 'Belum dijadwalkan';
    final dt = tanggalPemasangan!.toLocal();
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
      'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'
    ];
    const days = ['Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'];
    final dayName = days[dt.weekday - 1];
    final monthName = months[dt.month - 1];
    final dayStr = dt.day.toString().padLeft(2, '0');
    return '$dayName, $dayStr $monthName ${dt.year}';
  }

  Future<bool> launchMaps() async {
    if (linkGmaps == null || linkGmaps!.trim().isEmpty) return false;
    final uri = Uri.tryParse(linkGmaps!.trim());
    if (uri != null && await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }

  Future<bool> launchWhatsApp() async {
    final url = whatsappUrl;
    if (url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    if (uri != null && await canLaunchUrl(uri)) {
      return await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
    return false;
  }
}
