import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/admin_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:hadirin/ui/widgets/skeleton_loader.dart';
import 'package:provider/provider.dart';
import 'package:hadirin/core/utils/url_helper.dart';

class AnggotaListScreen extends StatefulWidget {
  const AnggotaListScreen({super.key});

  @override
  State<AnggotaListScreen> createState() => _AnggotaListScreenState();
}

class _AnggotaListScreenState extends State<AnggotaListScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  List<dynamic> _anggota = [];
  List<dynamic> _filteredAnggota = []; // NEW
  String _errorMsg = "";
  final TextEditingController _searchController = TextEditingController(); // NEW

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged); // NEW
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fetchEmployees();
    });
  }

  @override // NEW
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredAnggota = _anggota.where((emp) {
        final nama = emp['nama'].toString().toLowerCase();
        final id = emp['id'].toString().toLowerCase();
        return nama.contains(query) || id.contains(query);
      }).toList();
    });
  }

  Future<void> _fetchEmployees() async {
    setState(() {
      _isLoading = true;
      _errorMsg = "";
    });

    try {
      final auth = context.read<AuthProvider>();
      final clientId = auth.clientId ?? "";
      final data = await _adminService.getAllAnggota(clientId);
      setState(() {
        _anggota = data;
        _filteredAnggota = data; // Initialize filtered list
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMsg = e.toString().replaceAll("Exception: ", "");
          _isLoading = false;
        });
      }
    }
  }

  void _showActionSheet(Map<String, dynamic> emp) {
    final auth = context.read<AuthProvider>();
    final isSuperAdmin = emp['nama'].toString().toLowerCase().contains("admin") ||
        emp['bagian'].toString().toLowerCase().contains("pemilik");

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: const EdgeInsets.only(bottom: 24),
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: isSuperAdmin ? Colors.amber.withOpacity(0.1) : context.primaryColor.withOpacity(0.1),
                  child: Text(
                    emp['nama'].toString().substring(0, 1).toUpperCase(),
                    style: TextStyle(color: isSuperAdmin ? Colors.amber.shade800 : context.primaryColor, fontWeight: FontWeight.bold, fontSize: 20),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        emp['nama'] ?? "-",
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: Color(0xFF0F172A)),
                      ),
                      Text("ID: ${emp['id']}", style: TextStyle(color: Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            if (emp['no_hp'] != null && emp['no_hp'].toString().isNotEmpty && emp['no_hp'].toString() != "null")
              _buildActionItem(
                icon: Icons.phone_rounded,
                label: "Hubungi via WhatsApp",
                color: const Color(0xFF16A34A),
                onTap: () {
                  Navigator.pop(context);
                  UrlHelper.launchWhatsApp(
                    phone: emp['no_hp'].toString(),
                    message: "Halo ${emp['nama']}, saya dari Admin ingin menghubungi Anda.",
                  );
                },
              ),
            _buildActionItem(
              icon: Icons.edit_note_rounded,
              label: "Edit Data Anggota",
              color: Colors.blue.shade600,
              onTap: () {
                Navigator.pop(context);
                _showEditDialog(emp);
              },
            ),
            _buildActionItem(
              icon: Icons.phonelink_erase_rounded,
              label: "Reset Device ID",
              color: Colors.orange.shade700,
              onTap: () {
                Navigator.pop(context);
                _confirmResetDevice(emp);
              },
            ),
            const Divider(height: 32),
            _buildActionItem(
              icon: Icons.delete_outline_rounded,
              label: "Hapus Anggota",
              color: Colors.red.shade600,
              isDestructive: true,
              onTap: () {
                Navigator.pop(context);
                _confirmDelete(emp);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    bool isDestructive = false,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDestructive ? color : const Color(0xFF0F172A),
              ),
            ),
            const Spacer(),
            Icon(Icons.chevron_right_rounded, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(Map<String, dynamic> emp) {
    final namaController = TextEditingController(text: emp['nama']);
    final divisiController = TextEditingController(text: emp['bagian']);
    final phoneController = TextEditingController(text: emp['no_hp']);
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: const Text("Edit Anggota", style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: -0.5)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPopupField(controller: namaController, label: "Nama Lengkap", icon: Icons.person_outline),
                const SizedBox(height: 16),
                _buildPopupField(controller: divisiController, label: "Bagian / Divisi", icon: Icons.work_outline),
                const SizedBox(height: 16),
                _buildPopupField(controller: phoneController, label: "No. WhatsApp", icon: Icons.phone_android, keyboardType: TextInputType.phone),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Batal", style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      setDialogState(() => isSaving = true);
                      final auth = context.read<AuthProvider>();
                      final result = await _adminService.updateAnggota(
                        clientId: auth.clientId ?? "",
                        idAnggota: emp['id'],
                        nama: namaController.text.trim(),
                        divisi: divisiController.text.trim(),
                        noHp: phoneController.text.trim(),
                      );
                      if (mounted) {
                        setDialogState(() => isSaving = false);
                        Navigator.pop(context);
                        if (result['success']) {
                          _fetchEmployees();
                          _showSuccessSnackBar("Data berhasil diperbarui");
                        } else {
                          _showErrorSnackBar(result['message']);
                        }
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text("Simpan", style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20, color: context.primaryColor),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: context.primaryColor, width: 1.5)),
        filled: true,
        fillColor: Colors.grey.shade50,
      ),
    );
  }

  void _confirmResetDevice(Map<String, dynamic> emp) {
    showDialog(
      context: context,
      builder: (context) {
        bool isProcessing = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text("Reset Perangkat?"),
            content: Text("Hapus pendaftaran HP untuk ${emp['nama']}? User harus login ulang untuk mendaftarkan HP baru."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
              ElevatedButton(
                onPressed: isProcessing
                    ? null
                    : () async {
                        setDialogState(() => isProcessing = true);
                        final auth = context.read<AuthProvider>();
                        final result = await _adminService.resetDeviceID(auth.clientId ?? "", emp['id']);
                        if (mounted) {
                          setDialogState(() => isProcessing = false);
                          Navigator.pop(context);
                          if (result['code'] == 200) {
                            _fetchEmployees();
                            _showSuccessSnackBar("Device ID berhasil di-reset");
                          } else {
                            _showErrorSnackBar(result['message']);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange.shade700, foregroundColor: Colors.white),
                child: isProcessing ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Reset HP"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _confirmDelete(Map<String, dynamic> emp) {
    showDialog(
      context: context,
      builder: (context) {
        bool isDeleting = false;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: const Text("Hapus Anggota?"),
            content: Text("Apakah Anda yakin ingin menghapus ${emp['nama']}? Data absensi tetap ada namun akun ini tidak bisa login lagi."),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text("Batal")),
              ElevatedButton(
                onPressed: isDeleting
                    ? null
                    : () async {
                        setDialogState(() => isDeleting = true);
                        final auth = context.read<AuthProvider>();
                        final result = await _adminService.deleteAnggota(clientId: auth.clientId ?? "", idAnggota: emp['id']);
                        if (mounted) {
                          setDialogState(() => isDeleting = false);
                          Navigator.pop(context);
                          if (result['success']) {
                            _fetchEmployees();
                            _showSuccessSnackBar("Anggota berhasil dihapus");
                          } else {
                            _showErrorSnackBar(result['message']);
                          }
                        }
                      },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade600, foregroundColor: Colors.white),
                child: isDeleting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text("Hapus"),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showSuccessSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 10), Text(msg)]),
        backgroundColor: const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showErrorSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(children: [const Icon(Icons.error, color: Colors.white), const SizedBox(width: 10), Text(msg)]),
        backgroundColor: Colors.red.shade600,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Widget _buildStatusBadge({
    required bool isRegistered,
    required String activeLabel,
    required String inactiveLabel,
    required IconData activeIcon,
    required IconData inactiveIcon,
  }) {
    final color = isRegistered ? const Color(0xFF16A34A) : Colors.red.shade600;
    final bgColor = isRegistered
        ? const Color(0xFF16A34A).withOpacity(0.08)
        : Colors.red.shade50;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isRegistered ? activeIcon : inactiveIcon,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 4),
          Text(
            isRegistered ? activeLabel : inactiveLabel,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
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
          "Daftar Anggota",
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
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
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
                  onChanged: (_) => _onSearchChanged(),
                  decoration: InputDecoration(
                    hintText: "Cari nama atau ID anggota...",
                    hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                    prefixIcon: Icon(Icons.search_rounded, color: context.primaryColor),
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
                  // Background blobs (Inside Stack, below the list)
                  Positioned(
                    top: -70,
                    right: -50,
                    child: Container(
                      width: 230,
                      height: 230,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: context.primaryColor.withOpacity(0.04),
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
                        color: const Color(0xFF7C3AED).withOpacity(0.03),
                      ),
                    ),
                  ),

                  RefreshIndicator(
                    color: context.primaryColor,
                    onRefresh: _fetchEmployees,
                    child: _isLoading
                        ? ListView.builder(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 16,
                            ),
                            itemCount: 5,
                            itemBuilder: (context, index) => const CardSkeleton(),
                          )
                        : _errorMsg.isNotEmpty
                            ? ListView(
                                children: [
                                  SizedBox(
                                    height: MediaQuery.of(context).size.height * 0.3,
                                  ),
                                  Center(
                                    child: Text(
                                      _errorMsg,
                                      style: TextStyle(
                                        color: Colors.red.shade600,
                                        fontSize: 14,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              )
                            : _filteredAnggota.isEmpty
                                ? ListView(
                                    children: [
                                      SizedBox(
                                        height: MediaQuery.of(context).size.height * 0.25,
                                      ),
                                      Center(
                                        child: Column(
                                          children: [
                                            Icon(
                                              Icons.search_off_rounded,
                                              size: 64,
                                              color: Colors.grey.shade400,
                                            ),
                                            const SizedBox(height: 16),
                                            Text(
                                              _searchController.text.isEmpty
                                                  ? "Belum ada anggota."
                                                  : "Tidak ditemukan hasil.",
                                              style: const TextStyle(
                                                color: Color(0xFF0F172A),
                                                fontSize: 18,
                                                fontWeight: FontWeight.w800,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  )
                                : ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                                    itemCount: _filteredAnggota.length,
                                    itemBuilder: (context, index) {
                                      final emp = _filteredAnggota[index];
                                      final isSuperAdmin = emp['nama']
                                              .toString()
                                              .toLowerCase()
                                              .contains("admin") ||
                                          emp['bagian']
                                              .toString()
                                              .toLowerCase()
                                              .contains("pemilik");

                                      return Container(
                                        margin: const EdgeInsets.only(bottom: 16),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(20),
                                          boxShadow: [
                                            BoxShadow(
                                              color: Colors.black.withOpacity(0.04),
                                              blurRadius: 10,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        padding: const EdgeInsets.all(16),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            CircleAvatar(
                                              radius: 24,
                                              backgroundColor: isSuperAdmin
                                                  ? Colors.amber.withOpacity(0.15)
                                                  : context.primaryColor
                                                      .withOpacity(0.1),
                                              child: isSuperAdmin
                                                  ? const Icon(
                                                      Icons.shield_rounded,
                                                      color: Colors.amber,
                                                      size: 24,
                                                    )
                                                  : Text(
                                                      emp['nama']
                                                          .toString()
                                                          .substring(0, 1)
                                                          .toUpperCase(),
                                                      style: TextStyle(
                                                        color: context.primaryColor,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                        fontSize: 18,
                                                      ),
                                                    ),
                                            ),
                                            const SizedBox(width: 16),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(
                                                    emp['nama'] ?? "-",
                                                    style: const TextStyle(
                                                      fontWeight: FontWeight.w800,
                                                      fontSize: 16,
                                                      color: Color(0xFF0F172A),
                                                    ),
                                                  ),
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    "${emp['id']}  •  ${emp['bagian'] ?? '-'}",
                                                    style: TextStyle(
                                                      color:
                                                          Colors.grey.shade600,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w600,
                                                    ),
                                                  ),
                                                  const SizedBox(height: 12),
                                                  if (!isSuperAdmin)
                                                    Wrap(
                                                      spacing: 8,
                                                      runSpacing: 8,
                                                      children: [
                                                        _buildStatusBadge(
                                                          isRegistered:
                                                              emp['wajah_terdaftar'] ==
                                                                  true,
                                                          activeLabel:
                                                              "Wajah Terdaftar",
                                                          inactiveLabel:
                                                              "Belum Ada Wajah",
                                                          activeIcon: Icons
                                                              .face_retouching_natural,
                                                          inactiveIcon: Icons
                                                              .sentiment_dissatisfied,
                                                        ),
                                                        _buildStatusBadge(
                                                          isRegistered:
                                                              emp['sudah_enroll'] ==
                                                                  true,
                                                          activeLabel:
                                                              "HP Terdaftar",
                                                          inactiveLabel:
                                                              "Belum Ada HP",
                                                          activeIcon: Icons
                                                              .phonelink_setup,
                                                          inactiveIcon: Icons
                                                              .phonelink_erase,
                                                        ),
                                                      ],
                                                    )
                                                  else
                                                    Container(
                                                      padding: const EdgeInsets
                                                          .symmetric(
                                                        horizontal: 8,
                                                        vertical: 4,
                                                      ),
                                                      decoration: BoxDecoration(
                                                        color:
                                                            Colors.amber.shade50,
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                          8,
                                                        ),
                                                        border: Border.all(
                                                          color: Colors
                                                              .amber.shade200,
                                                        ),
                                                      ),
                                                      child: Text(
                                                        "Role Hak Akses Admin",
                                                        style: TextStyle(
                                                          fontSize: 10,
                                                          fontWeight:
                                                              FontWeight.w800,
                                                          color: Colors
                                                              .amber.shade800,
                                                        ),
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Padding(
                                              padding: const EdgeInsets.only(left: 8.0),
                                              child: IconButton(
                                                onPressed: () => _showActionSheet(emp),
                                                icon: const Icon(
                                                  Icons.more_vert_rounded,
                                                  color: Color(0xFF64748B),
                                                  size: 24,
                                                ),
                                                constraints: const BoxConstraints(),
                                                padding: const EdgeInsets.all(8),
                                              ),
                                            ),
                                          ],
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
}
