import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../app/theme.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/brand_logo.dart';

/// Logo dan pengecekan sesi.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _cek();
  }

  Future<void> _cek() async {
    final auth = context.read<AuthProvider>();
    final user = await auth.restoreSession();
    await Future.delayed(const Duration(milliseconds: 1400));
    if (!mounted) return;
    Navigator.pushReplacementNamed(
        context, user == null ? '/login' : AuthProvider.routeFor(user.role));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: const [
          BrandLogo(size: 96, light: true),
          SizedBox(height: 40),
          SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white)),
        ]),
      ),
    );
  }
}
