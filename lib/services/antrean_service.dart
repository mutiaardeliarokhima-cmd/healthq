import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/antrean_model.dart';
import '../models/jadwal_model.dart';
import '../models/notifikasi_model.dart';
import '../models/poli_model.dart';
import '../utils/formatters.dart';

class AntreanException implements Exception {
  final String message;
  AntreanException(this.message);
  @override
  String toString() => message;
}

class KuotaHabisException extends AntreanException {
  KuotaHabisException()
      : super('Kuota habis. Silakan pilih tanggal lain.');
}

class AntreanService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  CollectionReference<Map<String, dynamic>> get _col => _db.collection('antrean');

  AntreanModel _m(DocumentSnapshot<Map<String, dynamic>> d) =>
      AntreanModel.fromMap(d.id, d.data()!);

  // ---------- Stream ----------
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamAntreanSnap(String id) =>
      _col.doc(id).snapshots();

  Stream<List<AntreanModel>> streamAntreanSaya(String uid) =>
      _col.where('uid', isEqualTo: uid).snapshots().map((s) {
        final l = s.docs.map(_m).toList();
        l.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        return l;
      });

  Stream<List<AntreanModel>> streamAntreanPoli(String poliId, String tanggal) => _col
          .where('poli_id', isEqualTo: poliId)
          .where('tanggal', isEqualTo: tanggal)
          .snapshots()
          .map((s) {
        final l = s.docs.map(_m).toList();
        l.sort((a, b) => a.nomor.compareTo(b.nomor));
        return l;
      });

  Stream<List<AntreanModel>> streamAntreanTanggal(String tanggal) =>
      _col.where('tanggal', isEqualTo: tanggal).snapshots().map((s) {
        final l = s.docs.map(_m).toList();
        l.sort((a, b) => a.nomor.compareTo(b.nomor));
        return l;
      });

  Stream<List<AntreanModel>> streamAntreanRentang(String mulai, String akhir) => _col
      .where('tanggal', isGreaterThanOrEqualTo: mulai)
      .where('tanggal', isLessThanOrEqualTo: akhir)
      .snapshots()
      .map((s) => s.docs.map(_m).toList());

  // ---------- Notifikasi ----------
  Stream<List<NotifikasiModel>> streamNotifikasi(String uid) =>
      _db.collection('notifikasi').where('uid', isEqualTo: uid).snapshots().map((s) {
        final l = s.docs.map((d) => NotifikasiModel.fromMap(d.id, d.data())).toList();
        l.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        return l;
      });

  Future<void> tandaiDibaca(String notifId) =>
      _db.collection('notifikasi').doc(notifId).update({'dibaca': true});

  Future<void> tandaiSemuaDibaca(List<NotifikasiModel> list) async {
    final batch = _db.batch();
    for (final n in list.where((n) => !n.dibaca)) {
      batch.update(_db.collection('notifikasi').doc(n.notifId), {'dibaca': true});
    }
    await batch.commit();
  }

  void _notif(WriteBatch b, String uid, String judul, String isi) {
    if (uid.isEmpty) return;
    b.set(_db.collection('notifikasi').doc(), {
      'uid': uid,
      'judul': judul,
      'isi': isi,
      'dibaca': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Pengambilan nomor ----------
  /// Nomor dibuat dengan Firestore transaction (baca terpakai, bandingkan
  /// dengan kuota, tambah 1, simpan) agar tidak ada nomor ganda.
  Future<String> buatAntrean({
    required PoliModel poli,
    required String tanggal,
    required String sumber, // online / walkin
    String uid = '',
    String namaPasien = '',
    String namaWalkin = '',
  }) async {
    final jadwalRef = _db.collection('jadwal').doc(JadwalModel.idFor(poli.poliId, tanggal));
    final antreanRef = _col.doc();

    if (uid.isNotEmpty) {
      final dup = await _col
          .where('uid', isEqualTo: uid)
          .where('poli_id', isEqualTo: poli.poliId)
          .where('tanggal', isEqualTo: tanggal)
          .get();
      if (dup.docs.any((d) => AntreanStatus.aktif.contains(d.data()['status']))) {
        throw AntreanException(
            'Anda sudah memiliki antrean aktif di poli dan tanggal yang sama.');
      }
    }

    await _db.runTransaction((tx) async {
      final snap = await tx.get(jadwalRef);
      if (!snap.exists) {
        throw AntreanException('Belum ada jadwal pelayanan pada tanggal tersebut.');
      }
      final d = snap.data()!;
      final kuota = toInt(d['kuota']);
      final terpakai = toInt(d['terpakai']);
      if (terpakai >= kuota) throw KuotaHabisException();
      final nomor = terpakai + 1;
      tx.update(jadwalRef, {'terpakai': nomor});
      tx.set(antreanRef, {
        'uid': uid,
        'poli_id': poli.poliId,
        'jadwal_id': jadwalRef.id,
        'nama_poli': poli.namaPoli,
        'kode_poli': poli.kodePoli,
        'tanggal': tanggal,
        'nomor': nomor,
        'status': sumber == 'walkin' ? AntreanStatus.hadir : AntreanStatus.menunggu,
        'sumber': sumber,
        'nama_walkin': namaWalkin,
        'nama_pasien': sumber == 'walkin' ? namaWalkin : namaPasien,
        'durasi_menit': poli.rataDurasiMenit,
        'created_at': FieldValue.serverTimestamp(),
        'waktu_hadir': sumber == 'walkin' ? FieldValue.serverTimestamp() : null,
        'waktu_dipanggil': null,
      });
    });

    if (uid.isNotEmpty) {
      final b = _db.batch();
      _notif(b, uid, 'Antrean berhasil dibuat',
          'Antrean ${poli.namaPoli} tanggal ${fmtTanggalSingkat(tanggal)} telah terkonfirmasi.');
      await b.commit();
    }
    return antreanRef.id;
  }

  /// Petugas membuka kuota tambahan (walk-in saat kuota habis).
  Future<void> bukaKuotaTambahan(String poliId, String tanggal, int jumlah) =>
      _db.collection('jadwal').doc(JadwalModel.idFor(poliId, tanggal)).update({
        'kuota': FieldValue.increment(jumlah),
      });

  // ---------- Aksi pasien ----------
  Future<void> batalkan(AntreanModel a) async {
    if (a.status != AntreanStatus.menunggu && a.status != AntreanStatus.hadir) {
      throw AntreanException('Antrean ini tidak dapat dibatalkan.');
    }
    await _col.doc(a.antreanId).update({'status': AntreanStatus.batal});
  }

  /// Jadwal ulang: buat antrean baru lebih dulu, lalu batalkan yang lama.
  Future<String> jadwalUlang(AntreanModel a, PoliModel poli, String tanggalBaru,
      {required String namaPasien}) async {
    if (tanggalBaru == a.tanggal) {
      throw AntreanException('Pilih tanggal yang berbeda dari antrean saat ini.');
    }
    final id = await buatAntrean(
        poli: poli,
        tanggal: tanggalBaru,
        sumber: 'online',
        uid: a.uid,
        namaPasien: namaPasien);
    await _col.doc(a.antreanId).update({'status': AntreanStatus.batal});
    return id;
  }

  Future<void> checkIn(AntreanModel a) async {
    if (a.tanggal != todayKey()) {
      throw AntreanException('Check-in hanya bisa dilakukan pada tanggal antrean.');
    }
    if (a.status != AntreanStatus.menunggu) {
      throw AntreanException('Antrean ini tidak dapat di-check-in.');
    }
    await _col.doc(a.antreanId).update({
      'status': AntreanStatus.hadir,
      'waktu_hadir': FieldValue.serverTimestamp(),
    });
  }

  // ---------- Aksi petugas ----------
  Future<void> verifikasiCheckIn(AntreanModel a) async {
    if (a.tanggal != todayKey()) {
      throw AntreanException('Antrean ini bukan untuk hari ini.');
    }
    await _col.doc(a.antreanId).update({
      'status': AntreanStatus.hadir,
      'waktu_hadir': FieldValue.serverTimestamp(),
    });
  }

  Future<AntreanModel> panggilBerikutnya(String poliId, String tanggal) async {
    final snap = await _col
        .where('poli_id', isEqualTo: poliId)
        .where('tanggal', isEqualTo: tanggal)
        .get();
    final list = snap.docs.map(_m).toList()..sort((a, b) => a.nomor.compareTo(b.nomor));

    if (list.any((a) => a.status == AntreanStatus.dipanggil)) {
      throw AntreanException(
          'Selesaikan atau lewati pasien yang sedang dilayani terlebih dahulu.');
    }
    final hadir = list.where((a) => a.status == AntreanStatus.hadir).toList();
    final menunggu = list.where((a) => a.status == AntreanStatus.menunggu).toList();
    final next = hadir.isNotEmpty ? hadir.first : (menunggu.isNotEmpty ? menunggu.first : null);
    if (next == null) throw AntreanException('Tidak ada antrean yang menunggu.');

    final b = _db.batch();
    b.update(_col.doc(next.antreanId), {
      'status': AntreanStatus.dipanggil,
      'waktu_dipanggil': FieldValue.serverTimestamp(),
    });
    b.update(_db.collection('jadwal').doc(next.jadwalId), {'sedang_dilayani': next.nomor});
    _notif(b, next.uid, 'Giliran Anda tiba',
        'Nomor ${next.kode} dipanggil. Silakan menuju loket ${next.namaPoli}.');
    // Pasien dua nomor di belakang diberi tahu bahwa giliran hampir tiba.
    for (final a in list) {
      if (a.nomor == next.nomor + 2 && a.aktif && a.uid.isNotEmpty) {
        _notif(b, a.uid, 'Giliran hampir tiba',
            'Nomor Anda ${a.kode} tinggal 2 antrean lagi. Segera menuju puskesmas.');
      }
    }
    await b.commit();
    return next;
  }

  Future<void> selesai(AntreanModel a) =>
      _col.doc(a.antreanId).update({'status': AntreanStatus.selesai});

  Future<void> lewati(AntreanModel a) =>
      _col.doc(a.antreanId).update({'status': AntreanStatus.tidakHadir});
}
