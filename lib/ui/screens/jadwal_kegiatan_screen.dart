import 'dart:developer' as d;
import 'package:flutter/material.dart';
import 'package:hadirin/core/models/school_models.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/admin_service.dart';
import 'package:hadirin/core/service/school_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────
// HELPER: SharedPreferences key untuk mengingat status absen
// ─────────────────────────────────────────────────────────────
class _AbsenCache {
  static String _key(String idKegiatan, String idKaryawan) =>
      'absen_kegiatan_${idKegiatan}_$idKaryawan';

  static Future<String?> getStatus(String idKegiatan, String idKaryawan) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_key(idKegiatan, idKaryawan));
  }

  static Future<void> saveStatus(
    String idKegiatan,
    String idKaryawan,
    String status,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key(idKegiatan, idKaryawan), status);
  }
}

// ─────────────────────────────────────────────────────────────
// SCREEN 1: DAFTAR JADWAL KEGIATAN
// ─────────────────────────────────────────────────────────────
class JadwalKegiatanScreen extends StatefulWidget {
  const JadwalKegiatanScreen({super.key});

  @override
  State<JadwalKegiatanScreen> createState() => _JadwalKegiatanScreenState();
}

class _JadwalKegiatanScreenState extends State<JadwalKegiatanScreen> {
  final _service = SchoolService();
  List<JadwalKegiatanModel> _jadwalList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final data = await _service.getJadwalKegiatan(auth.clientId ?? '');
    setState(() {
      _jadwalList = data;
      _isLoading = false;
    });
  }

  void _handleTapKegiatan(JadwalKegiatanModel k) {
    final auth = context.read<AuthProvider>();

    if (k.tipe == 'Rapat') {
      // Tipe RAPAT: Hanya Admin yang bisa input
      if (!auth.isAdmin) {
        showDialog(
          context: context,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            icon: Icon(
              Icons.lock_rounded,
              color: Colors.indigo.shade400,
              size: 40,
            ),
            title: const Text(
              "Absensi Dikelola Admin",
              textAlign: TextAlign.center,
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            content: const Text(
              "Kehadiran untuk kegiatan Rapat diinput langsung oleh Admin. Silakan konfirmasi kehadiran Anda kepada Admin.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Mengerti"),
              ),
            ],
          ),
        );
        return;
      }
      // Admin → layar input absen per karyawan
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminAbsenRapatScreen(kegiatan: k)),
      ).then((_) => _fetch());
      return;
    }

    // Tipe lain → Guru/Karyawan absen mandiri
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AbsenKegiatanScreen(kegiatan: k)),
    ).then((_) => _fetch());
  }

  void _showTambahSheet() {
    final namaCtrl = TextEditingController();
    final deskripsiCtrl = TextEditingController();
    String selectedTipe = 'Rapat';
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  "Tambah Kegiatan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 24),
                _inputLabel("Nama Kegiatan"),
                const SizedBox(height: 8),
                _textField(namaCtrl, "Contoh: Rapat Koordinasi Guru"),
                const SizedBox(height: 16),
                _inputLabel("Tipe Kegiatan"),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTipe,
                  decoration: _inputDecoration(),
                  items:
                      [
                            'Rapat',
                            'Seminar',
                            'Kegiatan Sekolah',
                            'Olahraga',
                            'Lainnya',
                          ]
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                  onChanged: (v) => setSheet(() => selectedTipe = v!),
                ),
                const SizedBox(height: 16),
                _inputLabel("Tanggal & Waktu"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setSheet(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: context.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd MMM yyyy').format(selectedDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setSheet(() => selectedTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: context.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedTime.format(ctx),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _inputLabel("Deskripsi"),
                const SizedBox(height: 8),
                _textField(
                  deskripsiCtrl,
                  "Keterangan tambahan...",
                  maxLines: 3,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (namaCtrl.text.trim().isEmpty) return;
                            setSheet(() => isSaving = true);
                            final auth = context.read<AuthProvider>();
                            final tanggalWaktu =
                                '${DateFormat('yyyy-MM-dd').format(selectedDate)} ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                            final res = await _service.addJadwalKegiatan(
                              clientId: auth.clientId ?? '',
                              namaKegiatan: namaCtrl.text.trim(),
                              tipe: selectedTipe,
                              tanggalWaktu: tanggalWaktu,
                              deskripsi: deskripsiCtrl.text.trim(),
                              idAdmin: auth.idAnggota ?? '',
                            );
                            if (!mounted) return;
                            setSheet(() => isSaving = false);
                            if (res['success'] == true) {
                              Navigator.pop(ctx);
                              _fetch();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    "Kegiatan berhasil ditambahkan!",
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ?? 'Gagal'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Simpan Kegiatan",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showEditSheet(JadwalKegiatanModel k) {
    final namaCtrl = TextEditingController(text: k.namaKegiatan);
    final deskripsiCtrl = TextEditingController(text: k.deskripsi);
    String selectedTipe = k.tipe;
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    bool isSaving = false;

    try {
      selectedDate = DateTime.parse(k.tanggalWaktu);
      selectedTime = TimeOfDay.fromDateTime(selectedDate);
    } catch (_) {}

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 32,
            top: 24,
            left: 24,
            right: 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 20),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const Text(
                  "Edit Kegiatan",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 24),
                _inputLabel("Nama Kegiatan"),
                const SizedBox(height: 8),
                _textField(namaCtrl, "Contoh: Rapat Koordinasi Guru"),
                const SizedBox(height: 16),
                _inputLabel("Tipe Kegiatan"),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedTipe,
                  decoration: _inputDecoration(),
                  items:
                      [
                            'Rapat',
                            'Seminar',
                            'Kegiatan Sekolah',
                            'Olahraga',
                            'Lainnya',
                          ]
                          .map(
                            (t) => DropdownMenuItem(value: t, child: Text(t)),
                          )
                          .toList(),
                  onChanged: (v) => setSheet(() => selectedTipe = v!),
                ),
                const SizedBox(height: 16),
                _inputLabel("Tanggal & Waktu"),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: ctx,
                            initialDate: selectedDate,
                            firstDate: DateTime(2024),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365),
                            ),
                          );
                          if (picked != null) {
                            setSheet(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 16,
                                color: context.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                DateFormat('dd MMM yyyy').format(selectedDate),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: GestureDetector(
                        onTap: () async {
                          final picked = await showTimePicker(
                            context: ctx,
                            initialTime: selectedTime,
                          );
                          if (picked != null) {
                            setSheet(() => selectedTime = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time_rounded,
                                size: 16,
                                color: context.primaryColor,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                selectedTime.format(ctx),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _inputLabel("Deskripsi"),
                const SizedBox(height: 8),
                _textField(
                  deskripsiCtrl,
                  "Keterangan tambahan...",
                  maxLines: 3,
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            if (namaCtrl.text.trim().isEmpty) return;
                            setSheet(() => isSaving = true);
                            final auth = context.read<AuthProvider>();
                            final tanggalWaktu =
                                '${DateFormat('yyyy-MM-dd').format(selectedDate)} ${selectedTime.hour.toString().padLeft(2, '0')}:${selectedTime.minute.toString().padLeft(2, '0')}';
                            final res = await _service.editJadwalKegiatan(
                              clientId: auth.clientId ?? '',
                              idKegiatan: k.idKegiatan,
                              namaKegiatan: namaCtrl.text.trim(),
                              tipe: selectedTipe,
                              tanggalWaktu: tanggalWaktu,
                              deskripsi: deskripsiCtrl.text.trim(),
                            );
                            if (!mounted) return;
                            setSheet(() => isSaving = false);
                            if (res['success'] == true) {
                              Navigator.pop(ctx);
                              _fetch();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                    "Kegiatan berhasil diperbarui!",
                                  ),
                                  backgroundColor: Colors.green.shade600,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(res['message'] ?? 'Gagal'),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          },
                    child: isSaving
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            "Update Kegiatan",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _inputLabel(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: Color(0xFF1E293B),
    ),
  );

  Widget _textField(
    TextEditingController ctrl,
    String hint, {
    int maxLines = 1,
  }) => TextField(
    controller: ctrl,
    maxLines: maxLines,
    decoration: _inputDecoration().copyWith(hintText: hint),
  );

  InputDecoration _inputDecoration() => InputDecoration(
    filled: true,
    fillColor: Colors.grey.shade100,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(14),
      borderSide: BorderSide.none,
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
  );

  Color _tipeColor(String tipe) {
    switch (tipe) {
      case 'Rapat':
        return const Color(0xFF6366F1);
      case 'Seminar':
        return const Color(0xFF0891B2);
      case 'Olahraga':
        return Colors.green;
      default:
        return Colors.orange;
    }
  }

  IconData _tipeIcon(String tipe) {
    switch (tipe) {
      case 'Rapat':
        return Icons.groups_rounded;
      case 'Seminar':
        return Icons.school_rounded;
      case 'Olahraga':
        return Icons.sports_rounded;
      default:
        return Icons.event_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        title: const Text(
          "Jadwal Kegiatan",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
              onRefresh: _fetch,
              child: _jadwalList.isEmpty
                  ? _buildEmpty()
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                      itemCount: _jadwalList.length,
                      itemBuilder: (ctx, i) =>
                          _buildKegiatanCard(_jadwalList[i]),
                    ),
            ),
      floatingActionButton: isAdmin
          ? FloatingActionButton.extended(
              onPressed: _showTambahSheet,
              backgroundColor: context.primaryColor,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text(
                "Tambah Kegiatan",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.event_busy_rounded, size: 72, color: Colors.grey.shade300),
        const SizedBox(height: 16),
        Text(
          "Belum ada kegiatan",
          style: TextStyle(
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Tekan tombol '+' untuk menambah kegiatan baru.",
          style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
        ),
      ],
    ),
  );

  Widget _buildKegiatanCard(JadwalKegiatanModel k) {
    final color = _tipeColor(k.tipe);
    final isAdmin = context.watch<AuthProvider>().isAdmin;
    final isRapat = k.tipe == 'Rapat';
    DateTime? dt;
    try {
      dt = DateTime.parse(k.tanggalWaktu);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _handleTapKegiatan(k),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(_tipeIcon(k.tipe), color: color, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      k.namaKegiatan,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (dt != null)
                      Row(
                        children: [
                          Icon(
                            Icons.schedule_rounded,
                            size: 13,
                            color: Colors.grey.shade500,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              DateFormat(
                                'EEE, d MMM yyyy – HH:mm',
                                'id_ID',
                              ).format(dt),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    if (k.deskripsi.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        k.deskripsi,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade400,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    // Badge khusus Rapat untuk non-admin
                    if (isRapat && !isAdmin) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.lock_outline_rounded,
                            size: 11,
                            color: Colors.indigo.shade300,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              "Absensi dikelola Admin",
                              style: TextStyle(
                                fontSize: 10,
                                color: Colors.indigo.shade300,
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      k.tipe,
                      style: TextStyle(
                        color: color,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (isAdmin)
                    InkWell(
                      onTap: () => _showEditSheet(k),
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.edit_rounded,
                          color: context.primaryColor,
                          size: 22,
                        ),
                      ),
                    )
                  else
                    Icon(
                      isRapat
                          ? Icons.lock_rounded
                          : Icons.chevron_right_rounded,
                      color: isRapat
                          ? Colors.indigo.shade200
                          : Colors.grey.shade400,
                      size: isRapat ? 18 : 24,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SCREEN 2: ADMIN — Input absensi per karyawan (khusus Rapat)
// ─────────────────────────────────────────────────────────────
class AdminAbsenRapatScreen extends StatefulWidget {
  final JadwalKegiatanModel kegiatan;
  const AdminAbsenRapatScreen({super.key, required this.kegiatan});

  @override
  State<AdminAbsenRapatScreen> createState() => _AdminAbsenRapatScreenState();
}

class _AdminAbsenRapatScreenState extends State<AdminAbsenRapatScreen> {
  final _schoolService = SchoolService();
  final _adminService = AdminService();

  List<Map<String, dynamic>> _karyawanList = [];
  Map<String, String> _statusMap = {};
  bool _isLoading = true;
  bool _isSaving = false;

  // Search
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';

  List<Map<String, dynamic>> get _filtered => _searchQuery.isEmpty
      ? _karyawanList
      : _karyawanList.where((k) {
          final nama = k['nama']?.toString().toLowerCase() ?? '';
          final id = k['id']?.toString().toLowerCase() ?? '';
          final q = _searchQuery.toLowerCase();
          return nama.contains(q) || id.contains(q);
        }).toList();

  final List<Map<String, dynamic>> _statusOptions = [
    {'label': 'Hadir', 'color': Colors.green},
    {'label': 'Izin', 'color': Colors.orange},
    {'label': 'Sakit', 'color': Colors.red},
    {'label': 'Alpa', 'color': Colors.grey},
  ];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final auth = context.read<AuthProvider>();
    final anggotaList = await _adminService.getAllAnggota(auth.clientId ?? '');

    // Inisialisasi: cek cache per karyawan
    final statusMap = <String, String>{};
    for (final a in anggotaList) {
      final id = a['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final cached = await _AbsenCache.getStatus(
        widget.kegiatan.idKegiatan,
        id,
      );
      statusMap[id] = cached ?? 'Hadir'; // default Hadir
    }

    setState(() {
      _karyawanList = List<Map<String, dynamic>>.from(
        anggotaList.map((e) => Map<String, dynamic>.from(e)),
      );
      _statusMap = statusMap;
      _isLoading = false;
    });
  }

  Future<void> _simpanSemua() async {
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    int berhasil = 0;

    for (final karyawan in _karyawanList) {
      final id = karyawan['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final status = _statusMap[id] ?? 'Hadir';

      final res = await _schoolService.absenKegiatan(
        clientId: auth.clientId ?? '',
        idKegiatan: widget.kegiatan.idKegiatan,
        idKaryawan: id,
        statusKehadiran: status,
      );
      if (res['success'] == true) {
        await _AbsenCache.saveStatus(widget.kegiatan.idKegiatan, id, status);
        berhasil++;
      } else {
        d.log('Gagal simpan absen untuk $id: ${res['message']}');
      }
    }

    if (!mounted) return;
    setState(() => _isSaving = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Absensi tersimpan: $berhasil/${_karyawanList.length} karyawan",
        ),
        backgroundColor: berhasil == _karyawanList.length
            ? Colors.green.shade600
            : Colors.orange,
        behavior: SnackBarBehavior.floating,
      ),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        title: Text(
          widget.kegiatan.namaKegiatan,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Info banner
                Container(
                  margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF6366F1).withOpacity(0.08),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: const Color(0xFF6366F1).withOpacity(0.2),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.admin_panel_settings_rounded,
                        color: Color(0xFF6366F1),
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          "Pilih status kehadiran untuk setiap karyawan, lalu tekan 'Simpan Semua'.",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.indigo.shade600,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                // Search Bar
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchCtrl,
                      onChanged: (v) => setState(() => _searchQuery = v),
                      decoration: InputDecoration(
                        hintText: "Cari nama atau ID karyawan...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 13,
                        ),
                        prefixIcon: Icon(
                          Icons.search_rounded,
                          color: context.primaryColor,
                          size: 20,
                        ),
                        suffixIcon: _searchQuery.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.close_rounded, size: 18),
                                onPressed: () => setState(() {
                                  _searchCtrl.clear();
                                  _searchQuery = '';
                                }),
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                // Counter
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Text(
                    _searchQuery.isEmpty
                        ? "${_karyawanList.length} karyawan"
                        : "${_filtered.length} dari ${_karyawanList.length} karyawan",
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade500,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                // List karyawan
                Expanded(
                  child: _filtered.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.person_search_rounded,
                                size: 56,
                                color: Colors.grey.shade300,
                              ),
                              const SizedBox(height: 12),
                              Text(
                                "Tidak ditemukan",
                                style: TextStyle(
                                  color: Colors.grey.shade500,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
                          itemCount: _filtered.length,
                          itemBuilder: (ctx, i) {
                            final k = _filtered[i];
                            final id = k['id']?.toString() ?? '';
                            final nama = k['nama']?.toString() ?? 'Karyawan $i';
                            final currentStatus = _statusMap[id] ?? 'Hadir';

                            return Container(
                              margin: const EdgeInsets.only(bottom: 10),
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.04),
                                    blurRadius: 8,
                                    offset: const Offset(0, 3),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        backgroundColor: context.primaryColor
                                            .withOpacity(0.1),
                                        radius: 18,
                                        child: Text(
                                          nama.isNotEmpty
                                              ? nama[0].toUpperCase()
                                              : '?',
                                          style: TextStyle(
                                            color: context.primaryColor,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          nama,
                                          style: const TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  // Status chips
                                  Wrap(
                                    spacing: 8,
                                    children: _statusOptions.map((opt) {
                                      final label = opt['label'] as String;
                                      final color = opt['color'] as Color;
                                      final isSelected = currentStatus == label;
                                      return GestureDetector(
                                        onTap: () => setState(
                                          () => _statusMap[id] = label,
                                        ),
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 150,
                                          ),
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 14,
                                            vertical: 8,
                                          ),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? color.withOpacity(0.12)
                                                : Colors.grey.shade100,
                                            borderRadius: BorderRadius.circular(
                                              20,
                                            ),
                                            border: Border.all(
                                              color: isSelected
                                                  ? color
                                                  : Colors.transparent,
                                              width: 1.5,
                                            ),
                                          ),
                                          child: Text(
                                            label,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: isSelected
                                                  ? color
                                                  : Colors.grey.shade500,
                                            ),
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
      bottomNavigationBar: _isLoading
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: _isSaving ? null : _simpanSemua,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _isSaving
                          ? "Menyimpan..."
                          : "Simpan Semua (${_karyawanList.length} orang)",
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
              ),
            ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// SCREEN 3: ABSEN MANDIRI (Guru/Karyawan, selain Rapat)
// ─────────────────────────────────────────────────────────────
class AbsenKegiatanScreen extends StatefulWidget {
  final JadwalKegiatanModel kegiatan;
  const AbsenKegiatanScreen({super.key, required this.kegiatan});

  @override
  State<AbsenKegiatanScreen> createState() => _AbsenKegiatanScreenState();
}

class _AbsenKegiatanScreenState extends State<AbsenKegiatanScreen> {
  final _service = SchoolService();
  bool _isLoading = true;
  bool _isSaving = false;
  String _selectedStatus = 'Hadir';

  /// null = belum absen, non-null = sudah absen (terkunci)
  String? _sudahAbsen;

  final List<Map<String, dynamic>> _statusOptions = [
    {
      'label': 'Hadir',
      'icon': Icons.check_circle_rounded,
      'color': Colors.green,
    },
    {'label': 'Izin', 'icon': Icons.info_rounded, 'color': Colors.orange},
    {
      'label': 'Sakit',
      'icon': Icons.local_hospital_rounded,
      'color': Colors.red,
    },
  ];

  @override
  void initState() {
    super.initState();
    _checkCache();
  }

  Future<void> _checkCache() async {
    final auth = context.read<AuthProvider>();
    final saved = await _AbsenCache.getStatus(
      widget.kegiatan.idKegiatan,
      auth.idAnggota ?? '',
    );
    setState(() {
      _sudahAbsen = saved;
      _isLoading = false;
    });
  }

  Future<void> _submitAbsen() async {
    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();

    final res = await _service.absenKegiatan(
      clientId: auth.clientId ?? '',
      idKegiatan: widget.kegiatan.idKegiatan,
      idKaryawan: auth.idAnggota ?? '',
      statusKehadiran: _selectedStatus,
    );

    if (!mounted) return;
    setState(() => _isSaving = false);

    if (res['success'] == true) {
      // Simpan ke cache → UI akan terkunci
      await _AbsenCache.saveStatus(
        widget.kegiatan.idKegiatan,
        auth.idAnggota ?? '',
        _selectedStatus,
      );
      setState(() => _sudahAbsen = _selectedStatus);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Absensi berhasil dicatat!"),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(res['message'] ?? 'Gagal'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    DateTime? dt;
    try {
      dt = DateTime.parse(widget.kegiatan.tanggalWaktu);
    } catch (_) {}

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        title: const Text(
          "Absen Kegiatan",
          style: TextStyle(
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Info Card ──
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [context.primaryColor, const Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: context.primaryColor.withOpacity(0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            widget.kegiatan.tipe,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.kegiatan.namaKegiatan,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        if (dt != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(
                                Icons.schedule_rounded,
                                color: Colors.white70,
                                size: 14,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                DateFormat(
                                  'EEEE, d MMMM yyyy – HH:mm',
                                  'id_ID',
                                ).format(dt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                        if (widget.kegiatan.deskripsi.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.kegiatan.deskripsi,
                            style: const TextStyle(
                              color: Colors.white60,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),

                  // ── Status sudah absen (TERKUNCI) ──
                  if (_sudahAbsen != null) ...[
                    _buildSudahAbsenInfo(_sudahAbsen!),
                  ] else ...[
                    // ── Form Absen ──
                    const Text(
                      "Pilih Status Kehadiran Anda",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Pastikan pilihan sesuai dengan kondisi Anda saat ini.",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ..._statusOptions.map((opt) {
                      final isSelected = _selectedStatus == opt['label'];
                      final color = opt['color'] as Color;
                      return GestureDetector(
                        onTap: () =>
                            setState(() => _selectedStatus = opt['label']),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.08)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: isSelected ? color : Colors.grey.shade200,
                              width: isSelected ? 2 : 1,
                            ),
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: color.withOpacity(0.15),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ]
                                : [],
                          ),
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: color.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  opt['icon'] as IconData,
                                  color: color,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Text(
                                  opt['label'],
                                  style: TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                    color: color,
                                  ),
                                ),
                              ),
                              if (isSelected)
                                Icon(
                                  Icons.check_circle,
                                  color: color,
                                  size: 22,
                                ),
                            ],
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 32),
                    SizedBox(
                      width: double.infinity,
                      height: 58,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _submitAbsen,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: context.primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                          elevation: 2,
                        ),
                        child: _isSaving
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                              )
                            : const Text(
                                "Konfirmasi Absen",
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
    );
  }

  Widget _buildSudahAbsenInfo(String status) {
    Color color;
    IconData icon;
    switch (status) {
      case 'Izin':
        color = Colors.orange;
        icon = Icons.info_rounded;
        break;
      case 'Sakit':
        color = Colors.red;
        icon = Icons.local_hospital_rounded;
        break;
      default:
        color = Colors.green;
        icon = Icons.check_circle_rounded;
    }

    return Column(
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.3), width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 52),
              const SizedBox(height: 12),
              Text(
                "Status Anda: $status",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Absensi Anda sudah tercatat.",
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.amber.shade50,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.amber.shade200),
          ),
          child: Row(
            children: [
              Icon(Icons.lock_rounded, color: Colors.amber.shade700, size: 18),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "Jika perlu koreksi, hubungi Admin Anda untuk mengubah status kehadiran ini.",
                  style: TextStyle(
                    color: Colors.amber.shade800,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
