import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/admin_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
// Note: Export to Excel/PDF will be handled later

class MealReportScreen extends StatefulWidget {
  const MealReportScreen({super.key});

  @override
  State<MealReportScreen> createState() => _MealReportScreenState();
}

class _MealReportScreenState extends State<MealReportScreen> {
  bool _isLoading = true;
  String _selectedMonthYear = '';
  List<dynamic> _mealData = [];
  Map<String, dynamic> _config = {};

  int _totalPotongan = 0;
  int _totalBersih = 0;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    _selectedMonthYear = DateFormat('MM-yyyy').format(now);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);
    final auth = context.read<AuthProvider>();

    final res = await AdminService().getMealDeductionReport(
      auth.clientId ?? "",
      _selectedMonthYear,
    );

    if (mounted) {
      if (res != null) {
        setState(() {
          _mealData = res['data'] ?? [];
          _config = res['config'] ?? {};
          
          _totalPotongan = 0;
          _totalBersih = 0;
          for (var item in _mealData) {
            _totalPotongan += (item['total_potongan'] as num).toInt();
            _totalBersih += (item['uang_makan_bersih'] as num).toInt();
          }
          
          _isLoading = false;
        });
      } else {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal memuat laporan uang makan."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickMonthYear() async {
    final now = DateTime.now();
    final firstDate = DateTime(2023, 1, 1);
    
    // Simple month picker using standard date picker
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateFormat('MM-yyyy').parse(_selectedMonthYear),
      firstDate: firstDate,
      lastDate: DateTime(now.year + 2, 12, 31),
      initialDatePickerMode: DatePickerMode.year,
    );

    if (picked != null) {
      final newMonthYear = DateFormat('MM-yyyy').format(picked);
      if (newMonthYear != _selectedMonthYear) {
        setState(() => _selectedMonthYear = newMonthYear);
        _fetchData();
      }
    }
  }

  void _exportReport() {
    // TODO: Implement export to Excel/PDF/Word
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Fitur export belum diimplementasikan"),
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
        title: const Text(
          "Laporan Uang Makan",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
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
                    color: Colors.black.withValues(alpha: 0.06),
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
        actions: [
          IconButton(
            onPressed: _exportReport,
            icon: const Icon(Icons.download_rounded, color: Color(0xFF0F172A)),
            tooltip: "Export Laporan",
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Filter and Summary Section
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Periode Laporan",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: Colors.black87,
                          ),
                        ),
                        InkWell(
                          onTap: _pickMonthYear,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: context.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.calendar_month, size: 16, color: context.primaryColor),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedMonthYear,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: context.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: _buildSummaryItem(
                            "Nominal/Hari",
                            "Rp ${NumberFormat('#,###', 'id_ID').format(_config['uang_makan'] ?? 0)}",
                            const Color(0xFF3B82F6),
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        Expanded(
                          child: _buildSummaryItem(
                            "Total Potongan",
                            "Rp ${NumberFormat('#,###', 'id_ID').format(_totalPotongan)}",
                            const Color(0xFFEF4444),
                          ),
                        ),
                        Container(width: 1, height: 40, color: Colors.grey.shade200),
                        Expanded(
                          child: _buildSummaryItem(
                            "Total Bersih",
                            "Rp ${NumberFormat('#,###', 'id_ID').format(_totalBersih)}",
                            const Color(0xFF10B981),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            
            // List Section
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : _mealData.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade300),
                              const SizedBox(height: 16),
                              Text(
                                "Tidak ada data potongan di bulan ini",
                                style: TextStyle(color: Colors.grey.shade500),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          itemCount: _mealData.length,
                          itemBuilder: (context, index) {
                            final item = _mealData[index];
                            return _buildMealItemCard(item);
                          },
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: color,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildMealItemCard(Map<String, dynamic> item) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item['nama'] ?? '-',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "ID: ${item['id']} • ${item['bagian']}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  "Rp ${NumberFormat('#,###', 'id_ID').format(item['uang_makan_bersih'])}",
                  style: const TextStyle(
                    color: Color(0xFF10B981),
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Kehadiran", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  Text(
                    "${item['hari_hadir']} Hari",
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("Keterlambatan", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  Text(
                    "${item['hari_telat']} Kali",
                    style: TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 13,
                      color: (item['hari_telat'] as num) > 0 ? const Color(0xFFEF4444) : Colors.black87,
                    ),
                  ),
                ],
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("Potongan", style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
                  Text(
                    "-Rp ${NumberFormat('#,###', 'id_ID').format(item['total_potongan'])}",
                    style: const TextStyle(
                      fontWeight: FontWeight.w600, 
                      fontSize: 13,
                      color: Color(0xFFEF4444),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
