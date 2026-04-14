import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadirin/core/service/notification_service.dart';
import 'package:hadirin/core/service/sync_service.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:hadirin/core/config/app_config.dart';

// Import Provider
import 'package:hadirin/core/providers/auth_provider.dart';

// Import Screens
import 'package:hadirin/ui/screens/splash_screen.dart';
import 'package:hadirin/ui/screens/login_screen.dart';
import 'package:hadirin/ui/screens/admin_register_screen.dart';
import 'package:hadirin/ui/screens/attendance_screen.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  // Validasi variabel lingkungan (GAS_ENDPOINT & API_TOKEN)
  AppConfig.validate();

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
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor:
            Colors.transparent, // Ubah ke warna yang kamu mau (misal putih)
        systemNavigationBarIconBrightness:
            Brightness.dark, // Ikon navigasi jadi gelap agar kontras
        systemNavigationBarDividerColor:
            Colors.transparent, // Menghilangkan garis pembatas jika ada
      ),
    );
    );
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        return MaterialApp(
          title: 'Hadir.in',
          debugShowCheckedModeBanner: false,
          theme: FluidTheme.getTheme(auth.themeColor),
          // 2. Jadikan AuthWrapper sebagai home (halaman pertama yang dimuat)
          home: const AuthWrapper(),
        );
      },
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
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final auth = context.read<AuthProvider>();
      await auth.checkLoginStatus();

      // Trigger Sync & Notifications jika sudah login
      if (auth.isLoggedIn && auth.isAnggota) {
        SyncService().runSync(
          idAnggota: auth.idAnggota ?? "",
          clientId: auth.clientId ?? "",
        );
      }
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
        // Layar Khusus Pemilik Aplikasi (Super Admin)
        return const AdminRegisterScreen();

      case LoginRole.admin:
      case LoginRole.anggota:
        // Admin Instansi & Anggota masuk ke Dashboard yang sama.
        // Nanti menu "Tambah Anggota" disembunyikan otomatis jika yang login Anggota biasa.
        return const AttendanceScreen();

      default:
        // Jaga-jaga jika terjadi error role
        return const LoginScreen();
    }
  }
}
