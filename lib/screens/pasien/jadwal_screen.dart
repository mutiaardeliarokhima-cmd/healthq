import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/dokter_model.dart';
import '../../models/jadwal_model.dart';
import '../../models/poli_model.dart';
import '../../services/jadwal_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

/// Jadwal dokter, poli, dan sisa kuota harian.
class JadwalScreen extends StatelessWidget {
  const JadwalScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final svc = context.read<JadwalService>();
    final text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text('Jadwal Dokter', style: text.titleLarge),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
        child: Text('Lihat poli yang buka dan sisa kuota sebelum berangkat.', style: text.bodySmall),
      ),
      Expanded(
        child: StreamBuilder<List<PoliModel>>(
          stream: svc.streamPoli(),
          builder: (context, pSnap) => StreamBuilder<List<DokterModel>>(
            stream: svc.streamDokter(),
            builder: (context, dSnap) => StreamBuilder<List<JadwalModel>>(
              stream: svc.streamJadwalMulai(todayKey()),
              builder: (context, jSnap) {
                if (!pSnap.hasData) return const LoadingView();
                final poli = pSnap.data!;
                if (poli.isEmpty) {
                  return const EmptyState(icon: Icons.calendar_month_outlined, title: 'Belum ada jadwal');
                }
                final dokter = {for (final d in dSnap.data ?? <DokterModel>[]) d.dokterId: d};
                final jadwal = jSnap.data ?? <JadwalModel>[];
                return ListView(padding: const EdgeInsets.fromLTRB(20, 4, 20, 24), children: [
                  for (final p in poli)
                    _PoliJadwal(
                      poli: p,
                      dokter: dokter,
                      jadwal: jadwal.where((j) => j.poliId == p.poliId).take(8).toList(),
                    ),
                ]);
              },
            ),
          ),
        ),
      ),
    ]);
  }
}

class _PoliJadwal extends StatelessWidget {
  final PoliModel poli;
  final Map<String, DokterModel> dokter;
  final List<JadwalModel> jadwal;
  const _PoliJadwal({required this.poli, required this.dokter, required this.jadwal});

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.line, width: 1.2),
        ),
        clipBehavior: Clip.antiAlias,
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            initiallyExpanded: poli.aktif,
            tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            leading: Container(
              width: 44,
              height: 44,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: AppColors.mint.withOpacity(.6), borderRadius: BorderRadius.circular(12)),
              child: Text(poli.kodePoli,
                  style: const TextStyle(color: AppColors.primary, fontSize: 20, fontWeight: FontWeight.w900)),
            ),
            title: Text('Poli ${poli.namaPoli}', style: text.titleSmall),
            subtitle: Text(
                poli.aktif ? 'Buka ${poli.jamBuka} - ${poli.jamTutup}' : 'Sedang tutup',
                style: TextStyle(
                    fontSize: 14, color: poli.aktif ? AppColors.muted : AppColors.red, fontWeight: FontWeight.w600)),
            childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            children: [
              if (jadwal.isEmpty)
                Padding(padding: const EdgeInsets.all(8), child: Text('Belum ada jadwal.', style: text.bodySmall)),
              for (final j in jadwal)
                Container(
                  margin: const EdgeInsets.only(top: 8),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(fmtTanggalSingkat(j.tanggal), style: text.titleSmall),
                        const SizedBox(height: 2),
                        Text(
                            dokter[j.dokterId] == null
                                ? '-'
                                : '${dokter[j.dokterId]!.nama} (${dokter[j.dokterId]!.spesialis})',
                            style: text.bodySmall),
                      ]),
                    ),
                    Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                      Text(j.penuh ? 'Penuh' : 'Sisa ${j.sisa}',
                          style: TextStyle(
                              fontWeight: FontWeight.w800,
                              color: j.penuh ? AppColors.red : AppColors.primary)),
                      Text('dari ${j.kuota}', style: text.bodySmall),
                    ]),
                  ]),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
