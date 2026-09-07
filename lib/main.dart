import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'app/app.dart';
import 'app/app_theme.dart';
import 'app/gateway.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  const url = String.fromEnvironment('SUPABASE_URL');
  const key = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
  final uri = Uri.tryParse(url);
  if (uri == null || uri.scheme != 'https' || uri.host.isEmpty || key.isEmpty) {
    runApp(const StartupFailure());
    return;
  }
  try {
    await Supabase.initialize(url: url, publishableKey: key);
    runApp(MaintenanceApp(gateway: SupabaseGateway(Supabase.instance.client)));
  } catch (_) {
    runApp(const StartupFailure());
  }
}

class StartupFailure extends StatelessWidget {
  const StartupFailure({super.key});
  @override
  Widget build(BuildContext context) => MaterialApp(
    theme: maintenanceTheme(),
    home: const Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.all(24),
            child: Text(
              'Aplikasi belum dapat terhubung. Buka kembali aplikasi atau hubungi admin.',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    ),
  );
}
