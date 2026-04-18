import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/admin_service.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';

class AdminShiftScreen extends StatefulWidget {
  const AdminShiftScreen({super.key});

  @override
  State<AdminShiftScreen> createState() => _AdminShiftScreenState();
}

class _AdminShiftScreenState extends State<AdminShiftScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final AdminService _adminService = AdminService();
  bool _isLoading = true;

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

  Future<void> _loadAllData() async {
    setState(() => _isLoading = true);
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
      setState(() => _isLoading = false);
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
              child: _isLoading
                  ? _buildSkeleton()
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildMasterShiftTab(),
                        _buildDailyPlottingTab(),
                      ],
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
                  : null),
      ),
    );
  }

  Widget _buildHeader(Color primaryColor) {
    return Container(
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 20,
        bottom: 10,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryColor, primaryColor.withBlue(255).withOpacity(0.8)],
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
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.calendar_month_rounded,
                    color: Colors.white,
                  ),
                  onPressed: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _selectedDate,
                      firstDate: DateTime.now().subtract(
                        const Duration(days: 365),
                      ),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (d != null) {
                      setState(() => _selectedDate = d);
                      _loadAllData();
                    }
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          // CUSTOM TAB BAR
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 24),
            height: 48,
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
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              tabs: const [
                Tab(text: "Master"),
                Tab(text: "Plotting"),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMasterShiftTab() {
    return Column(
      children: [
        if (_officeConfig != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.fromLTRB(24, 24, 24, 8),
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: context.primaryColor.withOpacity(0.1)),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.business_rounded,
                  color: context.primaryColor,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Jam Kerja Kantor (Standar)",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      Text(
                        "${_officeConfig!['jam_masuk_mulai']} - ${_officeConfig!['jam_pulang_mulai']}",
                        style: TextStyle(
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                TextButton.icon(
                  onPressed: () => Navigator.pushNamed(context, '/atur-jam'),
                  icon: const Icon(Icons.settings_rounded, size: 14),
                  label: const Text("Ubah", style: TextStyle(fontSize: 12)),
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
                margin: const EdgeInsets.only(bottom: 16),
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
                    horizontal: 20,
                    vertical: 8,
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
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    "${s['masuk']} - ${s['pulang']}",
                    style: TextStyle(
                      color: Colors.grey.shade600,
                      fontWeight: FontWeight.w600,
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
        // MODERN DATE PICKER BAR
        Container(
          height: 100,
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: 30, // 1 Month range from now
            itemBuilder: (context, index) {
              final date = DateTime.now().add(Duration(days: index - 2));
              final isSelected =
                  DateFormat('yyyy-MM-dd').format(date) ==
                  DateFormat('yyyy-MM-dd').format(_selectedDate);

              return GestureDetector(
                onTap: () async {
                  if (_dirtyIds.isNotEmpty) {
                    bool? discard = await _showDiscardDialog();
                    if (discard != true) return;
                  }
                  setState(() => _selectedDate = date);
                  _loadAllData();
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 65,
                  margin: const EdgeInsets.only(right: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? context.primaryColor : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: context.primaryColor.withOpacity(0.3),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ]
                        : [],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        DateFormat('E').format(date),
                        style: TextStyle(
                          color: isSelected ? Colors.white70 : Colors.grey,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date.day.toString(),
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black87,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),

        Expanded(
          child: _shifts.isEmpty
              ? _buildEmptyShiftHint()
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _employees.length,
                  itemBuilder: (context, index) {
                    final emp = _employees[index];
                    final eid = emp['id'].toString();
                    final dateKey =
                        DateFormat('yyyy-MM-dd').format(_selectedDate) +
                        "_" +
                        eid;
                    final currentShift = _plotting[dateKey] ?? "";

                    return Container(
                      margin: const EdgeInsets.only(bottom: 20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
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
                                backgroundColor: context.primaryColor
                                    .withOpacity(0.1),
                                child: Text(
                                  emp['nama'][0],
                                  style: TextStyle(
                                    color: context.primaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      emp['nama'].toString(),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 16,
                                      ),
                                    ),
                                    Row(
                                      children: [
                                        Text(
                                          "ID: $eid",
                                          style: TextStyle(
                                            color: Colors.grey.shade500,
                                            fontSize: 12,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        GestureDetector(
                                          onTap: () =>
                                              _showPlotMassalDialog(emp),
                                          child: Container(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 2,
                                            ),
                                            decoration: BoxDecoration(
                                              color: context.primaryColor
                                                  .withOpacity(0.1),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              children: [
                                                Icon(
                                                  Icons.date_range_rounded,
                                                  size: 12,
                                                  color: context.primaryColor,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  "Plot Massal",
                                                  style: TextStyle(
                                                    color: context.primaryColor,
                                                    fontSize: 10,
                                                    fontWeight: FontWeight.bold,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // SHIFT CHIPS SELECTOR
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _buildShiftChip(
                                  "OFF",
                                  "",
                                  currentShift == "",
                                  eid,
                                ),
                                ..._shifts.map(
                                  (s) => _buildShiftChip(
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
        ),
      ],
    );
  }

  Widget _buildShiftChip(
    String label,
    String val,
    bool isSelected,
    String employeeId,
  ) {
    final color = _getShiftColor(val);
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (selected) {
          if (selected) {
            final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
            final key = dateStr + "_" + employeeId;
            setState(() {
              _plotting[key] = val;
              _dirtyIds.add(employeeId);
            });
          }
        },
        selectedColor: color.withOpacity(0.2),
        backgroundColor: Colors.grey.shade100,
        labelStyle: TextStyle(
          color: isSelected ? color : Colors.grey.shade600,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        showCheckmark: false,
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

  void _showPlotMassalDialog(dynamic emp) async {
    DateTimeRange? range = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now().subtract(const Duration(days: 30)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      helpText: "Pilih Rentang Jadwal untuk ${emp['nama']}",
    );

    if (range == null) return;

    String? selectedShift;

    // Show Shift Picker Dialog
    selectedShift = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Pilih Shift Massal"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "Pilih shift yang akan diterapkan pada rentang tanggal terpilih:",
            ),
            const SizedBox(height: 16),
            ...["OFF", ..._shifts.map((s) => s['id'].toString())].map(
              (sid) => ListTile(
                title: Text(sid == "OFF" ? "LIBUR (OFF)" : sid),
                trailing: Icon(
                  Icons.chevron_right_rounded,
                  color: context.primaryColor,
                ),
                onTap: () => Navigator.pop(context, sid == "OFF" ? "" : sid),
              ),
            ),
          ],
        ),
      ),
    );

    if (selectedShift == null) return;

    // Apply to local state
    setState(() {
      DateTime current = range.start;
      while (current.isBefore(range.end) ||
          current.isAtSameMomentAs(range.end)) {
        final dateStr = DateFormat('yyyy-MM-dd').format(current);
        final key = dateStr + "_" + emp['id'].toString();
        _plotting[key] = selectedShift;
        current = current.add(const Duration(days: 1));
      }
      _dirtyIds.add(emp['id'].toString());
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
    setState(() => _isLoading = true);
    final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
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
    String masukStr =
        shift?['masuk']?.toString().split('T').last.substring(0, 5) ?? "08:00";
    String pulangStr =
        shift?['pulang']?.toString().split('T').last.substring(0, 5) ?? "16:00";

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          Future<void> pickTime(bool isMasuk) async {
            final initial = TimeOfDay(
              hour: int.parse((isMasuk ? masukStr : pulangStr).split(':')[0]),
              minute: int.parse((isMasuk ? masukStr : pulangStr).split(':')[1]),
            );
            final picked = await showTimePicker(
              context: context,
              initialTime: initial,
            );
            if (picked != null) {
              setDialogState(() {
                final formatted =
                    "${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}";
                if (isMasuk)
                  masukStr = formatted;
                else
                  pulangStr = formatted;
              });
            }
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
}
