import 'package:flutter/material.dart';
import '../app/theme.dart';

class BrandLogo extends StatelessWidget {
  final double size;
  final bool withText;
  final bool light;
  const BrandLogo({super.key, this.size = 72, this.withText = true, this.light = false});

  @override
  Widget build(BuildContext context) {
    final mark = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(size * .3),
        gradient: const LinearGradient(
            colors: [AppColors.mint, Color(0xFF6CCFB0)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
      ),
      child: Icon(Icons.health_and_safety_rounded, size: size * .56, color: AppColors.primary),
    );
    if (!withText) return mark;
    return Column(mainAxisSize: MainAxisSize.min, children: [
      mark,
      SizedBox(height: size * .22),
      Text('HealthQ',
          style: TextStyle(
              fontSize: size * .42,
              fontWeight: FontWeight.w900,
              color: light ? Colors.white : AppColors.primary,
              letterSpacing: -.5)),
      Text('Sehat tanpa antre',
          style: TextStyle(fontSize: 15, color: light ? Colors.white70 : AppColors.muted)),
    ]);
  }
}
