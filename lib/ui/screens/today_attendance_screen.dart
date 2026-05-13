import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/admin_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:hadirin/ui/widgets/skeleton_loader.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

class TodayAttendanceScreen extends StatefulWidget {
  const TodayAttendanceScreen({super.key});

  @override
  State<TodayAttendanceScreen> createState() => _TodayAttendanceScreenState();
}

class _TodayAttendanceScreenState extends State<TodayAttendanceScreen>
    with SingleTickerProviderStateMixin {
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  String _errorMsg = "";
  List<dynamic> _allData = [];
  List<dynamic> _filteredData = [];
  String _activeFilter = "Semua";
  final TextEditingController _searchController = TextEditingController();
  late TabController _tabController;

  // Summary counts
  int _hadirCount = 0;
  int _terlambatCount = 0;
  int _belumAbsenCount = 0;
  int _izinCount = 0;

  final List<String> _filters = [
    "Semua",
    "Hadir",
    "Terlambat",
    "Belum Absen",
    "Izin/Sakit",
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _filters.length, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() => _activeFilter = _filters[_tabController.index]);
        _applyFilter();
      }
    });
    _searchController.addListener(_applyFilter);
    WidgetsBinding.instance.addPostFrameCallback((_) => _fetchData());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchData() async {
    setState(() {
      _isLoading = true;
      _errorMsg = "";
    });
    try {
      final auth = context.read<AuthProvider>();
      final data = await _adminService.getTodayAttendance(auth.clientId ?? "");
      _allData = data;
      _computeSummary(data);
      _applyFilter();
      setState(() => _isLoading = false);
    } catch (e) {
      setState(() {
        _errorMsg = e.toString().replaceAll("Exception: ", "");
        _isLoading = false;
      });
    }
  }

  void _computeSummary(List<dynamic> data) {
    _hadirCount = 0;
    _terlambatCount = 0;
    _belumAbsenCount = 0;
    _izinCount = 0;
    for (var item in data) {
      final status = item['status_absen'] ?? 'Belum Absen';
      if (status == 'Hadir')
        _hadirCount++;
      else if (status == 'Terlambat')
        _terlambatCount++;
      else if (status == 'Belum Absen')
        _belumAbsenCount++;
      else
        _izinCount++;
    }
  }

  void _applyFilter() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredData = _allData.where((item) {
        final matchFilter =
            _activeFilter == "Semua" ||
            (_activeFilter == "Hadir" && item['status_absen'] == 'Hadir') ||
            (_activeFilter == "Terlambat" &&
                item['status_absen'] == 'Terlambat') ||
            (_activeFilter == "Belum Absen" &&
                item['status_absen'] == 'Belum Absen') ||
            (_activeFilter == "Izin/Sakit" &&
                ['Izin', 'Sakit', 'Cuti'].contains(item['status_absen']));

        final matchSearch =
            query.isEmpty ||
            (item['nama'] ?? '').toString().toLowerCase().contains(query) ||
            (item['id'] ?? '').toString().toLowerCase().contains(query);

        return matchFilter && matchSearch;
      }).toList();
    });
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Hadir':
        return const Color(0xFF16A34A);
      case 'Terlambat':
        return const Color(0xFFD97706);
      case 'Belum Absen':
        return const Color(0xFFDC2626);
      case 'Izin':
      case 'Sakit':
      case 'Cuti':
        return const Color(0xFF2563EB);
      default:
        return Colors.grey.shade500;
    }
  }

  IconData _statusIcon(String status) {
    switch (status) {
      case 'Hadir':
        return Icons.check_circle_rounded;
      case 'Terlambat':
        return Icons.schedule_rounded;
      case 'Belum Absen':
        return Icons.radio_button_unchecked_rounded;
      case 'Izin':
      case 'Sakit':
      case 'Cuti':
        return Icons.sick_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final today = DateFormat(
      'EEEE, d MMMM yyyy',
      'id_ID',
    ).format(DateTime.now());

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8),
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
        title: Column(
          children: [
            const Text(
              "Absensi Hari Ini",
              style: TextStyle(
                color: Color(0xFF0F172A),
                fontWeight: FontWeight.w800,
                fontSize: 17,
              ),
            ),
            Text(
              today,
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: _fetchData,
            icon: const Icon(Icons.refresh_rounded, color: Color(0xFF0F172A)),
            tooltip: "Perbarui",
          ),
        ],
      ),
      body: Column(
        children: [
          // ── SUMMARY CARDS ──────────────────────────────────
          if (!_isLoading && _errorMsg.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
              child: Row(
                children: [
                  _buildSummaryCard(
                    "Hadir",
                    _hadirCount,
                    const Color(0xFF16A34A),
                    Icons.check_circle_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryCard(
                    "Terlambat",
                    _terlambatCount,
                    const Color(0xFFD97706),
                    Icons.schedule_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryCard(
                    "Belum",
                    _belumAbsenCount,
                    const Color(0xFFDC2626),
                    Icons.radio_button_unchecked_rounded,
                  ),
                  const SizedBox(width: 8),
                  _buildSummaryCard(
                    "Izin",
                    _izinCount,
                    const Color(0xFF2563EB),
                    Icons.sick_rounded,
                  ),
                ],
              ),
            ),

          // ── SEARCH BAR ─────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Cari nama atau ID anggota...",
                  hintStyle: TextStyle(
                    color: Colors.grey.shade400,
                    fontSize: 13,
                  ),
                  prefixIcon: Icon(
                    Icons.search_rounded,
                    color: context.primaryColor,
                    size: 20,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            _applyFilter();
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ),

          // ── FILTER TABS ────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 6,
                  ),
                ],
              ),
              child: TabBar(
                controller: _tabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: context.primaryColor,
                unselectedLabelColor: Colors.grey.shade500,
                indicatorColor: context.primaryColor,
                indicatorSize: TabBarIndicatorSize.label,
                labelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 4),
                tabs: _filters.map((f) => Tab(text: f)).toList(),
              ),
            ),
          ),

          const SizedBox(height: 8),

          // ── LIST ───────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: 6,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.only(bottom: 12),
                      child: CardSkeleton(),
                    ),
                  )
                : _errorMsg.isNotEmpty
                ? _buildErrorState()
                : _filteredData.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    color: context.primaryColor,
                    onRefresh: _fetchData,
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      itemCount: _filteredData.length,
                      itemBuilder: (context, index) =>
                          _buildEmployeeCard(_filteredData[index]),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────────────────────────
  // WIDGETS
  // ──────────────────────────────────────────────────────────────────

  Widget _buildSummaryCard(
    String label,
    int count,
    Color color,
    IconData icon,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              count.toString(),
              style: TextStyle(
                color: color,
                fontSize: 18,
                fontWeight: FontWeight.w900,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmployeeCard(dynamic item) {
    final String statusAbsen = item['status_absen'] ?? 'Belum Absen';
    final Color statusColor = _statusColor(statusAbsen);
    final IconData statusIcon = _statusIcon(statusAbsen);
    final String nama = item['nama'] ?? '-';
    final String id = item['id'] ?? '-';
    final String bagian = item['bagian'] ?? '-';
    final String? masuk = item['masuk'];
    final String? pulang = item['pulang'];
    final String? statusMasuk = item['status_masuk'];

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Icon(statusIcon, color: statusColor, size: 22),
              ),
            ),
            const SizedBox(width: 12),

            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    nama,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    "$id  •  $bagian",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Jam Masuk
                      _buildTimeChip(
                        icon: Icons.login_rounded,
                        label: masuk ?? "-",
                        color: masuk != null
                            ? (statusMasuk?.startsWith('TL') == true
                                  ? const Color(0xFFD97706)
                                  : const Color(0xFF16A34A))
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(width: 8),
                      // Jam Pulang
                      _buildTimeChip(
                        icon: Icons.logout_rounded,
                        label: pulang ?? "-",
                        color: pulang != null
                            ? const Color(0xFF7C3AED)
                            : Colors.grey.shade400,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Status Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Text(
                _badgeLabel(statusAbsen),
                style: TextStyle(
                  color: statusColor,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  String _badgeLabel(String status) {
    switch (status) {
      case 'Hadir':
        return 'HADIR';
      case 'Terlambat':
        return 'TERLAMBAT';
      case 'Belum Absen':
        return 'BELUM';
      case 'Izin':
        return 'IZIN';
      case 'Sakit':
        return 'SAKIT';
      case 'Cuti':
        return 'CUTI';
      default:
        return status.toUpperCase();
    }
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        SizedBox(height: MediaQuery.of(context).size.height * 0.2),
        Center(
          child: Column(
            children: [
              Icon(
                Icons.event_available_rounded,
                size: 64,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 16),
              Text(
                _activeFilter == "Semua"
                    ? "Belum ada data absensi"
                    : "Tidak ada anggota dengan status '$_activeFilter'",
                style: const TextStyle(
                  color: Color(0xFF0F172A),
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                "Tarik ke bawah untuk memperbarui data",
                style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off_rounded, size: 52, color: Colors.red.shade300),
            const SizedBox(height: 16),
            Text(
              _errorMsg,
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _fetchData,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Coba Lagi"),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF005147),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
