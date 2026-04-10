import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  String _statusText = "Memuat sistem...";

  @override
  void initState() {
    super.initState();
    _initializeApp();
  }

  Future<void> _initializeApp() async {
    // 1. Meminta Izin Akses (Lokasi & Kamera)
    setState(() => _statusText = "Memeriksa perizinan perangkat...");
    await _requestPermissions();

    // 2. Lanjut mengecek sesi login (RootNavigator yang akan memindahkan layar)
    setState(() => _statusText = "Memeriksa sesi pengguna...");
    if (mounted) {
      await context.read<AuthProvider>().checkLoginStatus();
    }
  }

  Future<void> _requestPermissions() async {
    // List izin yang wajib untuk aplikasi absensi
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
    ].request();

    // Opsional: Anda bisa menambahkan logika di sini jika izin ditolak
    // Misalnya, memaksa user membuka pengaturan jika statusnya permanentlyDenied
    if (statuses[Permission.location]!.isDenied ||
        statuses[Permission.camera]!.isDenied) {
      // Jika izin ditolak, kita tetap bisa melanjutkan,
      // namun nantinya fitur map/absen akan gagal di halaman masing-masing.
      debugPrint("Beberapa izin ditolak oleh pengguna.");
    }

    if (statuses[Permission.location]!.isPermanentlyDenied) {
      // Buka pengaturan aplikasi jika user memilih "Don't ask again"
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FluidColors.background, // Sesuai tema Fluid
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Ikon atau Logo Perusahaan Anda
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: FluidColors.surfaceContainerLow,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.fingerprint_rounded,
                size: 80,
                color: FluidColors.primary,
              ),
            ),
            const SizedBox(height: 32),
            const CircularProgressIndicator(color: FluidColors.primary),
            const SizedBox(height: 24),
            Text(
              _statusText,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}
