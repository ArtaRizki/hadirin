import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/core/service/notification_service.dart';
import 'package:hadirin/ui/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:intl/intl.dart';

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

  // =================================================================
  // 1. FUNGSI CEK STATUS CUTI HARI INI
  // =================================================================
  Future<bool> _cekStatusIzin(String idKaryawan) async {
    try {
      final history = await _attendanceService.getHistory(idKaryawan);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      for (var log in history) {
        final tipe = log['tipe'].toString();
        final status = log['status'].toString();

        if ((tipe == 'Cuti' || tipe == 'Izin' || tipe == 'Sakit') &&
            status == 'Disetujui') {
          final rentang = log['lat_long'].toString();

          RegExp dateRegex = RegExp(r'\d{4}-\d{2}-\d{2}');
          final matches = dateRegex.allMatches(rentang).toList();

          if (matches.length >= 2) {
            final startDt = DateTime.parse(matches[0].group(0)!);
            final endDt = DateTime.parse(matches[1].group(0)!);

            final startDate = DateTime(
              startDt.year,
              startDt.month,
              startDt.day,
            );
            final endDate = DateTime(endDt.year, endDt.month, endDt.day);

            if (today.compareTo(startDate) >= 0 &&
                today.compareTo(endDate) <= 0) {
              return true;
            }
          } else if (matches.length == 1) {
            final dateDt = DateTime.parse(matches[0].group(0)!);
            final dateDate = DateTime(dateDt.year, dateDt.month, dateDt.day);
            if (today.isAtSameMomentAs(dateDate)) return true;
          }
        }
      }
    } catch (e) {
      debugPrint("Gagal mengecek status cuti: $e");
    }
    return false;
  }

  // =================================================================
  // 2. FUNGSI PEMBUNGKUS TOMBOL ABSEN (SOFT BLOCK DIALOG)
  // =================================================================
  void _konfirmasiAbsen(String tipeAbsen) async {
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final idKaryawan = auth.idKaryawan ?? "";

    bool sedangCuti = await _cekStatusIzin(idKaryawan);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (sedangCuti) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FluidRadii.md),
          ),
          title: Row(
            children: const [
              Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
              SizedBox(width: 8),
              Text(
                "Status Cuti Aktif",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
            ],
          ),
          content: Text(
            "Anda terdaftar sedang Cuti/Izin/Sakit hari ini dan sudah disetujui oleh Admin.\n\nApakah Anda yakin ingin membatalkan status tersebut dan tetap melakukan Absen $tipeAbsen?",
            style: const TextStyle(height: 1.5),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Batal Absen",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: FluidColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                Navigator.pop(context);
                _prosesAbsensi(tipeAbsen); // <-- SUDAH MEMANGGIL PROSES ABSEN
              },
              child: const Text("Tetap Absen"),
            ),
          ],
        ),
      );
    } else {
      _prosesAbsensi(tipeAbsen); // <-- SUDAH MEMANGGIL PROSES ABSEN
    }
  }

  // =================================================================
  // 3. FUNGSI INTI: MENGIRIM ABSENSI KE SERVER
  // =================================================================
  void _prosesAbsensi(String tipeAbsen) async {
    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final idKaryawan = auth.idKaryawan ?? "";
    final namaKaryawan = auth.namaKaryawan ?? "";

    final result = await _attendanceService.submitAbsen(
      idKaryawan: idKaryawan,
      namaKaryawan: namaKaryawan,
      tipeAbsen: tipeAbsen,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      // Munculkan Notifikasi Sistem
      NotificationService().showNotification(
        id: DateTime.now().millisecond,
        title: "Absen $tipeAbsen Berhasil",
        body: "Terima kasih, absen $tipeAbsen Anda telah tercatat disistem.",
      );

      // Munculkan Pop-up Bawah
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 5), // Tahan lebih lama untuk dibaca
        ),
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
                        _getGreeting(),
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
                            fontFeatures: [FontFeature.tabularFigures()],
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
                              onPressed: () => _konfirmasiAbsen("Masuk"),
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
                              onPressed: () => _konfirmasiAbsen("Pulang"),
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
