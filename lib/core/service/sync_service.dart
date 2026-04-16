import 'dart:convert';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/core/service/admin_service.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/core/service/notification_service.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final AttendanceService _api = AttendanceService();
  final NotificationService _notify = NotificationService();

  /// Menjalankan sinkronisasi status izin dan setup pengingat
  Future<void> runSync({
    required String idAnggota,
    required String clientId,
    required AuthProvider auth,
  }) async {
    try {
      // 1. ANALISA RIWAYAT HARIAN (untuk Smart Notification)
      final history = await AttendanceService().getHistory(idAnggota, clientId);
      bool sudahMasuk = false;
      bool sudahPulang = false;

      final todayStr = DateFormat('yyyy-MM-dd').format(DateTime.now());
      for (var item in history) {
        if (item['tanggal'] == todayStr) {
          if (item['tipe'] == 'Masuk') sudahMasuk = true;
          if (item['tipe'] == 'Pulang') sudahPulang = true;
        }
      }

      // 2. UPDATE TEMA DINAMIS (Dynamic Branding)
      final config = await AdminService().getOfficeConfig(clientId);
      if (config != null && config.containsKey('theme_color')) {
        auth.updateThemeColor(config['theme_color']);
      }

      // 3. SETUP REMINDERS CERDAS
      await _notify.setupReminders(
        showMasuk: !sudahMasuk,
        showPulang: !sudahPulang,
      );

      // 4. Cek apakah ada perubahan status pada pengajuan izin/cuti
      await _checkLeaveStatusChangesFromHistory(idAnggota, history);
    } catch (e) {
      print("Sync Error: $e");
    }
  }

  String _getTodayString() {
    final now = DateTime.now();
    // Sesuaikan dengan format 'dd/MM/yyyy' atau 'yyyy-MM-dd' dari server.
    // GAS biasanya mengembalikan string yang mengandung tanggal.
    return "${now.day.toString().padLeft(2, '0')}/${now.month.toString().padLeft(2, '0')}/${now.year}";
  }

  Future<void> _checkLeaveStatusChangesFromHistory(
    String idAnggota,
    List<dynamic> history,
  ) async {
    try {
      if (history.isEmpty) return;

      final prefs = await SharedPreferences.getInstance();

      // Ambil data status sebelumnya yang disimpan di local (JSON String Map)
      final String? rawCache = prefs.getString('leave_status_cache_$idAnggota');
      Map<String, String> cache = {};
      if (rawCache != null) {
        cache = Map<String, String>.from(json.decode(rawCache));
      }

      bool hasChanges = false;
      Map<String, String> newCache = {};

      for (var item in history) {
        // Hanya cek item yang bertipe Izin/Sakit/Cuti
        final String tipe = item['tipe'] ?? "";
        if (tipe == "Izin" || tipe == "Sakit" || tipe == "Cuti") {
          final String waktu = item['waktu'] ?? "";
          final String status = item['status'] ?? "";

          newCache[waktu] = status;

          // Jika sebelumnya "Menunggu Approval" dan sekarang sudah berubah
          if (cache.containsKey(waktu) &&
              cache[waktu] == "Menunggu Approval" &&
              status != "Menunggu Approval") {
            _notify.showNotification(
              id: waktu.hashCode,
              title: "Update Pengajuan $tipe",
              body: status == "Disetujui"
                  ? "Kabar baik! Pengajuan $tipe Anda telah disetujui. ✅"
                  : "Pengajuan $tipe Anda telah diproses dengan status: $status.",
            );
            hasChanges = true;
          }
        }
      }

      // Selalu simpan state terbaru (hanya untuk tipe izin)
      await prefs.setString(
        'leave_status_cache_$idAnggota',
        json.encode(newCache),
      );
    } catch (e) {
      // Abaikan error sync diam-diam agar tidak mengganggu UI
      print("Sync Error: $e");
    }
  }
}
