import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/leave_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:hadirin/ui/widgets/custom_date_range_picker.dart';

class LeaveRequestScreen extends StatefulWidget {
  const LeaveRequestScreen({super.key});

  @override
  State<LeaveRequestScreen> createState() => _LeaveRequestScreenState();
}

class _LeaveRequestScreenState extends State<LeaveRequestScreen> {
  final _alasanController = TextEditingController();
  String _tipeIzin = "Sakit"; // Default
  DateTimeRange? _selectedDates;
  File? _suratDokter;
  bool _isLoading = false;

  Future<void> _pickDates() async {
    final picked = await showCustomDateRangePicker(
      context: context,
      initialDateRange: _selectedDates,
      allowFuture: true,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _selectedDates = picked);
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() => _suratDokter = File(pickedFile.path));
    }
  }

  void _submitPengajuan() async {
    if (_selectedDates == null) {
      _showSnack("Harap pilih rentang tanggal pengajuan.", isError: true);
      return;
    }
    if (_alasanController.text.trim().isEmpty) {
      _showSnack("Harap isi alasan pengajuan.", isError: true);
      return;
    }
    if (_tipeIzin == "Sakit" && _suratDokter == null) {
      _showSnack(
        "Pengajuan Sakit wajib melampirkan foto Surat Dokter.",
        isError: true,
      );
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final idAnggota = auth.idAnggota ?? "";

    String strTanggal =
        "${DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDates!.start)} s/d ${DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDates!.end)}";

    final result = await LeaveService().submitIzin(
      clientId: auth.clientId ?? "",
      idAnggota: idAnggota,
      namaAnggota: auth.namaAnggota ?? "",
      tipeIzin: _tipeIzin,
      rentangTanggal: strTanggal,
      alasan: _alasanController.text.trim(),
      imagePath: _suratDokter?.path,
      isAdmin: auth.isAdmin,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _showSnack(result['message'], isSuccess: true);
      if (mounted) Navigator.pop(context); // Kembali ke beranda
    } else {
      _showSnack(result['message'], isError: true);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false, bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isSuccess
                  ? Icons.check_circle_outline_rounded
                  : Icons.error_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isSuccess
            ? const Color(0xFF16A34A)
            : (isError ? Colors.red.shade600 : Colors.orange.shade800),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF), // Latar belakang seragam
      appBar: AppBar(
        backgroundColor: Colors.transparent,
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
        title: const Text(
          "Pengajuan Izin",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Dekorasi blob atas kanan
            Positioned(
              top: -50,
              right: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.primaryColor.withOpacity(0.06),
                ),
              ),
            ),
            // Dekorasi blob bawah kiri
            Positioned(
              bottom: -80,
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

            SafeArea(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 40),
                children: [
                  // HEADER SECTION
                  const Text(
                    "Formulir Pengajuan",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Lengkapi data di bawah ini untuk mengajukan ketidakhadiran Anda.",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontSize: 13,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),

                  // 1. Pilih Tipe
                  const Text(
                    "Jenis Pengajuan",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        initialValue: _tipeIzin,
                        icon: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: context.primaryColor,
                        ),
                        decoration: InputDecoration(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(16),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: ["Sakit", "Izin Keperluan", "Cuti Tahunan"].map((
                          String val,
                        ) {
                          return DropdownMenuItem(
                            value: val,
                            child: Text(
                              val,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (val) => setState(() {
                          _tipeIzin = val!;
                          _suratDokter = null; // Reset foto jika ganti tipe
                        }),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 2. Pilih Tanggal
                  const Text(
                    "Rentang Waktu",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: InkWell(
                      onTap: _pickDates,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 16,
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.calendar_month_rounded,
                              color: context.primaryColor,
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedDates == null
                                    ? "Pilih Tanggal Mulai - Selesai"
                                    : "${DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDates!.start)} - ${DateFormat('dd MMM yyyy', 'id_ID').format(_selectedDates!.end)}",
                                style: TextStyle(
                                  color: _selectedDates == null
                                      ? Colors.grey.shade500
                                      : const Color(0xFF0F172A),
                                  fontWeight: _selectedDates == null
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 3. Alasan
                  const Text(
                    "Keterangan / Alasan Lengkap",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _alasanController,
                      maxLines: 4,
                      decoration: InputDecoration(
                        hintText:
                            "Tuliskan alasan Anda secara detail di sini...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        contentPadding: const EdgeInsets.all(16),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(
                            color: context.primaryColor,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // 4. Upload Surat Dokter (Hanya jika Sakit)
                  if (_tipeIzin == "Sakit") ...[
                    Row(
                      children: const [
                        Text(
                          "Lampiran Surat Dokter ",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          "(Wajib)",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    InkWell(
                      onTap: _pickImage,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        height: 140,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: context.primaryColor.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: context.primaryColor.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: _suratDokter == null
                            ? Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: context.primaryColor.withOpacity(
                                        0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.camera_alt_rounded,
                                      color: context.primaryColor,
                                      size: 28,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  const Text(
                                    "Ambil Foto Surat Keterangan",
                                    style: TextStyle(
                                      color: context.primaryColor,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              )
                            : ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  _suratDokter!,
                                  fit: BoxFit.cover,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],

                  const SizedBox(height: 16),

                  // 5. Tombol Submit
                  SizedBox(
                    width: double.infinity,
                    height: 60,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _submitPengajuan,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shadowColor: context.primaryColor.withOpacity(0.4),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "Kirim Pengajuan",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
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
}
