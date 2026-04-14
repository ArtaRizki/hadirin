import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:hadirin/ui/widgets/skeleton_loader.dart';

class AttendanceHistoryList extends StatelessWidget {
  final List<dynamic> history;
  final bool isLoading;
  final String errorMessage;
  final Function(String url, String tipe, String waktu) onShowPhoto;

  const AttendanceHistoryList({
    super.key,
    required this.history,
    this.isLoading = false,
    this.errorMessage = "",
    required this.onShowPhoto,
  });

  String _formatTanggalIndo(DateTime dt) =>
      DateFormat('EEEE, d MMMM yyyy', 'id_ID').format(dt);

  String _formatJam(DateTime dt) => DateFormat('HH:mm').format(dt);

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Column(
        children: List.generate(3, (index) => const CardSkeleton(height: 80)),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Text(
            errorMessage,
            style: TextStyle(
              color: Colors.red.shade700,
              fontSize: 13,
            ),
          ),
        ),
      );
    }

    if (history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40.0),
          child: Column(
            children: [
              Icon(
                Icons.history_toggle_off,
                size: 52,
                color: Colors.grey.shade300,
              ),
              const SizedBox(height: 12),
              Text(
                "Belum ada data absen.",
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: history.map((log) => _buildHistoryItem(context, log as Map)).toList(),
    );
  }

  Widget _buildHistoryItem(BuildContext context, Map log) {
    final dt =
        DateTime.tryParse(log['waktu'].toString())?.toLocal() ?? DateTime.now();
    final isTerlambat = log['status'] == "Terlambat";
    final isMasuk = log['tipe'] == "Masuk";
    final isCuti =
        log['tipe'] == "Cuti" ||
        log['tipe'] == "Izin" ||
        log['tipe'] == "Sakit";

    Color accentColor = isMasuk ? context.primaryColor : Colors.orange.shade600;
    if (isCuti) accentColor = Colors.grey.shade500;

    String statusLabel = "";
    Color statusColor = context.primaryColor;
    Color statusBg = context.primaryColor.withOpacity(0.08);

    if (isMasuk) {
      statusLabel = log['status'] ?? "";
      statusColor = isTerlambat ? Colors.red.shade700 : const Color(0xFF16A34A);
      statusBg = isTerlambat
          ? Colors.red.shade50
          : const Color(0xFF16A34A).withOpacity(0.08);
    } else if (isCuti) {
      statusLabel = log['status'] ?? "";
      statusColor = log['status'] == 'Disetujui'
          ? const Color(0xFF16A34A)
          : Colors.orange.shade700;
      statusBg = log['status'] == 'Disetujui'
          ? const Color(0xFF16A34A).withOpacity(0.08)
          : Colors.orange.shade50;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accentColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              isMasuk
                  ? Icons.login_rounded
                  : isCuti
                  ? Icons.event_busy_rounded
                  : Icons.logout_rounded,
              color: accentColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Absen ${log['tipe']}  ·  ${_formatJam(dt)}",
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    color: Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  _formatTanggalIndo(dt),
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 11),
                ),
              ],
            ),
          ),
          if (log['foto'] != null && log['foto'].toString().isNotEmpty)
            GestureDetector(
              onTap: () => onShowPhoto(
                log['foto'],
                log['tipe'],
                "${_formatTanggalIndo(dt)} - ${_formatJam(dt)}",
              ),
              child: Container(
                padding: const EdgeInsets.all(7),
                margin: const EdgeInsets.only(right: 6),
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Icon(
                  Icons.image_rounded,
                  size: 16,
                  color: Colors.grey.shade500,
                ),
              ),
            ),
          if (statusLabel.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  color: statusColor,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
