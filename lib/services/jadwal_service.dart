import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dokter_model.dart';
import '../models/jadwal_model.dart';
import '../models/notifikasi_model.dart';
import '../models/poli_model.dart';
import '../utils/formatters.dart';

/// Data master: poli, dokter, jadwal, pengumuman.
class JadwalService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // ---------- Stream ----------
  Stream<List<PoliModel>> streamPoli() => _db.collection('poli').snapshots().map((s) {
        final l = s.docs.map((d) => PoliModel.fromMap(d.id, d.data())).toList();
        l.sort((a, b) => a.namaPoli.compareTo(b.namaPoli));
        return l;
      });

  Stream<List<DokterModel>> streamDokter() => _db.collection('dokter').snapshots().map((s) {
        final l = s.docs.map((d) => DokterModel.fromMap(d.id, d.data())).toList();
        l.sort((a, b) => a.nama.compareTo(b.nama));
        return l;
      });

  Stream<List<JadwalModel>> streamJadwalMulai(String tanggalMulai) => _db
          .collection('jadwal')
          .where('tanggal', isGreaterThanOrEqualTo: tanggalMulai)
          .snapshots()
          .map((s) {
        final l = s.docs.map((d) => JadwalModel.fromMap(d.id, d.data())).toList();
        l.sort((a, b) => a.tanggal.compareTo(b.tanggal));
        return l;
      });

  Stream<List<JadwalModel>> streamJadwalTanggal(String tanggal) => _db
      .collection('jadwal')
      .where('tanggal', isEqualTo: tanggal)
      .snapshots()
      .map((s) => s.docs.map((d) => JadwalModel.fromMap(d.id, d.data())).toList());

  Stream<JadwalModel?> streamJadwal(String poliId, String tanggal) => _db
      .collection('jadwal')
      .doc(JadwalModel.idFor(poliId, tanggal))
      .snapshots()
      .map((d) => d.exists ? JadwalModel.fromMap(d.id, d.data()!) : null);

  Stream<JadwalModel?> streamJadwalById(String jadwalId) => _db
      .collection('jadwal')
      .doc(jadwalId)
      .snapshots()
      .map((d) => d.exists ? JadwalModel.fromMap(d.id, d.data()!) : null);

  Stream<List<PengumumanModel>> streamPengumuman() =>
      _db.collection('pengumuman').snapshots().map((s) {
        final l = s.docs.map((d) => PengumumanModel.fromMap(d.id, d.data())).toList();
        l.sort((a, b) => (b.createdAt ?? DateTime(2000)).compareTo(a.createdAt ?? DateTime(2000)));
        return l;
      });

  // ---------- CRUD (admin) ----------
  Future<void> simpanPoli(PoliModel p) {
    final ref = _db.collection('poli').doc(p.poliId.isEmpty ? null : p.poliId);
    return ref.set(p.toMap());
  }

  Future<void> hapusPoli(String id) => _db.collection('poli').doc(id).delete();

  Future<void> simpanDokter(DokterModel d) {
    final ref = _db.collection('dokter').doc(d.dokterId.isEmpty ? null : d.dokterId);
    return ref.set(d.toMap());
  }

  Future<void> hapusDokter(String id) => _db.collection('dokter').doc(id).delete();

  /// Satu jadwal per poli per tanggal (id = poliId_tanggal).
  Future<void> simpanJadwal({
    required String poliId,
    required String dokterId,
    required String tanggal,
    required int kuota,
  }) async {
    final ref = _db.collection('jadwal').doc(JadwalModel.idFor(poliId, tanggal));
    final snap = await ref.get();
    if (snap.exists) {
      await ref.update({'dokter_id': dokterId, 'kuota': kuota});
    } else {
      await ref.set({
        'poli_id': poliId,
        'dokter_id': dokterId,
        'tanggal': tanggal,
        'kuota': kuota,
        'terpakai': 0,
        'sedang_dilayani': 0,
      });
    }
  }

  Future<void> hapusJadwal(String id) => _db.collection('jadwal').doc(id).delete();

  Future<void> simpanPengumuman({String? id, required String judul, required String isi}) {
    final ref = _db.collection('pengumuman').doc(id);
    return ref.set({
      'judul': judul,
      'isi': isi,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> hapusPengumuman(String id) => _db.collection('pengumuman').doc(id).delete();

  /// Mengisi data contoh: 4 poli, 4 dokter, jadwal 8 hari ke depan, pengumuman.
  Future<void> isiDataContoh() async {
    final batch = _db.batch();
    final poli = [
      ['umum', 'Umum', 'A', 10, 30],
      ['gigi', 'Gigi', 'G', 20, 20],
      ['kia', 'KIA', 'K', 15, 18],
      ['lansia', 'Lansia', 'L', 12, 10],
    ];
    final dokter = [
      ['dr_andi', 'dr. Andi Pratama', 'Dokter Umum'],
      ['drg_sari', 'drg. Sari Wulandari', 'Dokter Gigi'],
      ['dr_maya', 'dr. Maya Lestari, Sp.OG', 'Kebidanan dan Kandungan'],
      ['dr_budi', 'dr. Budi Santoso', 'Geriatri'],
    ];
    for (final p in poli) {
      batch.set(_db.collection('poli').doc(p[0] as String), {
        'nama_poli': p[1],
        'kode': p[2],
        'jam_buka': '08:00',
        'jam_tutup': '14:00',
        'rata_durasi_menit': p[3],
        'aktif': true,
      });
    }
    for (final d in dokter) {
      batch.set(_db.collection('dokter').doc(d[0]),
          {'nama': d[1], 'spesialis': d[2]});
    }
    final now = DateTime.now();
    for (var i = 0; i <= 8; i++) {
      final key = dateKey(now.add(Duration(days: i)));
      for (var j = 0; j < poli.length; j++) {
        batch.set(_db.collection('jadwal').doc(JadwalModel.idFor(poli[j][0] as String, key)), {
          'poli_id': poli[j][0],
          'dokter_id': dokter[j][0],
          'tanggal': key,
          'kuota': poli[j][4],
          'terpakai': 0,
          'sedang_dilayani': 0,
        });
      }
    }
    batch.set(_db.collection('pengumuman').doc(), {
      'judul': 'Posyandu lansia Kamis, 08.00',
      'isi': 'Posyandu lansia dilaksanakan setiap Kamis pukul 08.00 di aula puskesmas. Bawa kartu BPJS dan buku kontrol.',
      'created_at': FieldValue.serverTimestamp(),
    });
    batch.set(_db.collection('pengumuman').doc(), {
      'judul': 'Tips: cukup datang mendekati giliran',
      'isi': 'Pantau nomor antrean dari aplikasi. Anda akan diberi tahu saat giliran hampir tiba, jadi tidak perlu menunggu lama di ruang tunggu.',
      'created_at': FieldValue.serverTimestamp(),
    });
    await batch.commit();
  }
}
