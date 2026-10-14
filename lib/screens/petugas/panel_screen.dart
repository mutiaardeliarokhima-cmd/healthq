import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/antrean_model.dart';
import '../../models/poli_model.dart';
import '../../providers/antrean_provider.dart';
import '../../services/antrean_service.dart';
import '../../services/jadwal_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_chip.dart';

/// Panel Antrean per poli: panggil, lewati, selesai, dan daftar tunggu.
class PanelScreen extends StatefulWidget {
  const PanelScreen({super.key});
  @override
  State<PanelScreen> createState() => _PanelScreenState();
}

class _PanelScreenState extends State<PanelScreen> {
  String? _poliId;
  bool _busy = false;

  Future<void> _aksi(Future<dynamic> Function() job, {String? sukses}) async {
    setState(() => _busy = true);
    final err = await context.read<AntreanProvider>().jalankan(() async => await job());
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      showSnack(context, err, error: true);
    } else if (sukses != null) {
      showSnack(context, sukses);
    }
  }

  Future<void> _lewati(AntreanModel a) async {
    final ya = await konfirmasi(context,
        judul: 'Lewati ${a.kode}?',
        isi: 'Pasien sudah dipanggil dua kali dan tidak hadir. Status menjadi Tidak Hadir.',
        ya: 'Lewati',
        bahaya: true);
    if (ya && mounted) {
      await _aksi(() => context.read<AntreanService>().lewati(a), sukses: '${a.kode} dilewati.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.read<AntreanService>();
    final text = Theme.of(context).textTheme;
    final today = todayKey();

    return StreamBuilder<List<PoliModel>>(
      stream: context.read<JadwalService>().streamPoli(),
      builder: (context, pSnap) {
        if (!pSnap.hasData) return const LoadingView();
        final poli = pSnap.data!;
        if (poli.isEmpty) {
          return const EmptyState(
              icon: Icons.local_hospital_outlined,
              title: 'Belum ada poli',
              message: 'Minta admin menambahkan data poli dan jadwal.');
        }
        final sel = poli.firstWhere((p) => p.poliId == _poliId, orElse: () => poli.first);

        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 2),
            child: Text('Panel Antrean', style: text.titleLarge),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: Text(fmtTanggalPanjang(DateTime.now()), style: text.bodySmall),
          ),
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: poli.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (_, i) {
                final p = poli[i];
                final on = p.poliId == sel.poliId;
                return ChoiceChip(
                  label: Text(p.namaPoli),
                  selected: on,
                  showCheckmark: false,
                  labelStyle: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: on ? Colors.white : AppColors.ink),
                  selectedColor: AppColors.primary,
                  backgroundColor: AppColors.tint,
                  side: BorderSide.none,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  onSelected: (_) => setState(() => _poliId = p.poliId),
                );
              },
            ),
          ),
          Expanded(
            child: StreamBuilder<List<AntreanModel>>(
              stream: svc.streamAntreanPoli(sel.poliId, today),
              builder: (context, snap) {
                if (!snap.hasData) return const LoadingView();
                final list = snap.data!;
                final dilayani = list.where((a) => a.status == AntreanStatus.dipanggil).toList();
                final tunggu = list
                    .where((a) => a.status == AntreanStatus.hadir || a.status == AntreanStatus.menunggu)
                    .toList();
                final selesai = list.where((a) => a.status == AntreanStatus.selesai).length;
                final tidakHadir = list.where((a) => a.status == AntreanStatus.tidakHadir).length;

                return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
                  // Pasien yang sedang dilayani
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                        color: AppColors.sky, borderRadius: BorderRadius.circular(22)),
                    child: dilayani.isEmpty
                        ? Row(children: [
                            const Icon(Icons.hourglass_empty_rounded, color: AppColors.primary, size: 30),
                            const SizedBox(width: 12),
                            Expanded(
                                child: Text('Belum ada pasien yang sedang dilayani.', style: text.titleSmall)),
                          ])
                        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text('Sedang dilayani', style: text.bodySmall),
                            const SizedBox(height: 4),
                            Row(children: [
                              Text(dilayani.first.kode,
                                  style: const TextStyle(
                                      fontSize: 34, fontWeight: FontWeight.w900, color: AppColors.primary)),
                              const SizedBox(width: 12),
                              Expanded(child: Text(dilayani.first.namaTampil, style: text.titleMedium)),
                            ]),
                            const SizedBox(height: 14),
                            Row(children: [
                              Expanded(
                                  child: PrimaryButton(
                                      label: 'Selesai',
                                      icon: Icons.check_rounded,
                                      onPressed: _busy
                                          ? null
                                          : () => _aksi(() => svc.selesai(dilayani.first),
                                              sukses: '${dilayani.first.kode} selesai dilayani.'))),
                              const SizedBox(width: 10),
                              Expanded(
                                  child: PrimaryButton(
                                      label: 'Lewati',
                                      icon: Icons.skip_next_rounded,
                                      outlined: true,
                                      color: AppColors.red,
                                      onPressed: _busy ? null : () => _lewati(dilayani.first))),
                            ]),
                          ]),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    onPressed: _busy
                        ? null
                        : () => _aksi(() async {
                              final n = await svc.panggilBerikutnya(sel.poliId, today);
                              if (mounted) showSnack(context, 'Memanggil ${n.kode}, ${n.namaTampil}');
                            }),
                    icon: const Icon(Icons.campaign_rounded, size: 26),
                    label: const Text('Panggil Berikutnya'),
                    style: FilledButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: AppColors.ink,
                        minimumSize: const Size.fromHeight(56)),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    _mini(context, 'Selesai', '$selesai', AppColors.primary),
                    const SizedBox(width: 10),
                    _mini(context, 'Tidak hadir', '$tidakHadir', AppColors.red),
                    const SizedBox(width: 10),
                    _mini(context, 'Total', '${list.length}', AppColors.muted),
                  ]),
                  SectionTitle('Daftar Tunggu (${tunggu.length})'),
                  if (tunggu.isEmpty)
                    Text('Tidak ada pasien dalam daftar tunggu.', style: text.bodySmall),
                  for (final a in tunggu)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: AppCard(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        child: Row(children: [
                          Text(a.kode, style: text.titleSmall?.copyWith(color: AppColors.primary, fontSize: 17)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text(a.namaTampil, style: text.bodyMedium, maxLines: 1, overflow: TextOverflow.ellipsis),
                              if (a.isWalkin) Text('Walk-in', style: text.bodySmall),
                            ]),
                          ),
                          StatusChip(a.status),
                        ]),
                      ),
                    ),
                ]);
              },
            ),
          ),
        ]);
      },
    );
  }

  Widget _mini(BuildContext context, String label, String value, Color c) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
              color: AppColors.tint, borderRadius: BorderRadius.circular(14)),
          child: Column(children: [
            Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: c)),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      );
}
