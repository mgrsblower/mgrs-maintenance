import 'package:flutter/material.dart';
import '../../app/gateway.dart';
import '../../shared/async_state_view.dart';

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
  final identifier = TextEditingController(),
      password = TextEditingController();
  bool busy = false, hidden = true;
  String? error;
  @override
  void dispose() {
    identifier.dispose();
    password.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    if (busy || !form.currentState!.validate()) return;
    setState(() {
      busy = true;
      error = null;
    });
    try {
      await widget.gateway.signIn(identifier.text, password.text);
      if (mounted) widget.onSignedIn();
    } catch (e) {
      if (mounted) setState(() => error = failureMessage(e));
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: PageBody(
        children: [
          const SizedBox(height: 48),
          Icon(
            Icons.build_circle_outlined,
            size: 56,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 24),
          Text(
            'MGRS Maintenance',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Pemeriksaan dan perawatan komponen',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          Form(
            key: form,
            child: Column(
              children: [
                TextFormField(
                  controller: identifier,
                  enabled: !busy,
                  autofillHints: const [AutofillHints.username],
                  textInputAction: TextInputAction.next,
                  decoration: const InputDecoration(
                    labelText: 'Akun MGRS',
                    hintText: 'Username, email, atau nomor telepon',
                  ),
                  validator: (v) => v == null || v.trim().isEmpty
                      ? 'Masukkan akun MGRS.'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: password,
                  enabled: !busy,
                  obscureText: hidden,
                  autofillHints: const [AutofillHints.password],
                  onFieldSubmitted: (_) => submit(),
                  decoration: InputDecoration(
                    labelText: 'Kata sandi',
                    suffixIcon: IconButton(
                      tooltip: hidden
                          ? 'Tampilkan kata sandi'
                          : 'Sembunyikan kata sandi',
                      onPressed: () => setState(() => hidden = !hidden),
                      icon: Icon(
                        hidden
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Masukkan kata sandi.' : null,
                ),
                const SizedBox(height: 24),
                if (error != null) ...[
                  Text(
                    error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: busy ? null : submit,
                    child: Text(busy ? 'Memverifikasi…' : 'Masuk'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
