import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/notifikasi_model.dart';
import '../../services/jadwal_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

/// Pengumuman dan tips kesehatan dari puskesmas (edukasi).
class PengumumanScreen extends StatelessWidget {
  const PengumumanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengumuman dan Edukasi')),
      body: StreamBuilder<List<PengumumanModel>>(
        stream: context.read<JadwalService>().streamPengumuman(),
        builder: (context, snap) {
          if (!snap.hasData) return const LoadingView();
          final list = snap.data!;
          if (list.isEmpty) {
            return const EmptyState(
                icon: Icons.campaign_outlined,
                title: 'Belum ada pengumuman',
                message: 'Informasi dari puskesmas akan tampil di sini.');
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (_, i) {
              final p = list[i];
              return AppCard(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    const Icon(Icons.campaign_rounded, color: AppColors.orange),
                    const SizedBox(width: 8),
                    Expanded(child: Text(p.judul, style: Theme.of(context).textTheme.titleSmall)),
                  ]),
                  const SizedBox(height: 8),
                  Text(p.isi),
                  if (p.createdAt != null) ...[
                    const SizedBox(height: 8),
                    Text(fmtTanggalJam(p.createdAt!), style: Theme.of(context).textTheme.bodySmall),
                  ],
                ]),
              );
            },
          );
        },
      ),
    );
  }
}
