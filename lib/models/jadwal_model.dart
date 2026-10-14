import '../utils/formatters.dart';

class JadwalModel {
  final String jadwalId;
  final String poliId;
  final String dokterId;
  final String tanggal; // yyyy-MM-dd
  final int kuota;
  final int terpakai;
  final int sedangDilayani; // nomor yang sedang dilayani (0 = belum ada)

  const JadwalModel({
    required this.jadwalId,
    required this.poliId,
    required this.dokterId,
    required this.tanggal,
    required this.kuota,
    this.terpakai = 0,
    this.sedangDilayani = 0,
  });

  int get sisa => (kuota - terpakai).clamp(0, kuota);
  bool get penuh => terpakai >= kuota;

  static String idFor(String poliId, String tanggal) => '${poliId}_$tanggal';

  factory JadwalModel.fromMap(String id, Map<String, dynamic> m) => JadwalModel(
        jadwalId: id,
        poliId: m['poli_id'] ?? '',
        dokterId: m['dokter_id'] ?? '',
        tanggal: m['tanggal'] ?? '',
        kuota: toInt(m['kuota']),
        terpakai: toInt(m['terpakai']),
        sedangDilayani: toInt(m['sedang_dilayani']),
      );
}
