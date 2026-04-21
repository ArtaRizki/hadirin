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
  final weekNum = ((d.difference(DateTime(d.year, 1, 1)).inDays) / 7).ceil() + 1;
  return "Pekan $weekNum – ${DateFormat('MMMM yyyy', 'id_ID').format(d)}";
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
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
    // Admin → semua laporan; Guru → laporan milik sendiri
    final idGuru = auth.isAdmin ? 'SEMUA' : (auth.idAnggota ?? '');
    final data = await _service.getLaporanNgaji(auth.clientId ?? '', idGuru);
    setState(() {
      _laporanList = data;
      _isLoading = false;
    });
  }

  void _showFormAbsen() {
    final auth = context.read<AuthProvider>();

    // Daftar kelompok pengajian
    const kelompokOptions = [
      'Kelas 7A', 'Kelas 7B', 'Kelas 7C',
      'Kelas 8A', 'Kelas 8B', 'Kelas 8C',
      'Kelas 9A', 'Kelas 9B', 'Kelas 9C',
      'Kelompok Iqro 1', 'Kelompok Iqro 2', 'Kelompok Iqro 3',
      'Kelompok Al-Quran', 'Lainnya',
    ];
    String? selectedKelompok;
    final lainnyaCtrl = TextEditingController();
    final lokasiCtrl = TextEditingController();
    final materiCtrl = TextEditingController();
    bool isSaving = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
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
          child: SingleChildScrollView(
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
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),

                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: context.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(Icons.menu_book_rounded,
                          color: context.primaryColor, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("Absen Pengajian Pekan Ini",
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w900)),
                          Text(
                            _weekLabel(DateTime.now()),
                            style: TextStyle(
                                fontSize: 12, color: Colors.grey.shade500),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // Info guru
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: context.primaryColor.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                        color: context.primaryColor.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            context.primaryColor.withValues(alpha: 0.15),
                        radius: 18,
                        child: Text(
                          (auth.namaAnggota ?? 'G').substring(0, 1).toUpperCase(),
                          style: TextStyle(
                              color: context.primaryColor,
                              fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.namaAnggota ?? '-',
                                style: const TextStyle(
                                    fontWeight: FontWeight.w700, fontSize: 14)),
                            Text("ID: ${auth.idAnggota ?? '-'}",
                                style: TextStyle(
                                    color: Colors.grey.shade500, fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                 _label("Nama Kelompok Pengajian"),
                const SizedBox(height: 8),
                DropdownButtonFormField<String>(
                  value: selectedKelompok,
                  decoration: InputDecoration(
                    hintText: "Pilih kelompok pengajian",
                    hintStyle: TextStyle(
                        color: Colors.grey.shade400, fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    prefixIcon: Icon(Icons.group_rounded,
                        color: Colors.grey.shade400, size: 18),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 14),
                  ),
                  items: kelompokOptions
                      .map((k) => DropdownMenuItem(
                          value: k, child: Text(k)))
                      .toList(),
                  onChanged: (v) => setSheet(() => selectedKelompok = v),
                ),
                // Field custom jika pilih Lainnya
                if (selectedKelompok == 'Lainnya') ...[  
                  const SizedBox(height: 10),
                  TextField(
                    controller: lainnyaCtrl,
                    decoration: InputDecoration(
                      hintText: "Tulis nama kelompok...",
                      hintStyle: TextStyle(
                          color: Colors.grey.shade400, fontSize: 13),
                      filled: true,
                      fillColor: Colors.grey.shade100,
                      prefixIcon: Icon(Icons.edit_rounded,
                          color: Colors.grey.shade400, size: 18),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                _label("Lokasi Pelaksanaan"),
                const SizedBox(height: 8),
                _field(lokasiCtrl, "Contoh: Masjid Al-Ikhlas / Ruang Kelas 5",
                    icon: Icons.location_on_rounded),

                const SizedBox(height: 16),

                _label("Materi & Keterangan"),
                const SizedBox(height: 8),
                TextField(
                  controller: materiCtrl,
                  maxLines: 4,
                  decoration: InputDecoration(
                    hintText:
                        "Contoh: Surat Al-Baqarah ayat 1-5, tajwid hukum nun mati...",
                    hintStyle:
                        TextStyle(color: Colors.grey.shade400, fontSize: 13),
                    filled: true,
                    fillColor: Colors.grey.shade100,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                ),

                const SizedBox(height: 28),

                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: context.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: isSaving
                        ? null
                        : () async {
                            // Tentukan nilai kelompok yang dikirim
                            final namaKelompok = selectedKelompok == 'Lainnya'
                                ? lainnyaCtrl.text.trim()
                                : (selectedKelompok ?? '');

                            if (namaKelompok.isEmpty ||
                                lokasiCtrl.text.trim().isEmpty ||
                                materiCtrl.text.trim().isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                    content: Text("Semua field wajib diisi!"),
                                    backgroundColor: Colors.red),
                              );
                              return;
                            }
                            setSheet(() => isSaving = true);

                            final res = await _service.submitLaporanNgaji(
                              clientId: auth.clientId ?? '',
                              idGuru: auth.idAnggota ?? '',
                              namaKelompok: namaKelompok,
                              lokasi: lokasiCtrl.text.trim(),
                              materiKeterangan: materiCtrl.text.trim(),
                            );

                            if (!mounted) return;
                            setSheet(() => isSaving = false);

                            if (res['success'] == true) {
                              Navigator.pop(ctx);
                              _fetch();
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text(
                                      "Laporan pengajian berhasil disimpan!"),
                                  backgroundColor: Colors.green.shade600,
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
                    icon: isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.check_circle_rounded),
                    label: Text(
                      isSaving ? "Menyimpan..." : "Simpan Laporan",
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 16),
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

  Widget _label(String text) => Text(text,
      style: const TextStyle(
          fontWeight: FontWeight.w700,
          fontSize: 13,
          color: Color(0xFF1E293B)));

  Widget _field(TextEditingController ctrl, String hint,
          {IconData? icon}) =>
      TextField(
        controller: ctrl,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 13),
          filled: true,
          fillColor: Colors.grey.shade100,
          prefixIcon: icon != null
              ? Icon(icon, color: Colors.grey.shade400, size: 18)
              : null,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final isAdmin = auth.isAdmin;

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF),
      appBar: AppBar(
        title: const Text("Laporan Pengajian",
            style: TextStyle(
                fontWeight: FontWeight.w900, color: Color(0xFF0F172A))),
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF0F172A)),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: isAdmin
            ? TabBar(
                controller: _tabCtrl,
                labelColor: context.primaryColor,
                unselectedLabelColor: Colors.grey.shade400,
                indicatorColor: context.primaryColor,
                tabs: const [
                  Tab(text: "Semua Laporan"),
                  Tab(text: "Per Guru"),
                ],
              )
            : null,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : isAdmin
              ? TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _buildRiwayat(_laporanList),
                    _buildPerGuru(_laporanList),
                  ],
                )
              : RefreshIndicator(
                  onRefresh: _fetch,
                  child: _buildRiwayat(_laporanList),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showFormAbsen,
        backgroundColor: context.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Absen Pekan Ini",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // ── Tab: Daftar semua laporan (kronologis) ──
  Widget _buildRiwayat(List<LaporanNgajiModel> list) {
    if (list.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_outlined,
                size: 72, color: Colors.grey.shade200),
            const SizedBox(height: 16),
            Text("Belum ada laporan pengajian",
                style: TextStyle(
                    color: Colors.grey.shade500, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text("Tekan tombol '+' untuk mengisi absen pekan ini.",
                style:
                    TextStyle(color: Colors.grey.shade400, fontSize: 12)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
        itemCount: list.length,
        itemBuilder: (_, i) => _buildCard(list[i]),
      ),
    );
  }

  // ── Tab Admin: Kelompokkan per ID Guru ──
  Widget _buildPerGuru(List<LaporanNgajiModel> list) {
    // Kelompokkan berdasarkan idGuru
    final Map<String, List<LaporanNgajiModel>> byGuru = {};
    for (final l in list) {
      byGuru.putIfAbsent(l.idGuru, () => []).add(l);
    }

    if (byGuru.isEmpty) {
      return Center(
        child: Text("Belum ada data.",
            style: TextStyle(color: Colors.grey.shade500)),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetch,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
        children: byGuru.entries.map((entry) {
          final guruId = entry.key;
          final laporanGuru = entry.value;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header guru
              Container(
                margin: const EdgeInsets.only(bottom: 8, top: 12),
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      context.primaryColor,
                      const Color(0xFF7C3AED),
                    ],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.person_rounded,
                        color: Colors.white, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "ID Guru: $guruId  •  ${laporanGuru.length} laporan",
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                            fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              ...laporanGuru.map(_buildCard),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildCard(LaporanNgajiModel l) {
    DateTime? dt;
    try {
      if (l.tanggal != null) dt = DateTime.parse(l.tanggal!);
    } catch (_) {}

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4))
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          childrenPadding:
              const EdgeInsets.fromLTRB(16, 0, 16, 16),
          leading: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: context.primaryColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.menu_book_rounded,
                color: context.primaryColor, size: 22),
          ),
          title: Text(
            l.namaKelompok,
            style: const TextStyle(
                fontWeight: FontWeight.w800, fontSize: 15),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              Row(
                children: [
                  Icon(Icons.location_on_rounded,
                      size: 12, color: Colors.grey.shade400),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(l.lokasi,
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
              if (dt != null) ...[
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(Icons.calendar_today_rounded,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('EEE, d MMM yyyy • HH:mm', 'id_ID')
                          .format(dt),
                      style: TextStyle(
                          fontSize: 11, color: Colors.grey.shade400),
                    ),
                  ],
                ),
              ],
            ],
          ),
          children: [
            const Divider(height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.notes_rounded,
                    size: 16, color: context.primaryColor),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text("Materi & Keterangan",
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(l.materiKeterangan,
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600)),
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
}
