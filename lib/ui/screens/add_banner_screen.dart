import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:provider/provider.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/school_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';

class AddBannerScreen extends StatefulWidget {
  const AddBannerScreen({super.key});

  @override
  State<AddBannerScreen> createState() => _AddBannerScreenState();
}

class _AddBannerScreenState extends State<AddBannerScreen> {
  final _judulController = TextEditingController();
  final _schoolService = SchoolService();
  final _picker = ImagePicker();
  File? _image;
  bool _isLoading = false;
  // Ukuran file untuk ditampilkan
  int _originalSize = 0;
  int _compressedSize = 0;
  List<int>? _compressedBytes; // cache hasil kompresi

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 100,
    );

    if (pickedFile != null) {
      final file = File(pickedFile.path);
      final origSize = await file.length();

      setState(() {
        _image = file;
        _originalSize = origSize;
        _compressedSize = 0;
        _compressedBytes = null;
      });

      // Langsung compress untuk preview ukuran
      await _compressImage(file);
    }
  }

  Future<void> _compressImage(File file) async {
    setState(() => _isLoading = true);
    try {
      final targetPath = '${file.path}_compressed.jpg';
      final result = await FlutterImageCompress.compressAndGetFile(
        file.path,
        targetPath,
        quality: 35,
        minWidth: 800,
        minHeight: 400,
        format: CompressFormat.jpeg,
      );
      if (result != null) {
        final bytes = await result.readAsBytes();
        // Hapus temp file
        try { File(targetPath).deleteSync(); } catch (_) {}
        setState(() {
          _compressedBytes = bytes;
          _compressedSize = bytes.length;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _uploadBanner() async {
    if (_judulController.text.isEmpty) {
      _showSnackBar("Judul pengumuman wajib diisi!", isError: true);
      return;
    }
    if (_image == null) {
      _showSnackBar("Pilih gambar banner terlebih dahulu!", isError: true);
      return;
    }
    if (_compressedBytes == null) {
      _showSnackBar("Sedang memproses gambar, harap tunggu...", isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final base64Image = base64Encode(_compressedBytes!);

      final result = await _schoolService.addBanner(
        clientId: auth.clientId ?? "",
        judul: _judulController.text.trim(),
        fotoBase64: base64Image,
      );

      if (result['success'] == true) {
        _showSnackBar("Banner berhasil diupload!", isError: false);
        if (!mounted) return;
        Navigator.pop(context, true);
      } else {
        _showSnackBar(result['message'] ?? 'Gagal upload', isError: true);
      }
    } catch (e) {
      _showSnackBar("Terjadi kesalahan: $e", isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  String _formatSize(int bytes) {
    if (bytes <= 0) return '0 B';
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  Widget _buildSizeInfo() {
    final hemat = _originalSize > 0 && _compressedSize > 0
        ? ((_originalSize - _compressedSize) / _originalSize * 100)
            .toStringAsFixed(0)
        : null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.green.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.shade200),
      ),
      child: _compressedSize == 0
          ? Row(
              children: [
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.green.shade600,
                  ),
                ),
                const SizedBox(width: 10),
                Text("Sedang mengompres gambar...",
                    style: TextStyle(
                        fontSize: 12, color: Colors.green.shade700)),
              ],
            )
          : Row(
              children: [
                Icon(Icons.compress_rounded,
                    color: Colors.green.shade600, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: TextStyle(
                          fontSize: 12, color: Colors.green.shade800),
                      children: [
                        TextSpan(
                          text: _formatSize(_originalSize),
                          style: const TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey),
                        ),
                        const TextSpan(text: "  →  "),
                        TextSpan(
                          text: _formatSize(_compressedSize),
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                        if (hemat != null)
                          TextSpan(
                            text: "  (hemat $hemat%)",
                            style: TextStyle(
                                color: Colors.green.shade600,
                                fontWeight: FontWeight.w600),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  void _showSnackBar(String msg, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red.shade600 : Colors.green.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        title: const Text(
          "Upload Banner",
          style: TextStyle(fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Buat Pengumuman Baru",
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: Color(0xFF0F172A)),
            ),
            const SizedBox(height: 8),
            Text(
              "Banner ini akan muncul di dashboard depan siswa dan guru.",
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 32),

            // Input Judul
            const Text(
              "Judul Pengumuman",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _judulController,
              decoration: InputDecoration(
                hintText: "Contoh: Libur Hari Raya Idul Fitri",
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              ),
              maxLines: 2,
            ),
            const SizedBox(height: 24),

            // Pilih Gambar
            const Text(
              "Gambar Banner",
              style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
            ),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _pickImage,
              child: Container(
                width: double.infinity,
                height: 180,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                ),
                child: _image != null
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Image.file(_image!, fit: BoxFit.cover),
                      )
                    : Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_rounded, size: 48, color: context.primaryColor),
                          const SizedBox(height: 8),
                          Text(
                            "Klik untuk pilih gambar dari galeri",
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
                          ),
                        ],
                      ),
              ),
            ),
            // Info kompresi
            if (_image != null) ...[  
              const SizedBox(height: 10),
              _buildSizeInfo(),
            ],
            const SizedBox(height: 48),

            // Tombol Upload
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _uploadBanner,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        "Upload & Publikasikan",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
