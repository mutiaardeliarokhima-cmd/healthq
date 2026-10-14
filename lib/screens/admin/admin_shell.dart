import 'package:flutter/material.dart';

import '../../widgets/common.dart';
import '../shared/profil_screen.dart';
import 'dashboard_screen.dart';
import 'kelola_screen.dart';
import 'laporan_screen.dart';

/// Bottom navigation admin: Dashboard, Kelola Data, Laporan, Profil.
class AdminShell extends StatelessWidget {
  final int initialIndex;
  const AdminShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      initialIndex: initialIndex,
      items: const [
        NavItem('Dashboard', Icons.space_dashboard_outlined, Icons.space_dashboard_rounded),
        NavItem('Kelola', Icons.edit_calendar_outlined, Icons.edit_calendar_rounded),
        NavItem('Laporan', Icons.assessment_outlined, Icons.assessment_rounded),
        NavItem('Profil', Icons.person_outline_rounded, Icons.person_rounded),
      ],
      pages: const [DashboardScreen(), KelolaScreen(), LaporanScreen(), ProfilScreen()],
    );
  }
}
