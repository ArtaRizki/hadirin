import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/admin_service.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/core/service/export_service.dart';
import 'package:hadirin/core/service/face_service.dart';
import 'package:hadirin/ui/screens/add_anggota_screen.dart';
import 'package:hadirin/ui/screens/approval_screen.dart';
import 'package:hadirin/ui/screens/login_screen.dart';
import 'package:hadirin/ui/screens/set_location_screen.dart';
import 'package:hadirin/ui/widgets/custom_date_range_picker.dart';
import 'package:provider/provider.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hadirin/ui/widgets/skeleton_loader.dart';
import 'package:hadirin/core/utils/url_helper.dart';
import 'package:hadirin/ui/screens/leave_request_screen.dart';
import 'package:hadirin/ui/screens/anggota_list_screen.dart';
import 'package:hadirin/ui/widgets/attendance_history_list.dart';
import 'package:hadirin/ui/screens/leave_history_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _service = FaceService();
  bool _isLoading = true;
  bool _isRegisteringFace = false;
  bool _isExporting = false;
  String _errorMsg = "";

  List<dynamic> _allHistory = [];
  List<dynamic> _filteredHistory = [];
  String _filterTipe = "Semua";
  DateTimeRange? _selectedDateRange;
  List<dynamic> _listAnggotaStats = [];
  bool _isLoadingStats = false;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _fetchHistory();
      if (context.read<AuthProvider>().isAdmin) {
        _fetchStats();
      }
    });
  }

  Future<void> _fetchStats() async {
    setState(() => _isLoadingStats = true);
    try {
      final auth = context.read<AuthProvider>();
      final data = await AdminService().getAllAnggota(auth.clientId ?? "");
      setState(() {
        _listAnggotaStats = data;
        _isLoadingStats = false;
      });
    } catch (e) {
      debugPrint("Gagal fetch stats: $e");
      setState(() => _isLoadingStats = false);
    }
  }

  Future<void> _fetchHistory() async {
    final auth = context.read<AuthProvider>();
    if (auth.idAnggota == null) return;
    try {
      final data = await AttendanceService().getHistory(
        auth.idAnggota!,
        auth.clientId ?? "",
      );
      setState(() {
        _allHistory = data;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleRefresh() async {
    final auth = context.read<AuthProvider>();
    if (auth.isAdmin) {
      await Future.wait([_fetchHistory(), _fetchStats()]);
    } else {
      await _fetchHistory();
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredHistory = _allHistory.where((log) {
        bool passTipe = _filterTipe == "Semua" || log['tipe'] == _filterTipe;
        bool passTanggal = true;
        if (_selectedDateRange != null && log['waktu'] != null) {
          final dt = DateTime.tryParse(log['waktu'].toString())?.toLocal();
          if (dt != null) {
            final logDate = DateTime(dt.year, dt.month, dt.day);
            final s = _selectedDateRange!.start;
            final e = _selectedDateRange!.end;
            passTanggal =
                !logDate.isBefore(DateTime(s.year, s.month, s.day)) &&
                !logDate.isAfter(DateTime(e.year, e.month, e.day));
          }
        }
        return passTipe && passTanggal;
      }).toList();
    });
  }

  // =================================================================
  // REDESIGN KALENDER (DATE RANGE PICKER)
  // =================================================================
  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showCustomDateRangePicker(
      context: context,
      initialDateRange: _selectedDateRange,
    );
    if (picked != null) {
      setState(() => _selectedDateRange = picked);
      _applyFilter();
    }
  }

  String _formatTanggalIndo(DateTime dt) =>
      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);

  String _formatJam(DateTime dt) => DateFormat('HH:mm').format(dt);

  void _tampilkanFoto(
    BuildContext context,
    String url,
    String tipe,
    String waktu,
  ) {
    final auth = context.read<AuthProvider>();
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              child: Image.network(
                UrlHelper.getDirectUrl(url),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return SizedBox(
                    height: 200,
                    child: Center(
                      child: CircularProgressIndicator(color: auth.themeColor),
                    ),
                  );
                },
                errorBuilder: (_, __, ___) => const SizedBox(
                  height: 200,
                  child: Center(child: Text("Gagal memuat foto.")),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Text(
                    "Bukti Foto Absen $tipe",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    waktu,
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Tutup"),
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

  void _prosesDaftarWajah() async {
    setState(() => _isRegisteringFace = true);
    final auth = context.read<AuthProvider>();
    final result = await _service.daftarWajahMaster(
      auth.idAnggota!,
      auth.clientId ?? "",
    );
    if (!mounted) return;
    setState(() => _isRegisteringFace = false);
    if (result['success'] == true) {
      auth.setFaceRegistered(true);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              result['success'] == true ? Icons.check_circle : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(result['message'])),
          ],
        ),
        backgroundColor: result['success'] == true
            ? const Color(0xFF16A34A)
            : Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _tampilkanDialogPilihBulan() async {
    final auth = context.read<AuthProvider>();
    List<dynamic> listAnggota = [];
    if (auth.isAdmin) {
      setState(() => _isExporting = true);
      try {
        listAnggota = await AdminService().getAllAnggota(auth.clientId ?? "");
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Gagal memuat daftar anggota: $e"),
              backgroundColor: Colors.red,
            ),
          );
        }
        setState(() => _isExporting = false);
        return;
      }
      setState(() => _isExporting = false);
    }

    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;
    String selectedAnggotaId = auth.isAdmin ? "SEMUA" : (auth.idAnggota ?? "");

    final List<String> namaBulan = [
      "Januari",
      "Februari",
      "Maret",
      "April",
      "Mei",
      "Juni",
      "Juli",
      "Agustus",
      "September",
      "Oktober",
      "November",
      "Desember",
    ];

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Pilih Bulan Rekap",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedMonth,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                      items: List.generate(
                        12,
                        (i) => DropdownMenuItem(
                          value: i + 1,
                          child: Text(namaBulan[i]),
                        ),
                      ),
                      onChanged: (val) =>
                          setDialogState(() => selectedMonth = val!),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedYear,
                      isExpanded: true,
                      decoration: InputDecoration(
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                        ),
                      ),
                      items: List.generate(5, (i) {
                        final y = DateTime.now().year - i;
                        return DropdownMenuItem(
                          value: y,
                          child: Text(y.toString()),
                        );
                      }),
                      onChanged: (val) =>
                          setDialogState(() => selectedYear = val!),
                    ),
                  ),
                ],
              ),
              if (auth.isAdmin) ...[
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedAnggotaId,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: "Pilih Anggota",
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                  ),
                  items: [
                    const DropdownMenuItem(
                      value: "SEMUA",
                      child: Text("Semua Anggota"),
                    ),
                    ...listAnggota.map(
                      (k) => DropdownMenuItem<String>(
                        value: k['id'].toString(),
                        child: Text("${k['nama']} (${k['id']})"),
                      ),
                    ),
                  ],
                  onChanged: (val) =>
                      setDialogState(() => selectedAnggotaId = val!),
                ),
              ],
            ],
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
                final strBulan = selectedMonth.toString().padLeft(2, '0');
                _downloadLaporan(
                  "$strBulan-$selectedYear",
                  "${namaBulan[selectedMonth - 1]} $selectedYear",
                  selectedAnggotaId,
                );
              },
              child: const Text("Download"),
            ),
          ],
        ),
      ),
    );
  }

  void _downloadLaporan(
    String bulanTahun,
    String bulanNama,
    String targetId,
  ) async {
    setState(() => _isExporting = true);
    final auth = context.read<AuthProvider>();
    try {
      final dataMentah = await AdminService().getMonthlyReport(
        auth.clientId ?? "",
        bulanTahun,
        targetId,
      );
      if (dataMentah.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Belum ada data absen di bulan $bulanNama."),
            backgroundColor: Colors.orange.shade700,
          ),
        );
        setState(() => _isExporting = false);
        return;
      }
      String namaRekap = targetId == "SEMUA"
          ? "Instansi"
          : (targetId == auth.idAnggota
                ? (auth.namaAnggota ?? targetId)
                : targetId);
      await ExportService().generateMonthlyExcel(
        namaRekap,
        bulanNama,
        dataMentah,
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal mengunduh: $e"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _tampilkanDialogResetHP(BuildContext context) {
    final TextEditingController idController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        bool isResetting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.phonelink_erase,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Reset Perangkat",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Masukkan ID Anggota yang ingin direset perangkatnya.",
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: idController,
                  decoration: InputDecoration(
                    labelText: "ID Anggota",
                    prefixIcon: Icon(Icons.badge),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
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
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: isResetting
                    ? null
                    : () async {
                        if (idController.text.trim().isEmpty) return;
                        setDialogState(() => isResetting = true);
                        try {
                          final auth = context.read<AuthProvider>();
                          final targetId = idController.text.trim();
                          final result = await AdminService().resetDeviceID(
                            auth.idUser ?? "",
                            targetId,
                          );
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          if (result['code'] == 200) {
                            if (targetId == auth.idAnggota) {
                              auth.logout();
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const LoginScreen(),
                                ),
                                (route) => false,
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(result['message']),
                                  backgroundColor: const Color(0xFF16A34A),
                                ),
                              );
                            }
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message']),
                                backgroundColor: context.primaryColor,
                              ),
                            );
                          }
                        } catch (e) {
                          if (!context.mounted) return;
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text("Gagal mereset: $e"),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      },
                child: isResetting
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Reset"),
              ),
            ],
          ),
        );
      },
    );
  }

  // =================================================================
  // COMPONENT: MENU CARD
  // =================================================================
  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required VoidCallback? onTap,
    bool isLoading = false,
    required Color accentColor,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: accentColor.withOpacity(0.1),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: accentColor.withOpacity(0.15)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          padding: const EdgeInsets.all(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: accentColor,
                        ),
                      )
                    : Icon(icon, color: accentColor, size: 22),
              ),
              const SizedBox(height: 10),
              Text(
                title,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =================================================================
  // COMPONENT: HISTORY ITEM
  // =================================================================
  // History items extracted to AttendanceHistoryList widget

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        backgroundColor: const Color(0xFFF4F6FF),
        elevation: 0,
        scrolledUnderElevation: 0,
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
          "Profil & Menu",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          color: auth.themeColor,
          onRefresh: _handleRefresh,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
            children: [
              // ==========================================
              // 1. KARTU PROFIL UTAMA
              // ==========================================
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      auth.themeColor,
                      Color.lerp(
                        auth.themeColor,
                        const Color(0xFF7C3AED),
                        0.55,
                      )!,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: auth.themeColor.withOpacity(0.28),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Hero(
                      tag: 'profile-avatar',
                      child: CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        child: Icon(
                          auth.isAdmin
                              ? Icons.admin_panel_settings_rounded
                              : Icons.person_rounded,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.namaAnggota ?? "Unknown",
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ID: ${auth.idAnggota ?? '-'}",
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.7),
                              fontSize: 12,
                            ),
                          ),
                          if (auth.isAdmin) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                "ADMIN INSTANSI",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    // Logout
                    GestureDetector(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            title: const Text(
                              "Konfirmasi Logout",
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            content: const Text(
                              "Apakah Anda yakin ingin keluar dari akun ini?",
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
                                  backgroundColor: Colors.red.shade600,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(context);
                                  context.read<AuthProvider>().logout();
                                  Navigator.pushReplacement(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  );
                                },
                                child: const Text("Keluar"),
                              ),
                            ],
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.logout_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==========================================
              // 2. GRID MENU
              // ==========================================
              _sectionLabel("Menu Navigasi"),
              const SizedBox(height: 12),
              GridView.count(
                crossAxisCount: 3,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: 1.0,
                children: [
                  _buildMenuCard(
                    title: "Daftar\nWajah",
                    icon: Icons.face_retouching_natural,
                    isLoading: _isRegisteringFace,
                    onTap: _isRegisteringFace ? null : _prosesDaftarWajah,
                    accentColor: context.primaryColor,
                  ),
                  _buildMenuCard(
                    title: "Pengajuan\nIzin",
                    icon: Icons.edit_calendar_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LeaveRequestScreen(),
                      ),
                    ),
                    accentColor: const Color(0xFF7C3AED),
                  ),
                  _buildMenuCard(
                    title: "Download\nRekap",
                    icon: Icons.download_rounded,
                    isLoading: _isExporting,
                    onTap: _isExporting ? null : _tampilkanDialogPilihBulan,
                    accentColor: const Color(0xFF16A34A),
                  ),
                  _buildMenuCard(
                    title: "Riwayat\nIzin",
                    icon: Icons.history_edu_rounded,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const LeaveHistoryScreen(),
                      ),
                    ),
                    accentColor: Colors.blueGrey,
                  ),
                  if (!auth.isAdmin &&
                      auth.adminPhone != null &&
                      auth.adminPhone!.isNotEmpty)
                    _buildMenuCard(
                      title: "Hubungi\nPengelola",
                      icon: Icons.support_agent_rounded,
                      onTap: () => UrlHelper.launchWhatsApp(
                        phone: auth.adminPhone!,
                        message:
                            "Halo Bapak/Ibu Admin Hadir.in, saya ${auth.namaUser} ingin menanyakan sesuatu.",
                      ),
                      accentColor: const Color(0xFFE11D48), // Rose
                    ),
                  if (auth.isAdmin) ...[
                    _buildMenuCard(
                      title: "Daftar\nAnggota",
                      icon: Icons.people_alt_rounded,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AnggotaListScreen(),
                        ),
                      ),
                      accentColor: const Color(0xFF6366F1), // Indigo
                    ),
                    _buildMenuCard(
                      title: "Persetujuan\nIzin",
                      icon: Icons.playlist_add_check_circle,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ApprovalScreen(),
                        ),
                      ),
                      accentColor: Colors.orange.shade700,
                    ),
                    _buildMenuCard(
                      title: "Tambah\nAnggota",
                      icon: Icons.person_add_alt_1,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const AddAnggotaScreen(),
                        ),
                      ),
                      accentColor: const Color(0xFF0891B2),
                    ),
                    _buildMenuCard(
                      title: "Update\nLokasi",
                      icon: Icons.map_outlined,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const SetLocationScreen(),
                        ),
                      ),
                      accentColor: const Color(0xFF059669),
                    ),
                    _buildMenuCard(
                      title: "Reset\nPerangkat",
                      icon: Icons.phonelink_erase,
                      onTap: () => _tampilkanDialogResetHP(context),
                      accentColor: Colors.red.shade600,
                    ),
                  ],
                ],
              ),

              if (auth.isAdmin) ...[
                const SizedBox(height: 24),
                _sectionLabel("Statistik Instansi"),
                const SizedBox(height: 12),
                _buildAdminStats(),
              ],

              const SizedBox(height: 24),

              // ==========================================
              // 3. RIWAYAT ABSENSI
              // ==========================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _sectionLabel("Riwayat Absensi"),
                  GestureDetector(
                    onTap: _pickDateRange,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _selectedDateRange != null
                            ? context.primaryColor.withOpacity(0.08)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: _selectedDateRange != null
                              ? context.primaryColor.withOpacity(0.3)
                              : Colors.grey.shade200,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            _selectedDateRange == null
                                ? Icons.calendar_month_outlined
                                : Icons.event_available,
                            size: 14,
                            color: _selectedDateRange == null
                                ? Colors.grey.shade500
                                : context.primaryColor,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            "Filter",
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _selectedDateRange == null
                                  ? Colors.grey.shade500
                                  : context.primaryColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              // Active date range banner
              if (_selectedDateRange != null) ...[
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withOpacity(0.07),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: context.primaryColor.withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.date_range_rounded,
                        size: 14,
                        color: context.primaryColor,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} – ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}",
                          style: TextStyle(
                            color: context.primaryColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _selectedDateRange = null);
                          _applyFilter();
                        },
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color: Colors.red.shade400,
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 14),

              // Filter chips
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: ["Semua", "Masuk", "Pulang"].map((tipe) {
                    final isSelected = _filterTipe == tipe;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8.0),
                      child: GestureDetector(
                        onTap: () {
                          setState(() => _filterTipe = tipe);
                          _applyFilter();
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected ? auth.themeColor : Colors.white,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: isSelected
                                  ? auth.themeColor
                                  : Colors.grey.shade200,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: auth.themeColor.withOpacity(0.25),
                                      blurRadius: 8,
                                      offset: const Offset(0, 3),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Text(
                            tipe,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? Colors.white
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),

              const SizedBox(height: 16),

              AttendanceHistoryList(
                history: _filteredHistory,
                isLoading: _isLoading,
                errorMessage: _errorMsg,
                onShowPhoto: (url, tipe, waktu) =>
                    _tampilkanFoto(context, url, tipe, waktu),
              ),

              const SizedBox(height: 32),
              Center(
                child: Column(
                  children: [
                    Text(
                      "Hadirin v1.0.0",
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.grey.shade400,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Masterpiece Edition",
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade400,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label,
    style: TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w800,
      color: Color(0xFF0F172A),
      letterSpacing: 0.2,
    ),
  );

  Widget _buildAdminStats() {
    if (_isLoadingStats) {
      return Row(
        children: List.generate(
          3,
          (i) => Expanded(
            child: Container(
              margin: EdgeInsets.only(right: i == 2 ? 0 : 8),
              child: const SkeletonLoader(width: double.infinity, height: 80),
            ),
          ),
        ),
      );
    }

    int total = _listAnggotaStats.length;
    int wajahOk = _listAnggotaStats
        .where((a) => a['wajah_terdaftar'] == true)
        .length;
    int hpOk = _listAnggotaStats.where((a) => a['sudah_enroll'] == true).length;

    return Row(
      children: [
        _statCard(
          "Anggota",
          total.toString(),
          Icons.people_rounded,
          Colors.blue,
        ),
        const SizedBox(width: 8),
        _statCard(
          "Wajah OK",
          wajahOk.toString(),
          Icons.face_rounded,
          Colors.green,
        ),
        const SizedBox(width: 8),
        _statCard(
          "HP OK",
          hpOk.toString(),
          Icons.phonelink_setup,
          Colors.orange,
        ),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.1)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}
