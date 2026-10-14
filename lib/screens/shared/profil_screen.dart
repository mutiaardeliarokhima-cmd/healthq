import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../utils/validators.dart';
import '../../widgets/common.dart';
import '../../widgets/primary_button.dart';

/// Profil: data diri, nomor BPJS, dan Pengaturan / Keluar (semua peran).
class ProfilScreen extends StatefulWidget {
  const ProfilScreen({super.key});
  @override
  State<ProfilScreen> createState() => _ProfilScreenState();
}

class _ProfilScreenState extends State<ProfilScreen> {
  final _form = GlobalKey<FormState>();
  late final TextEditingController _nama, _nik, _bpjs, _hp;

  @override
  void initState() {
    super.initState();
    final u = context.read<AuthProvider>().user!;
    _nama = TextEditingController(text: u.nama);
    _nik = TextEditingController(text: u.nik);
    _bpjs = TextEditingController(text: u.noBpjs);
    _hp = TextEditingController(text: u.noHp);
  }

  @override
  void dispose() {
    for (final c in [_nama, _nik, _bpjs, _hp]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _simpan() async {
    if (!_form.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
        nama: _nama.text, nik: _nik.text, noBpjs: _bpjs.text, noHp: _hp.text);
    if (!mounted) return;
    showSnack(context, ok ? 'Profil disimpan' : (auth.error ?? 'Gagal menyimpan'), error: !ok);
  }

  Future<void> _keluar() async {
    final ya = await konfirmasi(context,
        judul: 'Keluar dari akun?', isi: 'Anda perlu masuk lagi untuk memakai aplikasi.', ya: 'Keluar');
    if (!ya || !mounted) return;
    await context.read<AuthProvider>().logout();
    if (!mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final u = auth.user!;
    final pasien = u.isPasien;
    final digits = [FilteringTextInputFormatter.digitsOnly];
    final inShell = !Navigator.canPop(context);

    return Scaffold(
      appBar: inShell ? null : AppBar(title: const Text('Profil')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              if (inShell) Text('Profil', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              AppCard(
                color: AppColors.tint,
                child: Row(children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.primary,
                    child: Text(u.nama.isEmpty ? '?' : u.nama[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(u.nama, style: Theme.of(context).textTheme.titleMedium),
                      Text(u.email, style: Theme.of(context).textTheme.bodySmall),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(color: AppColors.mint, borderRadius: BorderRadius.circular(20)),
                        child: Text(
                            u.isAdmin ? 'Admin puskesmas' : (u.isPetugas ? 'Petugas pendaftaran' : 'Pasien'),
                            style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800, fontSize: 13)),
                      ),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 22),
              TextFormField(
                controller: _nama,
                decoration: const InputDecoration(labelText: 'Nama Lengkap'),
                validator: Validators.nama,
              ),
              if (pasien) ...[
                const SizedBox(height: 14),
                TextFormField(
                  controller: _nik,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  maxLength: 16,
                  decoration: const InputDecoration(labelText: 'NIK', counterText: ''),
                  validator: Validators.nik,
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _bpjs,
                  keyboardType: TextInputType.number,
                  inputFormatters: digits,
                  maxLength: 13,
                  decoration: const InputDecoration(labelText: 'Nomor BPJS (opsional)', counterText: ''),
                  validator: Validators.noBpjs,
                ),
              ],
              const SizedBox(height: 14),
              TextFormField(
                controller: _hp,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(labelText: 'Nomor HP'),
                validator: Validators.noHp,
              ),
              const SizedBox(height: 22),
              PrimaryButton(label: 'Simpan Perubahan', loading: auth.loading, onPressed: _simpan),
              const SizedBox(height: 28),
              const Divider(),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout_rounded, color: AppColors.red),
                title: const Text('Keluar', style: TextStyle(color: AppColors.red, fontWeight: FontWeight.w800)),
                onTap: _keluar,
              ),
            ]),
          ),
        ),
      ),
    );
  }
}
