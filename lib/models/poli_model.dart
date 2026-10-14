import '../utils/formatters.dart';

class PoliModel {
  final String poliId;
  final String namaPoli;
  final String kode;
  final String jamBuka;
  final String jamTutup;
  final int rataDurasiMenit;
  final bool aktif;

  const PoliModel({
    required this.poliId,
    required this.namaPoli,
    this.kode = '',
    this.jamBuka = '08:00',
    this.jamTutup = '14:00',
    this.rataDurasiMenit = 10,
    this.aktif = true,
  });

  String get kodePoli => kode.isNotEmpty
      ? kode.toUpperCase()
      : (namaPoli.isNotEmpty ? namaPoli[0].toUpperCase() : 'X');

  factory PoliModel.fromMap(String id, Map<String, dynamic> m) => PoliModel(
        poliId: id,
        namaPoli: m['nama_poli'] ?? '',
        kode: m['kode'] ?? '',
        jamBuka: m['jam_buka'] ?? '08:00',
        jamTutup: m['jam_tutup'] ?? '14:00',
        rataDurasiMenit: toInt(m['rata_durasi_menit']) == 0 ? 10 : toInt(m['rata_durasi_menit']),
        aktif: m['aktif'] ?? true,
      );

  Map<String, dynamic> toMap() => {
        'nama_poli': namaPoli,
        'kode': kodePoli,
        'jam_buka': jamBuka,
        'jam_tutup': jamTutup,
        'rata_durasi_menit': rataDurasiMenit,
        'aktif': aktif,
      };
}
