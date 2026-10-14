import 'package:flutter/material.dart';

import '../screens/admin/admin_shell.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/splash_screen.dart';
import '../screens/pasien/ambil_antrean_screen.dart';
import '../screens/pasien/pasien_shell.dart';
import '../screens/pasien/tiket_screen.dart';
import '../screens/petugas/petugas_shell.dart';
import '../screens/shared/notifikasi_screen.dart';
import '../screens/shared/pengumuman_screen.dart';
import '../screens/shared/profil_screen.dart';

/// Daftar rute (Tabel 6 pada Tahap 2).
class AppRoutes {
  static const splash = '/splash';
  static const login = '/login';
  static const register = '/register';
  static const pasienHome = '/pasien/home';
  static const pasienAmbil = '/pasien/ambil';
  static const pasienJadwal = '/pasien/jadwal';
  static const pasienRiwayat = '/pasien/riwayat';
  static const profil = '/profil';
  static const petugasPanel = '/petugas/panel';
  static const petugasWalkin = '/petugas/walkin';
  static const adminDashboard = '/admin/dashboard';
  static const adminKelola = '/admin/kelola';
  static const adminLaporan = '/admin/laporan';
  static const notifikasi = '/notifikasi';
  static const pengumuman = '/pengumuman';

  static Route<dynamic> generate(RouteSettings settings) {
    final uri = Uri.parse(settings.name ?? splash);
    final seg = uri.pathSegments;

    // /pasien/antrean/:id
    if (seg.length == 3 && seg[0] == 'pasien' && seg[1] == 'antrean') {
      return _route(TiketScreen(antreanId: seg[2]), settings);
    }

    final Widget page;
    switch (uri.path) {
      case login:
        page = const LoginScreen();
        break;
      case register:
        page = const RegisterScreen();
        break;
      case pasienHome:
        page = const PasienShell(initialIndex: 0);
        break;
      case pasienAmbil:
        page = const AmbilAntreanScreen();
        break;
      case pasienJadwal:
        page = const PasienShell(initialIndex: 2);
        break;
      case pasienRiwayat:
        page = const PasienShell(initialIndex: 3);
        break;
      case profil:
        page = const ProfilScreen();
        break;
      case petugasPanel:
        page = const PetugasShell(initialIndex: 0);
        break;
      case petugasWalkin:
        page = const PetugasShell(initialIndex: 1);
        break;
      case adminDashboard:
        page = const AdminShell(initialIndex: 0);
        break;
      case adminKelola:
        page = const AdminShell(initialIndex: 1);
        break;
      case adminLaporan:
        page = const AdminShell(initialIndex: 2);
        break;
      case notifikasi:
        page = const NotifikasiScreen();
        break;
      case pengumuman:
        page = const PengumumanScreen();
        break;
      case splash:
      default:
        return _route(const SplashScreen(), settings, fade: true);
    }
    return _route(page, settings);
  }

  static PageRoute<dynamic> _route(Widget page, RouteSettings s, {bool fade = false}) {
    return PageRouteBuilder(
      settings: s,
      pageBuilder: (_, __, ___) => page,
      transitionDuration: const Duration(milliseconds: 260),
      reverseTransitionDuration: const Duration(milliseconds: 200),
      transitionsBuilder: (_, anim, __, child) {
        final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutCubic);
        if (fade) return FadeTransition(opacity: curved, child: child);
        return FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(begin: const Offset(0.04, 0), end: Offset.zero).animate(curved),
            child: child,
          ),
        );
      },
    );
  }
}
