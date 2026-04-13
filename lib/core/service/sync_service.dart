import 'dart:convert';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/core/service/notification_service.dart';
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
  }) async {
    // 1. Setup pengingat harian (idempotent)
    await _notify.setupReminders();

    // 2. Cek apakah ada perubahan status pada pengajuan izin/cuti
    await _checkLeaveStatusChanges(idAnggota, clientId);
  }

  Future<void> _checkLeaveStatusChanges(
    String idAnggota,
    String clientId,
  ) async {
    try {
      final history = await _api.getHistory(idAnggota, clientId);
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
          if (cache.containsKey(waktu) && cache[waktu] == "Menunggu Approval" && status != "Menunggu Approval") {
            _notify.showNotification(
              id: waktu.hashCode,
              title: "Update Pengajuan $tipe",
              body: "Pengajuan Anda pada $waktu telah $status.",
            );
            hasChanges = true;
          }
        }
      }

      // Selalu simpan state terbaru (hanya untuk tipe izin)
      await prefs.setString('leave_status_cache_$idAnggota', json.encode(newCache));
      
    } catch (e) {
      // Abaikan error sync diam-diam agar tidak mengganggu UI
      print("Sync Error: $e");
    }
  }
}
