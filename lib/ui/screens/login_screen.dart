import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/admin_service.dart';
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

  void _prosesLogin() async {
    final inputKodeUmkm = _kodeUmkmController.text.trim().toUpperCase();
    final inputId = _idController.text.trim();

    // ========================================================
    // FLOW 1: JALUR RAHASIA SUPER ADMIN (API VALIDATION)
    // ========================================================
    if (inputKodeUmkm.isEmpty && inputId.isNotEmpty) {
      setState(() => _isLoading = true);

      final superResult = await AdminService().verifySuperAdmin(inputId);

      if (superResult['success']) {
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

      // Jika ternyata bukan super admin namun kode UMKM kosong,
      // biarkan program lanjut ke validasi normal di bawah
      // (yang akan menampilkan error "Kode Perusahaan wajib diisi")
      setState(() => _isLoading = false);
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
      final result = await AdminService().enrollDevice(inputKodeUmkm, inputId);

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
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF), // Warna background modern
      body: SafeArea(
        child: Stack(
          children: [
            // Dekorasi blob atas kanan
            Positioned(
              top: -100,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: FluidColors.primary.withOpacity(0.06),
                ),
              ),
            ),
            // Dekorasi blob bawah kiri
            Positioned(
              bottom: -50,
              left: -80,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED).withOpacity(0.05),
                ),
              ),
            ),

            Center(
              child: SafeArea(
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32.0,
                      vertical: 24.0,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // LOGO & HEADER
                        Center(
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: FluidColors.primary.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.fingerprint_rounded,
                              size: 48,
                              color: FluidColors.primary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),

                        const Text(
                          "Selamat Datang di",
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const Text(
                          "Hadir.in",
                          style: TextStyle(
                            fontSize: 42,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF0F172A),
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Sistem Absensi",
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 48),

                        // FIELD 1: KODE UMKM
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _kodeUmkmController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: "Kode Perusahaan",
                              hintText: "Contoh: UMKM-123456",
                              labelStyle: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                              prefixIcon: const Icon(
                                Icons.business_rounded,
                                color: FluidColors.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: FluidColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // FIELD 2: ID PENGGUNA
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: TextField(
                            controller: _idController,
                            decoration: InputDecoration(
                              labelText: "ID Pengguna",
                              hintText: "Contoh: KRY-001",
                              labelStyle: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                              prefixIcon: const Icon(
                                Icons.badge_rounded,
                                color: FluidColors.primary,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                  color: FluidColors.primary,
                                  width: 1.5,
                                ),
                              ),
                              filled: true,
                              fillColor: Colors.white,
                            ),
                          ),
                        ),

                        const SizedBox(height: 40),

                        // TOMBOL LOGIN
                        SizedBox(
                          width: double.infinity,
                          height: 60,
                          child: ElevatedButton(
                            onPressed: _isLoading ? null : _prosesLogin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: FluidColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: FluidColors.primary.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: _isLoading
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : const Text(
                                    "Masuk Sekarang",
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
