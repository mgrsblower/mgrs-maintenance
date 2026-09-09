import 'package:flutter/material.dart';
import 'package:rive/rive.dart';
import '../../app/app_theme.dart';
import '../../app/gateway.dart';
import '../../shared/pressable.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.gateway,
    required this.onSignedIn,
  });

  final MaintenanceGateway gateway;
  final VoidCallback onSignedIn;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final form = GlobalKey<FormState>();
  final identifier = TextEditingController();
  final password = TextEditingController();

  final identifierFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  bool busy = false;
  bool hidden = true;
  String? error;

  /// Rive controller and state machine inputs
  StateMachineController? _riveController;
  SMIBool? _lookOnEmail;
  SMINumber? _followOnEmail;
  SMIBool? _lookOnPassword;
  SMIBool? _peekOnPassword;
  SMITrigger? _triggerSuccess;
  SMITrigger? _triggerFail;

  @override
  void initState() {
    super.initState();
    identifierFocusNode.addListener(() {
      _lookOnEmail?.change(identifierFocusNode.hasFocus);
    });

    passwordFocusNode.addListener(() {
      _lookOnPassword?.change(passwordFocusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _riveController?.dispose();
    identifier.dispose();
    password.dispose();
    identifierFocusNode.dispose();
    passwordFocusNode.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy) return;
    identifierFocusNode.unfocus();
    passwordFocusNode.unfocus();

    if (!form.currentState!.validate()) {
      _triggerFail?.fire();
      return;
    }

    setState(() {
      busy = true;
      error = null;
    });

    try {
      await widget.gateway.signIn(identifier.text.trim(), password.text);
      _triggerSuccess?.fire();
      // Allow user to briefly enjoy the success celebration animation
      await Future.delayed(const Duration(milliseconds: 1400));
      if (mounted) widget.onSignedIn();
    } catch (e) {
      _triggerFail?.fire();
      if (mounted) setState(() => error = failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  void _onTogglePasswordVisibility() {
    setState(() {
      hidden = !hidden;
      _peekOnPassword?.change(!hidden);
    });
  }

  static bool get _isTestEnvironment {
    return WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
  }

  Widget _buildBearAnimation() {
    if (_isTestEnvironment) {
      return Container(
        height: 300,
        width: 300,
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          shape: BoxShape.circle,
        ),
        child: const Center(
          child: Icon(
            Icons.pets_rounded,
            size: 80,
            color: Colors.white70,
          ),
        ),
      );
    }

    return SizedBox(
      height: 300,
      width: 300,
      child: RiveAnimation.asset(
        'assets/animation/auth_teddy.riv',
        fit: BoxFit.fitHeight,
        onInit: (artboard) {
          final controller = StateMachineController.fromArtboard(
            artboard,
            'Login Machine',
          );

          if (controller == null) return;
          artboard.addController(controller);
          _riveController = controller;

          _lookOnEmail = controller.getBoolInput('isFocus');
          _followOnEmail = controller.getNumberInput('numLook');
          _lookOnPassword = controller.getBoolInput('isPrivateField');
          _peekOnPassword = controller.getBoolInput('isPrivateFieldShow');
          _triggerSuccess = controller.getTriggerInput('successTrigger');
          _triggerFail = controller.getTriggerInput('failTrigger');
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF1C3E66),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: Container(
              constraints: const BoxConstraints(maxWidth: 380),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Animated Guardian Polar Bear (Rive) - positioned right on top of card
                  Transform.translate(
                    offset: const Offset(0, 14),
                    child: _buildBearAnimation(),
                  ),

                  // Form Card (White rounded card matching reference design)
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x33000000),
                          blurRadius: 20,
                          offset: Offset(0, 8),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(20),
                    child: Form(
                      key: form,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label: Email / Akun
                          const Text(
                            'Email / Akun MGRS',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: identifier,
                            focusNode: identifierFocusNode,
                            enabled: !busy,
                            autofillHints: const [AutofillHints.username],
                            textInputAction: TextInputAction.next,
                            onChanged: (val) {
                              _followOnEmail?.change((val.length * 1.5).clamp(0, 100));
                            },
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Masukkan email atau username...',
                              hintStyle: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1C3E66),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Masukkan akun MGRS.'
                                : null,
                          ),
                          const SizedBox(height: 14),

                          // Label: Password
                          const Text(
                            'Kata Sandi',
                            style: TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF334155),
                            ),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: password,
                            focusNode: passwordFocusNode,
                            enabled: !busy,
                            obscureText: hidden,
                            autofillHints: const [AutofillHints.password],
                            onFieldSubmitted: (_) => submit(),
                            style: const TextStyle(
                              fontFamily: 'Plus Jakarta Sans',
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF0F172A),
                            ),
                            decoration: InputDecoration(
                              hintText: 'Masukkan kata sandi...',
                              hintStyle: const TextStyle(
                                fontFamily: 'Plus Jakarta Sans',
                                fontSize: 13,
                                color: Color(0xFF94A3B8),
                              ),
                              suffixIcon: IconButton(
                                tooltip: hidden
                                    ? 'Tampilkan kata sandi'
                                    : 'Sembunyikan kata sandi',
                                onPressed: _onTogglePasswordVisibility,
                                icon: Icon(
                                  hidden
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  size: 20,
                                  color: const Color(0xFF1C3E66),
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 13,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(color: Color(0xFFCBD5E1)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: const BorderSide(
                                  color: Color(0xFF1C3E66),
                                  width: 1.5,
                                ),
                              ),
                            ),
                            validator: (v) => v == null || v.isEmpty
                                ? 'Masukkan kata sandi.'
                                : null,
                          ),

                          // Error alert if any
                          if (error != null) ...[
                            const SizedBox(height: 14),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 10,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFEF2F2),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: const Color(0xFFFECACA)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.error_outline_rounded,
                                    size: 18,
                                    color: AppTokens.danger,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      error!,
                                      style: const TextStyle(
                                        fontFamily: 'Plus Jakarta Sans',
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: AppTokens.danger,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                          const SizedBox(height: 24),

                          // Login / Masuk Button
                          PressableScale(
                            child: SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: FilledButton(
                                onPressed: busy ? null : submit,
                                style: FilledButton.styleFrom(
                                  backgroundColor: const Color(0xFF1C3E66),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                child: busy
                                    ? const SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Masuk',
                                        style: TextStyle(
                                          fontFamily: 'Plus Jakarta Sans',
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
