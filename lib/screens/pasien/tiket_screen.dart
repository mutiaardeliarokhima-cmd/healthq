import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../app/theme.dart';
import '../../models/antrean_model.dart';
import '../../models/jadwal_model.dart';
import '../../models/poli_model.dart';
import '../../providers/antrean_provider.dart';
import '../../providers/auth_provider.dart';
import '../../services/antrean_service.dart';
import '../../services/jadwal_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/common.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_chip.dart';

/// Tiket antrean: nomor besar, status real-time, check-in, jadwal ulang, batalkan.
class TiketScreen extends StatefulWidget {
  final String antreanId;
  const TiketScreen({super.key, required this.antreanId});
  @override
  State<TiketScreen> createState() => _TiketScreenState();
}

class _TiketScreenState extends State<TiketScreen> {
  DateTime _terakhir = DateTime.now();
  bool _busy = false;

  Future<void> _checkIn(AntreanModel a) async {
    setState(() => _busy = true);
    final err = await context.read<AntreanProvider>().jalankan(() => context.read<AntreanService>().checkIn(a));
    if (!mounted) return;
    setState(() => _busy = false);
    showSnack(context, err ?? 'Check-in berhasil. Status Anda: Hadir.', error: err != null);
  }

  Future<void> _batalkan(AntreanModel a) async {
    final ya = await konfirmasi(context,
        judul: 'Batalkan antrean?',
        isi: 'Nomor ${a.kode} akan dibatalkan dan tidak dapat dikembalikan.',
        ya: 'Batalkan',
        tidak: 'Kembali',
        bahaya: true);
    if (!ya || !mounted) return;
    final err = await context.read<AntreanProvider>().jalankan(() => context.read<AntreanService>().batalkan(a));
    if (!mounted) return;
    showSnack(context, err ?? 'Antrean dibatalkan.', error: err != null);
    if (err == null) Navigator.pop(context);
  }

