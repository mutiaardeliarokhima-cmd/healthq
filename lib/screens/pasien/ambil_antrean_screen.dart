import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/dokter_model.dart';
import '../../models/jadwal_model.dart';
import '../../models/poli_model.dart';
import '../../providers/antrean_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/jadwal_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/primary_button.dart';

/// Wizard 3 langkah: Poli, Tanggal, Konfirmasi (maksimal 4 langkah).
class AmbilAntreanScreen extends StatefulWidget {
  const AmbilAntreanScreen({super.key});
  @override
  State<AmbilAntreanScreen> createState() => _AmbilAntreanScreenState();
}

class _AmbilAntreanScreenState extends State<AmbilAntreanScreen> {
  final _page = PageController();
  int _step = 0;
  static const _labels = ['Poli', 'Tanggal', 'Konfirmasi'];

  @override
  void initState() {
    super.initState();
    context.read<AntreanProvider>().reset();
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _go(int s) {
    setState(() => _step = s);
    _page.animateToPage(s, duration: const Duration(milliseconds: 280), curve: Curves.easeOutCubic);
  }

  Future<void> _konfirmasi() async {
    final prov = context.read<AntreanProvider>();
    final user = context.read<AuthProvider>().user!;
    final id = await prov.ambil(user);
    if (!mounted) return;
    if (id != null) {
      Navigator.pushReplacementNamed(context, '/pasien/antrean/$id');
    } else {
      showSnack(context, prov.error ?? 'Gagal mengambil antrean', error: true);
      if ((prov.error ?? '').contains('Kuota habis')) _go(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final prov = context.watch<AntreanProvider>();

    if (!user.profilLengkap) {
      return Scaffold(
        appBar: AppBar(title: const Text('Ambil Antrean')),
        body: EmptyState(
          icon: Icons.assignment_ind_outlined,
          title: 'Lengkapi profil dulu',
          message: 'NIK dan nomor HP diperlukan untuk mengambil antrean.',
          action: PrimaryButton(label: 'Buka Profil', onPressed: () => Navigator.pushNamed(context, '/profil')),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Ambil Antrean')),
      body: Column(children: [
        _Stepper(step: _step, labels: _labels),
        Expanded(
          child: PageView(
            controller: _page,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _StepPoli(onNext: () => _go(1)),
              _StepTanggal(onBack: () => _go(0), onNext: () => _go(2)),
              _StepKonfirmasi(onBack: () => _go(1), onConfirm: _konfirmasi, loading: prov.loading),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Stepper extends StatelessWidget {
  final int step;
  final List<String> labels;
  const _Stepper({required this.step, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++) ...[
          Column(children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= step ? AppColors.primary : AppColors.tint,
                border: Border.all(color: i <= step ? AppColors.primary : AppColors.line, width: 1.5),
              ),
              child: i < step
                  ? const Icon(Icons.check_rounded, color: Colors.white, size: 20)
                  : Text('${i + 1}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, color: i == step ? Colors.white : AppColors.muted)),
            ),
            const SizedBox(height: 4),
            Text(labels[i],
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: i == step ? FontWeight.w800 : FontWeight.w600,
                    color: i == step ? AppColors.primary : AppColors.muted)),
          ]),
          if (i < labels.length - 1)
            Expanded(
              child: Container(
                height: 2,
                margin: const EdgeInsets.only(bottom: 20, left: 6, right: 6),
                color: i < step ? AppColors.primary : AppColors.line,
              ),
            ),
        ],
      ]),
    );
  }
}

// ---------- Langkah 1: pilih poli ----------
class _StepPoli extends StatelessWidget {
  final VoidCallback onNext;
  const _StepPoli({required this.onNext});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<JadwalService>();
    final prov = context.watch<AntreanProvider>();
    final text = Theme.of(context).textTheme;
    return StreamBuilder<List<PoliModel>>(
      stream: svc.streamPoli(),
      builder: (context, poliSnap) {
        return StreamBuilder<List<JadwalModel>>(
          stream: svc.streamJadwalTanggal(todayKey()),
          builder: (context, jSnap) {
            if (!poliSnap.hasData) return const LoadingView();
            final jadwal = {for (final j in jSnap.data ?? <JadwalModel>[]) j.poliId: j};
            final poli = poliSnap.data!;
            return Column(children: [
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 12), children: [
                  Text('Pilih Poli', style: text.titleMedium),
                  const SizedBox(height: 12),
                  if (poli.isEmpty)
                    const EmptyState(icon: Icons.local_hospital_outlined, title: 'Belum ada poli tersedia'),
                  for (final p in poli)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PoliTile(
                        poli: p,
                        sisaHariIni: jadwal[p.poliId]?.sisa,
                        selected: prov.poli?.poliId == p.poliId,
                        onTap: p.aktif ? () => prov.pilihPoli(p) : null,
                      ),
                    ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: PrimaryButton(label: 'Lanjut', onPressed: prov.poli == null ? null : onNext),
              ),
            ]);
          },
        );
      },
    );
  }
}

class _PoliTile extends StatelessWidget {
  final PoliModel poli;
  final int? sisaHariIni;
  final bool selected;
  final VoidCallback? onTap;
  const _PoliTile({required this.poli, this.sisaHariIni, required this.selected, this.onTap});

  @override
  Widget build(BuildContext context) {
    final off = onTap == null;
    return Opacity(
      opacity: off ? .5 : 1,
      child: AppCard(
        color: selected ? AppColors.sky : Colors.white,
        onTap: onTap,
        child: Row(children: [
          Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
              color: selected ? AppColors.primary : AppColors.muted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Poli ${poli.namaPoli}', style: Theme.of(context).textTheme.titleSmall),
              Text(off ? 'Sedang tutup' : '${poli.jamBuka} - ${poli.jamTutup}',
                  style: Theme.of(context).textTheme.bodySmall),
            ]),
          ),
          if (!off)
            Text(sisaHariIni == null ? 'Sisa: -' : 'Sisa: $sisaHariIni',
                style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w800)),
        ]),
      ),
    );
  }
}

