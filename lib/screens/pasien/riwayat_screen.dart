import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/antrean_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/antrean_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/status_chip.dart';

/// Riwayat kunjungan: daftar antrean lampau.
class RiwayatScreen extends StatelessWidget {
  const RiwayatScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user!.uid;
    final today = todayKey();
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Text('Riwayat Kunjungan', style: Theme.of(context).textTheme.titleLarge),
      ),
      Expanded(
        child: StreamBuilder<List<AntreanModel>>(
          stream: context.read<AntreanService>().streamAntreanSaya(uid),
          builder: (context, snap) {
            if (!snap.hasData) return const LoadingView();
            final list = snap.data!.where((a) => !a.aktif || a.tanggal.compareTo(today) < 0).toList()
              ..sort((a, b) => b.tanggal.compareTo(a.tanggal));
            if (list.isEmpty) {
              return const EmptyState(
                  icon: Icons.history_rounded,
                  title: 'Belum ada riwayat',
                  message: 'Kunjungan yang sudah selesai akan tercatat di sini.');
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final a = list[i];
                return AppCard(
                  child: Row(children: [
                    Container(
                      width: 62,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(12)),
                      child: Text(a.kode,
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Poli ${a.namaPoli}', style: Theme.of(context).textTheme.titleSmall),
                        Text(fmtTanggalSingkat(a.tanggal), style: Theme.of(context).textTheme.bodySmall),
                      ]),
                    ),
                    StatusChip(a.status),
                  ]),
                );
              },
            );
          },
        ),
      ),
    ]);
  }
}
