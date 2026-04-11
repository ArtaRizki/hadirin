import 'package:flutter/material.dart';
import 'package:hadirin/core/config/app_config.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:provider/provider.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hadirin/ui/screens/admin_register_screen.dart'; // Screen Super Admin
import 'package:hadirin/ui/screens/attendance_screen.dart'; // Screen Utama Absen

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _namaController = TextEditingController();
  bool _isLoading = false;

  // PASSWORD RAHASIA UNTUK SUPER ADMIN (BYPASS)
  final String _superAdminPassword = "HADIRIN_MASTER_2026";

  void _prosesLogin() async {
    final inputId = _idController.text.trim();

    if (inputId.isEmpty) {
      _showError("ID tidak boleh kosong");
      return;
    }

    setState(() => _isLoading = true);

    // ========================================================
    // FLOW 1: JALUR RAHASIA SUPER ADMIN (BYPASS API)
    // ========================================================
    if (inputId == _superAdminPassword) {
      await context.read<AuthProvider>().login(
        "SUPER_ADMIN",
        "Owner Hadirin",
        LoginRole.superAdmin,
      );

      setState(() => _isLoading = false);

      if (!mounted) return;

      // ARAHKAN KE HALAMAN PENDAFTARAN UMKM
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminRegisterScreen()),
      );
      return; // Wajib di-return agar tidak mengeksekusi kode API di bawahnya
    }

    // ========================================================
    // FLOW 2 & 3: LOGIN UNIVERSAL (ADMIN UMKM & KARYAWAN)
    // ========================================================
    try {
      final authService = AttendanceService();
      final result = await authService.enrollDevice(inputId);

      if (result['success']) {
        final dataKaryawan = result['message'];
        final clientId = dataKaryawan['client_id'];
        AppConfig.clientId = clientId;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('client_id', clientId);

        LoginRole assignedRole = inputId.toUpperCase().startsWith("UMKM-")
            ? LoginRole.adminUmkm
            : LoginRole.karyawan;

        await context.read<AuthProvider>().login(
          inputId,
          dataKaryawan['nama_karyawan'],
          assignedRole,
        );

        if (!mounted) return;

        // ARAHKAN KE HALAMAN UTAMA (ABSENSI)
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AttendanceScreen()),
        );
      } else {
        _showError(result['message'].toString());
      }
    } catch (e) {
      _showError("Gagal terhubung ke server: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FluidColors.background,
      body: Center(
        child: SingleChildScrollView(
          // Tambahkan ini agar tidak error saat keyboard muncul
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Masuk ke",
                  style: TextStyle(fontSize: 16, color: Colors.grey),
                ),
                const Text(
                  "Hadirin.",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: FluidColors.primary,
                  ),
                ),
                const SizedBox(height: 40),

                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: "Masukkan ID Karyawan / Client ID",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
                  ),
                ),
                const SizedBox(height: 16),

                // Kolom Nama opsional (Bisa Anda hapus jika murni hanya pakai ID, karena nama sudah ditarik dari Database saat Enroll)
                TextField(
                  controller: _namaController,
                  decoration: const InputDecoration(
                    labelText: "Nama Panggilan (Opsional)",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 32),

                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _prosesLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: FluidColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FluidRadii.sm),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Masuk Sekarang",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
