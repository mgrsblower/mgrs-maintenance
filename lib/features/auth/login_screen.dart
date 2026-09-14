import 'package:flutter/material.dart';
import 'package:mgrs_maintenance/app/gateway.dart';
import 'package:mgrs_maintenance/design_system/components/mgrs_button.dart';
import 'package:mgrs_maintenance/design_system/layout/mgrs_screen.dart';
import 'package:mgrs_maintenance/design_system/mgrs_tokens.dart';

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

  @override
  void dispose() {
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

    if (!form.currentState!.validate()) return;

    setState(() {
      busy = true;
      error = null;
    });

    try {
      await widget.gateway.signIn(identifier.text.trim(), password.text);
      if (mounted) widget.onSignedIn();
    } catch (exception) {
      if (!mounted) return;
      setState(() {
        error = exception is AppFailure
            ? exception.message
            : const AppFailure('unknown').message;
      });
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MgrsScreen(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight:
                MediaQuery.sizeOf(context).height -
                MediaQuery.paddingOf(context).vertical -
                MgrsSpacing.lg,
          ),
          child: Center(
            child: Form(
              key: form,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.build_circle_outlined,
                    size: 48,
                    color: MgrsColors.action,
                    semanticLabel: 'MGRS Maintenance',
                  ),
                  const SizedBox(height: MgrsSpacing.lg),
                  Text(
                    'Masuk ke MGRS',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: MgrsColors.ink,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: MgrsSpacing.sm),
                  Text(
                    'Gunakan akun operasional untuk melanjutkan.',
                    textAlign: TextAlign.center,
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: MgrsColors.muted),
                  ),
                  const SizedBox(height: MgrsSpacing.section),
                  Text(
                    'Email atau username',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: MgrsSpacing.sm),
                  TextFormField(
                    controller: identifier,
                    focusNode: identifierFocusNode,
                    enabled: !busy,
                    autofillHints: const [AutofillHints.username],
                    textInputAction: TextInputAction.next,
                    onFieldSubmitted: (_) => passwordFocusNode.requestFocus(),
                    decoration: const InputDecoration(
                      hintText: 'Email atau username',
                      prefixIcon: Icon(Icons.person_outline),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Masukkan email atau username.'
                        : null,
                  ),
                  const SizedBox(height: MgrsSpacing.base),
                  Text(
                    'Kata sandi',
                    style: Theme.of(context).textTheme.labelMedium,
                  ),
                  const SizedBox(height: MgrsSpacing.sm),
                  TextFormField(
                    controller: password,
                    focusNode: passwordFocusNode,
                    enabled: !busy,
                    obscureText: hidden,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) => submit(),
                    decoration: InputDecoration(
                      hintText: 'Kata sandi',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        tooltip: hidden
                            ? 'Tampilkan kata sandi'
                            : 'Sembunyikan kata sandi',
                        onPressed: busy
                            ? null
                            : () => setState(() => hidden = !hidden),
                        icon: Icon(
                          hidden
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                        ),
                      ),
                    ),
                    validator: (value) => value == null || value.isEmpty
                        ? 'Masukkan kata sandi.'
                        : null,
                  ),
                  if (error != null) ...[
                    const SizedBox(height: MgrsSpacing.base),
                    Semantics(
                      liveRegion: true,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: MgrsColors.dangerSoft,
                          borderRadius: BorderRadius.circular(
                            MgrsRadii.control,
                          ),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(MgrsSpacing.md),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.error_outline,
                                color: MgrsColors.danger,
                              ),
                              const SizedBox(width: MgrsSpacing.sm),
                              Expanded(
                                child: Text(
                                  error!,
                                  style: Theme.of(context).textTheme.bodyMedium
                                      ?.copyWith(color: MgrsColors.danger),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: MgrsSpacing.xl),
                  MgrsButton.primary(
                    label: 'Masuk',
                    icon: Icons.login,
                    loading: busy,
                    onPressed: submit,
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
