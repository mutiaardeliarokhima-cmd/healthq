import 'package:flutter/material.dart';

import '../../widgets/common.dart';
import '../shared/profil_screen.dart';
import 'antrean_saya_screen.dart';
import 'beranda_screen.dart';
import 'jadwal_screen.dart';
import 'riwayat_screen.dart';

/// Bottom navigation pasien: Beranda, Antrean, Jadwal, Riwayat, Profil.
class PasienShell extends StatelessWidget {
  final int initialIndex;
  const PasienShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      initialIndex: initialIndex,
      items: const [
        NavItem('Beranda', Icons.home_outlined, Icons.home_rounded),
        NavItem('Antrean', Icons.confirmation_number_outlined, Icons.confirmation_number_rounded),
        NavItem('Jadwal', Icons.calendar_month_outlined, Icons.calendar_month_rounded),
        NavItem('Riwayat', Icons.history_rounded, Icons.history_rounded),
        NavItem('Profil', Icons.person_outline_rounded, Icons.person_rounded),
      ],
      pages: const [
        BerandaScreen(),
        AntreanSayaScreen(),
        JadwalScreen(),
        RiwayatScreen(),
        ProfilScreen(),
      ],
    );
  }
}
