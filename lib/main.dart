import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'app/routes.dart';
import 'app/theme.dart';
import 'firebase_options.dart';
import 'providers/antrean_provider.dart';
import 'providers/auth_provider.dart';
import 'services/antrean_service.dart';
import 'services/auth_service.dart';
import 'services/jadwal_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('id_ID');
  String? initError;
  try {
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  } catch (e) {
    initError = e.toString();
  }
  runApp(initError == null ? const HealthQApp() : _SetupErrorApp(error: initError));
}

class HealthQApp extends StatelessWidget {
  const HealthQApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>(create: (_) => AuthService()),
        Provider<AntreanService>(create: (_) => AntreanService()),
        Provider<JadwalService>(create: (_) => JadwalService()),
        ChangeNotifierProvider<AuthProvider>(create: (c) => AuthProvider(c.read<AuthService>())),
        ChangeNotifierProvider<AntreanProvider>(create: (c) => AntreanProvider(c.read<AntreanService>())),
      ],
      child: MaterialApp(
        title: 'HealthQ',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.generate,
      ),
    );
  }
}

class _SetupErrorApp extends StatelessWidget {
  final String error;
  const _SetupErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Icon(Icons.cloud_off_rounded, size: 56, color: AppColors.orange),
              const SizedBox(height: 16),
              Text('Firebase belum dikonfigurasi', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              const Text('Jalankan perintah berikut di folder proyek, lalu jalankan ulang aplikasi:'),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppColors.tint, borderRadius: BorderRadius.circular(12)),
                child: const SelectableText('flutterfire configure', style: TextStyle(fontFamily: 'monospace')),
              ),
              const SizedBox(height: 16),
              Text(error, style: Theme.of(context).textTheme.bodySmall, maxLines: 4, overflow: TextOverflow.ellipsis),
            ]),
          ),
        ),
      ),
    );
  }
}
