import 'package:flutter/material.dart';
import 'package:hadirin/core/config/app_config.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/core/service/export_service.dart';
import 'package:hadirin/ui/screens/add_karyawan_screen.dart';
import 'package:hadirin/ui/screens/set_location_screen.dart';
import 'package:provider/provider.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:hadirin/ui/screens/leave_request_screen.dart';
import 'package:hadirin/ui/screens/approval_screen.dart'; // Import layar approval

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AttendanceService _service = AttendanceService();
  bool _isLoading = true;
  bool _isRegisteringFace = false;
  bool _isExporting = false;
  String _errorMsg = "";

  List<dynamic> _allHistory = [];
  List<dynamic> _filteredHistory = [];
  String _filterTipe = "Semua";

  DateTimeRange? _selectedDateRange;

  @override
  void initState() {
    super.initState();
    initializeDateFormatting('id_ID', null).then((_) {
      _fetchHistory();
    });
  }

  Future<void> _fetchHistory() async {
    final auth = context.read<AuthProvider>();
    if (auth.idKaryawan == null) return;

    try {
      final data = await _service.getHistory(auth.idKaryawan!);
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

  void _applyFilter() {
    setState(() {
      _filteredHistory = _allHistory.where((log) {
        bool passTipe = _filterTipe == "Semua" || log['tipe'] == _filterTipe;

        bool passTanggal = true;
        if (_selectedDateRange != null && log['waktu'] != null) {
          final dt = DateTime.tryParse(log['waktu'].toString())?.toLocal();
          if (dt != null) {
            final logDate = DateTime(dt.year, dt.month, dt.day);
            final startDate = DateTime(
              _selectedDateRange!.start.year,
              _selectedDateRange!.start.month,
              _selectedDateRange!.start.day,
            );
            final endDate = DateTime(
              _selectedDateRange!.end.year,
              _selectedDateRange!.end.month,
              _selectedDateRange!.end.day,
            );

            passTanggal =
                logDate.isAfter(startDate.subtract(const Duration(days: 1))) &&
                logDate.isBefore(endDate.add(const Duration(days: 1)));
          }
        }
        return passTipe && passTanggal;
      }).toList();
    });
  }

  Future<void> _pickDateRange() async {
    final DateTimeRange? picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      initialDateRange: _selectedDateRange,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: FluidColors.primary,
              onPrimary: Colors.white,
              onSurface: FluidColors.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDateRange = picked;
      });
      _applyFilter();
    }
  }

  String _formatTanggalIndo(DateTime dt) {
    return DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);
  }

  String _formatJam(DateTime dt) {
    return DateFormat('HH:mm').format(dt);
  }

  String getDirectUrl(String originalUrl) {
    if (originalUrl.contains("drive.google.com")) {
      final fileId = originalUrl.split("/d/")[1].split("/view")[0];
      return "https://docs.google.com/uc?export=view&id=$fileId";
    }
    return originalUrl;
  }

  void _tampilkanFoto(
    BuildContext context,
    String url,
    String tipe,
    String waktu,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FluidRadii.md),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(FluidRadii.md),
              ),
              child: Image.network(
                getDirectUrl(url),
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox(
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    waktu,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
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

    final result = await _service.daftarWajahMaster(auth.idKaryawan!);

    if (!mounted) return;
    setState(() => _isRegisteringFace = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(result['message']),
        backgroundColor: result['success'] == true
            ? FluidColors.primary
            : Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(FluidRadii.sm),
        ),
      ),
    );
  }

  // =================================================================
  // DIALOG PEMILIHAN BULAN & TAHUN UNTUK EXCEL
  // =================================================================
  void _tampilkanDialogPilihBulan() {
    int selectedMonth = DateTime.now().month;
    int selectedYear = DateTime.now().year;

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

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FluidRadii.md),
              ),
              title: const Text(
                "Pilih Bulan Rekap",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedMonth,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: List.generate(12, (index) {
                        return DropdownMenuItem(
                          value: index + 1,
                          child: Text(namaBulan[index]),
                        );
                      }),
                      onChanged: (val) =>
                          setDialogState(() => selectedMonth = val!),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DropdownButtonFormField<int>(
                      initialValue: selectedYear,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: List.generate(5, (index) {
                        int year = DateTime.now().year - index;
                        return DropdownMenuItem(
                          value: year,
                          child: Text(year.toString()),
                        );
                      }),
                      onChanged: (val) =>
                          setDialogState(() => selectedYear = val!),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Batal",
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
                    String strBulan = selectedMonth.toString().padLeft(2, '0');
                    String bulanTahun = "$strBulan-$selectedYear";
                    String bulanNama =
                        "${namaBulan[selectedMonth - 1]} $selectedYear";

                    _downloadLaporan(bulanTahun, bulanNama);
                  },
                  child: const Text("Download"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  // =================================================================
  // EKSEKUSI DOWNLOAD EXCEL
  // =================================================================
  void _downloadLaporan(String bulanTahun, String bulanNama) async {
    setState(() => _isExporting = true);
    final auth = context.read<AuthProvider>();

    try {
      final dataMentah = await _service.getMonthlyReport(
        AppConfig.clientId,
        bulanTahun,
      );

      if (dataMentah.isEmpty) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Belum ada data absen di bulan $bulanNama."),
            backgroundColor: Colors.orange,
          ),
        );
        setState(() => _isExporting = false);
        return;
      }

      await ExportService().generateMonthlyExcel(
        auth.namaKaryawan ?? "UMKM",
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

  // =================================================================
  // DIALOG & FUNGSI RESET DEVICE HP
  // =================================================================
  void _tampilkanDialogResetHP(BuildContext context) {
    final TextEditingController idController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        bool isResetting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FluidRadii.md),
              ),
              title: const Text(
                "Reset Perangkat",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Masukkan ID Karyawan yang ingin direset perangkatnya (Misal: KRY-001).",
                    style: TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: idController,
                    decoration: const InputDecoration(
                      labelText: "ID Karyawan",
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    "Batal",
                    style: TextStyle(color: Colors.grey),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: isResetting
                      ? null
                      : () async {
                          if (idController.text.trim().isEmpty) return;

                          setDialogState(() => isResetting = true);

                          try {
                            final result = await _service.resetDeviceID(
                              idController.text.trim(),
                            );
                            if (!context.mounted) return;
                            Navigator.pop(context); // Tutup dialog

                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(result['message']),
                                backgroundColor: result['code'] == 200
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            );
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
                      : const Text("Reset Sekarang"),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: FluidColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: FluidColors.onSurface),
        title: const Text(
          "Profil & Riwayat",
          style: TextStyle(
            color: FluidColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        color: FluidColors.primary,
        onRefresh: _fetchHistory,
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            // KARTU PROFIL
            Card(
              color: FluidColors.surfaceContainerLow,
              elevation: 0,
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: FluidColors.primary.withOpacity(0.1),
                      child: Icon(
                        auth.isAdmin
                            ? Icons.admin_panel_settings
                            : Icons.person,
                        color: FluidColors.primary,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            auth.namaKaryawan ?? "Unknown",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: FluidColors.onSurface,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "ID: ${auth.idKaryawan ?? '-'}",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14,
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
                                color: FluidColors.primaryGhost,
                                borderRadius: BorderRadius.circular(
                                  FluidRadii.sm,
                                ),
                              ),
                              child: const Text(
                                "ADMIN UMKM",
                                style: TextStyle(
                                  color: FluidColors.primary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.logout, color: Colors.redAccent),
                      onPressed: () {
                        context.read<AuthProvider>().logout();
                        Navigator.pop(context);
                      },
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // TOMBOL PENDAFTARAN WAJAH
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _isRegisteringFace ? null : _prosesDaftarWajah,
                icon: _isRegisteringFace
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: FluidColors.primary,
                        ),
                      )
                    : const Icon(Icons.face_retouching_natural),
                label: Text(
                  _isRegisteringFace
                      ? "Memproses Wajah..."
                      : "Daftarkan / Update Wajah",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: FluidColors.primary,
                  side: const BorderSide(color: FluidColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FluidRadii.sm),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // TOMBOL PENGAJUAN CUTI / IZIN / SAKIT
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LeaveRequestScreen()),
                ),
                icon: const Icon(Icons.edit_calendar_rounded),
                label: const Text(
                  "Pengajuan Cuti / Izin / Sakit",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: FluidColors.surfaceContainerLow,
                  foregroundColor: FluidColors.primary,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(FluidRadii.sm),
                  ),
                ),
              ),
            ),

            // MENU KHUSUS ADMIN
            if (auth.isAdmin) ...[
              const SizedBox(height: 12),

              // 1. TOMBOL PERSETUJUAN IZIN
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const ApprovalScreen()),
                  ),
                  icon: const Icon(
                    Icons.playlist_add_check_circle,
                    color: Colors.orange,
                  ),
                  label: const Text(
                    "Daftar Persetujuan Izin",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FluidRadii.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 2. TOMBOL DOWNLOAD EXCEL
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: _isExporting ? null : _tampilkanDialogPilihBulan,
                  icon: _isExporting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.green,
                          ),
                        )
                      : Icon(
                          Icons.download_rounded,
                          color: Colors.green.shade700,
                        ),
                  label: Text(
                    _isExporting
                        ? "Menyiapkan Excel..."
                        : "Download Rekap Absensi",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green.shade700,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FluidRadii.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 3. TOMBOL TAMBAH KARYAWAN
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const AddKaryawanScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text(
                    "Tambah Karyawan Baru",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FluidColors.surfaceContainerLow,
                    foregroundColor: FluidColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FluidRadii.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 4. TOMBOL RESET DEVICE HP
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => _tampilkanDialogResetHP(context),
                  icon: const Icon(Icons.phonelink_erase, color: Colors.red),
                  label: const Text(
                    "Reset Perangkat Karyawan",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.red,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FluidRadii.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // 5. TOMBOL UPDATE LOKASI
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton.icon(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const SetLocationScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.map_outlined),
                  label: const Text(
                    "Update Koordinat Kantor",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: FluidColors.surfaceContainerLow,
                    foregroundColor: FluidColors.primary,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FluidRadii.sm),
                    ),
                  ),
                ),
              ),
            ],

            const SizedBox(height: FluidSpacing.section),

            // HEADER RIWAYAT & FILTER TANGGAL
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Riwayat Absensi",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: FluidColors.onSurface,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _selectedDateRange == null
                        ? Icons.calendar_month_outlined
                        : Icons.event_available,
                    color: _selectedDateRange == null
                        ? Colors.grey
                        : FluidColors.primary,
                  ),
                  onPressed: _pickDateRange,
                  tooltip: "Filter Tanggal",
                ),
              ],
            ),

            if (_selectedDateRange != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "${DateFormat('dd MMM yyyy').format(_selectedDateRange!.start)} - ${DateFormat('dd MMM yyyy').format(_selectedDateRange!.end)}",
                        style: TextStyle(
                          color: FluidColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () {
                        setState(() => _selectedDateRange = null);
                        _applyFilter();
                      },
                      child: const Text(
                        "Hapus Filter",
                        style: TextStyle(
                          color: Colors.redAccent,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Filter Tipe
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ["Semua", "Masuk", "Pulang"].map((tipe) {
                  final isSelected = _filterTipe == tipe;
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: ChoiceChip(
                      label: Text(tipe),
                      selected: isSelected,
                      checkmarkColor: FluidColors.background,
                      selectedColor: FluidColors.primary,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : Colors.grey.shade700,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      backgroundColor: FluidColors.surfaceContainerLow,
                      side: BorderSide.none,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FluidRadii.sm),
                      ),
                      onSelected: (bool selected) {
                        setState(() => _filterTipe = tipe);
                        _applyFilter();
                      },
                    ),
                  );
                }).toList(),
              ),
            ),

            const SizedBox(height: 24),

            // LIST RIWAYAT
            if (_isLoading)
              const Center(
                child: CircularProgressIndicator(color: FluidColors.primary),
              )
            else if (_errorMsg.isNotEmpty)
              Center(
                child: Text(
                  _errorMsg,
                  style: const TextStyle(color: Colors.red),
                ),
              )
            else if (_filteredHistory.isEmpty)
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.history_toggle_off,
                      size: 48,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Belum ada data absen.",
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _filteredHistory.length,
                itemBuilder: (context, index) {
                  final log = _filteredHistory[index];
                  final dt =
                      DateTime.tryParse(log['waktu'].toString())?.toLocal() ??
                      DateTime.now();
                  final isTerlambat = log['status'] == "Terlambat";
                  final isMasuk = log['tipe'] == "Masuk";

                  final formatTgl = _formatTanggalIndo(dt);
                  final formatJam = _formatJam(dt);

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: FluidColors.surfaceContainerLow,
                      borderRadius: BorderRadius.circular(FluidRadii.md),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: FluidColors.background,
                            borderRadius: BorderRadius.circular(FluidRadii.sm),
                          ),
                          child: Icon(
                            isMasuk
                                ? Icons.login_rounded
                                : Icons.logout_rounded,
                            color: isMasuk
                                ? FluidColors.primary
                                : Colors.orange.shade700,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Absen ${log['tipe']} ($formatJam)",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                formatTgl,
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (log['foto'] != null &&
                            log['foto'].toString().isNotEmpty)
                          IconButton(
                            icon: const Icon(
                              Icons.image_search,
                              color: Colors.grey,
                            ),
                            tooltip: "Lihat Foto",
                            onPressed: () {
                              _tampilkanFoto(
                                context,
                                log['foto'],
                                log['tipe'],
                                "$formatTgl - $formatJam",
                              );
                            },
                          ),
                        if (isMasuk)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: isTerlambat
                                  ? Colors.red.shade50
                                  : FluidColors.primaryGhost,
                              borderRadius: BorderRadius.circular(
                                FluidRadii.sm,
                              ),
                            ),
                            child: Text(
                              log['status'],
                              style: TextStyle(
                                color: isTerlambat
                                    ? Colors.red.shade700
                                    : FluidColors.primary,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
