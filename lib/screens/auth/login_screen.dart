import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/brand_logo.dart';
import '../../widgets/common.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    _email.dispose();
    _pass.dispose();
    super.dispose();
  }

  Future<void> _masuk() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(_email.text, _pass.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, AuthProvider.routeFor(auth.user!.role), (_) => false);
    } else {
      showSnack(context, auth.error ?? 'Gagal masuk', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _form,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  const Center(child: BrandLogo(size: 88)),
                  const SizedBox(height: 36),
                  Text('Masuk', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text('Masuk untuk mengambil dan memantau antrean puskesmas.',
                      style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 22),
                  TextFormField(
                    controller: _email,
                    keyboardType: TextInputType.emailAddress,
                    autofillHints: const [AutofillHints.email],
                    decoration: const InputDecoration(
                        labelText: 'Email', hintText: 'contoh@email.com', prefixIcon: Icon(Icons.mail_outline_rounded)),
                    validator: Validators.email,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pass,
                    obscureText: _hide,
                    decoration: InputDecoration(
                      labelText: 'Kata Sandi',
                      prefixIcon: const Icon(Icons.lock_outline_rounded),
                      suffixIcon: IconButton(
                        tooltip: _hide ? 'Tampilkan kata sandi' : 'Sembunyikan kata sandi',
                        icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                        onPressed: () => setState(() => _hide = !_hide),
                      ),
                    ),
                    validator: Validators.kataSandi,
                    onFieldSubmitted: (_) => _masuk(),
                  ),
                  const SizedBox(height: 24),
                  PrimaryButton(label: 'Masuk', loading: loading, onPressed: _masuk),
                  const SizedBox(height: 10),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/register'),
                    child: const Text('Belum punya akun? Daftar',
                        style: TextStyle(color: AppColors.primary)),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