  Future<void> _jadwalUlang(AntreanModel a) async {
    DateTime pilih = DateTime.now();
    final now = DateTime.now();
    final first = DateTime(now.year, now.month, now.day);
    final hasil = await showDialog<DateTime>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setD) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Jadwal Ulang'),
          content: SizedBox(
            width: 320,
            height: 340,
            child: CalendarDatePicker(
              initialDate: first,
              firstDate: first,
              lastDate: first.add(const Duration(days: 7)),
              onDateChanged: (d) => setD(() => pilih = d),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Kembali')),
            FilledButton(
                style: FilledButton.styleFrom(minimumSize: const Size(88, 48)),
                onPressed: () => Navigator.pop(ctx, pilih),
                child: const Text('Pindahkan')),
          ],
        ),
      ),
    );
    if (hasil == null || !mounted) return;
    final user = context.read<AuthProvider>().user!;
    final poli = PoliModel(
        poliId: a.poliId,
        namaPoli: a.namaPoli,
        kode: a.kodePoli,
        rataDurasiMenit: a.durasiMenit);
    String? newId;
    final err = await context.read<AntreanProvider>().jalankan(() async {
      newId = await context.read<AntreanService>().jadwalUlang(a, poli, dateKey(hasil), namaPasien: user.nama);
    });
    if (!mounted) return;
    if (err != null) {
      showSnack(context, err, error: true);
    } else {
      showSnack(context, 'Antrean dipindahkan ke ${fmtTanggalSingkat(dateKey(hasil))}.');
      Navigator.pushReplacementNamed(context, '/pasien/antrean/$newId');
    }
  }

  @override
  Widget build(BuildContext context) {
    final svc = context.read<AntreanService>();
    return Scaffold(
      appBar: AppBar(title: const Text('Tiket Antrean')),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: svc.streamAntreanSnap(widget.antreanId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const EmptyState(icon: Icons.error_outline_rounded, title: 'Tiket tidak dapat dimuat');
          }
          if (!snap.hasData) return const LoadingView();
          final doc = snap.data!;
          if (!doc.exists) {
            return const EmptyState(icon: Icons.confirmation_number_outlined, title: 'Tiket tidak ditemukan');
          }
          final cache = doc.metadata.isFromCache;
          if (!cache) _terakhir = DateTime.now();
          final a = AntreanModel.fromMap(doc.id, doc.data()!);
          return StreamBuilder<JadwalModel?>(
            stream: context.read<JadwalService>().streamJadwalById(a.jadwalId),
            builder: (context, jSnap) => _isi(context, a, jSnap.data?.sedangDilayani ?? 0, cache),
          );
        },
      ),
    );
  }

  Widget _isi(BuildContext context, AntreanModel a, int sedang, bool cache) {
    final text = Theme.of(context).textTheme;
    final hariIni = a.tanggal == todayKey();
    final dipanggil = a.status == AntreanStatus.dipanggil;
    final bisaCheckIn = a.status == AntreanStatus.menunggu;
    final bisaUbah = a.status == AntreanStatus.menunggu || a.status == AntreanStatus.hadir;

    Widget row(String k, Widget v) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(children: [Expanded(child: Text(k, style: text.bodyMedium)), v]),
        );
    Text bold(String s) => Text(s, style: text.titleSmall);

    return ListView(padding: const EdgeInsets.fromLTRB(20, 8, 20, 28), children: [
      Center(child: Text('Poli ${a.namaPoli}', style: text.titleMedium)),
      Center(child: Text(fmtTanggalSingkat(a.tanggal), style: text.bodySmall)),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.symmetric(vertical: 26),
        decoration: BoxDecoration(
          color: dipanggil ? AppColors.orange.withOpacity(.2) : AppColors.mint.withOpacity(.7),
          borderRadius: BorderRadius.circular(28),
        ),
        child: Column(children: [
          Text(a.kode,
              style: const TextStyle(
                  fontSize: 48, fontWeight: FontWeight.w900, color: AppColors.primary, height: 1.1)),
          const SizedBox(height: 10),
          if (dipanggil)
            const Text('Giliran Anda! Menuju loket.',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16))
          else
            StatusChip(a.status),
        ]),
      ),
      const SizedBox(height: 16),
      AppCard(
        child: Column(children: [
          row('Dilayani sekarang',
              bold(sedang == 0 ? '-' : '${a.kodePoli}-${sedang.toString().padLeft(2, '0')}')),
          const Divider(),
          row('Antrean di depan', bold(a.aktif ? '${a.didepan(sedang)}' : '-')),
          const Divider(),
          row('Estimasi', bold(a.aktif && !dipanggil ? '±${a.estimasiMenit(sedang)} mnt' : '-')),
          const Divider(),
          row('Status', StatusChip(a.status)),
        ]),
      ),
      const SizedBox(height: 8),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(cache ? Icons.cloud_off_rounded : Icons.sync_rounded,
            size: 16, color: cache ? AppColors.orange : AppColors.muted),
        const SizedBox(width: 6),
        Text(cache ? 'Offline. Data terakhir pukul ${fmtJamDetik(_terakhir)}' : 'Diperbarui ${fmtJamDetik(_terakhir)}',
            style: text.bodySmall),
      ]),
      if (a.aktif) ...[
        const SizedBox(height: 16),
        AppCard(
          child: Row(children: [
            QrImageView(
              data: a.antreanId,
              size: 110,
              padding: EdgeInsets.zero,
              eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: AppColors.ink),
              dataModuleStyle:
                  const QrDataModuleStyle(dataModuleShape: QrDataModuleShape.square, color: AppColors.ink),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Kode QR tiket', style: text.titleSmall),
                const SizedBox(height: 4),
                Text('Tunjukkan kepada petugas bila check-in lewat tombol bermasalah.', style: text.bodySmall),
              ]),
            ),
          ]),
        ),
      ],
      if (bisaCheckIn) ...[
        const SizedBox(height: 18),
        PrimaryButton(
          label: 'Check-in',
          icon: Icons.qr_code_scanner_rounded,
          loading: _busy,
          onPressed: hariIni ? () => _checkIn(a) : null,
        ),
        if (!hariIni)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Center(
                child: Text('Check-in dibuka pada tanggal kunjungan.', style: text.bodySmall)),
          ),
      ],
      if (bisaUbah) ...[
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: PrimaryButton(
                  label: 'Jadwal Ulang',
                  outlined: true,
                  color: AppColors.ink,
                  onPressed: () => _jadwalUlang(a))),
          const SizedBox(width: 12),
          Expanded(
              child: PrimaryButton(
                  label: 'Batalkan', outlined: true, color: AppColors.red, onPressed: () => _batalkan(a))),
        ]),
      ],
    ]);
  }
}
