import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/antrean_model.dart';
import '../../providers/antrean_provider.dart';
import '../../services/antrean_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

/// Verifikasi check-in pasien yang tiba (manual oleh petugas).
class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});
  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  String _q = '';

  Future<void> _verifikasi(AntreanModel a) async {
    final err = await context
        .read<AntreanProvider>()
        .jalankan(() => context.read<AntreanService>().verifikasiCheckIn(a));
    if (!mounted) return;
    showSnack(context, err ?? '${a.kode} ${a.namaTampil} tercatat hadir.', error: err != null);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
        child: Text('Verifikasi Check-in', style: text.titleLarge),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
        child: Text('Untuk pasien yang tidak dapat check-in sendiri.', style: text.bodySmall),
      ),
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: TextField(
          decoration: const InputDecoration(hintText: 'Cari nomor atau nama', prefixIcon: Icon(Icons.search_rounded)),
          onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
        ),
      ),
      const SizedBox(height: 8),
      Expanded(
        child: StreamBuilder<List<AntreanModel>>(
          stream: context.read<AntreanService>().streamAntreanTanggal(todayKey()),
          builder: (context, snap) {
            if (!snap.hasData) return const LoadingView();
            final list = snap.data!
                .where((a) => a.status == AntreanStatus.menunggu && !a.isWalkin)
                .where((a) => _q.isEmpty || a.kode.toLowerCase().contains(_q) || a.namaTampil.toLowerCase().contains(_q))
                .toList();
            if (list.isEmpty) {
              return const EmptyState(
                  icon: Icons.how_to_reg_outlined,
                  title: 'Tidak ada yang perlu diverifikasi',
                  message: 'Pasien online yang belum check-in hari ini akan muncul di sini.');
            }
            return ListView.separated(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              itemCount: list.length,
              separatorBuilder: (_, __) => const SizedBox(height: 10),
              itemBuilder: (_, i) {
                final a = list[i];
                return AppCard(
                  child: Row(children: [
                    Container(
                      width: 64,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(12)),
                      child: Text(a.kode,
                          style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 18)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.namaTampil, style: text.titleSmall, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Poli ${a.namaPoli}', style: text.bodySmall),
                      ]),
                    ),
                    FilledButton(
                      onPressed: () => _verifikasi(a),
                      style: FilledButton.styleFrom(minimumSize: const Size(96, 48)),
                      child: const Text('Hadir'),
                    ),
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
