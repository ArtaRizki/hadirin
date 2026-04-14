import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:provider/provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  String _statusText = "Memuat sistem...";

  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    // Setup Animasi Denyut (Pulse)
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _scaleAnimation = Tween<double>(begin: 0.95, end: 1.05).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _initializeApp();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeApp() async {
    // Minimum delay agar pengguna sempat melihat animasi splash yang bagus (UX Trick)
    await Future.delayed(const Duration(milliseconds: 1500));

    // 1. Meminta Izin Akses (Lokasi & Kamera)
    if (mounted)
      setState(() => _statusText = "Memeriksa perizinan perangkat...");
    await _requestPermissions();

    // 2. Lanjut mengecek sesi login (RootNavigator yang akan memindahkan layar)
    if (mounted) setState(() => _statusText = "Memeriksa sesi pengguna...");

    if (mounted) {
      await context.read<AuthProvider>().checkLoginStatus();
    }
  }

  Future<void> _requestPermissions() async {
    // List izin yang wajib untuk aplikasi absensi
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.camera,
    ].request();

    if (statuses[Permission.location]!.isDenied ||
        statuses[Permission.camera]!.isDenied) {
      debugPrint("Beberapa izin ditolak oleh pengguna.");
    }

    if (statuses[Permission.location]!.isPermanentlyDenied) {
      openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF), // Latar modern yang seragam
      body: SafeArea(
        child: Stack(
          children: [
            // Dekorasi blob atas kanan
            Positioned(
              top: -100,
              right: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.primaryColor.withOpacity(0.06),
                ),
              ),
            ),
            // Dekorasi blob bawah kiri
            Positioned(
              bottom: -100,
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
        
            // KONTEN UTAMA
            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(flex: 3),
        
                  // LOGO ANIMASI
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      padding: const EdgeInsets.all(28),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: context.primaryColor.withOpacity(0.15),
                            blurRadius: 30,
                            spreadRadius: 10,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.fingerprint_rounded,
                          size: 72,
                          color: context.primaryColor,
                        ),
                      ),
                    ),
                  ),
        
                  const SizedBox(height: 32),
        
                  // NAMA BRAND
                  const Text(
                    "Hadir.in",
                    style: TextStyle(
                      fontSize: 36,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sistem Absensi & HRIS Terintegrasi",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.grey.shade600,
                    ),
                  ),
        
                  const Spacer(flex: 2),
        
                  // LOADING INDICATOR
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: context.primaryColor,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 16),
        
                  // STATUS TEXT
                  Text(
                    _statusText,
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(flex: 1),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
