import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hadirin/core/models/school_models.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/school_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

class BriefingScreen extends StatefulWidget {
  const BriefingScreen({super.key});

  @override
  State<BriefingScreen> createState() => _BriefingScreenState();
}

class _BriefingScreenState extends State<BriefingScreen>
    with SingleTickerProviderStateMixin {
  final _service = SchoolService();
  final _picker = ImagePicker();
  late TabController _tabCtrl;

  // Form state
  String? _selectedStatus;
  final _catatanCtrl = TextEditingController();
  XFile? _foto;
  bool _isSaving = false;

  // Riwayat state
  List<BriefingModel> _riwayatList = [];
  bool _isLoadingRiwayat = true;

  final List<String> _statusOptions = ['Hadir', 'Izin', 'Sakit'];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetchRiwayat();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _catatanCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchRiwayat() async {
    setState(() => _isLoadingRiwayat = true);
    final auth = context.read<AuthProvider>();
    final idKaryawan = auth.isAdmin ? 'SEMUA' : (auth.idAnggota ?? '');
    final data = await _service.getBriefing(auth.clientId ?? '', idKaryawan);
    setState(() {
      _riwayatList = data;
      _isLoadingRiwayat = false;
    });
  }

  Future<void> _ambilFoto() async {
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 100,
      preferredCameraDevice: CameraDevice.front,
    );
    if (image != null) {
      setState(() => _foto = image);
    }
  }

  Future<void> _submitAbsen() async {
    if (_selectedStatus == null) {
      _showSnackBar("Pilih status kehadiran terlebih dahulu!", isError: true);
      return;
    }

    // Foto wajib jika status Hadir
    if (_selectedStatus == 'Hadir' && _foto == null) {
      _showSnackBar("Foto wajib diambil jika status Hadir!", isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final auth = context.read<AuthProvider>();
      String fotoBase64 = '';

      if (_foto != null) {
        // Kompress foto
        final targetPath = '${_foto!.path}_compressed.jpg';
        final compressedFile = await FlutterImageCompress.compressAndGetFile(
          _foto!.path,
          targetPath,
          quality: 30,
          minWidth: 600,
          minHeight: 600,
          format: CompressFormat.jpeg,
        );

        if (compressedFile != null) {
          final imageBytes = await compressedFile.readAsBytes();
          fotoBase64 = base64Encode(imageBytes);

          // Cleanup temp file
          try {
            File(targetPath).deleteSync();
          } catch (_) {}
        }
      }

      final res = await _service.absenBriefing(
        clientId: auth.clientId ?? '',
        idKaryawan: auth.idAnggota ?? '',
        statusKehadiran: _selectedStatus!,
        fotoBase64: fotoBase64,
        catatan: _catatanCtrl.text.trim(),
      );

      if (mounted) {
        setState(() => _isSaving = false);

        if (res['success'] == true) {
          _showSnackBar("Absen briefing berhasil dicatat!");
          // Reset form
          setState(() {
            _selectedStatus = null;
            _foto = null;
            _catatanCtrl.clear();
          });
          // Refresh riwayat
          _fetchRiwayat();
        } else {
          _showSnackBar(
            res['message']?.toString() ?? 'Gagal menyimpan absen',
            isError: true,
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        _showSnackBar("Terjadi kesalahan: $e", isError: true);
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
        backgroundColor:
            isError ? Colors.red.shade600 : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Absensi Briefing",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
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
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A),
                size: 16,
              ),
            ),
          ),
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: context.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: context.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Form Absen"),
            Tab(text: "Riwayat"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: [
          _buildFormAbsen(),
          _buildRiwayat(),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TAB 1: FORM ABSEN BRIEFING
  // ─────────────────────────────────────────────────────────────────
  Widget _buildFormAbsen() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // HEADER
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  context.primaryColor,
                  Color.lerp(
                    context.primaryColor,
                    const Color(0xFF0EA5E9),
                    0.6,
                  )!,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: context.primaryColor.withOpacity(0.3),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.groups_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Absen Briefing Hari Ini",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 17,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Isi form di bawah untuk mencatat kehadiran briefing.",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 28),

          // DROPDOWN STATUS KEHADIRAN
          _formLabel("Status Kehadiran"),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: DropdownButtonFormField<String>(
              value: _selectedStatus,
              isExpanded: true,
              decoration: InputDecoration(
                hintText: "Pilih status kehadiran",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Icon(
                  Icons.how_to_reg_rounded,
                  color: context.primaryColor,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: context.primaryColor, width: 1.5),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
              ),
              items: _statusOptions
                  .map((s) => DropdownMenuItem(
                        value: s,
                        child: Row(
                          children: [
                            Icon(
                              _statusIcon(s),
                              size: 18,
                              color: _statusColor(s),
                            ),
                            const SizedBox(width: 10),
                            Text(s),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (val) => setState(() => _selectedStatus = val),
            ),
          ),

          const SizedBox(height: 20),

          // TOMBOL AMBIL FOTO
          _formLabel(
            _selectedStatus == 'Hadir'
                ? "Foto Selfie (Wajib)"
                : "Foto Selfie (Opsional)",
          ),
          const SizedBox(height: 8),
          GestureDetector(
            onTap: _ambilFoto,
            child: Container(
              width: double.infinity,
              height: _foto != null ? 220 : 120,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _foto != null
                      ? const Color(0xFF16A34A).withOpacity(0.4)
                      : Colors.grey.shade200,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _foto != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.file(
                            File(_foto!.path),
                            fit: BoxFit.cover,
                          ),
                          // Overlay ganti foto
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                              child: const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.camera_alt_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                  SizedBox(width: 6),
                                  Text(
                                    "Ketuk untuk ganti foto",
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            Icons.camera_alt_rounded,
                            color: context.primaryColor,
                            size: 28,
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          "Ketuk untuk ambil foto",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          // CATATAN
          _formLabel("Catatan (Opsional)"),
          const SizedBox(height: 8),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _catatanCtrl,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: "Tulis catatan jika perlu...",
                filled: true,
                fillColor: Colors.white,
                prefixIcon: Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Icon(
                    Icons.notes_rounded,
                    color: context.primaryColor,
                  ),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide:
                      BorderSide(color: context.primaryColor, width: 1.5),
                ),
              ),
            ),
          ),

          const SizedBox(height: 32),

          // TOMBOL SUBMIT
          SizedBox(
            width: double.infinity,
            height: 58,
            child: ElevatedButton.icon(
              onPressed: _isSaving ? null : _submitAbsen,
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                elevation: 4,
                shadowColor: context.primaryColor.withOpacity(0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: _isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    )
                  : const Icon(Icons.send_rounded),
              label: Text(
                _isSaving ? "Menyimpan..." : "Kirim Absen Briefing",
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // TAB 2: RIWAYAT BRIEFING
  // ─────────────────────────────────────────────────────────────────
  Widget _buildRiwayat() {
    if (_isLoadingRiwayat) {
      return Center(
        child: CircularProgressIndicator(color: context.primaryColor),
      );
    }

    if (_riwayatList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.groups_outlined,
              size: 72,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              "Belum ada riwayat briefing",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Data absen briefing akan muncul di sini.",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: context.primaryColor,
      onRefresh: _fetchRiwayat,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        itemCount: _riwayatList.length,
        itemBuilder: (_, i) => _buildRiwayatCard(_riwayatList[i]),
      ),
    );
  }

  Widget _buildRiwayatCard(BriefingModel b) {
    final color = _statusColor(b.statusKehadiran);
    final icon = _statusIcon(b.statusKehadiran);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Icon status
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            // Detail
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          b.namaKaryawan ?? b.idKaryawan,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          b.statusKehadiran,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (b.catatan != null && b.catatan!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text(
                        b.catatan!,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                          height: 1.4,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        size: 12,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        b.tanggal ?? '-',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade400,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────
  Widget _formLabel(String text) => Text(
        text,
        style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFF1E293B),
        ),
      );

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Hadir':
        return Icons.check_circle_rounded;
      case 'Izin':
        return Icons.edit_calendar_rounded;
      case 'Sakit':
        return Icons.local_hospital_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Hadir':
        return const Color(0xFF16A34A);
      case 'Izin':
        return const Color(0xFFEA580C);
      case 'Sakit':
        return const Color(0xFFDC2626);
      default:
        return Colors.grey;
    }
  }
}
