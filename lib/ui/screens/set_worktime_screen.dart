import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/admin_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:provider/provider.dart';

class SetWorktimeScreen extends StatefulWidget {
  const SetWorktimeScreen({super.key});

  @override
  State<SetWorktimeScreen> createState() => _SetWorktimeScreenState();
}

class _SetWorktimeScreenState extends State<SetWorktimeScreen> {
  bool _isLoading = true;
  bool _isSaving = false;
  
  int _jamMasukMulai = 4;
  int _batasJamMasuk = 7;
  int _jamPulangMulai = 13;

  final List<int> _hours = List.generate(24, (index) => index);

  @override
  void initState() {
    super.initState();
    _loadCurrentConfig();
  }

  Future<void> _loadCurrentConfig() async {
    final auth = context.read<AuthProvider>();
    final config = await AdminService().getOfficeConfig(auth.clientId ?? "");
    if (config != null && mounted) {
      setState(() {
        _jamMasukMulai = int.tryParse(config['jam_masuk_mulai'].toString()) ?? 4;
        _batasJamMasuk = int.tryParse(config['batas_jam_masuk'].toString()) ?? 7;
        _jamPulangMulai = int.tryParse(config['jam_pulang_mulai'].toString()) ?? 13;
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _simpanJamKerja() async {
    // Validasi logis sederhana
    if (_jamMasukMulai >= _batasJamMasuk) {
      _showErrorSnackBar("Jam Masuk Mulai harus lebih awal dari Batas Terlambat.");
      return;
    }
    if (_batasJamMasuk >= _jamPulangMulai) {
      _showErrorSnackBar("Batas Terlambat harus lebih awal dari Jam Pulang.");
      return;
    }

    setState(() => _isSaving = true);
    final auth = context.read<AuthProvider>();
    
    final sukses = await AdminService().updateJamKerja(
      clientId: auth.clientId ?? "",
      jamMasukMulai: _jamMasukMulai,
      batasJamMasuk: _batasJamMasuk,
      jamPulangMulai: _jamPulangMulai,
    );

    if (mounted) {
      setState(() => _isSaving = false);
      if (sukses) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Jam kerja berhasil diperbarui!"),
            backgroundColor: Color(0xFF16A34A),
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context);
      } else {
        _showErrorSnackBar("Gagal memperbarui jam kerja.");
      }
    }
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          "Pengaturan Jam Kerja",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
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
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24.0),
          children: [
            const Text(
              "Atur Jam Operasional",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Sesuaikan rentang waktu absensi masuk dan pulang untuk instansi ini.",
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            
            _buildSettingCard(
              title: "Jam Masuk Mulai",
              description: "Karyawan bisa mulai absen masuk pada jam ini.",
              value: _jamMasukMulai,
              onChanged: (val) => setState(() => _jamMasukMulai = val!),
              icon: Icons.login_rounded,
              accentColor: context.primaryColor,
            ),
            
            const SizedBox(height: 16),
            
            _buildSettingCard(
              title: "Batas Jam Masuk",
              description: "Setelah jam ini, karyawan akan dicatat sebagai 'Terlambat'.",
              value: _batasJamMasuk,
              onChanged: (val) => setState(() => _batasJamMasuk = val!),
              icon: Icons.timer_outlined,
              accentColor: Colors.orange.shade700,
            ),
            
            const SizedBox(height: 16),
            
            _buildSettingCard(
              title: "Jam Pulang Mulai",
              description: "Karyawan bisa melakukan absen pulang mulai jam ini.",
              value: _jamPulangMulai,
              onChanged: (val) => setState(() => _jamPulangMulai = val!),
              icon: Icons.logout_rounded,
              accentColor: const Color(0xFF7C3AED),
            ),
            
            const SizedBox(height: 48),
            
            SizedBox(
              width: double.infinity,
              height: 60,
              child: ElevatedButton(
                onPressed: _isSaving ? null : _simpanJamKerja,
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 4,
                  shadowColor: context.primaryColor.withOpacity(0.4),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: _isSaving
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "Simpan Perubahan",
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
    );
  }

  Widget _buildSettingCard({
    required String title,
    required String description,
    required int value,
    required ValueChanged<int?> onChanged,
    required IconData icon,
    required Color accentColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: accentColor, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          DropdownButtonFormField<int>(
            value: value,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF8FAFC),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            items: _hours.map((h) {
              return DropdownMenuItem<int>(
                value: h,
                child: Text(
                  "${h.toString().padLeft(2, '0')}:00",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }
}
