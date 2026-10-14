import 'package:flutter/foundation.dart';

import '../models/user_model.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _service;
  AuthProvider(this._service);

  UserModel? user;
  bool loading = false;
  String? error;

  bool get loggedIn => user != null;

  /// Rute awal sesuai peran.
  static String routeFor(String role) {
    switch (role) {
      case 'petugas':
        return '/petugas/panel';
      case 'admin':
        return '/admin/dashboard';
      default:
        return '/pasien/home';
    }
  }

  /// Memulihkan sesi (dipakai Splash).
  Future<UserModel?> restoreSession() async {
    final cu = _service.currentUser;
    if (cu == null) return null;
    try {
      user = await _service.getUser(cu.uid);
    } catch (_) {
      user = null;
    }
    notifyListeners();
    return user;
  }

  Future<bool> login(String email, String password) async {
    return _run(() async => user = await _service.login(email, password));
  }

  Future<bool> register({
    required String nama,
    required String nik,
    required String noBpjs,
    required String noHp,
    required String email,
    required String password,
  }) {
    return _run(() async => user = await _service.register(
        nama: nama, nik: nik, noBpjs: noBpjs, noHp: noHp, email: email, password: password));
  }

  Future<bool> updateProfile({
    required String nama,
    required String nik,
    required String noBpjs,
    required String noHp,
  }) {
    return _run(() async {
      await _service.updateProfile(user!.uid, nama: nama, nik: nik, noBpjs: noBpjs, noHp: noHp);
      user = await _service.getUser(user!.uid);
    });
  }

  Future<void> logout() async {
    await _service.logout();
    user = null;
    error = null;
    notifyListeners();
  }

  Future<bool> _run(Future<void> Function() job) async {
    loading = true;
    error = null;
    notifyListeners();
    try {
      await job();
      loading = false;
      notifyListeners();
      return true;
    } catch (e) {
      error = AuthService.pesanError(e);
      loading = false;
      notifyListeners();
      return false;
    }
  }
}
