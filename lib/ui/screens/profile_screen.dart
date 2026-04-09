import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text(
          "Apakah Anda yakin ingin keluar? Sesi Anda akan dihapus dari perangkat ini dan Anda harus mendaftarkan ulang Device ID jika ingin absen dari HP ini lagi.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext), // Tutup dialog
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              // 1. Tutup dialog konfirmasi
              Navigator.pop(dialogContext);

              // 2. Hapus data sesi menggunakan Provider
              await context.read<AuthProvider>().logout();

              // 3. Kembali ke layar sebelumnya (root).
              // Karena state AuthProvider berubah, RootNavigator di main.dart
              // akan otomatis langsung mengganti layar menjadi SplashScreen/LoginScreen.
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: const Text("Ya, Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Membaca data state dari Provider
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil Karyawan"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircleAvatar(
                radius: 60,
                backgroundColor: Colors.blue,
                child: Icon(Icons.person, size: 80, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Text(
                auth.namaKaryawan ?? "Nama Tidak Ditemukan",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  "ID: ${auth.idKaryawan ?? '-'}",
                  style: const TextStyle(fontSize: 16, color: Colors.black54),
                ),
              ),
              const SizedBox(height: 40),

              // Tombol Logout Utama
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: () => _showLogoutDialog(context),
                  icon: const Icon(Icons.logout),
                  label: const Text(
                    "Logout / Ganti Perangkat",
                    style: TextStyle(fontSize: 16),
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
