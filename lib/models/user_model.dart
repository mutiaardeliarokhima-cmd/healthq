import '../utils/formatters.dart';

class UserModel {
  final String uid;
  final String nama;
  final String nik;
  final String noBpjs;
  final String noHp;
  final String email;
  final String role; // pasien, petugas, admin
  final DateTime? createdAt;

  const UserModel({
    required this.uid,
    required this.nama,
    this.nik = '',
    this.noBpjs = '',
    this.noHp = '',
    this.email = '',
    this.role = 'pasien',
    this.createdAt,
  });

  bool get isPasien => role == 'pasien';
  bool get isPetugas => role == 'petugas';
  bool get isAdmin => role == 'admin';
  String get namaDepan => nama.trim().split(' ').first;
  bool get profilLengkap => nama.isNotEmpty && nik.length == 16 && noHp.isNotEmpty;

  factory UserModel.fromMap(String uid, Map<String, dynamic> m) => UserModel(
        uid: uid,
        nama: m['nama'] ?? '',
        nik: m['nik'] ?? '',
        noBpjs: m['no_bpjs'] ?? '',
        noHp: m['no_hp'] ?? '',
        email: m['email'] ?? '',
        role: m['role'] ?? 'pasien',
        createdAt: toDate(m['created_at']),
      );
}
