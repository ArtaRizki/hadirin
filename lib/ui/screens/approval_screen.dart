import 'package:flutter/material.dart';
import 'package:hadirin/core/config/app_config.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  final AttendanceService _service = AttendanceService();
  bool _isLoading = true;
  List<dynamic> _approvalList = [];

  @override
  void initState() {
    super.initState();
    _fetchApprovals();
  }

  Future<void> _fetchApprovals() async {
    setState(() => _isLoading = true);
    try {
      final data = await _service.getPendingApprovals(AppConfig.clientId);
      setState(() {
        _approvalList = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Gagal memuat data: $e"), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _prosesApproval(int rowIndex, String statusBaru, int listIndex) async {
    // Tampilkan loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator(color: FluidColors.primary)),
    );

    try {
      final success = await _service.updateLeaveStatus(AppConfig.clientId, rowIndex, statusBaru);
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Pengajuan berhasil di-$statusBaru"),
            backgroundColor: statusBaru == "Disetujui" ? Colors.green : Colors.red,
          ),
        );
        // Hapus item dari list UI secara instan agar tidak perlu reload server
        setState(() {
          _approvalList.removeAt(listIndex);
        });
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal update: $e"), backgroundColor: Colors.red),
      );
    }
  }

  // Fungsi pembantu untuk melihat foto surat dokter
  void _lihatSuratDokter(String url) {
    if (url.isEmpty) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.network(url, fit: BoxFit.contain),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Tutup"),
            )
          ],
        ),
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
        title: const Text("Persetujuan Izin", style: TextStyle(color: FluidColors.onSurface, fontWeight: FontWeight.bold)),
      ),
      body: RefreshIndicator(
        color: FluidColors.primary,
        onRefresh: _fetchApprovals,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator(color: FluidColors.primary))
            : _approvalList.isEmpty
                ? ListView(
                    children: [
                      SizedBox(height: MediaQuery.of(context).size.height * 0.3),
                      const Center(
                        child: Column(
                          children: [
                            Icon(Icons.check_circle_outline, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text("Tidak ada pengajuan yang menunggu.", style: TextStyle(color: Colors.grey, fontSize: 16)),
                          ],
                        ),
                      ),
                    ],
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(24.0),
                    itemCount: _approvalList.length,
                    itemBuilder: (context, index) {
                      final item = _approvalList[index];
                      return Card(
                        color: FluidColors.surfaceContainerLow,
                        elevation: 0,
                        margin: const EdgeInsets.only(bottom: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(FluidRadii.md)),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    item['nama'],
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.shade100,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      item['tipe'],
                                      style: TextStyle(color: Colors.orange.shade800, fontSize: 12, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text("Tanggal: ${item['rentang']}", style: TextStyle(color: Colors.grey.shade700)),
                              const SizedBox(height: 4),
                              Text("Alasan: ${item['alasan']}", style: TextStyle(color: Colors.grey.shade700)),
                              
                              if (item['foto_bukti'] != null && item['foto_bukti'].toString().isNotEmpty) ...[
                                const SizedBox(height: 8),
                                InkWell(
                                  onTap: () => _lihatSuratDokter(item['foto_bukti']),
                                  child: const Text("Lihat Surat Keterangan", style: TextStyle(color: FluidColors.primary, fontWeight: FontWeight.bold, decoration: TextDecoration.underline)),
                                )
                              ],
                              
                              const Divider(height: 32),
                              
                              // Tombol Aksi
                              Row(
                                children: [
                                  Expanded(
                                    child: OutlinedButton(
                                      onPressed: () => _prosesApproval(item['row_index'], "Ditolak", index),
                                      style: OutlinedButton.styleFrom(foregroundColor: Colors.red, side: const BorderSide(color: Colors.red)),
                                      child: const Text("Tolak"),
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: ElevatedButton(
                                      onPressed: () => _prosesApproval(item['row_index'], "Disetujui", index),
                                      style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                                      child: const Text("Setujui"),
                                    ),
                                  ),
                                ],
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
      ),
    );
  }
}