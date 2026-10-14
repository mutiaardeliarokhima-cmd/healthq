import '../utils/formatters.dart';

class NotifikasiModel {
  final String notifId;
  final String uid;
  final String judul;
  final String isi;
  final bool dibaca;
  final DateTime? createdAt;

  const NotifikasiModel({
    required this.notifId,
    required this.uid,
    required this.judul,
    required this.isi,
    this.dibaca = false,
    this.createdAt,
  });

  factory NotifikasiModel.fromMap(String id, Map<String, dynamic> m) => NotifikasiModel(
        notifId: id,
        uid: m['uid'] ?? '',
        judul: m['judul'] ?? '',
        isi: m['isi'] ?? '',
        dibaca: m['dibaca'] ?? false,
        createdAt: toDate(m['created_at']),
      );
}

class PengumumanModel {
  final String id;
  final String judul;
  final String isi;
  final DateTime? createdAt;

  const PengumumanModel({required this.id, required this.judul, required this.isi, this.createdAt});

  factory PengumumanModel.fromMap(String id, Map<String, dynamic> m) => PengumumanModel(
        id: id,
        judul: m['judul'] ?? '',
        isi: m['isi'] ?? '',
        createdAt: toDate(m['created_at']),
      );
}
