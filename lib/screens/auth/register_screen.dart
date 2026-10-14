import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/common.dart';
import '../../widgets/primary_button.dart';

/// Registrasi pasien + isi profil (NIK, BPJS, HP).
class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});
  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _nik = TextEditingController();
  final _bpjs = TextEditingController();
  final _hp = TextEditingController();
  final _email = TextEditingController();
  final _pass = TextEditingController();
  bool _hide = true;

  @override
  void dispose() {
    for (final c in [_nama, _nik, _bpjs, _hp, _email, _pass]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _daftar() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.register(
        nama: _nama.text,
        nik: _nik.text,
        noBpjs: _bpjs.text,
        noHp: _hp.text,
        email: _email.text,
        password: _pass.text);
    if (!mounted) return;
    if (ok) {
      Navigator.pushNamedAndRemoveUntil(context, '/pasien/home', (_) => false);
    } else {
      showSnack(context, auth.error ?? 'Gagal mendaftar', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loading = context.watch<AuthProvider>().loading;
    final digits = [FilteringTextInputFormatter.digitsOnly];
    return Scaffold(
      appBar: AppBar(title: const Text('Daftar Akun')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Data diri', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.person_outline_rounded)),
                validator: Validators.nama,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _nik,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                maxLength: 16,
                decoration: const InputDecoration(labelText: 'NIK (16 digit)', counterText: '', prefixIcon: Icon(Icons.badge_outlined)),
                validator: Validators.nik,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _bpjs,
                keyboardType: TextInputType.number,
                inputFormatters: digits,
                maxLength: 13,
                decoration: const InputDecoration(
                    labelText: 'Nomor BPJS (opsional)', counterText: '', prefixIcon: Icon(Icons.credit_card_rounded)),
                validator: Validators.noBpjs,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _hp,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                    labelText: 'Nomor HP', hintText: '08xxxxxxxxxx', prefixIcon: Icon(Icons.phone_outlined)),
                validator: Validators.noHp,
              ),
              const SizedBox(height: 26),
              Text('Akun', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email', prefixIcon: Icon(Icons.mail_outline_rounded)),
                validator: Validators.email,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pass,
                obscureText: _hide,
                decoration: InputDecoration(
                  labelText: 'Kata Sandi (minimal 8 karakter)',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: 'Tampilkan atau sembunyikan',
                    icon: Icon(_hide ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _hide = !_hide),
                  ),
                ),
                validator: Validators.kataSandi,
              ),
              const SizedBox(height: 28),
              PrimaryButton(label: 'Daftar', loading: loading, onPressed: _daftar),
            ]),
          ),
        ),
      ),
    );
  }
}
