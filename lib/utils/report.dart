import '../models/antrean_model.dart';
import 'formatters.dart';

/// Ringkasan laporan kunjungan (dipakai Dashboard dan Laporan admin).
class ReportSummary {
  final List<AntreanModel> data;
  late final List<AntreanModel> kunjungan; // semua kecuali batal
  late final Map<String, int> perPoli;
  late final Map<String, int> perStatus;
  late final double rataTungguMenit;

  ReportSummary(this.data) {
    kunjungan = data.where((a) => a.status != AntreanStatus.batal).toList();
    perPoli = {};
    for (final a in kunjungan) {
      perPoli[a.namaPoli] = (perPoli[a.namaPoli] ?? 0) + 1;
    }
    perStatus = {};
    for (final a in data) {
      perStatus[a.status] = (perStatus[a.status] ?? 0) + 1;
    }
    final waits = data
        .where((a) => a.waktuHadir != null && a.waktuDipanggil != null)
        .map((a) => a.waktuDipanggil!.difference(a.waktuHadir!).inMinutes)
        .where((m) => m >= 0)
        .toList();
    rataTungguMenit =
        waits.isEmpty ? 0 : waits.reduce((a, b) => a + b) / waits.length;
  }

  int get total => kunjungan.length;

  String toCsv() {
    String esc(String s) => '"${s.replaceAll('"', '""')}"';
    final sb = StringBuffer(
        'tanggal,poli,nomor,nama,sumber,status,waktu_hadir,waktu_dipanggil\n');
    final rows = [...data]..sort((a, b) {
        final c = a.tanggal.compareTo(b.tanggal);
        if (c != 0) return c;
        final p = a.namaPoli.compareTo(b.namaPoli);
        return p != 0 ? p : a.nomor.compareTo(b.nomor);
      });
    for (final a in rows) {
      sb.writeln([
        a.tanggal,
        esc(a.namaPoli),
        a.kode,
        esc(a.namaTampil),
        a.sumber,
        a.status,
        a.waktuHadir == null ? '' : fmtTanggalJam(a.waktuHadir!),
        a.waktuDipanggil == null ? '' : fmtTanggalJam(a.waktuDipanggil!),
      ].join(','));
    }
    return sb.toString();
  }
}
