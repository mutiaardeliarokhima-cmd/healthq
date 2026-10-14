import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/antrean_model.dart';
import '../../models/poli_model.dart';
import '../../services/antrean_service.dart';
import '../../services/auth_service.dart';
import '../../services/jadwal_service.dart';
import '../../utils/formatters.dart';
import '../../utils/validators.dart';
import '../../widgets/common.dart';
import '../../widgets/primary_button.dart';

/// Daftarkan pasien yang datang langsung (tanpa smartphone) ke antrean yang sama.
class WalkinScreen extends StatefulWidget {
  const WalkinScreen({super.key});
  @override
  State<WalkinScreen> createState() => _WalkinScreenState();
}

class _WalkinScreenState extends State<WalkinScreen> {
  final _form = GlobalKey<FormState>();
  final _nama = TextEditingController();
  String? _poliId;
  bool _loading = false;

  @override
  void dispose() {
    _nama.dispose();
    super.dispose();
  }

  Future<String> _buat(PoliModel poli) => context.read<AntreanService>().buatAntrean(
        poli: poli,
        tanggal: todayKey(),
        sumber: 'walkin',
        namaWalkin: _nama.text.trim(),
      );

  Future<void> _daftarkan(List<PoliModel> poli) async {
    if (!_form.currentState!.validate()) return;
    final p = poli.firstWhere((e) => e.poliId == _poliId);
    setState(() => _loading = true);
    try {
      String id;
      try {
        id = await _buat(p);
      } on KuotaHabisException {
        if (!mounted) return;
        final buka = await konfirmasi(context,
            judul: 'Kuota habis',
            isi: 'Kuota Poli ${p.namaPoli} hari ini sudah penuh. Buka kuota tambahan 5 nomor?',
            ya: 'Buka Kuota',
            tidak: 'Batal');
        if (!buka || !mounted) {
          setState(() => _loading = false);
          return;
        }
        await context.read<AntreanService>().bukaKuotaTambahan(p.poliId, todayKey(), 5);
        id = await _buat(p);
      }
      final snap = await context.read<AntreanService>().streamAntreanSnap(id).first;
      if (!mounted) return;
      final a = AntreanModel.fromMap(snap.id, snap.data()!);
      _nama.clear();
      setState(() => _loading = false);
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text('Pasien terdaftar'),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            Text('${a.namaTampil}, Poli ${a.namaPoli}'),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: BoxDecoration(color: AppColors.mint.withOpacity(.7), borderRadius: BorderRadius.circular(20)),
              child: Center(
                child: Text(a.kode,
                    style: const TextStyle(fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary)),
              ),
            ),
            const SizedBox(height: 8),
            const Text('Berikan nomor ini kepada pasien.'),
          ]),
          actions: [
            FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(88, 48)),
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Selesai')),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        showSnack(context, AuthService.pesanError(e), error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return StreamBuilder<List<PoliModel>>(
      stream: context.read<JadwalService>().streamPoli(),
      builder: (context, snap) {
        if (!snap.hasData) return const LoadingView();
        final poli = snap.data!.where((p) => p.aktif).toList();
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Form(
            key: _form,
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Text('Daftarkan Pasien Walk-in', style: text.titleLarge),
              const SizedBox(height: 4),
              Text('Nomor diambil dari antrean yang sama dengan pasien online.', style: text.bodySmall),
              const SizedBox(height: 22),
              TextFormField(
                controller: _nama,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(labelText: 'Nama Pasien', prefixIcon: Icon(Icons.person_outline_rounded)),
                validator: Validators.nama,
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String>(
                value: poli.any((p) => p.poliId == _poliId) ? _poliId : null,
                decoration: const InputDecoration(labelText: 'Poli', prefixIcon: Icon(Icons.local_hospital_outlined)),
                items: [for (final p in poli) DropdownMenuItem(value: p.poliId, child: Text('Poli ${p.namaPoli}'))],
                onChanged: (v) => setState(() => _poliId = v),
                validator: (v) => v == null ? 'Poli wajib dipilih' : null,
              ),
              const SizedBox(height: 26),
              PrimaryButton(
                  label: 'Daftarkan',
                  icon: Icons.person_add_alt_1_rounded,
                  loading: _loading,
                  onPressed: () => _daftarkan(poli)),
            ]),
          ),
        );
      },
    );
  }
}
