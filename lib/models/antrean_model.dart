import '../utils/formatters.dart';

class AntreanStatus {
  static const menunggu = 'menunggu';
  static const hadir = 'hadir';
  static const dipanggil = 'dipanggil';
  static const selesai = 'selesai';
  static const batal = 'batal';
  static const tidakHadir = 'tidak_hadir';

  static const aktif = [menunggu, hadir, dipanggil];
}

class AntreanModel {
  final String antreanId;
  final String uid; // kosong untuk walk-in
  final String poliId;
  final String jadwalId;
  final String namaPoli;
  final String kodePoli;
  final String tanggal;
  final int nomor;
  final String status;
  final String sumber; // online / walkin
  final String namaWalkin;
  final String namaPasien;
  final int durasiMenit;
  final DateTime? createdAt;
  final DateTime? waktuHadir;
  final DateTime? waktuDipanggil;

  const AntreanModel({
    required this.antreanId,
    this.uid = '',
    required this.poliId,
    required this.jadwalId,
    this.namaPoli = '',
    this.kodePoli = 'A',
    required this.tanggal,
    required this.nomor,
    required this.status,
    this.sumber = 'online',
    this.namaWalkin = '',
    this.namaPasien = '',
    this.durasiMenit = 10,
    this.createdAt,
    this.waktuHadir,
    this.waktuDipanggil,
  });

  String get kode => '$kodePoli-${nomor.toString().padLeft(2, '0')}';
  bool get aktif => AntreanStatus.aktif.contains(status);
  bool get isWalkin => sumber == 'walkin';
  String get namaTampil {
    final n = isWalkin ? namaWalkin : namaPasien;
    return n.isNotEmpty ? n : (isWalkin ? 'Walk-in' : 'Pasien');
  }

  factory AntreanModel.fromMap(String id, Map<String, dynamic> m) => AntreanModel(
        antreanId: id,
        uid: m['uid'] ?? '',
        poliId: m['poli_id'] ?? '',
        jadwalId: m['jadwal_id'] ?? '',
        namaPoli: m['nama_poli'] ?? '',
        kodePoli: m['kode_poli'] ?? 'A',
        tanggal: m['tanggal'] ?? '',
        nomor: toInt(m['nomor']),
        status: m['status'] ?? AntreanStatus.menunggu,
        sumber: m['sumber'] ?? 'online',
        namaWalkin: m['nama_walkin'] ?? '',
        namaPasien: m['nama_pasien'] ?? '',
        durasiMenit: toInt(m['durasi_menit']) == 0 ? 10 : toInt(m['durasi_menit']),
        createdAt: toDate(m['created_at']),
        waktuHadir: toDate(m['waktu_hadir']),
        waktuDipanggil: toDate(m['waktu_dipanggil']),
      );

  /// Jumlah antrean di depan (perkiraan) berdasarkan nomor yang sedang dilayani.
  int didepan(int sedangDilayani) {
    final d = nomor - sedangDilayani - 1;
    return d < 0 ? 0 : d;
  }

  /// Estimasi = (nomor pasien - nomor yang sedang dilayani) x rata_durasi_menit.
  int estimasiMenit(int sedangDilayani) {
    final n = nomor - sedangDilayani;
    return n <= 0 ? 0 : n * durasiMenit;
  }
}
