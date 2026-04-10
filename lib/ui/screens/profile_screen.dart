import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/ui/screens/set_location_screen.dart'; // ← PENTING: Import halaman Set Location
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final AttendanceService _service = AttendanceService();
  bool _isLoading = true;
  String _errorMsg = "";

  List<dynamic> _allHistory = [];
  List<dynamic> _filteredHistory = [];

  String _filterTipe = "Semua";
  String _filterStatus = "Semua";

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  void _fetchHistory() async {
    final auth = context.read<AuthProvider>();
    if (auth.idKaryawan == null) return;

    try {
      final data = await _service.getHistory(auth.idKaryawan!);
      setState(() {
        _allHistory = data;
        _isLoading = false;
      });
      _applyFilter();
    } catch (e) {
      setState(() {
        _errorMsg = e.toString();
        _isLoading = false;
      });
    }
  }

  void _applyFilter() {
    setState(() {
      _filteredHistory = _allHistory.where((log) {
        bool matchTipe = _filterTipe == "Semua" || log['tipe'] == _filterTipe;
        bool matchStatus =
            _filterStatus == "Semua" || log['status'] == _filterStatus;
        return matchTipe && matchStatus;
      }).toList();
    });
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Konfirmasi Logout"),
        content: const Text(
          "Apakah Anda yakin ingin keluar? Sesi Anda akan dihapus dari perangkat ini.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Batal"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              Navigator.pop(dialogContext);
              await context.read<AuthProvider>().logout();
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text("Ya, Logout"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Profil & Riwayat"),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.red),
            onPressed: () => _showLogoutDialog(context),
            tooltip: "Logout",
          ),
        ],
      ),
      body: Column(
        children: [
          // HEADER PROFIL
          Container(
            padding: const EdgeInsets.all(20),
            color: Colors.blue.shade50,
            child: Row(
              children: [
                CircleAvatar(
                  radius: 35,
                  backgroundColor: auth.isAdmin
                      ? Colors.deepPurple
                      : Colors.blue,
                  child: Icon(
                    auth.isAdmin ? Icons.admin_panel_settings : Icons.person,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        auth.namaKaryawan ?? "Unknown",
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "ID: ${auth.idKaryawan ?? '-'}",
                        style: TextStyle(color: Colors.grey.shade700),
                      ),
                      if (auth.isAdmin) ...[
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.deepPurple,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Text(
                            "ADMIN UMKM",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ==============================================================
          // MENU KHUSUS ADMIN (Hanya muncul jika auth.isAdmin == true)
          // ==============================================================
          if (auth.isAdmin)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const SetLocationScreen(),
                    ),
                  );
                },
                icon: const Icon(Icons.map),
                label: const Text("Pengaturan Koordinat Kantor"),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 50),
                  backgroundColor: Colors.deepPurple.shade50,
                  foregroundColor: Colors.deepPurple,
                  elevation: 0,
                  side: BorderSide(color: Colors.deepPurple.shade200),
                ),
              ),
            ),
          // ==============================================================

          // BARIS FILTER
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Tipe",
                      border: OutlineInputBorder(),
                    ),
                    value: _filterTipe,
                    items: ["Semua", "Masuk", "Pulang"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _filterTipe = val!);
                      _applyFilter();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    decoration: const InputDecoration(
                      labelText: "Status",
                      border: OutlineInputBorder(),
                    ),
                    value: _filterStatus,
                    items: ["Semua", "Tepat Waktu", "Terlambat"]
                        .map((e) => DropdownMenuItem(value: e, child: Text(e)))
                        .toList(),
                    onChanged: (val) {
                      setState(() => _filterStatus = val!);
                      _applyFilter();
                    },
                  ),
                ),
              ],
            ),
          ),
          const Divider(),

          // LIST RIWAYAT ABSENSI
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMsg.isNotEmpty
                ? Center(
                    child: Text(
                      _errorMsg,
                      style: const TextStyle(color: Colors.red),
                    ),
                  )
                : _filteredHistory.isEmpty
                ? const Center(
                    child: Text("Tidak ada riwayat absen ditemukan."),
                  )
                : RefreshIndicator(
                    onRefresh: () async {
                      _fetchHistory();
                    },
                    child: ListView.builder(
                      itemCount: _filteredHistory.length,
                      itemBuilder: (context, index) {
                        final log = _filteredHistory[index];
                        final dt =
                            DateTime.tryParse(
                              log['waktu'].toString(),
                            )?.toLocal() ??
                            DateTime.now();
                        final isTerlambat = log['status'] == "Terlambat";

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: log['tipe'] == "Masuk"
                                  ? Colors.green.shade100
                                  : Colors.orange.shade100,
                              child: Icon(
                                log['tipe'] == "Masuk"
                                    ? Icons.login
                                    : Icons.logout,
                                color: log['tipe'] == "Masuk"
                                    ? Colors.green
                                    : Colors.orange,
                              ),
                            ),
                            title: Text(
                              "${log['tipe']} - ${dt.day}/${dt.month}/${dt.year} ${dt.hour}:${dt.minute.toString().padLeft(2, '0')}",
                            ),
                            subtitle: Text(
                              "Biometrik: ${log['biometrik'] == true ? 'Valid' : 'Gagal'}",
                            ),
                            trailing: log['tipe'] == "Masuk"
                                ? Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 4,
                                    ),
                                    decoration: BoxDecoration(
                                      color: isTerlambat
                                          ? Colors.red.shade100
                                          : Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      log['status'],
                                      style: TextStyle(
                                        color: isTerlambat
                                            ? Colors.red
                                            : Colors.green,
                                        fontSize: 12,
                                      ),
                                    ),
                                  )
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
