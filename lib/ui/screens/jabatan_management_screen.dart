import 'package:flutter/material.dart';
import 'package:hadirin/core/models/school_models.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/school_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:provider/provider.dart';

class JabatanManagementScreen extends StatefulWidget {
  const JabatanManagementScreen({super.key});

  @override
  State<JabatanManagementScreen> createState() =>
      _JabatanManagementScreenState();
}

class _JabatanManagementScreenState extends State<JabatanManagementScreen> {
  final _service = SchoolService();
  List<JabatanModel> _jabatanList = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchJabatan();
  }

  Future<void> _fetchJabatan() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final data = await _service.getJabatan(auth.clientId ?? '');
    setState(() {
      _jabatanList = data;
      _isLoading = false;
    });
  }

  void _showTambahDialog() {
    final ctrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: context.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.work_rounded,
                  color: context.primaryColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                "Tambah Jabatan",
                style: TextStyle(fontWeight: FontWeight.w900, fontSize: 17),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Jabatan ini akan muncul di dropdown saat menambah anggota baru.",
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey.shade500,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: ctrl,
                decoration: InputDecoration(
                  hintText: "Contoh: Guru, Staf TU, Kepala Sekolah",
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  prefixIcon: Icon(
                    Icons.badge_rounded,
                    color: Colors.grey.shade400,
                    size: 18,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "Batal",
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (ctrl.text.trim().isEmpty) return;
                      setDialog(() => isSaving = true);
                      final auth = context.read<AuthProvider>();
                      final res = await _service.addJabatan(
                        clientId: auth.clientId ?? '',
                        namaJabatan: ctrl.text.trim(),
                      );
                      if (res['success'] == true) {
                        if (mounted) {
                          Navigator.pop(ctx);
                          _fetchJabatan();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(
                                    Icons.check_circle_rounded,
                                    color: Colors.white,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text("Jabatan berhasil ditambahkan"),
                                ],
                              ),
                              backgroundColor: const Color(0xFF16A34A),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              margin: const EdgeInsets.all(16),
                            ),
                          );
                        }
                      } else {
                        setDialog(() => isSaving = false);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                res['message']?.toString() ?? 'Gagal menambah',
                              ),
                              backgroundColor: Colors.red.shade600,
                            ),
                          );
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: isSaving
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Text("Tambah"),
            ),
          ],
        ),
      ),
    );
  }

  void _konfirmasiHapus(JabatanModel jabatan) {
    showDialog(
      context: context,
      builder: (ctx) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (ctx, setDialog) => AlertDialog(
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
                    Icons.delete_rounded,
                    color: Colors.red.shade600,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  "Hapus Jabatan",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                ),
              ],
            ),
            content: RichText(
              text: TextSpan(
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 14,
                  height: 1.5,
                ),
                children: [
                  const TextSpan(text: "Yakin ingin menghapus jabatan "),
                  TextSpan(
                    text: "\"${jabatan.namaJabatan}\"",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: "?"),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: Text(
                  "Batal",
                  style: TextStyle(color: Colors.grey.shade500),
                ),
              ),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialog(() => isDeleting = true);
                        final auth = context.read<AuthProvider>();
                        final res = await _service.deleteJabatan(
                          clientId: auth.clientId ?? '',
                          idJabatan: jabatan.id,
                        );
                        if (res['success'] == true) {
                          if (mounted) {
                            Navigator.pop(ctx);
                            _fetchJabatan();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      color: Colors.white,
                                    ),
                                    SizedBox(width: 8),
                                    Text("Jabatan berhasil dihapus"),
                                  ],
                                ),
                                backgroundColor: const Color(0xFF16A34A),
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                margin: const EdgeInsets.all(16),
                              ),
                            );
                          }
                        } else {
                          setDialog(() => isDeleting = false);
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  res['message']?.toString() ??
                                      'Gagal menghapus',
                                ),
                                backgroundColor: Colors.red.shade600,
                              ),
                            );
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade600,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: isDeleting
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text("Hapus"),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
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
        title: const Text(
          "Manajemen Jabatan",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(color: context.primaryColor),
            )
          : RefreshIndicator(
              color: context.primaryColor,
              onRefresh: _fetchJabatan,
              child: _jabatanList.isEmpty
                  ? ListView(
                      children: [
                        SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.work_off_rounded,
                                  size: 72,
                                  color: Colors.grey.shade200,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  "Belum ada jabatan",
                                  style: TextStyle(
                                    color: Colors.grey.shade500,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  "Tekan tombol '+' untuk menambahkan jabatan.",
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                      itemCount: _jabatanList.length,
                      itemBuilder: (_, i) => _buildJabatanCard(_jabatanList[i]),
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showTambahDialog,
        backgroundColor: context.primaryColor,
        label: const Text(
          "Tambah",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildJabatanCard(JabatanModel jabatan) {
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
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: const Color(0xFF6366F1).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.work_rounded,
            color: Color(0xFF6366F1),
            size: 22,
          ),
        ),
        title: Text(
          jabatan.namaJabatan,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 15,
          ),
        ),
        subtitle: Text(
          "ID: ${jabatan.id}",
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade400,
          ),
        ),
        trailing: IconButton(
          icon: Icon(
            Icons.delete_outline_rounded,
            color: Colors.red.shade400,
          ),
          onPressed: () => _konfirmasiHapus(jabatan),
        ),
      ),
    );
  }
}
