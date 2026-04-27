import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/leave_service.dart';
import 'package:hadirin/core/config/app_config.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:hadirin/core/utils/url_helper.dart';
import 'package:hadirin/ui/widgets/skeleton_loader.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class ApprovalScreen extends StatefulWidget {
  const ApprovalScreen({super.key});

  @override
  State<ApprovalScreen> createState() => _ApprovalScreenState();
}

class _ApprovalScreenState extends State<ApprovalScreen> {
  final _service = LeaveService();
  bool _isLoading = true;
  List<dynamic> _approvalList = [];
  List<dynamic> _filteredApprovalList = [];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchApprovals();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredApprovalList = _approvalList.where((item) {
        final nama = (item['nama'] ?? "").toString().toLowerCase();
        final tipe = (item['tipe'] ?? "").toString().toLowerCase();
        final alasan = (item['alasan'] ?? "").toString().toLowerCase();
        return nama.contains(query) ||
            tipe.contains(query) ||
            alasan.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchApprovals() async {
    setState(() => _isLoading = true);
    try {
      final auth = context.read<AuthProvider>();
      final clientId = auth.clientId ?? "";

      final data = await _service.getPendingApprovals(clientId);
      setState(() {
        _approvalList = data;
        _filteredApprovalList = data;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Gagal memuat data: $e"),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _prosesApproval(
    int rowIndex,
    String statusBaru,
    int listIndex,
  ) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 32.0, horizontal: 24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: context.primaryColor),
              const SizedBox(height: 24),
              Text(
                "Memproses $statusBaru...",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Mohon tunggu sebentar",
                style: TextStyle(color: Colors.grey.shade500, fontSize: 13),
              ),
            ],
          ),
        ),
      ),
    );

    try {
      final auth = context.read<AuthProvider>();
      final clientId = auth.clientId ?? "";

      final success = await _service.updateLeaveStatus(
        clientId,
        rowIndex,
        statusBaru,
      );

      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  statusBaru == "Disetujui"
                      ? Icons.check_circle_outline
                      : Icons.info_outline,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text("Pengajuan berhasil di-$statusBaru"),
              ],
            ),
            backgroundColor: statusBaru == "Disetujui"
                ? const Color(0xFF16A34A)
                : Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
        setState(() {
          _approvalList.removeAt(listIndex);
          _onSearchChanged(); // Refresh filtered list
        });
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Tutup loading dialog
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Gagal update: $e"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }
  }

  void _lihatFoto(String url) {
    if (url.isEmpty || url == "No Photo" || url == "null") {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Tidak ada lampiran foto.")));
      return;
    }
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              color: Colors.grey.shade100,
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.6,
              ),
              child: Image.network(
                UrlHelper.getDirectDriveUrl(url),
                fit: BoxFit.contain,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const SizedBox(
                    height: 200,
                    child: Center(child: CircularProgressIndicator()),
                  );
                },
                errorBuilder: (context, error, stackTrace) => const SizedBox(
                  height: 200,
                  child: Center(child: Text("Gagal memuat gambar")),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SizedBox(
                width: double.infinity,
                height: 45,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    "Tutup",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDetailDialog(dynamic item) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(28.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Detail Pengajuan",
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.grey),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                _buildDetailRow("Karyawan", item['nama'] ?? "-"),
                _buildDetailRow(
                  "Jenis Izin",
                  item['tipe']?.toString().toUpperCase() ?? "-",
                ),
                _buildDetailRow("Periode", item['rentang'] ?? "-"),
                _buildDetailRow("Alasan", item['alasan'] ?? "-"),
                _buildDetailRow(
                  "Waktu Pengajuan",
                  item['waktu_pengajuan'] ?? "-",
                ),
                if (item['no_hp'] != null &&
                    item['no_hp'].toString().isNotEmpty &&
                    item['no_hp'].toString() != "null")
                  _buildDetailRow(
                    "No. WhatsApp",
                    UrlHelper.formatPhoneNumber(item['no_hp'].toString()),
                  ),

                if (item['foto'] != null &&
                    item['foto'].toString() != "No Photo" &&
                    item['foto'].toString() != "null")
                  Padding(
                    padding: const EdgeInsets.only(top: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "Lampiran Dokumen:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: InkWell(
                            onTap: () => _lihatFoto(item['foto']),
                            child: Image.network(
                              UrlHelper.getDirectDriveUrl(item['foto']),
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                    height: 100,
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Center(
                                      child: Text("Gagal memuat lampiran"),
                                    ),
                                  ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF0F172A),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      elevation: 0,
                    ),
                    child: const Text(
                      "Tutup Dashboard",
                      style: TextStyle(fontWeight: FontWeight.bold),
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

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade500,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Color(0xFF1E293B),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBadgeColor(String tipe) {
    switch (tipe.toLowerCase()) {
      case 'sakit':
        return Colors.red;
      case 'cuti':
        return Colors.purple;
      case 'izin':
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
            size: 16,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Persetujuan Izin",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // SEARCH BAR
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (_) => setState(() {}),
                  decoration: InputDecoration(
                    hintText: "Cari nama, jenis, atau alasan...",
                    hintStyle: TextStyle(
                      color: Colors.grey.shade400,
                      fontSize: 14,
                    ),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: context.primaryColor,
                    ),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded, size: 20),
                            onPressed: () {
                              _searchController.clear();
                              _onSearchChanged();
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                ),
              ),
            ),

            Expanded(
              child: Stack(
                children: [
                  // BLOBS DECORATION
                  Positioned(
                    top: -70,
                    right: -50,
                    child: Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.primaryColor.withOpacity(0.06),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: -50,
                    left: -40,
                    child: Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF7C3AED).withOpacity(0.05),
                      ),
                    ),
                  ),

                  RefreshIndicator(
                    color: context.primaryColor,
                    onRefresh: _fetchApprovals,
                    child: _isLoading
                        ? const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 20),
                            child: CardSkeletonList(itemCount: 4),
                          )
                        : _filteredApprovalList.isEmpty
                        ? _buildEmptyState()
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                            itemCount: _filteredApprovalList.length,
                            itemBuilder: (context, index) {
                              final item = _filteredApprovalList[index];
                              final badgeColor = _getBadgeColor(
                                item['tipe'] ?? "",
                              );
                              final listIndex = _approvalList.indexOf(item);

                              return Container(
                                margin: const EdgeInsets.only(bottom: 16),
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
                                child: Padding(
                                  padding: const EdgeInsets.all(20.0),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // HEADER
                                      Row(
                                        children: [
                                          CircleAvatar(
                                            radius: 20,
                                            backgroundColor: badgeColor
                                                .withOpacity(0.1),
                                            child: Text(
                                              (item['nama'] ?? "A")
                                                  .substring(0, 1)
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: badgeColor,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  item['nama'] ?? "Tanpa Nama",
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.w800,
                                                    fontSize: 16,
                                                  ),
                                                ),
                                                Text(
                                                  "Diajukan: ${item['waktu_pengajuan'] ?? "-"}",
                                                  style: TextStyle(
                                                    color: Colors.grey.shade500,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (item['no_hp'] != null &&
                                              item['no_hp']
                                                  .toString()
                                                  .isNotEmpty)
                                            IconButton(
                                              onPressed: () =>
                                                  UrlHelper.launchWhatsApp(
                                                    phone: item['no_hp']
                                                        .toString(),
                                                    message:
                                                        "Halo ${item['nama']}, ini Admin ${AppConfig.appName} mengenai pengajuan ${item['tipe']} Anda.",
                                                  ),
                                              icon: const Icon(
                                                Icons.phone,
                                                color: Color(0xFF16A34A),
                                              ),
                                            ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 10,
                                              vertical: 5,
                                            ),
                                            decoration: BoxDecoration(
                                              color: badgeColor.withOpacity(
                                                0.1,
                                              ),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Text(
                                              item['tipe']
                                                  .toString()
                                                  .toUpperCase(),
                                              style: TextStyle(
                                                color: badgeColor,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const Divider(height: 32),
                                      // CONTENT (INLINE)
                                      _buildInfoRow(
                                        Icons.calendar_month_rounded,
                                        item['rentang'] ?? "-",
                                      ),
                                      const SizedBox(height: 12),
                                      _buildInfoRow(
                                        Icons.notes_rounded,
                                        item['alasan'] ?? "-",
                                      ),

                                      const SizedBox(height: 24),
                                      // ACTIONS
                                      Row(
                                        children: [
                                          Expanded(
                                            child: OutlinedButton(
                                              onPressed: () =>
                                                  _showDetailDialog(item),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor:
                                                    Colors.grey.shade700,
                                                side: BorderSide(
                                                  color: Colors.grey.shade300,
                                                ),
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                              child: const Text(
                                                "Detail",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: ElevatedButton(
                                              onPressed: () => _prosesApproval(
                                                item['row_index'],
                                                "Disetujui",
                                                listIndex,
                                              ),
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF16A34A,
                                                ),
                                                foregroundColor: Colors.white,
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      vertical: 14,
                                                    ),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                                elevation: 0,
                                              ),
                                              child: const Text(
                                                "Setujui",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 8),
                                          IconButton(
                                            onPressed: () => _prosesApproval(
                                              item['row_index'],
                                              "Ditolak",
                                              listIndex,
                                            ),
                                            icon: const Icon(
                                              Icons.close_rounded,
                                              color: Colors.red,
                                            ),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.red
                                                  .withOpacity(0.1),
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(12),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
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

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: Colors.grey.shade400),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              color: Colors.grey.shade700,
              fontSize: 13,
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 24),
              const Text(
                "Semua Beres!",
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const SizedBox(height: 8),
              Text(
                "Tidak ada pengajuan yang menunggu persetujuan.",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
