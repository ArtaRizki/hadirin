import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/core/service/notification_service.dart';
import 'package:hadirin/ui/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:intl/intl.dart'; // Tambahkan intl untuk formatting yang lebih mudah

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  bool _isLoading = false;
  final AttendanceService _attendanceService = AttendanceService();

  late Timer _timer;
  DateTime _currentTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  // Fungsi penentu sapaan berdasarkan jam
  String _getGreeting() {
    var hour = _currentTime.hour;
    if (hour < 11) return "Selamat Pagi,";
    if (hour < 15) return "Selamat Siang,";
    if (hour < 18) return "Selamat Sore,";
    return "Selamat Malam,";
  }

  // Format jam dengan detik (HH:mm:ss)
  String _formatFullTime(DateTime time) {
    return DateFormat('HH:mm:ss').format(time);
  }

  void _prosesAbsensi(String tipe) async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    var result = await _attendanceService.submitAbsen(
      idKaryawan: auth.idKaryawan ?? "UNKNOWN",
      namaKaryawan: auth.namaKaryawan ?? "UNKNOWN",
      tipeAbsen: tipe,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message'] ?? 'Terjadi kesalahan.'),
        backgroundColor: result['success'] == true
            ? FluidColors.primary
            : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FluidRadii.sm),
        ),
      ),
    );

    if (result['success'] == true) {
      NotificationService().showNotification(
        id: DateTime.now().millisecond,
        title: 'Absen $tipe Berhasil! ✅',
        body:
            'Terima kasih ${auth.namaKaryawan}, absen Anda telah tercatat pada ${_formatFullTime(DateTime.now())} WIB.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: FluidColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER (Sapaan Dinamis)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _getGreeting(), // Memanggil sapaan dinamis
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        auth.namaKaryawan ?? "Karyawan",
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: FluidColors.onSurface,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const ProfileScreen()),
                    ),
                    child: Hero(
                      tag: 'profile-avatar',
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: FluidColors.primaryGhost,
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: FluidColors.surfaceContainerLow,
                          child: Icon(
                            auth.isAdmin
                                ? Icons.admin_panel_settings
                                : Icons.person,
                            color: FluidColors.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: FluidSpacing.section),

              // KARTU UTAMA (Jam Digital + Detik)
              Expanded(
                child: Card(
                  color: FluidColors.surfaceContainerLow,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FluidRadii.sm),
                  ),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(32.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Jam Digital Besar + Detik
                        Text(
                          _formatFullTime(_currentTime),
                          style: const TextStyle(
                            fontSize: 68,
                            fontWeight: FontWeight.w800,
                            fontFeatures: [
                              FontFeature.tabularFigures(),
                            ], // Agar angka tidak goyang saat berganti
                            letterSpacing: -2,
                            color: FluidColors.primary,
                          ),
                        ),
                        Text(
                          DateFormat(
                            'EEEE, d MMMM yyyy',
                            'id_ID',
                          ).format(_currentTime),
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 48),

                        if (_isLoading)
                          const CircularProgressIndicator(
                            color: FluidColors.primary,
                          )
                        else ...[
                          // Tombol Masuk
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: FluidColors.primary,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    FluidRadii.md,
                                  ),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () => _prosesAbsensi("Masuk"),
                              child: const Text(
                                "Absen Masuk",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Tombol Pulang
                          SizedBox(
                            width: double.infinity,
                            height: 60,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(
                                foregroundColor: FluidColors.primary,
                                side: const BorderSide(
                                  color: FluidColors.primary,
                                  width: 2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    FluidRadii.md,
                                  ),
                                ),
                              ),
                              onPressed: () => _prosesAbsensi("Pulang"),
                              child: const Text(
                                "Absen Pulang",
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
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
