import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../models/antrean_model.dart';
import '../../services/antrean_service.dart';
import '../../utils/formatters.dart';
import '../../utils/report.dart';
import '../../widgets/common.dart';
import '../../widgets/export_dialog.dart';
import '../../widgets/primary_button.dart';

/// Dashboard admin: ringkasan kunjungan, rata-rata tunggu, grafik batang per poli.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  bool _bulanan = false;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final mulai = _bulanan ? dateKey(DateTime(now.year, now.month, 1)) : todayKey();
    final akhir = _bulanan ? dateKey(DateTime(now.year, now.month + 1, 0)) : todayKey();
    final label = _bulanan ? fmtBulan(now) : fmtTanggalSingkat(todayKey());
    final text = Theme.of(context).textTheme;

    return StreamBuilder<List<AntreanModel>>(
      stream: context.read<AntreanService>().streamAntreanRentang(mulai, akhir),
      builder: (context, snap) {
        final r = ReportSummary(snap.data ?? []);
        final maxVal = r.perPoli.values.isEmpty ? 1 : r.perPoli.values.reduce((a, b) => a > b ? a : b);
        return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
          Text('Dashboard', style: text.titleLarge),
          const SizedBox(height: 4),
          Text(label, style: text.bodySmall),
          const SizedBox(height: 14),
          SegmentedButton<bool>(
            segments: const [
              ButtonSegment(value: false, label: Text('Harian')),
              ButtonSegment(value: true, label: Text('Bulanan')),
            ],
            selected: {_bulanan},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _bulanan = s.first),
          ),
          const SizedBox(height: 16),
          if (!snap.hasData)
            const Padding(padding: EdgeInsets.all(32), child: LoadingView())
          else ...[
            Row(children: [
              Expanded(child: _stat(context, 'Kunjungan', '${r.total}', Icons.groups_rounded)),
              const SizedBox(width: 12),
              Expanded(
                  child: _stat(context, 'Rata-rata tunggu',
                      '${r.rataTungguMenit.round()} mnt', Icons.timer_outlined)),
            ]),
            const SectionTitle('Kunjungan per Poli'),
            if (r.perPoli.isEmpty)
              Text('Belum ada data kunjungan pada periode ini.', style: text.bodySmall),
            for (final e in r.perPoli.entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(children: [
                  SizedBox(width: 70, child: Text(e.key, style: text.bodyMedium)),
                  Expanded(
                    child: LayoutBuilder(
                      builder: (context, c) => Stack(children: [
                        Container(height: 26, decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(8))),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeOutCubic,
                          height: 26,
                          width: c.maxWidth * (e.value / maxVal),
                          decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                        ),
                      ]),
                    ),
                  ),
                  SizedBox(
                      width: 40,
                      child: Text('${e.value}', textAlign: TextAlign.end, style: text.titleSmall)),
                ]),
              ),
            const SizedBox(height: 18),
            PrimaryButton(
                label: 'Ekspor Laporan',
                icon: Icons.file_download_outlined,
                onPressed: () => showExportDialog(context, r, label)),
          ],
        ]);
      },
    );
  }

  Widget _stat(BuildContext context, String k, String v, IconData icon) => AppCard(
        color: AppColors.sky.withOpacity(.6),
        outlined: false,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(child: Text(k, style: Theme.of(context).textTheme.bodySmall)),
          ]),
          const SizedBox(height: 8),
          Text(v, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primary)),
        ]),
      );
}
