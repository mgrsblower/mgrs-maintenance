import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../app/app_theme.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../app/gateway.dart';
import '../../shared/pressable.dart';
import '../components/component.dart';
import '../components/component_detail_screen.dart';
import '../maintenance/checking_screen.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({
    super.key,
    required this.gateway,
    this.initialComponent,
    this.user,
    this.readOnly = false,
  });
  final MaintenanceGateway gateway;
  final Component? initialComponent;
  final UserProfile? user;
  final bool readOnly;

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  bool get _effectiveReadOnly =>
      widget.readOnly || (widget.user?.isPic ?? false);
  late final MobileScannerController camera;
  late final AnimationController _laserController;
  late final Animation<double> _laserAnimation;
  late bool scanning;
  bool busy = false;
  Object? error;
  Component? scannedComponent;

  // Lens & Touch to Focus state
  String _activeLensMode = '1x';
  Offset? _focusPoint;
  Timer? _focusTimer;
  bool _showFocusRing = false;

  static bool get _isTestEnvironment {
    return WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    scannedComponent = widget.initialComponent;
    scanning = widget.initialComponent == null;
    camera = MobileScannerController(
      autoStart: widget.initialComponent == null,
      lensType: CameraLensType
          .normal, // Default ke Lensa Utama 1x (Bukan Ultra Wide 0.5x)
      facing: CameraFacing.back,
      detectionSpeed: DetectionSpeed.noDuplicates,
    );

    _laserController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2500),
    );
    _laserAnimation = CurvedAnimation(
      parent: _laserController,
      curve: Curves.easeInOut,
    );
    if (!_isTestEnvironment) {
      _laserController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _focusTimer?.cancel();
    _laserController.dispose();
    WidgetsBinding.instance.removeObserver(this);
    unawaited(camera.dispose());
    super.dispose();
  }

  Future<void> _switchLensMode(String mode) async {
    if (_activeLensMode == mode) return;
    HapticFeedback.lightImpact();
    setState(() => _activeLensMode = mode);
    try {
      if (mode == '0.5x') {
        await camera.switchCamera(
          const SelectCamera(lensType: CameraLensType.wide),
        );
      } else if (mode == '1x') {
        await camera.switchCamera(
          const SelectCamera(lensType: CameraLensType.normal),
        );
        await camera.resetZoomScale();
      } else if (mode == '2x') {
        final supported = await camera.getSupportedLenses(
          facing: CameraFacing.back,
        );
        if (supported.contains(CameraLensType.zoom)) {
          await camera.switchCamera(
            const SelectCamera(lensType: CameraLensType.zoom),
          );
        } else {
          await camera.switchCamera(
            const SelectCamera(lensType: CameraLensType.normal),
          );
          await camera.setZoomScale(0.35);
        }
      }
    } catch (_) {
      if (mode == '2x') {
        try {
          await camera.setZoomScale(0.35);
        } catch (_) {}
      } else {
        try {
          await camera.resetZoomScale();
        } catch (_) {}
      }
    }
  }

  void _onTapFocus(TapDownDetails details, Size screenSize) {
    final dx = details.globalPosition.dx;
    final dy = details.globalPosition.dy;
    final nx = (dx / screenSize.width).clamp(0.0, 1.0);
    final ny = (dy / screenSize.height).clamp(0.0, 1.0);

    HapticFeedback.lightImpact();
    try {
      final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
      // In iOS portrait back camera, sensor X is portrait Y, sensor Y is 1.0 - portrait X
      final targetPoint = isIOS ? Offset(ny, 1.0 - nx) : Offset(nx, ny);
      camera.setFocusPoint(targetPoint);
    } catch (_) {}

    _focusTimer?.cancel();
    setState(() {
      _focusPoint = Offset(dx, dy);
      _showFocusRing = true;
    });
    _focusTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) setState(() => _showFocusRing = false);
    });
  }

  Widget _buildLensOption(String label) {
    final isSelected = _activeLensMode == label;
    return Semantics(
      button: true,
      label: 'Lensa $label',
      selected: isSelected,
      child: SizedBox(
        width: 48,
        height: 48,
        child: Center(
          child: PressableScale(
            onTap: () => _switchLensMode(label),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 44,
              height: 32,
              decoration: BoxDecoration(
                color: isSelected
                    ? const Color(0xFFFBBF24)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: isSelected ? AppTokens.ink : Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      if (!scanning && scannedComponent == null) {
        unawaited(camera.start());
        setState(() => scanning = true);
      }
    } else if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (scanning) {
        unawaited(camera.stop());
        setState(() => scanning = false);
      }
    }
  }

  Future<void> lookup(String raw) async {
    final value = raw.trim();
    if (value.isEmpty || busy) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      final res = await widget.gateway.rpc('maintenance_lookup_component', {
        'p_code': value,
      });
      if (!mounted) return;
      if (res is List) {
        if (res.isEmpty) {
          setState(() {
            error = const AppFailure('not_found');
            scannedComponent = null;
          });
        } else if (res.length > 1) {
          setState(() {
            error = const AppFailure('ambiguous');
            scannedComponent = null;
          });
        } else {
          final c = Component(res.first as Map<String, Object?>);
          unawaited(camera.stop());
          setState(() {
            scannedComponent = c;
            scanning = false;
            error = null;
          });
        }
      } else {
        setState(() {
          error = const AppFailure('not_found');
          scannedComponent = null;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          error = e;
          scannedComponent = null;
        });
      }
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.sizeOf(context);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Full-Screen Immersive Camera Preview (Edge-to-Edge)
          Positioned.fill(
            child: GestureDetector(
              behavior: HitTestBehavior.translucent,
              onTapDown: (details) => _onTapFocus(details, screenSize),
              child: MobileScanner(
                controller: camera,
                fit: BoxFit.cover,
                onDetect: (capture) {
                  for (final b in capture.barcodes) {
                    final v = b.rawValue;
                    if (v != null && v.isNotEmpty) {
                      unawaited(lookup(v));
                      break;
                    }
                  }
                },
                errorBuilder: (context, error) =>
                    _buildCameraErrorView(context, error),
              ),
            ),
          ),

          // 2. Subtle Dark Gradient Vignette for Top Bar Readability
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 160,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.75),
                      Colors.black.withValues(alpha: 0.30),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 3. Center Viewfinder Frame (food-scanner-camera wireframe style with animated laser)
          // Centered slightly higher than middle so it balances perfectly above the bottom sheet
          Align(
            alignment: const Alignment(0, -0.22),
            child: IgnorePointer(
              child: SizedBox(
                width: 280,
                height: 280,
                child: Stack(
                  children: [
                    // Top-Left Corner
                    Align(
                      alignment: Alignment.topLeft,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(26),
                          ),
                          border: Border(
                            top: BorderSide(color: Colors.white, width: 3.5),
                            left: BorderSide(color: Colors.white, width: 3.5),
                          ),
                        ),
                      ),
                    ),
                    // Top-Right Corner
                    Align(
                      alignment: Alignment.topRight,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            topRight: Radius.circular(26),
                          ),
                          border: Border(
                            top: BorderSide(color: Colors.white, width: 3.5),
                            right: BorderSide(color: Colors.white, width: 3.5),
                          ),
                        ),
                      ),
                    ),
                    // Bottom-Left Corner
                    Align(
                      alignment: Alignment.bottomLeft,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(26),
                          ),
                          border: Border(
                            bottom: BorderSide(color: Colors.white, width: 3.5),
                            left: BorderSide(color: Colors.white, width: 3.5),
                          ),
                        ),
                      ),
                    ),
                    // Bottom-Right Corner
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          borderRadius: BorderRadius.only(
                            bottomRight: Radius.circular(26),
                          ),
                          border: Border(
                            bottom: BorderSide(color: Colors.white, width: 3.5),
                            right: BorderSide(color: Colors.white, width: 3.5),
                          ),
                        ),
                      ),
                    ),

                    // Animated Scanning Laser Beam from food-scanner-camera wireframe
                    AnimatedBuilder(
                      animation: _laserAnimation,
                      builder: (context, child) {
                        final t = _laserAnimation.value;
                        // Moves between 10% and 90% (28px to 252px)
                        final posY = 28.0 + t * (280.0 - 56.0);
                        final opacity =
                            (t < 0.1
                                    ? (t / 0.1)
                                    : (t > 0.9 ? ((1.0 - t) / 0.1) : 1.0))
                                .clamp(0.0, 1.0);

                        return Positioned(
                          top: posY,
                          left: 6,
                          right: 6,
                          child: Opacity(
                            opacity: opacity,
                            child: Container(
                              height: 2.5,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.95),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                  BoxShadow(
                                    color: Colors.white.withValues(alpha: 0.6),
                                    blurRadius: 20,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Touch-to-Focus Animated Ring (Apple Camera Yellow Target)
          if (_focusPoint != null && _showFocusRing)
            Positioned(
              left: (_focusPoint!.dx - 32).clamp(0.0, screenSize.width - 64),
              top: (_focusPoint!.dy - 32).clamp(0.0, screenSize.height - 64),
              child: IgnorePointer(
                child: TweenAnimationBuilder<double>(
                  tween: Tween(begin: 1.3, end: 1.0),
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOutBack,
                  builder: (context, scale, child) {
                    return Transform.scale(
                      scale: scale,
                      child: Container(
                        width: 64,
                        height: 64,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: const Color(0xFFFBBF24),
                            width: 1.8,
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: SizedBox(
                            width: 6,
                            height: 6,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                color: Color(0xFFFBBF24),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

          // 5. Lens & Zoom Switcher Pill (Floating cleanly right above the bottom sheet)
          if (scannedComponent == null)
            Positioned(
              left: 0,
              right: 0,
              bottom: 148 + MediaQuery.paddingOf(context).bottom,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.65),
                    borderRadius: BorderRadius.circular(22),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.20),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.35),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildLensOption('0.5x'),
                      const SizedBox(width: 4),
                      _buildLensOption('1x'),
                      const SizedBox(width: 4),
                      _buildLensOption('2x'),
                    ],
                  ),
                ),
              ),
            ),

          // 6. Floating Top Bar
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Tooltip(
                      message: 'Tutup pemindai',
                      child: Semantics(
                        button: true,
                        label: 'Tutup pemindai',
                        child: PressableScale(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            width: AppTokens.minTouchTarget,
                            height: AppTokens.minTouchTarget,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.45),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.2),
                              ),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.close_rounded,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          CircleAvatar(
                            radius: 3.5,
                            backgroundColor: AppTokens.success,
                          ),
                          SizedBox(width: 7),
                          Text(
                            'Scanner Cepat Lapangan',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                              letterSpacing: -0.2,
                            ),
                          ),
                        ],
                      ),
                    ),
                    ValueListenableBuilder<MobileScannerState>(
                      valueListenable: camera,
                      builder: (context, state, child) {
                        final torchState = state.torchState;
                        final isOn = torchState == TorchState.on;
                        final isUnavailable =
                            torchState == TorchState.unavailable;

                        return Tooltip(
                          message: isUnavailable
                              ? 'Lampu kilat tidak tersedia'
                              : (isOn
                                    ? 'Matikan lampu kilat'
                                    : 'Nyalakan lampu kilat'),
                          child: Semantics(
                            button: true,
                            label: isUnavailable
                                ? 'Lampu kilat tidak tersedia'
                                : (isOn
                                      ? 'Matikan lampu kilat'
                                      : 'Nyalakan lampu kilat'),
                            child: PressableScale(
                              onTap: isUnavailable
                                  ? null
                                  : () => camera.toggleTorch(),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: AppTokens.minTouchTarget,
                                height: AppTokens.minTouchTarget,
                                decoration: BoxDecoration(
                                  color: isOn
                                      ? const Color(
                                          0xFFFBBF24,
                                        ).withValues(alpha: 0.3)
                                      : Colors.black.withValues(alpha: 0.45),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isOn
                                        ? const Color(0xFFFBBF24)
                                        : Colors.white.withValues(alpha: 0.2),
                                    width: isOn ? 1.5 : 1.0,
                                  ),
                                ),
                                child: Center(
                                  child: Icon(
                                    isOn
                                        ? Icons.flash_on_rounded
                                        : Icons.flash_off_rounded,
                                    color: isOn
                                        ? const Color(0xFFFBBF24)
                                        : (isUnavailable
                                              ? Colors.white38
                                              : Colors.white),
                                    size: 20,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 7. Docked Bottom Sheet
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: _buildScannedResultSheet(context),
          ),
        ],
      ),
    );
  }

  Widget _buildScannedResultSheet(BuildContext context) {
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    if (scannedComponent == null) {
      return Container(
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(28),
            topRight: Radius.circular(28),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTokens.mist,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (busy) ...[
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  SizedBox(width: 12),
                  Text(
                    'Mencari data komponen...',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: AppTokens.graphite,
                    ),
                  ),
                ],
              ),
            ] else if (error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTokens.dangerSurface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTokens.dangerSurface),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppTokens.danger,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        failureMessage(error),
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: AppTokens.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      error = null;
                      scanning = true;
                    });
                    unawaited(camera.start());
                  },
                  icon: const Icon(Icons.refresh_rounded, size: 18),
                  label: const Text(
                    'Pindai Ulang',
                    style: TextStyle(fontWeight: FontWeight.w700),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.magenta,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ] else ...[
              const Icon(
                Icons.qr_code_scanner_rounded,
                size: 32,
                color: AppTokens.magenta,
              ),
              const SizedBox(height: 8),
              const Text(
                'Arahkan Kamera ke Barcode Komponen',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTokens.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Sistem akan memeriksa nomor stiker resmi unit blower MGRS.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppTokens.stone),
              ),
            ],
          ],
        ),
      );
    }

    final comp = scannedComponent!;
    final isOk = comp.condition == 'OK';
    final isService = comp.condition == 'Service';
    final isRusakBerat = comp.condition == 'Rusak Berat';
    final badgeColor = isOk
        ? AppTokens.success
        : (isService || isRusakBerat ? AppTokens.danger : AppTokens.warning);
    final badgeText = isOk
        ? 'LAYAK PAKAI'
        : (isService
              ? 'PERLU SERVIS'
              : (isRusakBerat ? 'GANGGUAN FUNGSI' : 'PERLU TINDAKAN'));
    final lastCheckText =
        comp.lastCheckingAt != null && comp.lastCheckingAt!.length >= 10
        ? 'Pemeriksaan Terakhir: ${comp.lastCheckingAt!.substring(0, 10)}'
        : 'Pemeriksaan Terakhir: Belum pernah diperiksa';
    final noteText = comp.note != null && comp.note!.trim().isNotEmpty
        ? comp.note!.trim()
        : 'Tidak ada catatan kendala fisik.';

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: EdgeInsets.fromLTRB(20, 14, 20, 16 + bottomInset),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: AppTokens.mist,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 14),

          // Code + Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    comp.code,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTokens.ink,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: AppTokens.mistLight,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      comp.kind,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppTokens.ink,
                      ),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: badgeColor,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      isOk ? Icons.check : Icons.warning_amber_rounded,
                      size: 12,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      badgeText,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            lastCheckText,
            style: const TextStyle(fontSize: 12, color: AppTokens.stone),
          ),
          if (_effectiveReadOnly) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTokens.mistLight,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppTokens.mist),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.remove_red_eye_outlined,
                    size: 13,
                    color: AppTokens.stone,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Mode Pantau Status • Hanya Baca',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppTokens.graphite,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),

          // Note Card
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTokens.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppTokens.mist),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'CATATAN KONDISI FISIK',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: AppTokens.stone,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  noteText,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTokens.graphite,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons
          if (!_effectiveReadOnly) ...[
            PressableScale(
              onTap: () async {
                final isService = comp.condition != 'OK';
                final res = await Navigator.of(context).push<bool>(
                  MaterialPageRoute(
                    builder: (_) => CheckingScreen(
                      gateway: widget.gateway,
                      component: comp,
                      service: isService,
                    ),
                  ),
                );
                if (res == true && mounted) {
                  lookup(comp.code);
                }
              },
              child: Container(
                height: 46,
                decoration: BoxDecoration(
                  color: comp.condition != 'OK'
                      ? AppTokens.danger
                      : AppTokens.magenta,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      comp.condition != 'OK'
                          ? Icons.build_rounded
                          : Icons.fact_check_outlined,
                      size: 18,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      comp.condition != 'OK'
                          ? 'Catat Servis Unit Ini'
                          : 'Perbarui Kondisi Unit',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: PressableScale(
                  child: SizedBox(
                    height: 44,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(context).push<void>(
                          MaterialPageRoute(
                            builder: (_) => ComponentDetailScreen(
                              gateway: widget.gateway,
                              id: comp.id,
                              user: widget.user,
                              readOnly: _effectiveReadOnly,
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.visibility_outlined, size: 16),
                      label: const Text(
                        'Buka Detail',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTokens.ink,
                        side: const BorderSide(color: AppTokens.mist),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: PressableScale(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          scannedComponent = null;
                          scanning = true;
                        });
                        unawaited(camera.start());
                      },
                      icon: const Icon(
                        Icons.crop_free_rounded,
                        color: Colors.white,
                        size: 16,
                      ),
                      label: const Text(
                        'Pindai Berikutnya',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTokens.graphite,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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

  Widget _buildCameraErrorView(
    BuildContext context,
    MobileScannerException error,
  ) {
    final isPermissionDenied =
        error.errorCode == MobileScannerErrorCode.permissionDenied;

    return Container(
      color: AppTokens.ink,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 68,
            height: 68,
            decoration: BoxDecoration(
              color: isPermissionDenied
                  ? AppTokens.dangerSurface
                  : Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
              border: Border.all(
                color: isPermissionDenied
                    ? AppTokens.dangerSurface
                    : Colors.white.withValues(alpha: 0.15),
              ),
            ),
            child: Center(
              child: Icon(
                isPermissionDenied
                    ? Icons.no_photography_outlined
                    : Icons.videocam_off_outlined,
                color: isPermissionDenied ? AppTokens.danger : Colors.white70,
                size: 32,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            isPermissionDenied
                ? 'Izin Akses Kamera Diperlukan'
                : 'Kamera Tidak Tersedia',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPermissionDenied
                ? 'Aplikasi membutuhkan akses kamera untuk memindai barcode unit di lapangan. Silakan izinkan akses kamera pada perangkat Anda.'
                : 'Kamera perangkat sedang digunakan oleh aplikasi lain atau tidak didukung.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.7),
              height: 1.45,
            ),
          ),
          const SizedBox(height: 22),
          ElevatedButton.icon(
            onPressed: () {
              unawaited(camera.start());
              setState(() {});
            },
            icon: const Icon(
              Icons.refresh_rounded,
              size: 18,
              color: Colors.white,
            ),
            label: Text(
              isPermissionDenied
                  ? 'Beri Izin / Coba Lagi'
                  : 'Hubungkan Ulang Kamera',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTokens.magenta,
              elevation: 0,
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
