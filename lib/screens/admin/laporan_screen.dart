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
import '../../widgets/status_chip.dart';

/// Laporan kunjungan harian dan bulanan + ekspor.
class LaporanScreen extends StatefulWidget {
  const LaporanScreen({super.key});
  @override
  State<LaporanScreen> createState() => _LaporanScreenState();
}

class _LaporanScreenState extends State<LaporanScreen> {
  bool _bulanan = false;
  DateTime _tgl = DateTime.now();

  Future<void> _pilihTanggal() async {
    final d = await showDatePicker(
        context: context,
        initialDate: _tgl,
        firstDate: DateTime(2024),
        lastDate: DateTime.now().add(const Duration(days: 30)));
    if (d != null) setState(() => _tgl = d);
  }

  void _geserBulan(int n) => setState(() => _tgl = DateTime(_tgl.year, _tgl.month + n, 1));

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    final mulai = _bulanan ? dateKey(DateTime(_tgl.year, _tgl.month, 1)) : dateKey(_tgl);
    final akhir = _bulanan ? dateKey(DateTime(_tgl.year, _tgl.month + 1, 0)) : dateKey(_tgl);
    final label = _bulanan ? fmtBulan(_tgl) : fmtTanggalSingkat(dateKey(_tgl));

    return StreamBuilder<List<AntreanModel>>(
      stream: context.read<AntreanService>().streamAntreanRentang(mulai, akhir),
      builder: (context, snap) {
        final r = ReportSummary(snap.data ?? []);
        final rows = [...r.data]..sort((a, b) {
            final c = b.tanggal.compareTo(a.tanggal);
            return c != 0 ? c : a.nomor.compareTo(b.nomor);
          });
        return ListView(padding: const EdgeInsets.fromLTRB(20, 16, 20, 24), children: [
          Text('Laporan Kunjungan', style: text.titleLarge),
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
          const SizedBox(height: 12),
          AppCard(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(children: [
              if (_bulanan)
                IconButton(
                    tooltip: 'Bulan sebelumnya',
                    onPressed: () => _geserBulan(-1),
                    icon: const Icon(Icons.chevron_left_rounded, size: 30)),
              Expanded(
                child: InkWell(
                  onTap: _bulanan ? null : _pilihTanggal,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
                    child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                      if (!_bulanan) const Icon(Icons.calendar_today_rounded, size: 18, color: AppColors.primary),
                      if (!_bulanan) const SizedBox(width: 8),
                      Text(label, style: text.titleSmall),
                    ]),
                  ),
                ),
              ),
              if (_bulanan)
                IconButton(
                    tooltip: 'Bulan berikutnya',
                    onPressed: () => _geserBulan(1),
                    icon: const Icon(Icons.chevron_right_rounded, size: 30)),
            ]),
          ),
          const SizedBox(height: 14),
          if (!snap.hasData)
            const Padding(padding: EdgeInsets.all(32), child: LoadingView())
          else ...[
            Row(children: [
              _kpi(context, 'Kunjungan', '${r.total}'),
              const SizedBox(width: 10),
              _kpi(context, 'Rata-rata tunggu', '${r.rataTungguMenit.round()} mnt'),
              const SizedBox(width: 10),
              _kpi(context, 'Dibatalkan', '${r.perStatus[AntreanStatus.batal] ?? 0}'),
            ]),
            const SectionTitle('Per Poli'),
            if (r.perPoli.isEmpty) Text('Tidak ada data pada periode ini.', style: text.bodySmall),
            for (final e in r.perPoli.entries)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(children: [
                  Expanded(child: Text('Poli ${e.key}', style: text.bodyMedium)),
                  Text('${e.value} kunjungan', style: text.titleSmall),
                ]),
              ),
            const SectionTitle('Per Status'),
            Wrap(spacing: 8, runSpacing: 8, children: [
              for (final e in r.perStatus.entries)
                Row(mainAxisSize: MainAxisSize.min, children: [
                  StatusChip(e.key),
                  const SizedBox(width: 4),
                  Text('${e.value}', style: text.titleSmall),
                  const SizedBox(width: 6),
                ]),
            ]),
            SectionTitle('Rincian (${rows.length})'),
            for (final a in rows.take(100))
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    Text(a.kode, style: text.titleSmall?.copyWith(color: AppColors.primary)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(a.namaTampil, maxLines: 1, overflow: TextOverflow.ellipsis),
                        Text('Poli ${a.namaPoli}, ${a.tanggal}', style: text.bodySmall),
                      ]),
                    ),
                    StatusChip(a.status),
                  ]),
                ),
              ),
            if (rows.length > 100)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text('Menampilkan 100 baris pertama. Ekspor untuk data lengkap.', style: text.bodySmall),
              ),
            const SizedBox(height: 18),
            PrimaryButton(
                label: 'Ekspor Laporan (CSV)',
                icon: Icons.file_download_outlined,
                onPressed: r.data.isEmpty ? null : () => showExportDialog(context, r, label)),
          ],
        ]);
      },
    );
  }

  Widget _kpi(BuildContext context, String k, String v) => Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(16)),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(v, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: AppColors.primary)),
            const SizedBox(height: 2),
            Text(k, style: Theme.of(context).textTheme.bodySmall),
          ]),
        ),
      );
}
