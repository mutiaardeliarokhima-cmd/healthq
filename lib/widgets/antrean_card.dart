import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app/theme.dart';
import '../models/antrean_model.dart';
import '../models/jadwal_model.dart';
import '../services/jadwal_service.dart';
import 'status_chip.dart';

/// Kartu antrean aktif (Beranda dan Antrean Saya).
/// Nomor besar 48 sp; estimasi dihitung dari nomor yang sedang dilayani.
class AntreanCard extends StatelessWidget {
  final AntreanModel antrean;
  final VoidCallback? onDetail;
  const AntreanCard({super.key, required this.antrean, this.onDetail});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<JadwalModel?>(
      stream: context.read<JadwalService>().streamJadwalById(antrean.jadwalId),
      builder: (context, snap) {
        final sedang = snap.data?.sedangDilayani ?? 0;
        final dipanggil = antrean.status == AntreanStatus.dipanggil;
        final estimasi = antrean.estimasiMenit(sedang);
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF23635A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(
                child: Text('Antrean ${antrean.namaPoli}',
                    style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700)),
              ),
              Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                  child: StatusChip(antrean.status)),
            ]),
            const SizedBox(height: 10),
            Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
              Text(antrean.kode,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 48, fontWeight: FontWeight.w900, height: 1)),
              const Spacer(),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text(
                    sedang == 0
                        ? 'Belum ada yang dilayani'
                        : 'Sedang dilayani: ${antrean.kodePoli}-${sedang.toString().padLeft(2, '0')}',
                    style: const TextStyle(color: Colors.white70, fontSize: 14)),
                const SizedBox(height: 2),
                Text(dipanggil ? 'Giliran Anda!' : 'Estimasi: ±$estimasi menit',
                    style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
              ]),
            ]),
            if (onDetail != null) ...[
              const SizedBox(height: 16),
              FilledButton(
                onPressed: onDetail,
                style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size(0, 48)),
                child: const Text('Lihat Detail'),
              ),
            ],
          ]),
        );
      },
    );
  }
}
