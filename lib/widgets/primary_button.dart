import 'package:flutter/material.dart';
import '../app/theme.dart';

/// Tombol utama: tinggi 52 dp, sudut 12 dp, lebar penuh.
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;
  final Color? color;
  final bool outlined;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.loading = false,
    this.color,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    final child = loading
        ? SizedBox(
            height: 22,
            width: 22,
            child: CircularProgressIndicator(
                strokeWidth: 2.6, color: outlined ? AppColors.primary : Colors.white))
        : Row(mainAxisSize: MainAxisSize.min, children: [
            if (icon != null) ...[Icon(icon, size: 22), const SizedBox(width: 8)],
            Flexible(child: Text(label, textAlign: TextAlign.center)),
          ]);
    final action = loading ? null : onPressed;
    return SizedBox(
      width: double.infinity,
      child: outlined
          ? OutlinedButton(
              onPressed: action,
              style: color == null
                  ? null
                  : OutlinedButton.styleFrom(
                      foregroundColor: color, side: BorderSide(color: color!.withOpacity(.4), width: 1.5)),
              child: child)
          : FilledButton(
              onPressed: action,
              style: FilledButton.styleFrom(backgroundColor: color ?? AppColors.primary),
              child: child),
    );
  }
}
