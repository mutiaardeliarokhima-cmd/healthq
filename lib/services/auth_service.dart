import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../models/user_model.dart';
import 'antrean_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<UserModel?> getUser(String uid) async {
    final d = await _db.collection('users').doc(uid).get();
    if (!d.exists) return null;
    return UserModel.fromMap(d.id, d.data()!);
  }

  Future<UserModel> login(String email, String password) async {
    final cred = await _auth.signInWithEmailAndPassword(
        email: email.trim(), password: password);
    final user = await getUser(cred.user!.uid);
    if (user == null) {
      await _auth.signOut();
      throw 'Profil pengguna tidak ditemukan. Hubungi admin puskesmas.';
    }
    return user;
  }

  Future<UserModel> register({
    required String nama,
    required String nik,
    required String noBpjs,
    required String noHp,
    required String email,
    required String password,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    final uid = cred.user!.uid;
    await _db.collection('users').doc(uid).set({
      'nama': nama.trim(),
      'nik': nik.trim(),
      'no_bpjs': noBpjs.trim(),
      'no_hp': noHp.trim(),
      'email': email.trim(),
      'role': 'pasien',
      'created_at': FieldValue.serverTimestamp(),
    });
    return (await getUser(uid))!;
  }

  Future<void> logout() => _auth.signOut();

  Future<void> updateProfile(String uid,
      {required String nama,
      required String nik,
      required String noBpjs,
      required String noHp}) {
    return _db.collection('users').doc(uid).update({
      'nama': nama.trim(),
      'nik': nik.trim(),
      'no_bpjs': noBpjs.trim(),
      'no_hp': noHp.trim(),
    });
  }

  /// Admin membuat akun petugas memakai instance Firebase kedua
  /// agar sesi admin tidak ikut berganti.
  Future<void> createStaffAccount({
    required String nama,
    required String email,
    required String password,
    required String noHp,
  }) async {
    FirebaseApp app;
    try {
      app = Firebase.app('secondary');
    } catch (_) {
      app = await Firebase.initializeApp(
          name: 'secondary', options: Firebase.app().options);
    }
    final secondaryAuth = FirebaseAuth.instanceFor(app: app);
    final cred = await secondaryAuth.createUserWithEmailAndPassword(
        email: email.trim(), password: password);
    await _db.collection('users').doc(cred.user!.uid).set({
      'nama': nama.trim(),
      'nik': '',
      'no_bpjs': '',
      'no_hp': noHp.trim(),
      'email': email.trim(),
      'role': 'petugas',
      'created_at': FieldValue.serverTimestamp(),
    });
    await secondaryAuth.signOut();
  }

  Stream<List<UserModel>> streamPetugas() {
    return _db
        .collection('users')
        .where('role', isEqualTo: 'petugas')
        .snapshots()
        .map((s) => s.docs.map((d) => UserModel.fromMap(d.id, d.data())).toList());
  }

  static String pesanError(Object e) {
    if (e is String) return e;
    if (e is AntreanException) return e.message;
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'invalid-credential':
        case 'wrong-password':
        case 'user-not-found':
        case 'invalid-email':
          return 'Email atau kata sandi salah.';
        case 'email-already-in-use':
          return 'Email sudah terdaftar. Silakan masuk.';
        case 'weak-password':
          return 'Kata sandi terlalu lemah.';
        case 'network-request-failed':
          return 'Tidak ada koneksi internet.';
        case 'too-many-requests':
          return 'Terlalu banyak percobaan. Coba lagi nanti.';
        default:
          return e.message ?? 'Terjadi kesalahan autentikasi.';
      }
    }
    if (e is FirebaseException) return e.message ?? 'Terjadi kesalahan data.';
    return 'Terjadi kesalahan. Coba lagi.';
  }
}
