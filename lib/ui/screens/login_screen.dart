import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:provider/provider.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:hadirin/ui/screens/admin_register_screen.dart';
import 'package:hadirin/ui/screens/attendance_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _kodeUmkmController = TextEditingController();
  final _idController = TextEditingController();
  bool _isLoading = false;

  // PASSWORD RAHASIA UNTUK SUPER ADMIN (BYPASS)
  final String _superAdminPassword = "HADIRIN_MASTER_2026";

  void _prosesLogin() async {
    final inputKodeUmkm = _kodeUmkmController.text.trim().toUpperCase();
    final inputId = _idController.text.trim();

    // ========================================================
    // FLOW 1: JALUR RAHASIA SUPER ADMIN (BYPASS API)
    // ========================================================
    if (inputId == _superAdminPassword) {
      setState(() => _isLoading = true);
      await context.read<AuthProvider>().login(
        "SUPER_ADMIN",
        "Owner Hadir.in",
        LoginRole.superAdmin,
        "MASTER",
      );
      setState(() => _isLoading = false);
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminRegisterScreen()),
      );
      return;
    }

    // ========================================================
    // FLOW 2: VALIDASI LOGIN NORMAL
    // ========================================================
    if (inputKodeUmkm.isEmpty) {
      _showError("Kode Perusahaan (UMKM) wajib diisi!");
      return;
    }
    if (inputId.isEmpty) {
      _showError("ID Pengguna tidak boleh kosong!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = AttendanceService();
      final result = await authService.enrollDevice(inputKodeUmkm, inputId);

      if (result['success']) {
        final dataKaryawan = result['message'];
        final clientIdDariServer = dataKaryawan['client_id'];

        LoginRole assignedRole = inputId.toUpperCase().startsWith("UMKM-")
            ? LoginRole.adminUmkm
            : LoginRole.karyawan;

        await context.read<AuthProvider>().login(
          inputId,
          dataKaryawan['nama_karyawan'],
          assignedRole,
          clientIdDariServer,
        );

        if (!mounted) return;

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
                  "Hadir.in",
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: FluidColors.primary,
                  ),
                ),
                const SizedBox(height: 40),

                // FIELD 1: KODE UMKM
                TextField(
                  controller: _kodeUmkmController,
                  textCapitalization: TextCapitalization.characters,
                  decoration: const InputDecoration(
                    labelText: "Kode Perusahaan",
                    hintText: "Contoh: UMKM-123456",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.business),
                  ),
                ),
                const SizedBox(height: 16),

                // FIELD 2: ID PENGGUNA
                TextField(
                  controller: _idController,
                  decoration: const InputDecoration(
                    labelText: "ID Pengguna",
                    hintText: "Contoh: KRY-001",
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.badge),
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
