import 'package:flutter/material.dart';
import 'package:hadirin/core/service/admin_service.dart';
import 'package:provider/provider.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';

class AddAnggotaScreen extends StatefulWidget {
  const AddAnggotaScreen({super.key});

  @override
  State<AddAnggotaScreen> createState() => _AddAnggotaScreenState();
}

class _AddAnggotaScreenState extends State<AddAnggotaScreen> {
  final _idController = TextEditingController();
  final _namaController = TextEditingController();
  final _bagianController = TextEditingController();
  bool _isLoading = false;

  void _simpanAnggota() async {
    if (_idController.text.isEmpty || _namaController.text.isEmpty) {
      _showSnackBar("ID dan Nama Anggota wajib diisi!", isError: true);
      return;
    }

    setState(() => _isLoading = true);

    // BACA ID ADMIN INSTANSI YANG SEDANG LOGIN
    final auth = context.read<AuthProvider>();
    final clientId = auth.idUser ?? "";

    final result = await AdminService().tambahAnggota(
      clientId: clientId,
      idAnggotaBaru: _idController.text.trim(),
      namaAnggotaBaru: _namaController.text.trim(),
      bagian: _bagianController.text.trim().isEmpty
          ? "-"
          : _bagianController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      _showSnackBar(result['message'], isError: !result['success']);

      if (result['success']) {
        Navigator.pop(context);
      }
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: isError
            ? Colors.red.shade600
            : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF), // Latar belakang seragam
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A),
                size: 16,
              ),
            ),
          ),
        ),
        title: const Text(
          "Tambah Anggota",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Dekorasi blob atas kanan
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
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
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED).withOpacity(0.05),
                ),
              ),
            ),

            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                children: [
                  // HEADER SECTION
                  const Text(
                    "Informasi Anggota",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Masukkan detail data diri anggota baru ke dalam sistem Instansi Anda.",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // FORM INPUTS
                  _buildInputField(
                    controller: _idController,
                    label: "ID Anggota",
                    hint: "Contoh: AGT-001",
                    icon: Icons.badge_rounded,
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    controller: _namaController,
                    label: "Nama Lengkap",
                    hint: "Sesuai KTP / Panggilan",
                    icon: Icons.person_rounded,
                  ),
                  const SizedBox(height: 20),

                  _buildInputField(
                    controller: _bagianController,
                    label: "Bagian / Jabatan",
                    hint: "Opsional (Contoh: Guru, Staf)",
                    icon: Icons.work_outline_rounded,
                  ),

                  const SizedBox(height: 48),

                  // SUBMIT BUTTON
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _simpanAnggota,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: context.primaryColor.withOpacity(0.4),
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
                              "Simpan Data Anggota",
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
          ],
        ),
      ),
    );
  }

  // Fungsi Pembantu untuk membuat TextField agar kode lebih rapi (DRY)
  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return Container(
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
        controller: controller,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          labelStyle: TextStyle(color: Colors.grey.shade500),
          prefixIcon: Icon(icon, color: context.primaryColor),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: context.primaryColor, width: 1.5),
          ),
          filled: true,
          fillColor: Colors.white,
        ),
      ),
    );
  }
}
