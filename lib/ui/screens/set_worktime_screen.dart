import 'package:flutter/cupertino.dart';
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

  String _jamMasukMulai = "04:00";
  String _batasJamMasuk = "07:00";
  String _jamPulangMulai = "13:00";

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
        _jamMasukMulai = config['jam_masuk_mulai']?.toString() == "null" ? "-" : (config['jam_masuk_mulai']?.toString() ?? "-");
        _batasJamMasuk = config['batas_jam_masuk']?.toString() == "null" ? "-" : (config['batas_jam_masuk']?.toString() ?? "-");
        _jamPulangMulai = config['jam_pulang_mulai']?.toString() == "null" ? "-" : (config['jam_pulang_mulai']?.toString() ?? "-");
        _isLoading = false;
      });
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  int _timeToTotalMinutes(String time) {
    if (time == "-") return 0;
    final parts = time.split(':');
    return (int.parse(parts[0]) * 60) + int.parse(parts[1]);
  }

  void _simpanJamKerja() async {
    final minMasuk = _timeToTotalMinutes(_jamMasukMulai);
    final minBatas = _timeToTotalMinutes(_batasJamMasuk);
    final minPulang = _timeToTotalMinutes(_jamPulangMulai);

    // Validasi logis
    if (minMasuk >= minBatas) {
      _showErrorSnackBar("Jam Masuk Mulai harus lebih awal dari Batas Terlambat.");
      return;
    }
    if (minBatas >= minPulang) {
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

  void _showTimePicker(String current, Function(String) onPicked) {
    final validTime = (current == "-" || current.isEmpty) ? "00:00" : current;
    final parts = validTime.split(':');
    DateTime initial = DateTime(2026, 1, 1, int.parse(parts[0]), int.parse(parts[1]));
    DateTime tempDateTime = initial;

    showCupertinoModalPopup(
      context: context,
      builder: (context) => Material(
        color: Colors.transparent,
        child: Container(
          height: 360,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(32),
              topRight: Radius.circular(32),
            ),
          ),
          child: Column(
            children: [
              // Grab Handle
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 8),

              // Header
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.grey.shade600,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: const Text(
                        "Batal",
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                      ),
                    ),
                    const Text(
                      "Pilih Jam",
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 17,
                        color: Color(0xFF0F172A),
                        letterSpacing: -0.5,
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        onPicked(
                          "${tempDateTime.hour.toString().padLeft(2, '0')}:${tempDateTime.minute.toString().padLeft(2, '0')}",
                        );
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "Selesai",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Picker
              Expanded(
                child: CupertinoDatePicker(
                  mode: CupertinoDatePickerMode.time,
                  initialDateTime: initial,
                  use24hFormat: true,
                  onDateTimeChanged: (date) {
                    tempDateTime = date;
                  },
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
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
              onTap: () => _showTimePicker(_jamMasukMulai, (val) => setState(() => _jamMasukMulai = val)),
              icon: Icons.login_rounded,
              accentColor: context.primaryColor,
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: "Batas Jam Masuk",
              description: "Setelah jam ini, karyawan akan dicatat sebagai 'Terlambat'.",
              value: _batasJamMasuk,
              onTap: () => _showTimePicker(_batasJamMasuk, (val) => setState(() => _batasJamMasuk = val)),
              icon: Icons.timer_outlined,
              accentColor: Colors.orange.shade700,
            ),

            const SizedBox(height: 16),

            _buildSettingCard(
              title: "Jam Pulang Mulai",
              description: "Karyawan bisa melakukan absen pulang mulai jam ini.",
              value: _jamPulangMulai,
              onTap: () => _showTimePicker(_jamPulangMulai, (val) => setState(() => _jamPulangMulai = val)),
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
    required String value,
    required VoidCallback onTap,
    required IconData icon,
    required Color accentColor,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
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
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    value,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: accentColor,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.unfold_more_rounded, size: 20, color: Colors.grey.shade400),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
