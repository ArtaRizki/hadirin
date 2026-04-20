import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:flutter/cupertino.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'dart:ui';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:hadirin/ui/screens/set_worktime_screen.dart';
import 'package:hadirin/core/service/admin_service.dart';
import 'package:hadirin/ui/widgets/custom_date_range_picker.dart';

class AdminShiftScreen extends StatefulWidget {
  const AdminShiftScreen({super.key});

  @override
  State<AdminShiftScreen> createState() => _AdminShiftScreenState();
}

class _AdminShiftScreenState extends State<AdminShiftScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = "";
  final Set<String> _selectedIds = {};
  String _selectedShiftFilter = "All";
  final AdminService _adminService = AdminService();
  bool _isLoading = true;
  bool _isRefreshing = false; // Add refresh state

  List<dynamic> _shifts = [];
  Map<String, dynamic> _plotting = {};
  List<dynamic> _employees = [];
  Map<String, dynamic>? _officeConfig;

  // BATCH SAVE TRACKING
  final Set<String> _dirtyIds = {};

  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
    _loadAllData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAllData({bool quiet = false}) async {
    if (!quiet) setState(() => _isLoading = true);
    if (quiet) setState(() => _isRefreshing = true);
    try {
      final auth = context.read<AuthProvider>();
      final clientId = auth.clientId ?? "";

      final results = await Future.wait([
        _adminService.getShiftList(
          clientId,
          year: _selectedDate.year,
          month: _selectedDate.month,
        ),
        _adminService.getAllAnggota(clientId),
        _adminService.getOfficeConfig(clientId),
      ]);

      final shiftRes = results[0] as Map<String, dynamic>;
      final empRes = results[1] as List<dynamic>;
      final configRes = results[2] as Map<String, dynamic>?;

      if (shiftRes['success']) {
        setState(() {
          _shifts = shiftRes['data']['shifts'];
          _plotting = shiftRes['data']['plotting'];
          _employees = empRes;
          _officeConfig = configRes;
          _dirtyIds.clear(); // Clear dirty on new load
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("Error loading shift data: $e");
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    } finally {
      setState(() {
        _isLoading = false;
        _isRefreshing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = context.primaryColor;
    final isTabMaster = _tabController.index == 0;
    final hasDirty = _dirtyIds.isNotEmpty;

    return PopScope(
      canPop: !hasDirty,
      onPopInvoked: (didPop) {
        if (didPop) return;
        _showDiscardDialog();
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFF8FAFC),
        body: Column(
          children: [
            // 1. PREMIUM HEADER
            _buildHeader(primaryColor),

            // 2. TAB CONTENT
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [_buildMasterShiftTab(), _buildDailyPlottingTab()],
              ),
            ),
          ],
        ),
        floatingActionButton: isTabMaster
            ? FloatingActionButton.extended(
                onPressed: () => _showEditShiftDialog(),
                backgroundColor: primaryColor,
                icon: const Icon(Icons.add_rounded, color: Colors.white),
                label: const Text(
                  "Tambah Shift",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : (hasDirty
                  ? FloatingActionButton.extended(
                      onPressed: _saveBatchPlotting,
                      backgroundColor: const Color(0xFF16A34A),
                      icon: const Icon(
                        Icons.check_circle_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        "Simpan Plotting (${_dirtyIds.length})",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  : FloatingActionButton.extended(
                      onPressed: () => _showPlotMassalSheet(
                        isFromSelection: _selectedIds.isNotEmpty,
                      ),
                      backgroundColor: primaryColor,
                      icon: Icon(
                        _selectedIds.isNotEmpty
                            ? Icons.checklist_rtl_rounded
                            : Icons.auto_awesome_motion_rounded,
                        color: Colors.white,
                      ),
                      label: Text(
                        _selectedIds.isNotEmpty
                            ? "Plot Terpilih (${_selectedIds.length})"
                            : "Plot Massal Semua",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 8,
        bottom: 6,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withOpacity(0.8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(32)),
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    "Manajemen Shift",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                const SizedBox(width: 48), // Balance
              ],
            ),
          ),
          const SizedBox(height: 20),
          // CUSTOM TAB BAR
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorSize: TabBarIndicatorSize.tab, // FIXED
              indicator: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
              ),
              labelColor: primaryColor,
              unselectedLabelColor: Colors.white,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w900,
                fontSize: 11,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: "Master"),
                Tab(text: "Plotting"),
              ],
            ),
          ),
          const SizedBox(height: 4),
        ],
      ),
    );
  }

  Widget _buildMasterShiftTab() {
    if (_isLoading) return _buildSkeleton();
    return Column(
      children: [
        if (_officeConfig != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.fromLTRB(24, 16, 24, 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: context.primaryColor.withOpacity(0.15)),
              boxShadow: [
                BoxShadow(
                  color: context.primaryColor.withOpacity(0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.auto_awesome_rounded,
                    color: context.primaryColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Jam Kerja Standar",
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "${_formatTime(_officeConfig!['jam_masuk_mulai'])} - ${_formatTime(_officeConfig!['jam_pulang_mulai'])}",
                        style: TextStyle(
                          color: context.primaryColor,
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                CupertinoButton(
                  padding: EdgeInsets.zero,
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SetWorktimeScreen(),
                    ),
                  ).then((_) => _loadAllData()),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: context.primaryColor,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      "Ubah",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            itemCount: _shifts.length,
            itemBuilder: (context, index) {
              final s = _shifts[index];
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _getShiftColor(s['id']).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.access_time_rounded,
                      color: _getShiftColor(s['id']),
                    ),
                  ),
                  title: Text(
                    s['nama'].toString(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w900,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    "${_formatTime(s['masuk'])} - ${_formatTime(s['pulang'])}",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.edit_note_rounded,
                      color: Colors.blueGrey,
                    ),
                    onPressed: () => _showEditShiftDialog(shift: s),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildDailyPlottingTab() {
    return Column(
      children: [
        Container(
          height: 90,
          padding: const EdgeInsets.only(top: 16, bottom: 4),
          child: Row(
            children: [
              // JUMP TO DATE BUTTON
              Padding(
                padding: const EdgeInsets.only(left: 20, right: 8),
                child: IconButton.filled(
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 90),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (picked != null) {
                      setState(() => _selectedDate = picked);
                      _loadAllData(quiet: true);
                    }
                  },
                  icon: const Icon(Icons.calendar_month_rounded, size: 20),
                  style: IconButton.styleFrom(
                    backgroundColor: context.primaryColor.withOpacity(0.1),
                    foregroundColor: context.primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.only(right: 20),
                  itemCount: 90, // 3 Months range
                  itemBuilder: (context, index) {
                    final date = DateTime.now().add(Duration(days: index - 14));
                    final isSelected =
                        DateFormat('yyyy-MM-dd').format(date) ==
                        DateFormat('yyyy-MM-dd').format(_selectedDate);
                    final isToday =
                        DateFormat('yyyy-MM-dd').format(date) ==
                        DateFormat('yyyy-MM-dd').format(DateTime.now());
                    final isSunday = date.weekday == DateTime.sunday;
                    final isSaturday = date.weekday == DateTime.saturday;

                    double density = 0;
                    if (_employees.isNotEmpty) {
                      final dateKeyStr = DateFormat('yyyy-MM-dd').format(date);
                      int plotted = 0;
                      for (var emp in _employees) {
                        final key = dateKeyStr + "_" + emp['id'].toString();
                        if (_plotting.containsKey(key)) plotted++;
                      }
                      density = plotted / _employees.length;
                    }

                    return GestureDetector(
                      onTap: () async {
                        if (_dirtyIds.isNotEmpty) {
                          bool? discard = await _showDiscardDialog();
                          if (discard != true) return;
                        }
                        setState(() => _selectedDate = date);
                        _loadAllData(quiet: true);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 58,
                        margin: const EdgeInsets.only(right: 10),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? context.primaryColor
                              : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: context.primaryColor.withOpacity(
                                      0.3,
                                    ),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // "HARI INI" BADGE - Positioned at top to avoid shifting central text
                            if (isToday)
                              Positioned(
                                top: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? Colors.white
                                        : context.primaryColor,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    "HARI INI",
                                    style: TextStyle(
                                      fontSize: 7,
                                      fontWeight: FontWeight.w900,
                                      color: isSelected
                                          ? context.primaryColor
                                          : Colors.white,
                                    ),
                                  ),
                                ),
                              ),

                            Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                // Center the names and numbers
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat('E', 'id_ID').format(date),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white70
                                        : (isSunday
                                              ? Colors.red.shade400
                                              : (isSaturday
                                                    ? Colors.orange.shade400
                                                    : Colors.grey)),
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  date.day.toString(),
                                  style: TextStyle(
                                    color: isSelected
                                        ? Colors.white
                                        : (isSunday
                                              ? Colors.red.shade600
                                              : Colors.black87),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10), // Bottom Balance
                              ],
                            ),

                            // DENSITY INDICATOR BAR - Fixed at bottom
                            Positioned(
                              left: 10,
                              right: 10,
                              bottom: 6,
                              child: Container(
                                height: 3,
                                decoration: BoxDecoration(
                                  color: isSelected
                                      ? Colors.white.withOpacity(0.3)
                                      : Colors.grey.shade100,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                                child: FractionallySizedBox(
                                  alignment: Alignment.centerLeft,
                                  widthFactor: density,
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? Colors.white
                                          : context.primaryColor,
                                      borderRadius: BorderRadius.circular(2),
                                    ),
                                  ),
                                ),
                              ),
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

        _buildPlottingSummaryBar(),

        // SEARCH BAR
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
          child: Container(
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: context.primaryColor.withOpacity(0.15),
                width: 1.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              decoration: InputDecoration(
                hintText: "Cari nama atau ID karyawan...",
                hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                prefixIcon: Icon(
                  Icons.search_rounded,
                  color: context.primaryColor,
                ),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 20),
                        onPressed: () {
                          _searchController.clear();
                          setState(() => _searchQuery = "");
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
        ),

        // SHIFT FILTER CHIPS
        Container(
          height: 36,
          margin: const EdgeInsets.only(bottom: 8),
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            children: [
              _buildFilterChip("Semua", "All"),
              _buildFilterChip("Belum Ter-plot", "Unassigned"),
              ..._shifts.map((s) {
                final id = s['id'].toString();
                return _buildFilterChip("Shift $id", id);
              }),
            ],
          ),
        ),

        // SELECTION TOOLS (Select All / Clear)
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 2),
          child: Row(
            children: [
              Text(
                "Daftar Karyawan",
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  color: Colors.grey.shade800,
                  fontSize: 10,
                ),
              ),
              const Spacer(),
              if (_selectedIds.isNotEmpty)
                TextButton.icon(
                  onPressed: () => setState(() => _selectedIds.clear()),
                  icon: const Icon(Icons.close_rounded, size: 16),
                  label: const Text("Batal", style: TextStyle(fontSize: 12)),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                ),
              TextButton.icon(
                onPressed: () {
                  final filtered = _getFilteredEmployees();
                  setState(() {
                    if (_selectedIds.length == filtered.length) {
                      _selectedIds.clear();
                    } else {
                      _selectedIds.addAll(
                        filtered.map((e) => e['id'].toString()),
                      );
                    }
                  });
                },
                icon: Icon(
                  _selectedIds.length == _getFilteredEmployees().length &&
                          _selectedIds.isNotEmpty
                      ? Icons.check_box_rounded
                      : Icons.check_box_outline_blank_rounded,
                  size: 16,
                ),
                label: Text(
                  _selectedIds.length == _getFilteredEmployees().length &&
                          _selectedIds.isNotEmpty
                      ? "Batal Semua"
                      : "Pilih Semua",
                  style: const TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _isLoading
              ? _buildSkeleton()
              : Stack(
                  children: [
                    if (_shifts.isEmpty)
                      _buildEmptyShiftHint()
                    else
                      ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: _getFilteredEmployees().length,
                        itemBuilder: (context, index) {
                          final emp = _getFilteredEmployees()[index];
                          final eid = emp['id'].toString();
                          final isSelected = _selectedIds.contains(eid);
                          final dateKey =
                              DateFormat('yyyy-MM-dd').format(_selectedDate) +
                              "_" +
                              eid;
                          final currentShift = _plotting[dateKey] ?? "";

                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 15,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 13,
                                      backgroundColor: context.primaryColor
                                          .withOpacity(0.1),
                                      child: Text(
                                        emp['nama'][0],
                                        style: TextStyle(
                                          color: context.primaryColor,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            emp['nama'].toString(),
                                            style: const TextStyle(
                                              fontWeight: FontWeight.w900,
                                              fontSize: 14,
                                            ),
                                          ),
                                          Text(
                                            "ID: $eid",
                                            style: TextStyle(
                                              color: Colors.grey.shade500,
                                              fontSize: 10,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    // IMPROVED PLOT BUTTON
                                    CupertinoButton(
                                      padding: EdgeInsets.zero,
                                      onPressed: () =>
                                          _showPlotMassalSheet(emp: emp),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 12,
                                          vertical: 6,
                                        ),
                                        decoration: BoxDecoration(
                                          color: context.primaryColor,
                                          borderRadius: BorderRadius.circular(
                                            14,
                                          ),
                                          boxShadow: [
                                            BoxShadow(
                                              color: context.primaryColor
                                                  .withOpacity(0.3),
                                              blurRadius: 8,
                                              offset: const Offset(0, 4),
                                            ),
                                          ],
                                        ),
                                        child: const Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.edit_calendar_rounded,
                                              size: 14,
                                              color: Colors.white,
                                            ),
                                            const SizedBox(width: 8),
                                            const Text(
                                              "Plot",
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.w900,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    // CHECKBOX AT FAR RIGHT
                                    Transform.scale(
                                      scale: 1.0,
                                      child: Checkbox(
                                        value: isSelected,
                                        activeColor: context.primaryColor,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(
                                            6,
                                          ),
                                        ),
                                        onChanged: (val) {
                                          setState(() {
                                            if (val == true) {
                                              _selectedIds.add(eid);
                                            } else {
                                              _selectedIds.remove(eid);
                                            }
                                          });
                                        },
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                // SHIFT CHIPS SELECTOR
                                SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: Row(
                                    children: [
                                      _buildModernShiftChip(
                                        "OFF",
                                        "",
                                        currentShift == "",
                                        eid,
                                      ),
                                      ..._shifts.map(
                                        (s) => _buildModernShiftChip(
                                          s['id'].toString(),
                                          s['id'].toString(),
                                          currentShift == s['id'],
                                          eid,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    if (_isRefreshing)
                      Positioned.fill(
                        child: Container(
                          color: Colors.white.withOpacity(0.5),
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                      ),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildPlottingSummaryBar() {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final stats = <String, int>{};
    for (var emp in _employees) {
      final key = dateStr + "_" + emp['id'].toString();
      final sId = _plotting[key] ?? "";
      stats[sId] = (stats[sId] ?? 0) + 1;
    }

    return Container(
      height: 36,
      margin: const EdgeInsets.only(bottom: 12),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        children: [
          _buildStatChip("OFF", stats[""] ?? 0, Colors.grey),
          ..._shifts.map((s) {
            final id = s['id'].toString();
            return _buildStatChip(id, stats[id] ?? 0, _getShiftColor(id));
          }),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, int count, Color color) {
    if (count == 0) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(right: 12),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              count.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModernShiftChip(
    String label,
    String val,
    bool isSelected,
    String employeeId,
  ) {
    final color = _getShiftColor(val);
    return GestureDetector(
      onTap: () {
        final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
        final key = dateStr + "_" + employeeId;
        setState(() {
          _plotting[key] = val;
          _dirtyIds.add(employeeId);
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.grey.shade50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade600,
            fontWeight: FontWeight.w900,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyShiftHint() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.info_outline_rounded,
              size: 64,
              color: Colors.grey.shade300,
            ),
            const SizedBox(height: 16),
            const Text(
              "Master Shift Kosong",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            const SizedBox(height: 8),
            Text(
              "Anda belum menentukan jam kerja di tab 'Master'. Agar bisa mem-plot jadwal, silakan tambah Shift terlebih dahulu.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade600),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => _tabController.animateTo(0),
              child: const Text("Ke Tab Master"),
            ),
          ],
        ),
      ),
    );
  }

  void _showPlotMassalSheet({dynamic emp, bool isFromSelection = false}) async {
    final isBulk = emp == null;
    final targetEmpIds = isFromSelection
        ? _selectedIds.toList()
        : (isBulk
              ? _employees.map((e) => e['id'].toString()).toList()
              : [emp['id'].toString()]);

    DateTimeRange? range = await showCustomDateRangePicker(
      context: context,
      allowFuture: true,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(
        start: _selectedDate,
        end: _selectedDate.add(const Duration(days: 6)),
      ),
    );

    if (range == null) return;

    if (!mounted) return;

    // SHOW MODERN BOTTOM SHEET FOR SHIFT PICKER
    String? selectedShift = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "Pilih Shift",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: Colors.grey.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFromSelection
                  ? "Pilih shift untuk ${targetEmpIds.length} karyawan terpilih."
                  : (isBulk
                        ? "Pilih shift untuk semua karyawan pada rentang ini."
                        : "Pilih shift untuk ${emp['nama']} pada rentang ini."),
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            const SizedBox(height: 24),
            // OPTIONS
            ...["OFF", ..._shifts.map((s) => s['id'].toString())].map((sid) {
              final isOff = sid == "OFF";
              final color = _getShiftColor(sid);
              return Container(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  onTap: () => Navigator.pop(context, isOff ? "" : sid),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      isOff ? Icons.beach_access_rounded : Icons.timer_rounded,
                      color: color,
                    ),
                  ),
                  title: Text(
                    isOff ? "LIBUR (OFF)" : "Shift $sid",
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  trailing: Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.grey.shade400,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey.shade100),
                  ),
                ),
              );
            }),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );

    if (selectedShift == null) return;

    // Apply to local state
    setState(() {
      final updatedPlotting = Map<String, dynamic>.from(_plotting);
      DateTime current = range.start;
      while (current.isBefore(range.end) ||
          current.isAtSameMomentAs(range.end)) {
        final dateStr = DateFormat('yyyy-MM-dd').format(current);

        for (var eid in targetEmpIds) {
          final key = dateStr + "_" + eid;
          updatedPlotting[key] = selectedShift;
          _dirtyIds.add(eid);
        }
        current = current.add(const Duration(days: 1));
      }
      _plotting = updatedPlotting;
    });
  }

  Color _getShiftColor(String id) {
    if (id == "" || id == "OFF") return Colors.grey;
    if (id == "S1") return Colors.blue.shade600;
    if (id == "S2") return Colors.orange.shade700;
    if (id == "S3") return Colors.purple.shade600;
    return context.primaryColor;
  }

  Widget _buildSkeleton() {
    return const Center(child: CircularProgressIndicator());
  }

  void _saveBatchPlotting() async {
    // 1. REVIEW CHANGES DIALOG
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: const Text(
            "Tinjau Perubahan",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Anda akan menyimpan ${_dirtyIds.length} perubahan jadwal pada tanggal $dateStr.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                ),
                const SizedBox(height: 16),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: _dirtyIds.length,
                    itemBuilder: (context, index) {
                      final eid = _dirtyIds.elementAt(index);
                      final emp = _employees.firstWhere(
                        (e) => e['id'].toString() == eid,
                        orElse: () => {'nama': 'Karyawan $eid'},
                      );
                      final key = dateStr + "_" + eid;
                      final sid = _plotting[key] ?? "";
                      final color = _getShiftColor(sid);

                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          radius: 12,
                          backgroundColor: color.withOpacity(0.1),
                          child: Text(
                            emp['nama'][0],
                            style: TextStyle(color: color, fontSize: 10),
                          ),
                        ),
                        title: Text(
                          emp['nama'],
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        trailing: Text(
                          sid == "" ? "LIBUR" : "Shift $sid",
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w900,
                            fontSize: 10,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                "Kembali",
                style: TextStyle(color: Colors.grey),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text("Simpan Sekarang"),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    List<Map<String, dynamic>> batch = [];
    for (String eid in _dirtyIds) {
      final key = dateStr + "_" + eid;
      batch.add({
        'key_id': key,
        'tanggal': dateStr,
        'id_karyawan': eid,
        'id_shift': _plotting[key] ?? "",
      });
    }

    final res = await _adminService.savePlotting(auth.clientId!, batch);

    setState(() => _isLoading = false);

    if (res['success']) {
      setState(() => _dirtyIds.clear());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Berhasil menyimpan semua plotting."),
          backgroundColor: Color(0xFF16A34A),
        ),
      );
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(res['message'])));
    }
  }

  Future<bool?> _showDiscardDialog() async {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Perubahan Belum Disimpan"),
        content: const Text(
          "Anda memiliki perubahan jadwal yang belum disimpan. Apakah Anda ingin membuang perubahan ini?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Kembali"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Buang", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _showEditShiftDialog({Map? shift}) {
    final idCtrl = TextEditingController(
      text: shift?['id'] ?? "S${_shifts.length + 1}",
    );
    final namaCtrl = TextEditingController(text: shift?['nama'] ?? "");
    String masukStr = _formatTime(shift?['masuk'] ?? "08:00");
    String pulangStr = _formatTime(shift?['pulang'] ?? "16:00");

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickTime(bool isMasuk) async {
            final initialParts = (isMasuk ? masukStr : pulangStr).split(':');
            DateTime tempDate = DateTime(
              2024,
              1,
              1,
              int.parse(initialParts[0]),
              int.parse(initialParts[1]),
            );

            showCupertinoModalPopup(
              context: context,
              builder: (val) => BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
                child: Material(
                  type: MaterialType.transparency,
                  child: Container(
                    height: 350,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(32),
                      ),
                    ),
                    child: Column(
                      children: [
                        const SizedBox(height: 12),
                        Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade300,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 8,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () => Navigator.pop(val),
                                child: Text(
                                  "Batal",
                                  style: TextStyle(
                                    color: Colors.grey.shade400,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                isMasuk ? "Jam Masuk" : "Jam Pulang",
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 18,
                                  color: Colors.black,
                                ),
                              ),
                              CupertinoButton(
                                padding: EdgeInsets.zero,
                                onPressed: () {
                                  setDialogState(() {
                                    final formatted =
                                        "${tempDate.hour.toString().padLeft(2, '0')}:${tempDate.minute.toString().padLeft(2, '0')}";
                                    if (isMasuk)
                                      masukStr = formatted;
                                    else
                                      pulangStr = formatted;
                                  });
                                  Navigator.pop(val);
                                },
                                child: Text(
                                  "Selesai",
                                  style: TextStyle(
                                    fontWeight: FontWeight.w900,
                                    color: context.primaryColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        Expanded(
                          child: CupertinoDatePicker(
                            mode: CupertinoDatePickerMode.time,
                            use24hFormat: true,
                            initialDateTime: tempDate,
                            onDateTimeChanged: (dt) => tempDate = dt,
                          ),
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(28),
            ),
            title: Text(
              shift == null ? "Tambah Shift Baru" : "Edit Shift",
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: idCtrl,
                    decoration: const InputDecoration(
                      labelText: "ID Shift",
                      hintText: "Misal: S1",
                    ),
                    enabled: shift == null,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: namaCtrl,
                    decoration: const InputDecoration(labelText: "Nama Shift"),
                  ),
                  if (_officeConfig != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: OutlinedButton.icon(
                        onPressed: () {
                          setDialogState(() {
                            masukStr =
                                _officeConfig!['jam_masuk_mulai'] ?? "08:00";
                            pulangStr =
                                _officeConfig!['jam_pulang_mulai'] ?? "16:00";
                            if (namaCtrl.text.isEmpty) {
                              namaCtrl.text = "Jam Kantor";
                            }
                          });
                        },
                        icon: const Icon(Icons.sync_rounded, size: 18),
                        label: const Text("Gunakan Jam Kantor"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: context.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: _buildTimePickerTile(
                          context,
                          "Masuk",
                          masukStr,
                          () => pickTime(true),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildTimePickerTile(
                          context,
                          "Pulang",
                          pulangStr,
                          () => pickTime(false),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Batal",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              ElevatedButton(
                onPressed: () async {
                  final newShifts = List.from(_shifts);
                  final newS = {
                    'id': idCtrl.text,
                    'nama': namaCtrl.text,
                    'masuk': masukStr,
                    'pulang': pulangStr,
                  };
                  if (shift == null) {
                    newShifts.add(newS);
                  } else {
                    final idx = newShifts.indexWhere(
                      (x) => x['id'] == shift['id'],
                    );
                    if (idx != -1) newShifts[idx] = newS;
                  }

                  final res = await _adminService.saveShifts(
                    context.read<AuthProvider>().clientId!,
                    newShifts,
                  );
                  if (res['success']) {
                    Navigator.pop(context);
                    _loadAllData();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: context.primaryColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text("Simpan"),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatTime(dynamic val) {
    if (val == null || val == "") return "00:00";
    String s = val.toString();

    // Prioritaskan mencari pola HH:mm di dalam string (bisa ISO, Long Date, atau HH:mm langsung)
    final match = RegExp(r'(\d{1,2}:\d{2})').firstMatch(s);
    if (match != null) {
      final parts = match.group(1)!.split(':');
      return "${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}";
    }

    return s.length > 5 ? s.substring(0, 5) : s;
  }

  Widget _buildTimePickerTile(
    BuildContext context,
    String label,
    String time,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Text(
              label,
              style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Text(
              time,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  // ADVANCED FILTERING HELPERS
  bool _matchesFilters(Map<String, dynamic> emp) {
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final matchSearch =
        emp['nama'].toString().toLowerCase().contains(
          _searchQuery.toLowerCase(),
        ) ||
        emp['id'].toString().toLowerCase().contains(_searchQuery.toLowerCase());

    if (!matchSearch) return false;

    // Filter by shift
    final key = dateStr + "_" + emp['id'].toString();
    final currentShift = _plotting[key] ?? "";

    if (_selectedShiftFilter == "All") return true;
    if (_selectedShiftFilter == "Unassigned") return currentShift == "";
    return currentShift == _selectedShiftFilter;
  }

  Widget _buildFilterChip(String label, String val) {
    final isSelected = _selectedShiftFilter == val;
    return GestureDetector(
      onTap: () => setState(() => _selectedShiftFilter = val),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? context.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? context.primaryColor : Colors.grey.shade200,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? Colors.white : Colors.grey.shade700,
            fontSize: 10,
            fontWeight: isSelected ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ),
    );
  }

  List<dynamic> _getFilteredEmployees() {
    return _employees.where((e) => _matchesFilters(e)).toList();
  }
}
