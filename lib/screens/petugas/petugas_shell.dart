import 'package:flutter/material.dart';

import '../../widgets/common.dart';
import '../shared/profil_screen.dart';
import 'checkin_screen.dart';
import 'panel_screen.dart';
import 'walkin_screen.dart';

/// Bottom navigation petugas: Panel, Walk-in, Check-in, Profil.
class PetugasShell extends StatelessWidget {
  final int initialIndex;
  const PetugasShell({super.key, this.initialIndex = 0});

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      initialIndex: initialIndex,
      items: const [
        NavItem('Panel', Icons.dashboard_outlined, Icons.dashboard_rounded),
        NavItem('Walk-in', Icons.person_add_alt_outlined, Icons.person_add_alt_1_rounded),
        NavItem('Check-in', Icons.how_to_reg_outlined, Icons.how_to_reg_rounded),
        NavItem('Profil', Icons.person_outline_rounded, Icons.person_rounded),
      ],
      pages: const [PanelScreen(), WalkinScreen(), CheckinScreen(), ProfilScreen()],
    );
  }
}
