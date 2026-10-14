import 'package:flutter/material.dart';
import '../app/theme.dart';
import '../models/antrean_model.dart';

/// Status ditampilkan dengan warna, ikon, DAN teks (aksesibel bagi buta warna).
class StatusChip extends StatelessWidget {
  final String status;
  const StatusChip(this.status, {super.key});

  static (String, Color, IconData) info(String s) {
    switch (s) {
      case AntreanStatus.menunggu:
        return ('Menunggu', const Color(0xFFB45309), Icons.schedule_rounded);
      case AntreanStatus.hadir:
        return ('Hadir', AppColors.primary, Icons.how_to_reg_rounded);
      case AntreanStatus.dipanggil:
        return ('Dipanggil', const Color(0xFF1D4ED8), Icons.campaign_rounded);
      case AntreanStatus.selesai:
        return ('Selesai', AppColors.primary, Icons.check_circle_rounded);
      case AntreanStatus.batal:
        return ('Batal', AppColors.red, Icons.cancel_rounded);
      case AntreanStatus.tidakHadir:
        return ('Tidak Hadir', AppColors.red, Icons.person_off_rounded);
      default:
        return (s, AppColors.muted, Icons.help_outline_rounded);
    }
  }

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = info(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 5),
        Text(label,
            style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 14)),
      ]),
    );
  }
}