// ---------- Langkah 2: pilih tanggal ----------
class _StepTanggal extends StatelessWidget {
  final VoidCallback onBack, onNext;
  const _StepTanggal({required this.onBack, required this.onNext});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AntreanProvider>();
    final svc = context.read<JadwalService>();
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final last = first.add(const Duration(days: 7));
    final poli = prov.poli;
    if (poli == null) return const SizedBox();

    return StreamBuilder<JadwalModel?>(
      stream: svc.streamJadwal(poli.poliId, prov.tanggalKey),
      builder: (context, snap) {
        final j = snap.data;
        final ada = j != null;
        final penuh = j != null && j.penuh;
        final bisa = ada && !penuh;
        return Column(children: [
          Expanded(
            child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 12), children: [
              Text('Pilih Tanggal Kunjungan', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 4),
              Text('Poli ${poli.namaPoli}, maksimal 7 hari ke depan.', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 8),
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: CalendarDatePicker(
                  initialDate: prov.tanggal.isBefore(first) ? first : prov.tanggal,
                  firstDate: first,
                  lastDate: last,
                  onDateChanged: prov.pilihTanggal,
                ),
              ),
              const SizedBox(height: 14),
              AppCard(
                color: !ada ? AppColors.tint : (penuh ? const Color(0xFFFEE2E2) : AppColors.mint.withOpacity(.55)),
                outlined: false,
                child: Row(children: [
                  Icon(!ada ? Icons.event_busy_rounded : (penuh ? Icons.block_rounded : Icons.event_available_rounded),
                      color: penuh ? AppColors.red : AppColors.primary, size: 30),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(fmtTanggalSingkat(prov.tanggalKey), style: Theme.of(context).textTheme.titleSmall),
                      Text(
                          !ada
                              ? 'Belum ada jadwal pada tanggal ini.'
                              : (penuh
                                  ? 'Kuota habis. Silakan pilih tanggal lain.'
                                  : 'Sisa kuota ${j.sisa} dari ${j.kuota}'),
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: penuh ? AppColors.red : AppColors.ink)),
                    ]),
                  ),
                ]),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            child: Row(children: [
              Expanded(child: PrimaryButton(label: 'Kembali', outlined: true, onPressed: onBack)),
              const SizedBox(width: 12),
              Expanded(flex: 2, child: PrimaryButton(label: 'Lanjut', onPressed: bisa ? onNext : null)),
            ]),
          ),
        ]);
      },
    );
  }
}

// ---------- Langkah 3: konfirmasi ----------
class _StepKonfirmasi extends StatelessWidget {
  final VoidCallback onBack, onConfirm;
  final bool loading;
  const _StepKonfirmasi({required this.onBack, required this.onConfirm, required this.loading});

  @override
  Widget build(BuildContext context) {
    final prov = context.watch<AntreanProvider>();
    final svc = context.read<JadwalService>();
    final poli = prov.poli;
    if (poli == null) return const SizedBox();
    final text = Theme.of(context).textTheme;

    return StreamBuilder<JadwalModel?>(
      stream: svc.streamJadwal(poli.poliId, prov.tanggalKey),
      builder: (context, jSnap) {
        final j = jSnap.data;
        return StreamBuilder<List<DokterModel>>(
          stream: svc.streamDokter(),
          builder: (context, dSnap) {
            final dokter = (dSnap.data ?? []).where((d) => d.dokterId == j?.dokterId).toList();
            Widget row(String k, String v) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: 110, child: Text(k, style: text.bodySmall)),
                    Expanded(child: Text(v, style: text.titleSmall)),
                  ]),
                );
            return Column(children: [
              Expanded(
                child: ListView(padding: const EdgeInsets.fromLTRB(20, 12, 20, 12), children: [
                  Text('Periksa Data Antrean', style: text.titleMedium),
                  const SizedBox(height: 12),
                  AppCard(
                    child: Column(children: [
                      row('Poli', 'Poli ${poli.namaPoli}'),
                      const Divider(),
                      row('Tanggal', fmtTanggalSingkat(prov.tanggalKey)),
                      const Divider(),
                      row('Jam layanan', '${poli.jamBuka} - ${poli.jamTutup}'),
                      const Divider(),
                      row('Dokter', dokter.isEmpty ? '-' : dokter.first.nama),
                      const Divider(),
                      row('Sisa kuota', j == null ? '-' : '${j.sisa} dari ${j.kuota}'),
                    ]),
                  ),
                  const SizedBox(height: 14),
                  AppCard(
                    color: AppColors.sky.withOpacity(.6),
                    outlined: false,
                    child: Row(children: [
                      const Icon(Icons.info_outline_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Text(
                              'Anda akan menerima notifikasi saat giliran hampir tiba. Lakukan check-in setelah sampai di puskesmas.',
                              style: text.bodyMedium)),
                    ]),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
                child: Row(children: [
                  Expanded(child: PrimaryButton(label: 'Kembali', outlined: true, onPressed: loading ? null : onBack)),
                  const SizedBox(width: 12),
                  Expanded(
                      flex: 2,
                      child: PrimaryButton(
                          label: 'Konfirmasi', icon: Icons.check_rounded, loading: loading, onPressed: onConfirm)),
                ]),
              ),
            ]);
          },
        );
      },
    );
  }
}
