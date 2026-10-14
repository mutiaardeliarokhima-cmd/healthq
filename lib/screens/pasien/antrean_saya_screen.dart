import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/antrean_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/antrean_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/antrean_card.dart';
import '../../widgets/common.dart';
import '../../widgets/primary_button.dart';

/// Tab "Antrean Saya": nomor yang sedang dilayani, antrean di depan, estimasi.
class AntreanSayaScreen extends StatelessWidget {
  const AntreanSayaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user!.uid;
    final today = todayKey();
    return StreamBuilder<List<AntreanModel>>(
      stream: context.read<AntreanService>().streamAntreanSaya(uid),
      builder: (context, snap) {
        if (!snap.hasData) return const LoadingView();
        final aktif = snap.data!
            .where((a) => a.aktif && a.tanggal.compareTo(today) >= 0)
            .toList()
          ..sort((a, b) => a.tanggal.compareTo(b.tanggal));
        return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Text('Antrean Saya', style: Theme.of(context).textTheme.titleLarge),
          ),
          Expanded(
            child: aktif.isEmpty
                ? EmptyState(
                    icon: Icons.confirmation_number_outlined,
                    title: 'Belum ada antrean aktif',
                    message: 'Ambil nomor antrean dari rumah dan pantau gilirannya di sini.',
                    action: PrimaryButton(
                        label: 'Ambil Antrean',
                        icon: Icons.add_rounded,
                        onPressed: () => Navigator.pushNamed(context, '/pasien/ambil')),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                    itemCount: aktif.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 14),
                    itemBuilder: (_, i) {
                      final a = aktif[i];
                      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4, bottom: 6),
                          child: Text(fmtTanggalSingkat(a.tanggal), style: Theme.of(context).textTheme.bodySmall),
                        ),
                        AntreanCard(
                          antrean: a,
                          onDetail: () => Navigator.pushNamed(context, '/pasien/antrean/${a.antreanId}'),
                        ),
                      ]);
                    },
                  ),
          ),
        ]);
      },
    );
  }
}
