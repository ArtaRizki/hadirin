import 'package:flutter/material.dart';
import 'package:hadirin/core/models/school_models.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/school_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

// ─────────────────────────────────────────────────────────────────────────────
// HELPER: Nomor pekan dalam tahun
// ─────────────────────────────────────────────────────────────────────────────
String _weekLabel(DateTime d) {
  final weekNum =
      ((d.difference(DateTime(d.year, 1, 1)).inDays) / 7).ceil() + 1;
  return "Pekan $weekNum – ${DateFormat('MMMM yyyy', 'id_ID').format(d)}";
}

class LaporanNgajiScreen extends StatefulWidget {
  const LaporanNgajiScreen({super.key});

  @override
  State<LaporanNgajiScreen> createState() => _LaporanNgajiScreenState();
}

class _LaporanNgajiScreenState extends State<LaporanNgajiScreen>
    with SingleTickerProviderStateMixin {
  final _service = SchoolService();
  List<LaporanNgajiModel> _laporanList = [];
  bool _isLoading = true;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _fetch();
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetch() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();
    final idGuru = auth.isAdmin ? 'SEMUA' : (auth.idAnggota ?? '');
    final data = await _service.getLaporanNgaji(auth.clientId ?? '', idGuru);
    setState(() {
      _laporanList = data;
      _isLoading = false;
    });
  }

  void _showFormAbsen() {
    final auth = context.read<AuthProvider>();
    List<String> kelompokOptions = ['Memuat...'];
    String? selectedKelompok;
    final lainnyaCtrl = TextEditingController();
    final lokasiCtrl = TextEditingController();
    final materiCtrl = TextEditingController();
    bool isSaving = false;
    bool isLoadingKelompok = true;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) {
          if (isLoadingKelompok) {
            Future.microtask(() async {
              final list = await _service.getKelompokNgaji(auth.clientId ?? '');
              if (ctx.mounted) {
                setSheet(() {
                  kelompokOptions = list.isEmpty
                      ? ['Lainnya']
                      : [...list, 'Lainnya'];
                  isLoadingKelompok = false;
                });
              }
            });
          }

          return Container(
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
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 20),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: context.primaryColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          color: context.primaryColor,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Absen Pengajian Pekan Ini",
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            Text(
                              _weekLabel(DateTime.now()),
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  _label("Nama Kelompok Pengajian"),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedKelompok,
                    isExpanded: true,
                    decoration: InputDecoration(
                      hintText: isLoadingKelompok
                          ? "Memuat..."
                          : "Pilih kelompok",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: Icon(
                        Icons.group_rounded,
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
                    items: kelompokOptions
                        .map((k) => DropdownMenuItem(value: k, child: Text(k)))
                        .toList(),
                    onChanged: isLoadingKelompok
                        ? null
                        : (v) => setSheet(() => selectedKelompok = v),
                  ),
                  if (selectedKelompok == 'Lainnya') ...[
                    const SizedBox(height: 10),
                    _field(
                      lainnyaCtrl,
                      "Tulis nama kelompok...",
                      icon: Icons.edit_rounded,
                    ),
                  ],
                  const SizedBox(height: 16),
                  _label("Lokasi Pelaksanaan"),
                  const SizedBox(height: 8),
                  _field(
                    lokasiCtrl,
                    "Nama Masjid/Kelas",
                    icon: Icons.location_on_rounded,
                  ),
                  const SizedBox(height: 16),
                  _label("Materi & Keterangan"),
                  const SizedBox(height: 8),
                  TextField(
                    controller: materiCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Isi materi...",
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: ElevatedButton.icon(
                      onPressed: isSaving
                          ? null
                          : () async {
                              final kelompokFinal =
                                  selectedKelompok == 'Lainnya'
                                  ? lainnyaCtrl.text
                                  : selectedKelompok;
                              if (kelompokFinal == null ||
                                  kelompokFinal.isEmpty ||
                                  lokasiCtrl.text.isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Lengkapi data!"),
                                  ),
                                );
                                return;
                              }
                              setSheet(() => isSaving = true);
                              final res = await _service.submitLaporanNgaji(
                                clientId: auth.clientId ?? '',
                                idGuru: auth.idAnggota ?? '',
                                namaKelompok: kelompokFinal,
                                lokasi: lokasiCtrl.text,
                                materiKeterangan: materiCtrl.text,
                              );
                              if (res['success']) {
                                if (mounted) Navigator.pop(context);
                                _fetch();
                              } else {
                                setSheet(() => isSaving = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: context.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: isSaving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                          : const Icon(Icons.check_circle_rounded),
                      label: Text(isSaving ? "Menyimpan..." : "Simpan Laporan"),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontWeight: FontWeight.w700,
      fontSize: 13,
      color: Color(0xFF1E293B),
    ),
  );

  Widget _field(TextEditingController ctrl, String hint, {IconData? icon}) =>
      TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          filled: true,
          fillColor: Colors.grey.shade100,
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.grey.shade400, size: 18)
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
      );

  void _showManageKelompok() {
    final auth = context.read<AuthProvider>();
    final ctrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text(
            "Tambah Kelompok Baru",
            style: TextStyle(fontWeight: FontWeight.w900),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Kelompok ini akan muncul di daftar pilihan absen guru.",
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              _field(
                ctrl,
                "Contoh: Kelas 10A / Kelompok B",
                icon: Icons.group_add_rounded,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Batal"),
            ),
            ElevatedButton(
              onPressed: isSaving
                  ? null
                  : () async {
                      if (ctrl.text.trim().isEmpty) return;
                      setDialog(() => isSaving = true);
                      final res = await _service.addKelompokNgaji(
                        clientId: auth.clientId ?? '',
                        namaKelompok: ctrl.text.trim(),
                      );
                      if (res['success']) {
                        if (mounted) {
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Kelompok Berhasil Ditambahkan"),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } else {
                        setDialog(() => isSaving = false);
                      }
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: context.primaryColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
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

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          "Laporan Pengajian",
          style: TextStyle(fontWeight: FontWeight.w900, color: Colors.black87),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        actions: [
          if (auth.isAdmin)
            IconButton(
              onPressed: _showManageKelompok,
              icon: Icon(
                Icons.settings_suggest_rounded,
                color: context.primaryColor,
              ),
              tooltip: "Kelola Kelompok",
            ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          labelColor: context.primaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: context.primaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Riwayat"),
            Tab(text: "Statistik"),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabCtrl,
              children: [_buildRiwayat(), _buildStatistik()],
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFormAbsen,
        backgroundColor: context.primaryColor,
        label: const Text(
          "Absen",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        icon: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildRiwayat() {
    if (_laporanList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.menu_book_outlined,
              size: 72,
              color: Colors.grey.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              "Belum ada laporan pengajian",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Tekan tombol '+' untuk mengisi absen pekan ini.",
              style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: _laporanList.length,
        itemBuilder: (_, i) => _buildCard(_laporanList[i]),
      ),
    );
  }

  Widget _buildCard(LaporanNgajiModel l) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              color: context.primaryColor,
              size: 22,
            ),
          ),
          title: Text(
            l.namaKelompok ?? '-',
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(
                    Icons.location_on_rounded,
                    size: 12,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      l.lokasi ?? '-',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_rounded,
                    size: 12,
                    color: Colors.grey.shade400,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    l.tanggal ?? '-',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
                  ),
                ],
              ),
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.notes_rounded,
                  size: 16,
                  color: context.primaryColor,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Materi & Keterangan",
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        l.materiKeterangan ?? '-',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistik() =>
      const Center(child: Text("Fitur Statistik Segera Hadir"));
}
