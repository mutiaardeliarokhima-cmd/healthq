import 'package:flutter/foundation.dart';

import '../models/poli_model.dart';
import '../models/user_model.dart';
import '../services/antrean_service.dart';
import '../services/auth_service.dart';
import '../utils/formatters.dart';

/// State wizard "Ambil Antrean" dan aksi antrean (pasien dan petugas).
class AntreanProvider extends ChangeNotifier {
  final AntreanService _service;
  AntreanProvider(this._service);

  PoliModel? poli;
  DateTime tanggal = DateTime.now();
  bool loading = false;
  String? error;

  String get tanggalKey => dateKey(tanggal);

  void pilihPoli(PoliModel p) {
    poli = p;
    notifyListeners();
  }

  void pilihTanggal(DateTime d) {
    tanggal = d;
    notifyListeners();
  }

  void reset() {
    poli = null;
    tanggal = DateTime.now();
    error = null;
    loading = false;
  }

  /// Mengembalikan id antrean bila berhasil.
  Future<String?> ambil(UserModel user) async {
    if (poli == null) {
      error = 'Pilih poli terlebih dahulu.';
      notifyListeners();
      return null;
    }
    final v = _validasiTanggal(tanggal);
    if (v != null) {
      error = v;
      notifyListeners();
      return null;
    }
    loading = true;
    error = null;
    notifyListeners();
    try {
      final id = await _service.buatAntrean(
        poli: poli!,
        tanggal: tanggalKey,
        sumber: 'online',
        uid: user.uid,
        namaPasien: user.nama,
      );
      loading = false;
      notifyListeners();
      return id;
    } catch (e) {
      error = AuthService.pesanError(e);
      loading = false;
      notifyListeners();
      return null;
    }
  }

  String? _validasiTanggal(DateTime d) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final pick = DateTime(d.year, d.month, d.day);
    if (pick.isBefore(today)) return 'Tanggal tidak boleh lampau';
    if (pick.isAfter(today.add(const Duration(days: 7)))) return 'Maksimal 7 hari ke depan';
    return null;
  }

  /// Membungkus aksi agar error tampil sebagai pesan.
  Future<String?> jalankan(Future<void> Function() aksi) async {
    try {
      await aksi();
      return null;
    } catch (e) {
      return AuthService.pesanError(e);
    }
  }
}
