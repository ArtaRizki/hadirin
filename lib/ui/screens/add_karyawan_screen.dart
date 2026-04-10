import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // TAMBAHAN IMPORT
import 'package:hadirin/core/providers/auth_provider.dart'; // TAMBAHAN IMPORT
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';

class AddKaryawanScreen extends StatefulWidget {
  const AddKaryawanScreen({super.key});

  @override
  State<AddKaryawanScreen> createState() => _AddKaryawanScreenState();
}

class _AddKaryawanScreenState extends State<AddKaryawanScreen> {
  final _idController = TextEditingController();
  final _namaController = TextEditingController();
  final _divisiController = TextEditingController();
  bool _isLoading = false;

  void _simpanKaryawan() async {
    if (_idController.text.isEmpty || _namaController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("ID dan Nama Karyawan wajib diisi!")),
      );
      return;
    }

    setState(() => _isLoading = true);

    // BACA ID ADMIN UMKM YANG SEDANG LOGIN
    final auth = context.read<AuthProvider>();
    final clientId = auth.idUser ?? "";

    final result = await AttendanceService().tambahKaryawan(
      clientId: clientId, // KIRIM CLIENT ID KE SERVICE
      idKaryawanBaru: _idController.text.trim(),
      namaKaryawanBaru: _namaController.text.trim(),
      divisi: _divisiController.text.trim().isEmpty
          ? "-"
          : _divisiController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: result['success'] ? FluidColors.primary : Colors.red,
        ),
      );
      if (result['success']) {
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FluidColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: FluidColors.onSurface),
        title: const Text(
          "Tambah Karyawan Baru",
          style: TextStyle(
            color: FluidColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          Card(
            color: FluidColors.surfaceContainerLow,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FluidRadii.md),
            ),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  TextField(
                    controller: _idController,
                    decoration: const InputDecoration(
                      labelText: "ID Karyawan (Contoh: KRY-001)",
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _namaController,
                    decoration: const InputDecoration(
                      labelText: "Nama Lengkap",
                      prefixIcon: Icon(Icons.person),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _divisiController,
                    decoration: const InputDecoration(
                      labelText: "Divisi / Jabatan (Opsional)",
                      prefixIcon: Icon(Icons.work),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _simpanKaryawan,
              style: ElevatedButton.styleFrom(
                backgroundColor: FluidColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FluidRadii.sm),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Simpan Data Karyawan",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
