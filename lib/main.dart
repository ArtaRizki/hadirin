import 'package:flutter/material.dart';
import 'package:hadirin/core/config/app_config.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/ui/screens/attendance_screen.dart';
import 'package:hadirin/ui/screens/login_screen.dart';
import 'package:hadirin/ui/screens/splash_screen.dart';
import 'package:provider/provider.dart';

void main() {
  AppConfig.validate();
  runApp(
    MultiProvider(
      providers: [ChangeNotifierProvider(create: (_) => AuthProvider())],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(useMaterial3: true, colorSchemeSeed: Colors.blue),
      home: const RootNavigator(),
    );
  }
}

class RootNavigator extends StatelessWidget {
  const RootNavigator({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (!auth.isInitialized) {
          // ← Tampilkan splash HANYA saat belum selesai cek
          return const SplashScreen();
        }
        return auth.isLoggedIn ? const AttendanceScreen() : const LoginScreen();
      },
    );
  }
}
