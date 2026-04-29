import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/admin_service.dart';
import 'package:provider/provider.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:hadirin/core/config/app_config.dart';
import 'package:hadirin/ui/screens/admin_register_screen.dart';
import 'package:hadirin/ui/screens/attendance_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _kodeInstansiController = TextEditingController();
  final _idController = TextEditingController();
  bool _isLoading = false;

  void _prosesLogin() async {
    final inputKodeInstansi = _kodeInstansiController.text.trim().toUpperCase();
    final inputId = _idController.text.trim();

    // ========================================================
    // FLOW 1: JALUR RAHASIA SUPER ADMIN (API VALIDATION)
    // ========================================================
    if (inputKodeInstansi.isEmpty && inputId.isNotEmpty) {
      setState(() => _isLoading = true);

      final superResult = await AdminService().verifySuperAdmin(inputId);

      if (superResult['success']) {
        await context.read<AuthProvider>().login(
          "SUPER_ADMIN",
          "Owner ${AppConfig.appName}",
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

      // Jika ternyata bukan super admin namun kode Instansi kosong,
      // biarkan program lanjut ke validasi normal di bawah
      // (yang akan menampilkan error "Kode Instansi wajib diisi")
      setState(() => _isLoading = false);
    }
    // ========================================================
    // FLOW 2: VALIDASI LOGIN NORMAL
    // ========================================================
    if (inputKodeInstansi.isEmpty) {
      _showError("Kode Instansi wajib diisi!");
      return;
    }
    if (inputId.isEmpty) {
      _showError("ID Pengguna tidak boleh kosong!");
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await AdminService().enrollDevice(
        inputKodeInstansi,
        inputId,
      );

      if (result['success']) {
        final dataAnggota = result['message'];
        final clientIdDariServer = dataAnggota['client_id'];
        final divisi = (dataAnggota['divisi'] ?? "").toString().toUpperCase();
        final nama = (dataAnggota['nama_karyawan'] ?? "")
            .toString()
            .toUpperCase();

        final roleAkses = (dataAnggota['role_akses'] ?? "").toString().toUpperCase();

        // Logika penentuan role:
        // Admin jika ID diawali INST-/ADM-/ADMIN- ATAU Divisi/Nama/Role mengandung kata ADMIN/PEMILIK
        bool isIdAdmin =
            inputId.toUpperCase().startsWith("INST-") ||
            inputId.toUpperCase().startsWith("ADM-") ||
            inputId.toUpperCase().startsWith("ADMIN-");

        bool isRoleAdmin =
            divisi.contains("ADMIN") ||
            divisi.contains("PEMILIK") ||
            nama.contains("ADMIN") ||
            nama.contains("PEMILIK") ||
            roleAkses == "ADMIN";

        LoginRole assignedRole = (isIdAdmin || isRoleAdmin)
            ? LoginRole.admin
            : LoginRole.anggota;

        await context.read<AuthProvider>().login(
          inputId,
          dataAnggota['nama_karyawan'],
          assignedRole,
          clientIdDariServer,
          userPhone: (dataAnggota['no_hp'] ?? "").toString(),
          adminPhone: (dataAnggota['admin_phone'] ?? "").toString(),
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const AttendanceScreen()),
        );
      } else {
        String serverMsg = result['message'].toString();
        if (serverMsg.contains("Kode Instansi") &&
            inputKodeInstansi.contains("MASTER")) {
          serverMsg +=
              "\n\nPetunjuk: Kosongkan kotak pertama untuk login Super Admin.";
        }
        _showError(serverMsg);
      }
    } catch (e) {
      String errorMsg = e.toString().replaceAll('Exception: ', '');
      if (errorMsg.contains("Kode Instansi") &&
          inputKodeInstansi.contains("MASTER")) {
        errorMsg +=
            "\n\nPetunjuk: Kosongkan kotak pertama untuk login Super Admin.";
      }
      _showError("Gagal terhubung ke server: $errorMsg");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error_outline, color: Colors.white),
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
                  color: context.primaryColor.withOpacity(0.06),
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
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: context.primaryColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Image.asset(
                              AppConfig.appLogo,
                              width: 86,
                              height: 86,
                              fit: BoxFit.contain,
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
                          AppConfig.appName,
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

                        // FIELD 1: KODE INSTANSI
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
                            controller: _kodeInstansiController,
                            textCapitalization: TextCapitalization.characters,
                            decoration: InputDecoration(
                              labelText: "Kode Instansi",
                              hintText: "Contoh: INST-123456",
                              labelStyle: TextStyle(
                                color: Colors.grey.shade500,
                              ),
                              prefixIcon: Icon(
                                Icons.business_rounded,
                                color: context.primaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.primaryColor,
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
                              prefixIcon: Icon(
                                Icons.badge_rounded,
                                color: context.primaryColor,
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(
                                  color: context.primaryColor,
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
                              backgroundColor: context.primaryColor,
                              foregroundColor: Colors.white,
                              elevation: 4,
                              shadowColor: context.primaryColor.withOpacity(
                                0.4,
                              ),
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
