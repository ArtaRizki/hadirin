import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

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
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(primary: FluidColors.primary),
        ),
        child: child!,
      ),
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
      _showSnack("Harap pilih rentang tanggal pengajuan.");
      return;
    }
    if (_alasanController.text.trim().isEmpty) {
      _showSnack("Harap isi alasan pengajuan.");
      return;
    }
    if (_tipeIzin == "Sakit" && _suratDokter == null) {
      _showSnack("Pengajuan Sakit wajib melampirkan foto Surat Dokter.");
      return;
    }

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    String strTanggal =
        "${DateFormat('dd MMM yyyy').format(_selectedDates!.start)} s/d ${DateFormat('dd MMM yyyy').format(_selectedDates!.end)}";

    final result = await AttendanceService().submitIzin(
      idKaryawan: auth.idKaryawan!,
      tipeIzin: _tipeIzin,
      rentangTanggal: strTanggal,
      alasan: _alasanController.text.trim(),
      imagePath: _suratDokter?.path,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      _showSnack(result['message'], isSuccess: true);
      Navigator.pop(context); // Kembali ke beranda
    } else {
      _showSnack(result['message']);
    }
  }

  void _showSnack(String msg, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isSuccess ? FluidColors.primary : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FluidColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: FluidColors.onSurface),
        title: const Text(
          "Pengajuan Izin",
          style: TextStyle(
            color: FluidColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24.0),
        children: [
          // 1. Pilih Tipe
          const Text(
            "Jenis Pengajuan",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            initialValue: _tipeIzin,
            decoration: InputDecoration(
              filled: true,
              fillColor: FluidColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FluidRadii.sm),
                borderSide: BorderSide.none,
              ),
            ),
            items: ["Sakit", "Izin Keperluan", "Cuti Tahunan"].map((
              String val,
            ) {
              return DropdownMenuItem(value: val, child: Text(val));
            }).toList(),
            onChanged: (val) => setState(() {
              _tipeIzin = val!;
              _suratDokter = null; // Reset foto jika ganti tipe
            }),
          ),
          const SizedBox(height: 24),

          // 2. Pilih Tanggal
          const Text(
            "Rentang Waktu",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          InkWell(
            onTap: _pickDates,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                color: FluidColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(FluidRadii.sm),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_month, color: FluidColors.primary),
                  const SizedBox(width: 12),
                  Text(
                    _selectedDates == null
                        ? "Pilih Tanggal Mulai - Selesai"
                        : "${DateFormat('dd/MM/yyyy').format(_selectedDates!.start)} - ${DateFormat('dd/MM/yyyy').format(_selectedDates!.end)}",
                    style: TextStyle(
                      color: _selectedDates == null
                          ? Colors.grey
                          : FluidColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 3. Alasan
          const Text(
            "Keterangan / Alasan Lengkap",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _alasanController,
            maxLines: 4,
            decoration: InputDecoration(
              hintText: "Tulis alasan Anda di sini...",
              filled: true,
              fillColor: FluidColors.surfaceContainerLow,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(FluidRadii.sm),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // 4. Upload Surat Dokter (Hanya jika Sakit)
          if (_tipeIzin == "Sakit") ...[
            const Text(
              "Lampiran Surat Dokter (Wajib)",
              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickImage,
              child: Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: FluidColors.primaryGhost,
                  borderRadius: BorderRadius.circular(FluidRadii.sm),
                  border: Border.all(
                    color: FluidColors.primary.withOpacity(0.5),
                    style: BorderStyle.solid,
                  ),
                ),
                child: _suratDokter == null
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.camera_alt,
                            color: FluidColors.primary,
                            size: 32,
                          ),
                          SizedBox(height: 8),
                          Text(
                            "Ambil Foto Surat Keterangan",
                            style: TextStyle(color: FluidColors.primary),
                          ),
                        ],
                      )
                    : ClipRRect(
                        borderRadius: BorderRadius.circular(FluidRadii.sm),
                        child: Image.file(_suratDokter!, fit: BoxFit.cover),
                      ),
              ),
            ),
            const SizedBox(height: 32),
          ],

          // 5. Tombol Submit
          SizedBox(
            height: 56,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _submitPengajuan,
              style: ElevatedButton.styleFrom(
                backgroundColor: FluidColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(FluidRadii.sm),
                ),
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text(
                      "Kirim Pengajuan",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
