import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/antrean_model.dart';
import '../../models/jadwal_model.dart';
import '../../models/notifikasi_model.dart';
import '../../models/poli_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/antrean_service.dart';
import '../../services/jadwal_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/antrean_card.dart';
import '../../widgets/common.dart';

/// Beranda pasien: kartu antrean aktif, tombol Ambil Antrean,
/// layanan hari ini beserta sisa kuota, dan pengumuman.
class BerandaScreen extends StatelessWidget {
  const BerandaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().user!;
    final antreanSvc = context.read<AntreanService>();
    final jadwalSvc = context.read<JadwalService>();
    final today = todayKey();
    final text = Theme.of(context).textTheme;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Halo, ${user.namaDepan}', style: text.titleLarge?.copyWith(fontSize: 24)),
              const SizedBox(height: 2),
              Text(fmtTanggalPanjang(DateTime.now()), style: text.bodySmall),
            ]),
          ),
          StreamBuilder<List<NotifikasiModel>>(
            stream: antreanSvc.streamNotifikasi(user.uid),
            builder: (context, snap) {
              final unread = (snap.data ?? []).where((n) => !n.dibaca).length;
              return Stack(clipBehavior: Clip.none, children: [
                IconButton.filledTonal(
                  tooltip: 'Notifikasi',
                  style: IconButton.styleFrom(
                      backgroundColor: AppColors.sky, minimumSize: const Size(52, 52)),
                  icon: const Icon(Icons.notifications_rounded, color: AppColors.primary),
                  onPressed: () => Navigator.pushNamed(context, '/notifikasi'),
                ),
                if (unread > 0)
                  Positioned(
                    right: 2,
                    top: 2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(color: AppColors.red, borderRadius: BorderRadius.circular(12)),
                      child: Text('$unread',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w800)),
                    ),
                  ),
              ]);
            },
          ),
        ]),
        const SizedBox(height: 20),

        // Antrean aktif
        StreamBuilder<List<AntreanModel>>(
          stream: antreanSvc.streamAntreanSaya(user.uid),
          builder: (context, snap) {
            final aktif = (snap.data ?? [])
                .where((a) => a.aktif && a.tanggal.compareTo(today) >= 0)
                .toList()
              ..sort((a, b) => a.tanggal.compareTo(b.tanggal));
            if (aktif.isEmpty) {
              return AppCard(
                color: AppColors.tint,
                child: Row(children: [
                  const Icon(Icons.event_available_rounded, size: 34, color: AppColors.primary),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Belum ada antrean aktif', style: text.titleSmall),
                      Text('Ambil nomor dari rumah, datang mendekati giliran.', style: text.bodySmall),
                    ]),
                  ),
                ]),
              );
            }
            final a = aktif.first;
            return AntreanCard(
              antrean: a,
              onDetail: () => Navigator.pushNamed(context, '/pasien/antrean/${a.antreanId}'),
            );
          },
        ),
        const SizedBox(height: 14),
        FilledButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/pasien/ambil'),
          icon: const Icon(Icons.add_rounded, size: 26),
          label: const Text('Ambil Antrean'),
          style: FilledButton.styleFrom(
              backgroundColor: AppColors.orange,
              foregroundColor: AppColors.ink,
              minimumSize: const Size.fromHeight(56)),
        ),

        // Layanan hari ini
        const SectionTitle('Layanan Hari Ini'),
        StreamBuilder<List<PoliModel>>(
          stream: jadwalSvc.streamPoli(),
          builder: (context, poliSnap) {
            return StreamBuilder<List<JadwalModel>>(
              stream: jadwalSvc.streamJadwalTanggal(today),
              builder: (context, jSnap) {
                if (!poliSnap.hasData) return const Padding(padding: EdgeInsets.all(24), child: LoadingView());
                final poli = poliSnap.data!;
                if (poli.isEmpty) {
                  return Text('Data layanan belum tersedia.', style: text.bodySmall);
                }
                final jadwal = {for (final j in jSnap.data ?? <JadwalModel>[]) j.poliId: j};
                return Column(children: [
                  for (final p in poli)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LayananRow(poli: p, jadwal: jadwal[p.poliId]),
                    ),
                ]);
              },
            );
          },
        ),

        // Pengumuman
        SectionTitle('Pengumuman',
            trailing: TextButton(
                onPressed: () => Navigator.pushNamed(context, '/pengumuman'),
                child: const Text('Lihat semua'))),
        StreamBuilder<List<PengumumanModel>>(
          stream: jadwalSvc.streamPengumuman(),
          builder: (context, snap) {
            final list = (snap.data ?? []).take(2).toList();
            if (list.isEmpty) return Text('Belum ada pengumuman.', style: text.bodySmall);
            return Column(children: [
              for (final p in list)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    color: AppColors.sky.withOpacity(.6),
                    outlined: false,
                    onTap: () => Navigator.pushNamed(context, '/pengumuman'),
                    child: Row(children: [
                      const Icon(Icons.campaign_rounded, color: AppColors.primary),
                      const SizedBox(width: 12),
                      Expanded(child: Text(p.judul, style: text.titleSmall)),
                    ]),
                  ),
                ),
            ]);
          },
        ),
      ],
    );
  }
}

class _LayananRow extends StatelessWidget {
  final PoliModel poli;
  final JadwalModel? jadwal;
  const _LayananRow({required this.poli, this.jadwal});

  @override
  Widget build(BuildContext context) {
    final buka = poli.aktif && jadwal != null;
    final warna = buka ? AppColors.primary : AppColors.red;
    return AppCard(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: AppColors.mint.withOpacity(.6), borderRadius: BorderRadius.circular(12)),
          child: Text(poli.kodePoli,
              style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w900)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Poli ${poli.namaPoli}', style: Theme.of(context).textTheme.titleSmall),
            Text('${poli.jamBuka} - ${poli.jamTutup}', style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(buka ? Icons.check_circle_rounded : Icons.cancel_rounded, size: 16, color: warna),
            const SizedBox(width: 4),
            Text(buka ? 'Buka' : 'Tutup', style: TextStyle(color: warna, fontWeight: FontWeight.w800)),
          ]),
          Text(buka ? '${jadwal!.terpakai}/${jadwal!.kuota}' : '-',
              style: Theme.of(context).textTheme.bodySmall),
        ]),
      ]),
    );
  }
}
