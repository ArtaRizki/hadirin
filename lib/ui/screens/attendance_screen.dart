import 'package:flutter/material.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/ui/screens/profile_screen.dart';
import 'package:provider/provider.dart';

// Sesuaikan path import ini jika struktur folder Anda berbeda
import '../../core/providers/auth_provider.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = false;
  final AttendanceService _attendanceService = AttendanceService();

  void _prosesAbsensi(String tipe) async {
    // 1. Munculkan loading spinner
    setState(() {
      _isLoading = true;
    });

    // 2. Baca data karyawan yang sedang login dari Provider
    // Menggunakan context.read karena kita berada di dalam fungsi (bukan di metode build)
    final auth = context.read<AuthProvider>();

    // 3. Panggil service untuk mengeksekusi biometrik, GPS, Kamera, dan kirim ke GAS
    var result = await _attendanceService.submitAbsen(
      idKaryawan: auth.idKaryawan ?? "UNKNOWN",
      namaKaryawan: auth.namaKaryawan ?? "UNKNOWN",
      tipeAbsen: tipe,
    );

    // 4. Hilangkan loading spinner
    if (!mounted) return;
    setState(() {
      _isLoading = false;
    });

    // 5. Tampilkan Notifikasi Hasil (SnackBar)
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Terjadi kesalahan tidak dikenal.'),
        backgroundColor: result['success'] == true ? Colors.green : Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Memantau perubahan data login (opsional di sini, tapi baik untuk memastikan UI ter-update)
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Absensi Karyawan"),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          // Tombol Profil di pojok kanan atas
          IconButton(
            icon: const Icon(Icons.account_circle, size: 30),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          const SizedBox(
            width: 8,
          ), // Memberikan jarak (margin) agar tidak terlalu mepet ke tepi layar
        ],
      ),
      body: Center(
        child: _isLoading
            // Tampilan saat proses loading absensi berjalan
            ? const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text("Memvalidasi biometrik & lokasi..."),
                ],
              )
            // Tampilan utama saat standby
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.fingerprint, size: 80, color: Colors.blue),
                  const SizedBox(height: 24),

                  // Menampilkan Nama Karyawan yang login
                  Text(
                    "Halo, ${auth.namaKaryawan ?? '-'}",
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "Silakan lakukan absensi hari ini",
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                  ),

                  const SizedBox(height: 50),

                  // Tombol Absen
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      ElevatedButton.icon(
                        onPressed: () => _prosesAbsensi("Masuk"),
                        icon: const Icon(Icons.login),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 8.0,
                          ),
                          child: Text(
                            "Absen Masuk",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green.shade100,
                          foregroundColor: Colors.green.shade900,
                          elevation: 2,
                        ),
                      ),
                      ElevatedButton.icon(
                        onPressed: () => _prosesAbsensi("Pulang"),
                        icon: const Icon(Icons.logout),
                        label: const Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 12.0,
                            horizontal: 8.0,
                          ),
                          child: Text(
                            "Absen Pulang",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange.shade100,
                          foregroundColor: Colors.orange.shade900,
                          elevation: 2,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
