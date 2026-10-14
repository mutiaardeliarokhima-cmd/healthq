import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/notifikasi_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/antrean_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';

/// Daftar pemberitahuan dalam aplikasi.
class NotifikasiScreen extends StatelessWidget {
  const NotifikasiScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = context.read<AuthProvider>().user!.uid;
    final svc = context.read<AntreanService>();
    return StreamBuilder<List<NotifikasiModel>>(
      stream: svc.streamNotifikasi(uid),
      builder: (context, snap) {
        final list = snap.data ?? [];
        return Scaffold(
          appBar: AppBar(
            title: const Text('Notifikasi'),
            actions: [
              if (list.any((n) => !n.dibaca))
                TextButton(onPressed: () => svc.tandaiSemuaDibaca(list), child: const Text('Tandai dibaca')),
            ],
          ),
          body: !snap.hasData
              ? const LoadingView()
              : list.isEmpty
                  ? const EmptyState(
                      icon: Icons.notifications_none_rounded,
                      title: 'Belum ada notifikasi',
                      message: 'Konfirmasi antrean dan pemberitahuan giliran akan muncul di sini.')
                  : ListView.separated(
                      padding: const EdgeInsets.all(16),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 10),
                      itemBuilder: (_, i) {
                        final n = list[i];
                        return AppCard(
                          color: n.dibaca ? Colors.white : AppColors.sky.withOpacity(.55),
                          onTap: () => svc.tandaiDibaca(n.notifId),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                  color: n.dibaca ? AppColors.tint : AppColors.mint, shape: BoxShape.circle),
                              child: const Icon(Icons.notifications_active_rounded, color: AppColors.primary, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(n.judul, style: Theme.of(context).textTheme.titleSmall),
                                const SizedBox(height: 2),
                                Text(n.isi),
                                if (n.createdAt != null) ...[
                                  const SizedBox(height: 6),
                                  Text(fmtTanggalJam(n.createdAt!), style: Theme.of(context).textTheme.bodySmall),
                                ],
                              ]),
                            ),
                          ]),
                        );
                      },
                    ),
        );
      },
    );
  }
}
