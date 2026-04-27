import 'package:flutter/material.dart';
import 'package:hadirin/core/models/school_models.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/school_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:hadirin/core/utils/url_helper.dart';
import 'package:hadirin/ui/screens/add_banner_screen.dart';
import 'package:provider/provider.dart';

class BannerManagementScreen extends StatefulWidget {
  const BannerManagementScreen({super.key});

  @override
  State<BannerManagementScreen> createState() => _BannerManagementScreenState();
}

class _BannerManagementScreenState extends State<BannerManagementScreen> {
  final _schoolService = SchoolService();
  List<BannerModel> _banners = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchBanners();
  }

  Future<void> _fetchBanners({bool force = false}) async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final data =
        await _schoolService.getBanners(auth.clientId ?? "", forceRefresh: force);
    setState(() {
      _banners = data;
      _isLoading = false;
    });
  }

  Future<void> _confirmDelete(BannerModel banner) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: const Icon(Icons.delete_rounded, color: Colors.red, size: 40),
        title: const Text("Hapus Banner?",
            textAlign: TextAlign.center,
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
          "Banner '${banner.judul}' akan dihapus permanen.",
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade600),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Batal")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12))),
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Hapus", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      final auth = context.read<AuthProvider>();
      final result = await _schoolService.deleteBanner(
        clientId: auth.clientId ?? "",
        idBanner: banner.idBanner,
      );

      if (!mounted) return;
      if (result['success'] == true) {
        _fetchBanners(force: true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text("Banner berhasil dihapus"),
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showEditSheet(BannerModel banner) {
    final judulCtrl = TextEditingController(text: banner.judul);
    String selectedStatus = banner.status;
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: context.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.edit_rounded,
                        color: context.primaryColor, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Text("Edit Banner",
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w900)),
                ],
              ),
              const SizedBox(height: 24),
              const Text("Judul Pengumuman",
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              TextField(
                controller: judulCtrl,
                maxLines: 2,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.all(14),
                ),
              ),
              const SizedBox(height: 16),
              const Text("Status Tampilan",
                  style: TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                      color: Color(0xFF1E293B))),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: selectedStatus,
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey.shade100,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                items: ["Aktif", "Tidak Aktif"]
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setSheet(() => selectedStatus = v!),
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
                        borderRadius: BorderRadius.circular(16)),
                  ),
                  onPressed: isSaving
                      ? null
                      : () async {
                          setSheet(() => isSaving = true);
                          final auth = context.read<AuthProvider>();
                          final res = await _schoolService.editBanner(
                            clientId: auth.clientId ?? "",
                            idBanner: banner.idBanner,
                            judulBaru: judulCtrl.text.trim(),
                            statusBaru: selectedStatus,
                          );
                          if (!mounted) return;
                          setSheet(() => isSaving = false);
                          if (res['success'] == true) {
                            Navigator.pop(ctx);
                            _fetchBanners(force: true);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content:
                                    const Text("Banner berhasil diperbarui"),
                                backgroundColor: Colors.green.shade700,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                  content: Text(
                                      res['message'] ?? 'Gagal menyimpan'),
                                  backgroundColor: Colors.red),
                            );
                          }
                        },
                  child: isSaving
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text("Simpan Perubahan",
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showImageDialog(BannerModel banner) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Image.network(
                UrlHelper.getDirectDriveUrl(banner.urlGambar),
                fit: BoxFit.contain,
                loadingBuilder: (_, child, progress) => progress == null
                    ? child
                    : const SizedBox(
                        height: 200,
                        child: Center(
                            child: CircularProgressIndicator(
                                color: Colors.white))),
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(20)),
                  child: const Center(
                      child: Icon(Icons.broken_image_rounded,
                          color: Colors.white54, size: 48)),
                ),
              ),
            ),
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close_rounded,
                      color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        title: const Text("Manajemen Banner",
            style: TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _banners.isEmpty
              ? _buildEmpty()
              : RefreshIndicator(
                  onRefresh: () => _fetchBanners(force: true),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                    itemCount: _banners.length,
                    itemBuilder: (_, i) => _buildBannerCard(_banners[i]),
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final refresh = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AddBannerScreen()),
          );
          if (refresh == true) _fetchBanners(force: true);
        },
        backgroundColor: context.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Tambah Banner",
            style:
                TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildEmpty() => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported_rounded,
                size: 72, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text("Belum ada banner",
                style: TextStyle(
                    color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text("Tekan tombol '+' untuk menambah banner baru.",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );

  Widget _buildBannerCard(BannerModel banner) {
    final isAktif = banner.status == "Aktif";
    final imageUrl = UrlHelper.getDirectDriveUrl(banner.urlGambar);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Gambar ──
          GestureDetector(
            onTap: () => _showImageDialog(banner),
            child: ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(20)),
              child: Stack(
                children: [
                  Image.network(
                    imageUrl,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    loadingBuilder: (_, child, progress) {
                      if (progress == null) return child;
                      return Container(
                        height: 180,
                        color: Colors.grey.shade100,
                        child: Center(
                          child: CircularProgressIndicator(
                            value: progress.expectedTotalBytes != null
                                ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                : null,
                            strokeWidth: 2,
                            color: context.primaryColor,
                          ),
                        ),
                      );
                    },
                    errorBuilder: (_, __, ___) => Container(
                      height: 180,
                      color: Colors.grey.shade100,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.broken_image_rounded,
                              color: Colors.grey.shade400, size: 40),
                          const SizedBox(height: 8),
                          Text("Gambar tidak dapat dimuat",
                              style: TextStyle(
                                  color: Colors.grey.shade400,
                                  fontSize: 12)),
                        ],
                      ),
                    ),
                  ),
                  // Tap-to-zoom hint
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.open_in_full_rounded,
                          color: Colors.white, size: 14),
                    ),
                  ),
                  // Status overlay badge
                  if (!isAktif)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.45),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(20)),
                        ),
                        child: const Center(
                          child: Text("TIDAK AKTIF",
                              style: TextStyle(
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  letterSpacing: 2)),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Info & Actions ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 8, 14),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Badge status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: isAktif
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isAktif
                                ? Colors.green.withValues(alpha: 0.3)
                                : Colors.grey.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAktif
                                    ? Colors.green
                                    : Colors.grey.shade500,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              banner.status,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: isAktif
                                    ? Colors.green.shade700
                                    : Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      // Judul
                      Text(
                        banner.judul,
                        style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 15,
                            color: Color(0xFF0F172A)),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Action buttons
                Column(
                  children: [
                    _actionBtn(
                      icon: Icons.edit_rounded,
                      color: context.primaryColor,
                      onTap: () => _showEditSheet(banner),
                    ),
                    const SizedBox(height: 4),
                    _actionBtn(
                      icon: Icons.delete_rounded,
                      color: Colors.red,
                      onTap: () => _confirmDelete(banner),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn(
          {required IconData icon,
          required Color color,
          required VoidCallback onTap}) =>
      InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
      );
}
