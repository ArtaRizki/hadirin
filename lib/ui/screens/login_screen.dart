import 'package:flutter/material.dart';
import 'package:hadirin/core/config/app_config.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:provider/provider.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _namaController =
      TextEditingController(); // Bisa juga dikosongkan jika mau ambil dari GAS
  bool _isLoading = false;

  // GANTI PASSWORD INI DENGAN PASSWORD RAHASIA ANDA SEBAGAI PEMILIK APLIKASI
  final String _superAdminPassword = "HADIRIN_MASTER_2026";

  void _prosesLogin() async {
    final inputId = _idController.text.trim();
    // final inputNama = _namaController.text.trim(); // Opsional, bisa dihapus jika tidak dipakai

    if (inputId.isEmpty) {
      _showError("ID tidak boleh kosong");
      return;
    }

    setState(() => _isLoading = true);

    // ========================================================
    // FLOW 1: LOGIN SUPER ADMIN (Pembuat Aplikasi / Anda)
    // ========================================================
    if (inputId == _superAdminPassword) {
      await context.read<AuthProvider>().login(
        "SUPER_ADMIN",
        "Owner Hadirin",
        LoginRole.superAdmin,
      );
      setState(() => _isLoading = false);
      return;
    }

    // ========================================================
    // FLOW 2 & 3: LOGIN UNIVERSAL (ADMIN UMKM & KARYAWAN)
    // ========================================================
    // Keduanya wajib dicek Device ID-nya dan diambil data namanya dari Server
    final authService = AttendanceService();

    // Panggil API Enroll Device (berlaku untuk semua ID selain Super Admin)
    final result = await authService.enrollDevice(inputId);

    setState(() => _isLoading = false);

    if (result['success']) {
      final dataKaryawan = result['message'];

      // Simpan Client ID di memori global aplikasi
      AppConfig.clientId = dataKaryawan['client_id'];

      // Tentukan Jabatan berdasarkan ID yang diketik
      // Jika ID berawalan UMKM-, dia adalah Admin UMKM. Jika tidak, dia Karyawan.
      LoginRole assignedRole = inputId.toUpperCase().startsWith("UMKM-")
          ? LoginRole.adminUmkm
          : LoginRole.karyawan;

      // Login menggunakan nama asli dari Database Excel
      await context.read<AuthProvider>().login(
        inputId,
        dataKaryawan['nama_karyawan'],
        assignedRole,
      );
    } else {
      // Jika ID tidak ditemukan atau HP sudah dipakai orang lain
      _showError(result['message'].toString());
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: Colors.red));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FluidColors.background,
      body: Center(
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
                  ),
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
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
    );
  }
}
