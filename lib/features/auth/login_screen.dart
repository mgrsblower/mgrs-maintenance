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
    return WidgetsBinding.instance.runtimeType.toString().contains(
      'TestWidgetsFlutterBinding',
    );
  }

  Widget _buildBearAnimation() {
    if (_isTestEnvironment) {
      return const SizedBox(
        height: 184,
        width: double.infinity,
        child: Center(
          child: Icon(Icons.pets_rounded, size: 72, color: AppTokens.white),
        ),
      );
    }

    return SizedBox(
      height: 184,
      width: double.infinity,
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
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppTokens.porcelain,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            const verticalPadding = AppTokens.space24 * 2;
            final minimumContentHeight = constraints.maxHeight > verticalPadding
                ? constraints.maxHeight - verticalPadding
                : 0.0;

            return SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.all(AppTokens.space24),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: minimumContentHeight),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 420),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: double.infinity,
                          clipBehavior: Clip.antiAlias,
                          decoration: const BoxDecoration(
                            color: AppTokens.ink,
                            borderRadius: BorderRadius.all(
                              Radius.circular(AppTokens.cardRadius),
                            ),
                          ),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.fromLTRB(
                                  AppTokens.space24,
                                  AppTokens.space24,
                                  AppTokens.space24,
                                  0,
                                ),
                                child: Text(
                                  'MGRS-Maintenance',
                                  textAlign: TextAlign.center,
                                  style: textTheme.headlineSmall?.copyWith(
                                    color: AppTokens.white,
                                  ),
                                ),
                              ),
                              _buildBearAnimation(),
                            ],
                          ),
                        ),
                        const SizedBox(height: AppTokens.space16),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(AppTokens.space24),
                          decoration: BoxDecoration(
                            color: AppTokens.white,
                            borderRadius: BorderRadius.circular(
                              AppTokens.cardRadius,
                            ),
                            border: Border.all(color: AppTokens.mist),
                          ),
                          child: Form(
                            key: form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Email / Akun MGRS',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: AppTokens.ink,
                                  ),
                                ),
                                const SizedBox(height: AppTokens.space8),
                                TextFormField(
                                  controller: identifier,
                                  focusNode: identifierFocusNode,
                                  enabled: !busy,
                                  autofillHints: const [AutofillHints.username],
                                  textInputAction: TextInputAction.next,
                                  onChanged: (value) {
                                    _followOnEmail?.change(
                                      (value.length * 1.5).clamp(0, 100),
                                    );
                                  },
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppTokens.ink,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan email atau username...',
                                    hintStyle: textTheme.bodyMedium?.copyWith(
                                      color: AppTokens.stone,
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == null || value.trim().isEmpty
                                      ? 'Masukkan akun MGRS.'
                                      : null,
                                ),
                                const SizedBox(height: AppTokens.space16),
                                Text(
                                  'Kata Sandi',
                                  style: textTheme.labelLarge?.copyWith(
                                    color: AppTokens.ink,
                                  ),
                                ),
                                const SizedBox(height: AppTokens.space8),
                                TextFormField(
                                  controller: password,
                                  focusNode: passwordFocusNode,
                                  enabled: !busy,
                                  obscureText: hidden,
                                  autofillHints: const [AutofillHints.password],
                                  onFieldSubmitted: (_) => submit(),
                                  style: textTheme.bodyMedium?.copyWith(
                                    color: AppTokens.ink,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Masukkan kata sandi...',
                                    hintStyle: textTheme.bodyMedium?.copyWith(
                                      color: AppTokens.stone,
                                    ),
                                    suffixIcon: IconButton(
                                      tooltip: hidden
                                          ? 'Tampilkan kata sandi'
                                          : 'Sembunyikan kata sandi',
                                      constraints:
                                          const BoxConstraints.tightFor(
                                            width: AppTokens.minTouchTarget,
                                            height: AppTokens.minTouchTarget,
                                          ),
                                      color: AppTokens.ink,
                                      onPressed: _onTogglePasswordVisibility,
                                      icon: Icon(
                                        hidden
                                            ? Icons.visibility_off_outlined
                                            : Icons.visibility_outlined,
                                      ),
                                    ),
                                  ),
                                  validator: (value) =>
                                      value == null || value.isEmpty
                                      ? 'Masukkan kata sandi.'
                                      : null,
                                ),
                                if (error != null) ...[
                                  const SizedBox(height: AppTokens.space16),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(
                                      AppTokens.space12,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTokens.dangerSurface,
                                      borderRadius: BorderRadius.circular(
                                        AppTokens.controlRadius,
                                      ),
                                    ),
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Padding(
                                          padding: EdgeInsets.only(
                                            top: AppTokens.space4,
                                          ),
                                          child: Icon(
                                            Icons.error_outline_rounded,
                                            color: AppTokens.danger,
                                          ),
                                        ),
                                        const SizedBox(width: AppTokens.space8),
                                        Expanded(
                                          child: Text(
                                            error!,
                                            style: textTheme.bodyMedium
                                                ?.copyWith(
                                                  color: AppTokens.danger,
                                                ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                                const SizedBox(height: AppTokens.space24),
                                PressableScale(
                                  enabled: !busy,
                                  child: SizedBox(
                                    width: double.infinity,
                                    child: FilledButton(
                                      onPressed: busy ? null : submit,
                                      style: FilledButton.styleFrom(
                                        foregroundColor: AppTokens.ink,
                                      ),
                                      child: busy
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: AppTokens.ink,
                                              ),
                                            )
                                          : const Text('Masuk'),
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
            );
          },
        ),
      ),
    );
  }
}
