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
  final TextEditingController _searchController =
      TextEditingController(); // NEW

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
        _filteredAnggota = data;
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

  Future<void> _showMemberActionDialog(Map<String, dynamic> emp) async {
    final auth = context.read<AuthProvider>();
    final clientId = auth.clientId ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              "Kelola ${emp['nama']}",
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "ID: ${emp['id']} • ${emp['bagian']}",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.history_rounded, color: Colors.blue),
              ),
              title: const Text(
                "Atur Shift Default",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(
                "Saat ini: ${emp['id_shift_default'] ?? 'Standar Kantor'}",
              ),
              onTap: () {
                Navigator.pop(context);
                _showSetShiftDialog(emp);
              },
            ),
            ListTile(
              leading: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.phonelink_erase_rounded,
                  color: Colors.orange,
                ),
              ),
              title: const Text(
                "Reset Device ID",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text("Gunakan jika anggota ganti HP"),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => AlertDialog(
                    title: const Text("Konfirmasi Reset"),
                    content: const Text("Yakin ingin mereset HP anggota ini?"),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(c, false),
                        child: const Text("Batal"),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pop(c, true),
                        child: const Text("Reset"),
                      ),
                    ],
                  ),
                );
                if (confirm == true) {
                  setState(() => _isLoading = true);
                  final res = await _adminService.resetDeviceID(
                    clientId,
                    emp['id'].toString(),
                  );
                  setState(() => _isLoading = false);
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(res['message'] ?? "Berhasil")),
                    );
                    _fetchEmployees();
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSetShiftDialog(Map<String, dynamic> emp) async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final clientId = auth.clientId ?? "";
    final res = await _adminService.getShiftList(clientId);
    setState(() => _isLoading = false);

    if (res['success'] != true) return;
    final List shifts = res['data']['shifts'] ?? [];

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pilih Shift Default"),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: shifts.length + 1,
            itemBuilder: (c, i) {
              if (i == shifts.length) {
                return ListTile(
                  title: const Text("KEMBALIKAN KE STANDAR"),
                  subtitle: const Text("Mengikuti jam kantor utama"),
                  onTap: () async {
                    Navigator.pop(c);
                    _doUpdateShift(emp['id'].toString(), "");
                  },
                );
              }
              final s = shifts[i];
              return ListTile(
                title: Text(s['nama']),
                subtitle: Text("${s['jam_masuk']} - ${s['pulang']}"),
                onTap: () {
                  Navigator.pop(c);
                  _doUpdateShift(emp['id'].toString(), s['id'].toString());
                },
              );
            },
          ),
        ),
      ),
    );
  }

  Future<void> _doUpdateShift(String targetId, String shiftId) async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final clientId = auth.clientId ?? "";
    final res = await _adminService.updateDefaultShift(
      clientId,
      targetId,
      shiftId,
    );
    setState(() => _isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            res['success']
                ? "Shift Default Diperbarui"
                : (res['message'] ?? "Gagal"),
          ),
        ),
      );
      _fetchEmployees();
    }
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
                            itemBuilder: (context, index) =>
                                const CardSkeleton(),
                          )
                        : _errorMsg.isNotEmpty
                        ? ListView(
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.3,
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
                                height:
                                    MediaQuery.of(context).size.height * 0.25,
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
                              final isSuperAdmin =
                                  emp['nama'].toString().toLowerCase().contains(
                                    "admin",
                                  ) ||
                                  emp['bagian']
                                      .toString()
                                      .toLowerCase()
                                      .contains("pemilik");

                              return InkWell(
                                onTap: () => _showMemberActionDialog(emp),
                                borderRadius: BorderRadius.circular(20),
                                child: Container(
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
                                            : context.primaryColor.withOpacity(
                                                0.1,
                                              ),
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
                                                  fontWeight: FontWeight.bold,
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
                                                color: Colors.grey.shade600,
                                                fontSize: 12,
                                                fontWeight: FontWeight.w600,
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
                                                    activeLabel: "HP Terdaftar",
                                                    inactiveLabel:
                                                        "Belum Ada HP",
                                                    activeIcon:
                                                        Icons.phonelink_setup,
                                                    inactiveIcon:
                                                        Icons.phonelink_erase,
                                                  ),
                                                ],
                                              )
                                            else
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 4,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.amber.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(8),
                                                  border: Border.all(
                                                    color:
                                                        Colors.amber.shade200,
                                                  ),
                                                ),
                                                child: Text(
                                                  "Role Hak Akses Admin",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.w800,
                                                    color:
                                                        Colors.amber.shade800,
                                                  ),
                                                ),
                                              ),
                                            const SizedBox(height: 8),
                                            if (emp['id_shift_default'] !=
                                                    null &&
                                                emp['id_shift_default'] != "")
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                      horizontal: 8,
                                                      vertical: 2,
                                                    ),
                                                decoration: BoxDecoration(
                                                  color: Colors.blue.shade50,
                                                  borderRadius:
                                                      BorderRadius.circular(6),
                                                ),
                                                child: Text(
                                                  "Default: ${emp['id_shift_default']}",
                                                  style: TextStyle(
                                                    fontSize: 10,
                                                    color: Colors.blue.shade800,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      Column(
                                        children: [
                                          if (emp['no_hp'] != null &&
                                              emp['no_hp']
                                                  .toString()
                                                  .isNotEmpty &&
                                              emp['no_hp'].toString() != "null")
                                            IconButton(
                                              onPressed: () =>
                                                  UrlHelper.launchWhatsApp(
                                                    phone: emp['no_hp']
                                                        .toString(),
                                                    message:
                                                        "Halo ${emp['nama']}, saya dari Admin Hadir.in ingin menghubungi Anda.",
                                                  ),
                                              icon: const Icon(
                                                Icons.phone,
                                                color: Color(0xFF25D366),
                                                size: 24,
                                              ),
                                              style: IconButton.styleFrom(
                                                backgroundColor: const Color(
                                                  0xFF25D366,
                                                ).withOpacity(0.1),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(12),
                                                ),
                                              ),
                                            ),
                                          const SizedBox(height: 8),
                                          IconButton(
                                            onPressed: () =>
                                                _showMemberActionDialog(emp),
                                            icon: const Icon(
                                              Icons.settings_rounded,
                                              size: 20,
                                              color: Colors.blueGrey,
                                            ),
                                            style: IconButton.styleFrom(
                                              backgroundColor: Colors.blueGrey
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
}
