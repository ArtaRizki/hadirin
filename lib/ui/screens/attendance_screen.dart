import 'dart:async';
import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/core/service/admin_service.dart';
import 'package:hadirin/core/service/notification_service.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hadirin/ui/screens/profile_screen.dart';
import 'package:provider/provider.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:intl/intl.dart';
import 'package:hadirin/core/service/school_service.dart';
import 'package:hadirin/core/models/school_models.dart';
import 'package:hadirin/core/utils/url_helper.dart';

class AttendanceScreen extends StatefulWidget {
  const AttendanceScreen({super.key});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = false;
  final AttendanceService _attendanceService = AttendanceService();
  final SchoolService _schoolService = SchoolService();

  List<BannerModel> _banners = [];
  bool _isBannersLoading = true;
  final PageController _bannerPageCtrl = PageController();
  int _currentBannerPage = 0;
  Timer? _carouselTimer;

  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  StreamSubscription<Position>? _positionStream;

  // Variabel Jam Kerja Dinamis (Default sesuai req)
  String _jamMasukMulai = "04:00";
  String _batasJamMasuk = "07:00";
  String _jamPulangMulai = "13:00";
  bool _isConfigLoaded = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() => _currentTime = DateTime.now());
    });
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Mulai pantau lokasi & fetch config jam
    _fetchOfficeConfig();
    _fetchBanners();
    _syncFaceStatus(); // Tambahkan sinkronisasi wajah
    _startProximityListener();
  }

  // Fungsi sinkronisasi status wajah dari server
  Future<void> _syncFaceStatus() async {
    try {
      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn || !auth.isAnggota) return;

      final isRegisteredOnServer = await _attendanceService.faceService
          .syncFaceRegistrationStatus(
            auth.idAnggota ?? "",
            auth.clientId ?? "",
          );

      if (isRegisteredOnServer != auth.isFaceRegistered) {
        await auth.setFaceRegistered(isRegisteredOnServer);
        debugPrint("==== FACE STATUS SYNCED: $isRegisteredOnServer ====");
      }
    } catch (e) {
      debugPrint("Gagal sinkronisasi wajah: $e");
    }
  }

  void _startCarousel() {
    _carouselTimer?.cancel();
    if (_banners.length <= 1) return;
    _carouselTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_bannerPageCtrl.hasClients) return;
      final next = (_currentBannerPage + 1) % _banners.length;
      _bannerPageCtrl.animateToPage(
        next,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _fetchBanners({bool force = false}) async {
    try {
      final auth = context.read<AuthProvider>();
      final banners =
          await _schoolService.getBanners(auth.clientId ?? "", forceRefresh: force);
      if (mounted) {
        setState(() {
          _banners = banners;
          _isBannersLoading = false;
        });
        _startCarousel();
      }
    } catch (e) {
      if (mounted) setState(() => _isBannersLoading = false);
    }
  }

  Future<void> _fetchOfficeConfig({bool force = false}) async {
    try {
      final auth = context.read<AuthProvider>();
      final config =
          await AdminService().getOfficeConfig(auth.clientId ?? "", forceRefresh: force);
      if (config != null && mounted) {
        setState(() {
          _jamMasukMulai = config['jam_masuk_mulai']?.toString() == "null"
              ? "-"
              : (config['jam_masuk_mulai']?.toString() ?? "-");
          _batasJamMasuk = config['batas_jam_masuk']?.toString() == "null"
              ? "-"
              : (config['batas_jam_masuk']?.toString() ?? "-");
          _jamPulangMulai = config['jam_pulang_mulai']?.toString() == "null"
              ? "-"
              : (config['jam_pulang_mulai']?.toString() ?? "-");
          _isConfigLoaded = true;
        });
      }
    } catch (e) {
      debugPrint("Gagal fetch config jam: $e");
    }
  }

  bool _hasNotifiedProximity = false;

  int _timeToMinutes(String s) {
    try {
      final parts = s.split(':');
      return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
    } catch (e) {
      return 0;
    }
  }

  void _startProximityListener() async {
    try {
      // Pastikan izin sudah ada
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever)
        return;

      final auth = context.read<AuthProvider>();
      if (!auth.isLoggedIn || !auth.isAnggota) return;

      final config = await AdminService().getOfficeConfig(auth.clientId ?? "");
      if (config == null) return;

      double offLat = double.parse(config['lat'].toString());
      double offLng = double.parse(config['lng'].toString());
      double radius = double.parse(config['radius'].toString());

      _positionStream =
          Geolocator.getPositionStream(
            locationSettings: const LocationSettings(
              accuracy: LocationAccuracy.high,
              distanceFilter: 10, // Update setiap 10 meter
            ),
          ).listen((Position pos) {
            double distance = Geolocator.distanceBetween(
              pos.latitude,
              pos.longitude,
              offLat,
              offLng,
            );

            if (distance <= radius && !_hasNotifiedProximity) {
              NotificationService().showNotification(
                id: 999,
                title: "Sudah Sampai di Lokasi?📍",
                body:
                    "Anda sudah berada dalam radius Instansi. Yuk, segera lakukan Absen Masuk!",
              );
              _hasNotifiedProximity = true;
            } else if (distance > radius + 20) {
              // Reset flag kalau user keluar radius (beri buffer 20m)
              // agar bisa notif lagi kalau masuk lagi
              _hasNotifiedProximity = false;
            }
          });
    } catch (e) {
      debugPrint("Proximity listener failed: $e");
    }
  }

  @override
  void dispose() {
    _timer.cancel();
    _carouselTimer?.cancel();
    _bannerPageCtrl.dispose();
    _pulseController.dispose();
    _positionStream?.cancel();
    super.dispose();
  }

  String _getGreeting() {
    var hour = _currentTime.hour;
    if (hour < 11) return "Selamat Pagi";
    if (hour < 15) return "Selamat Siang";
    if (hour < 18) return "Selamat Sore";
    return "Selamat Malam";
  }

  Future<bool> _cekStatusIzin(String idAnggota, String clientId) async {
    try {
      // Menggunakan endpoint khusus agar lebih ringan dan cepat
      return await _attendanceService.cekStatusCutiHariIni(idAnggota, clientId);
    } catch (e) {
      debugPrint("Gagal mengecek status cuti: $e");
    }
    return false;
  }

  // =================================================================
  // 2. FUNGSI PEMBUNGKUS TOMBOL ABSEN (DENGAN TIME-FENCING)
  // =================================================================
  void _konfirmasiAbsen(String tipeAbsen) async {
    if (_isLoading) return;

    final now = DateTime.now();
    final currentMinutes = (now.hour * 60) + now.minute;

    // --- VALIDASI JAM OPERASIONAL (TIME-FENCING DINAMIS) ---
    if (tipeAbsen == "Masuk") {
      final startMin = _timeToMinutes(_jamMasukMulai);
      final endMin = _timeToMinutes(_jamPulangMulai);

      if (currentMinutes < startMin || currentMinutes >= endMin) {
        _showSnackBar(
          "Gagal! Absen Masuk hanya tersedia pukul $_jamMasukMulai - $_jamPulangMulai.",
          isError: true,
        );
        return;
      }
    } else {
      final pulangMin = _timeToMinutes(_jamPulangMulai);
      if (currentMinutes < pulangMin) {
        _showSnackBar(
          "Belum saatnya pulang! Absen Pulang dibuka mulai pukul $_jamPulangMulai.",
          isError: true,
        );
        return;
      }
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final idAnggota = auth.idAnggota ?? "";

    bool sedangCuti = await _cekStatusIzin(idAnggota, auth.clientId ?? "");

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (sedangCuti) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange.shade600,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Status Cuti Aktif",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
              ),
            ],
          ),
          content: Text(
            "Anda terdaftar sedang Cuti/Izin/Sakit hari ini dan sudah disetujui.\n\nApakah Anda yakin ingin tetap melakukan Absen $tipeAbsen?",
            style: TextStyle(
              color: Colors.grey.shade600,
              height: 1.6,
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Batal",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.pop(context);
                _prosesAbsensi(tipeAbsen);
              },
              child: const Text("Tetap Absen"),
            ),
          ],
        ),
      );
    } else {
      _prosesAbsensi(tipeAbsen);
    }
  }

  // =================================================================
  // 3. FUNGSI INTI: MENGIRIM ABSENSI KE SERVER
  // =================================================================
  void _prosesAbsensi(String tipeAbsen) async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    final result = await _attendanceService.submitAbsen(
      idAnggota: auth.idAnggota ?? "",
      namaAnggota: auth.namaAnggota ?? "",
      tipeAbsen: tipeAbsen,
      clientId: auth.clientId ?? "",
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result['success']) {
      NotificationService().showNotification(
        id: DateTime.now().millisecond,
        title: "Absen $tipeAbsen Berhasil",
        body: "Terima kasih, absen $tipeAbsen Anda telah tercatat.",
      );
      _showSnackBar(result['message'], isError: false);
    } else {
      _showSnackBar(result['message'], isError: true);
    }
  }

  void _showSnackBar(String msg, {required bool isError}) {
    // Beri waktu lebih lama untuk pesan error panjang (seperti deteksi Root/Fake GPS)
    final int durationInSeconds = isError ? (msg.length > 50 ? 8 : 5) : 3;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError ? Icons.error_outline : Icons.check_circle_outline,
              color: Colors.white,
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        duration: Duration(seconds: durationInSeconds),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      body: SafeArea(
        child: Stack(
          children: [
            // Dekorasi Background Blobs
            Positioned(
              top: -70,
              right: -50,
              child: Container(
                width: 230,
                height: 230,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.primaryColor.withOpacity(0.09),
                ),
              ),
            ),
            Positioned(
              bottom: -50,
              left: -40,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED).withOpacity(0.06),
                ),
              ),
            ),

            SafeArea(
              child: RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    _fetchBanners(force: true),
                    _fetchOfficeConfig(force: true),
                  ]);
                },
                color: context.primaryColor,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 20.0,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // HEADER PROFILE
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    AnimatedBuilder(
                                      animation: _pulseAnimation,
                                      builder: (_, __) => Transform.scale(
                                        scale: _pulseAnimation.value,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            color: const Color(0xFF16A34A),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFF16A34A,
                                                ).withOpacity(0.4),
                                                blurRadius: 6,
                                                spreadRadius: 2,
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      _getGreeting(),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.grey.shade500,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  auth.namaAnggota ?? "Anggota",
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFF0F172A),
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ),
                            child: Hero(
                              tag: 'profile-avatar',
                              child: Container(
                                padding: const EdgeInsets.all(3),
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: LinearGradient(
                                    colors: [
                                      context.primaryColor,
                                      context.primaryColor.withOpacity(0.5),
                                    ],
                                  ),
                                ),
                                child: CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.white,
                                  child: Icon(
                                    Icons.person_rounded,
                                    color: context.primaryColor,
                                    size: 24,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),

                      if (auth.isAnggota && !auth.isFaceRegistered)
                        Padding(
                          padding: const EdgeInsets.only(top: 20),
                          child: GestureDetector(
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const ProfileScreen(),
                              ),
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    Colors.orange.shade400,
                                    Colors.orange.shade600,
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.orange.withOpacity(0.3),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  ),
                                ],
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.face_retouching_natural_rounded,
                                      color: Colors.white,
                                      size: 20,
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  const Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          "Wajah Belum Terdaftar",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 14,
                                          ),
                                        ),
                                        Text(
                                          "Klik untuk daftarkan wajah agar bisa absen.",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(
                                    Icons.chevron_right_rounded,
                                    color: Colors.white,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                      const SizedBox(height: 16),

                      // CLOCK CARD
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [auth.themeColor, const Color(0xFF7C3AED)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(28),
                          boxShadow: [
                            BoxShadow(
                              color: context.primaryColor.withOpacity(0.32),
                              blurRadius: 32,
                              offset: const Offset(0, 16),
                            ),
                          ],
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(
                                  DateFormat('HH:mm').format(_currentTime),
                                  style: TextStyle(
                                    fontSize: 76,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    letterSpacing: -4,
                                    height: 1.0,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(
                                    bottom: 10,
                                    left: 6,
                                  ),
                                  child: Text(
                                    DateFormat('ss').format(_currentTime),
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white.withOpacity(0.45),
                                      fontFeatures: const [
                                        FontFeature.tabularFigures(),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 18),
                            Divider(color: Colors.white.withOpacity(0.2)),
                            const SizedBox(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.calendar_today_rounded,
                                  size: 14,
                                  color: Colors.white.withOpacity(0.65),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  DateFormat(
                                    'EEEE, d MMMM yyyy',
                                    'id_ID',
                                  ).format(_currentTime),
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                            if (_isConfigLoaded) ...[
                              const SizedBox(height: 12),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Column(
                                  children: [
                                    const Text(
                                      "Jam Kerja",
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 13,
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Masuk: $_jamMasukMulai | Batas: $_batasJamMasuk | Pulang: $_jamPulangMulai",
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),

                      // =================================================================
                      // 1. BANNER PENGUMUMAN (DASHBOARD)
                      // =================================================================
                      const SizedBox(height: 24),
                      _buildBannerSection(),

                      const SizedBox(height: 20),

                      // TOMBOL ABSEN
                      if (_isLoading)
                        Center(
                          child: CircularProgressIndicator(
                            color: context.primaryColor,
                            strokeWidth: 3,
                          ),
                        )
                      else ...[
                        GestureDetector(
                          onTap: () => _konfirmasiAbsen("Masuk"),
                          child: Container(
                            width: double.infinity,
                            height: 62,
                            decoration: BoxDecoration(
                              color: context.primaryColor,
                              borderRadius: BorderRadius.circular(18),
                              boxShadow: [
                                BoxShadow(
                                  color: context.primaryColor.withOpacity(0.35),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: const Center(
                              child: Text(
                                "Absen Masuk",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        GestureDetector(
                          onTap: () => _konfirmasiAbsen("Pulang"),
                          child: Container(
                            width: double.infinity,
                            height: 62,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.red.shade200,
                                width: 1.5,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                "Absen Pulang",
                                style: TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.red.shade600,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showBannerDialog(BannerModel banner) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            // Gambar fullscreen
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                UrlHelper.getDirectDriveUrl(banner.urlGambar),
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        height: 200,
                        child: Center(
                          child: CircularProgressIndicator(color: Colors.white),
                        ),
                      ),
              ),
            ),
            // Judul di bawah
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.85),
                      Colors.transparent,
                    ],
                  ),
                ),
                child: Text(
                  banner.judul,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            // Tombol tutup
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.close_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBannerSection() {
    if (_isBannersLoading) {
      return SizedBox(
        height: 168,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
        ),
      );
    }

    if (_banners.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Pengumuman Sekolah",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Color(0xFF1E293B),
          ),
        ),
        const SizedBox(height: 12),
        // ── Carousel ──
        SizedBox(
          height: 168,
          child: PageView.builder(
            controller: _bannerPageCtrl,
            itemCount: _banners.length,
            onPageChanged: (i) => setState(() => _currentBannerPage = i),
            itemBuilder: (context, index) {
              final banner = _banners[index];
              return GestureDetector(
                onTap: () => _showBannerDialog(banner),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Gambar
                        Image.network(
                          UrlHelper.getDirectDriveUrl(banner.urlGambar),
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey.shade200,
                            child: Icon(
                              Icons.broken_image_rounded,
                              color: Colors.grey.shade400,
                              size: 40,
                            ),
                          ),
                        ),
                        // Gradient overlay
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [
                                Colors.black.withValues(alpha: 0.65),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                        // Judul
                        Positioned(
                          bottom: 14,
                          left: 16,
                          right: 16,
                          child: Text(
                            banner.judul,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              shadows: [
                                Shadow(blurRadius: 4, color: Colors.black45),
                              ],
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        // Tap hint icon
                        Positioned(
                          top: 10,
                          right: 12,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.open_in_full_rounded,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // ── Dot Indicator ──
        if (_banners.length > 1) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              _banners.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: _currentBannerPage == i ? 20 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: _currentBannerPage == i
                      ? context.primaryColor
                      : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }
}
