import 'package:flutter/material.dart';
import 'package:hadirin/core/service/notification_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

// Import Provider
import 'package:hadirin/core/providers/auth_provider.dart';

// Import Screens
import 'package:hadirin/ui/screens/splash_screen.dart';
import 'package:hadirin/ui/screens/login_screen.dart';
import 'package:hadirin/ui/screens/admin_register_screen.dart';
import 'package:hadirin/ui/screens/attendance_screen.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Inisialisasi sistem notifikasi saat aplikasi dibuka
  await initializeDateFormatting('id_ID');
  await NotificationService().init();
  FlutterNativeSplash.remove();
  runApp(
    // 1. Bungkus aplikasi dengan Provider agar status login bisa dibaca di semua halaman
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
      title: 'Hadir.in',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF005147),
        ), // Emerald Green
        useMaterial3: true,
      ),
      // 2. Jadikan AuthWrapper sebagai home (halaman pertama yang dimuat)
      home: const AuthWrapper(),
    );
  }
}

// ========================================================
// PENGATUR LALU LINTAS LAYAR (ROUTER)
// ========================================================
class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // 3. Cek status memori saat aplikasi pertama kali dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthProvider>().checkLoginStatus();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Pantau terus perubahan status di AuthProvider
    final auth = context.watch<AuthProvider>();

    // A. Jika sistem masih mengecek memori HP -> Tampilkan Splash Screen
    if (!auth.isInitialized) {
      return const SplashScreen();
    }

    // B. Jika belum login sama sekali -> Tampilkan Halaman Login
    if (!auth.isLoggedIn) {
      return const LoginScreen();
    }

    // C. Jika sudah login, cek Jabatannya (Role)
    switch (auth.role) {
      case LoginRole.superAdmin:
        // Layar Khusus Anda (Pemilik Aplikasi)
        return const AdminRegisterScreen();

      case LoginRole.adminUmkm:
      case LoginRole.karyawan:
        // Admin UMKM & Karyawan masuk ke Dashboard yang sama.
        // Nanti menu "Tambah Karyawan" disembunyikan otomatis jika yang login Karyawan biasa.
        return const AttendanceScreen();

      default:
        // Jaga-jaga jika terjadi error role
        return const LoginScreen();
    }
  }
}
