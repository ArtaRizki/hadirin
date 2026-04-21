import 'dart:convert';
import 'dart:developer' as d;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hadirin/core/config/app_config.dart';
import 'package:hadirin/core/service/api_client.dart';

/// Tanggung jawab: Semua operasi yang hanya bisa dilakukan admin Instansi —
/// kelola anggota, lokasi kantor, perangkat, laporan, dan registrasi klien.
class AdminService extends ApiClient {
  final _deviceInfo = DeviceInfoPlugin();

  // =================================================================
  // UPDATE LOKASI KANTOR (titik pusat & radius absensi)
  // =================================================================
  Future<bool> updateLokasi(
    String clientId,
    double lat,
    double lng,
    double radius,
  ) async {
    if (clientId.isEmpty) return false;
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'update_lokasi',
        'client_id': clientId,
        'lat': lat,
        'lng': lng,
        'radius': radius,
      };

      final response = await sendRequest('update_lokasi', payload);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['code'] == 200;
      }
      return false;
    } catch (e) {
      d.log('==== ERROR UPDATE LOKASI ==== $e');
      return false;
    }
  }

  // =================================================================
  // UPDATE JAM KERJA (masuk, batas, pulang)
  // =================================================================
  Future<bool> updateJamKerja({
    required String clientId,
    required String jamMasukMulai,
    required String batasJamMasuk,
    required String jamPulangMulai,
    int tlInterval = 30,
    int maxTier = 0,
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'update_jam_kerja',
        'client_id': clientId,
        'jam_masuk_mulai': jamMasukMulai,
        'batas_jam_masuk': batasJamMasuk,
        'jam_pulang_mulai': jamPulangMulai,
        'tl_interval': tlInterval,
        'max_tier': maxTier,
      };

      final response = await sendRequest('update_jam_kerja', payload);
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['code'] == 200;
      }
      return false;
    } catch (e) {
      d.log('==== ERROR UPDATE JAM KERJA ==== $e');
      return false;
    }
  }

  // =================================================================
  // AMBIL KONFIGURASI KANTOR (lat, lng, radius) + SHIFT PERSONAL
  // =================================================================
  Future<Map<String, dynamic>?> getOfficeConfig(
    String clientId, {
    String? idKaryawan,
  }) async {
    if (clientId.isEmpty) return null;
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'get_office_config',
        'client_id': clientId,
        'id_karyawan': idKaryawan,
      };

      final response = await sendRequest('get_office_config', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final msg = data['message'];
          return {
            ...msg,
            'tl_interval': int.tryParse(msg['tl_interval']?.toString() ?? "30") ?? 30,
            'max_tier': int.tryParse(msg['max_tier']?.toString() ?? "0") ?? 0,
          };
        }
      }
      return null;
    } catch (e) {
      d.log('==== ERROR GET OFFICE CONFIG ==== $e');
      return null;
    }
  }

  // =================================================================
  // TAMBAH ANGGOTA BARU KE DATABASE INSTANSI
  // =================================================================
  Future<Map<String, dynamic>> tambahAnggota({
    required String clientId,
    required String idAnggotaBaru,
    required String namaAnggotaBaru,
    required String bagian,
    String noHp = "",
    String? defaultShift,
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'add_karyawan',
        'client_id': clientId,
        'id_karyawan_baru': idAnggotaBaru,
        'nama_karyawan_baru': namaAnggotaBaru,
        'divisi_baru': bagian,
        'no_hp': noHp,
        'default_shift': defaultShift,
      };

      final response = await sendRequest('add_karyawan', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return {'success': true, 'message': data['message']};
        }
        throw Exception(data['message']);
      }
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      d.log('==== ERROR ADD ANGGOTA ==== $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // =================================================================
  // AMBIL SEMUA DATA ANGGOTA SATU INSTANSI
  // =================================================================
  Future<List<dynamic>> getAllAnggota(String clientId) async {
    if (clientId.isEmpty) throw Exception("Kode Instansi tidak boleh kosong.");
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'get_all_karyawan',
        'client_id': clientId,
      };

      final response = await sendRequest('get_all_karyawan', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) return data['message'] as List<dynamic>;
        throw Exception(data['message']);
      }
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      d.log('==== ERROR GET ALL ANGGOTA ==== $e');
      throw Exception('Gagal mengambil data anggota: $e');
    }
  }

  // =================================================================
  // LAPORAN BULANAN (bisa semua anggota atau 1 anggota tertentu)
  // =================================================================
  Future<List<dynamic>> getMonthlyReport(
    String clientId,
    String bulanTahun,
    String idAnggotaTarget,
  ) async {
    if (clientId.isEmpty) throw Exception("Kode Instansi tidak boleh kosong.");
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'get_monthly_report',
        'client_id': clientId,
        'bulan_tahun': bulanTahun,
        'id_karyawan_target': idAnggotaTarget,
      };

      final response = await sendRequest(
        'get_monthly_report',
        payload,
        timeout: const Duration(seconds: 60),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) return data['message'] as List<dynamic>;
        throw Exception(data['message']);
      }
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      d.log('==== ERROR GET MONTHLY REPORT ==== $e');
      throw Exception('Gagal mengambil data bulanan: $e');
    }
  }

  // =================================================================
  // RESET DEVICE ID ANGGOTA (jika anggota ganti HP)
  // =================================================================
  Future<Map<String, dynamic>> resetDeviceID(
    String clientId,
    String targetId,
  ) async {
    if (clientId.isEmpty) throw Exception("Kode Instansi tidak boleh kosong.");
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'reset_device',
        'client_id': clientId,
        'target_id_karyawan': targetId,
      };

      final response = await sendRequest('reset_device', payload);
      if (response.statusCode == 200) return jsonDecode(response.body);
      throw Exception(
        'Gagal terhubung ke server (HTTP ${response.statusCode}).',
      );
    } catch (e) {
      d.log('==== ERROR RESET DEVICE ==== $e');
      return {
        'code': 500,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // =================================================================
  // DAFTARKAN KLIEN INSTANSI BARU (dipakai di AdminRegisterScreen)
  // =================================================================
  Future<Map<String, dynamic>> registerKlien({
    required String namaInstansi,
    required double lat,
    required double lng,
    required double radius,
    String adminPhone = "",
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'register_klien',
        'nama_umkm': namaInstansi,
        'lat': lat,
        'lng': lng,
        'radius': radius,
        'admin_phone': adminPhone,
      };

      final response = await sendRequest(
        'register_klien',
        payload,
        timeout: const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return {'success': true, 'client_id': data['message']['client_id']};
        }
        throw Exception(data['message'] ?? 'Gagal mendaftarkan Instansi');
      }
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      d.log('==== ERROR REGISTER KLIEN ==== $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // =================================================================
  // ENROLL PERANGKAT ANGGOTA (dipakai di LoginScreen)
  // =================================================================
  Future<Map<String, dynamic>> enrollDevice(
    String clientId,
    String idAnggota,
  ) async {
    if (clientId.isEmpty) throw Exception("Kode Instansi tidak boleh kosong.");
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final deviceId = androidInfo.id;

      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'enroll_device',
        'client_id': clientId,
        'id_karyawan': idAnggota,
        'device_id': deviceId,
      };

      final response = await sendRequest(
        'enroll_device',
        payload,
        timeout: const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return {'success': true, 'message': data['message']};
        }
        throw Exception(data['message']);
      }
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // =================================================================
  // VERIFIKASI SUPER ADMIN
  // =================================================================
  Future<Map<String, dynamic>> verifySuperAdmin(String password) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'verify_super_admin',
        'password': password,
      };

      final response = await sendRequest(
        'verify_super_admin',
        payload,
        timeout: const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return {'success': true, 'message': 'Super Admin Verified'};
        }
        throw Exception(data['message']);
      }
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // =================================================================
  // GET SHIFT LIST & PLOTTING SETTINGS
  // =================================================================
  Future<Map<String, dynamic>> getShiftList(
    String clientId, {
    int? year,
    int? month,
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'get_shift_list',
        'client_id': clientId,
        'year': year ?? DateTime.now().year,
        'month': month ?? DateTime.now().month,
      };

      final response = await sendRequest('get_shift_list', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return {'success': true, 'data': data['message']};
        }
        throw Exception(data['message']);
      }
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // =================================================================
  // SAVE SHIFT DEFINITIONS
  // =================================================================
  Future<Map<String, dynamic>> saveShifts(
    String clientId,
    List<dynamic> shifts,
  ) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'save_shifts',
        'client_id': clientId,
        'shift_list': shifts,
      };

      final response = await sendRequest('save_shifts', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) return {'success': true};
        throw Exception(data['message']);
      }
      throw Exception('Gagal menyimpan.');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // =================================================================
  // SAVE PLOTTING ASSIGNMENTS
  // =================================================================
  Future<Map<String, dynamic>> savePlotting(
    String clientId,
    List<dynamic> plottingList,
  ) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'save_plotting',
        'client_id': clientId,
        'plotting_list': plottingList,
      };

      final response = await sendRequest('save_plotting', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) return {'success': true};
        throw Exception(data['message'] ?? 'Gagal menyimpan plotting.');
      }
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // =================================================================
  // UPDATE DEFAULT SHIFT FOR USER
  // =================================================================
  Future<Map<String, dynamic>> updateDefaultShift(
    String clientId,
    String targetId,
    String newShiftId,
  ) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'update_default_shift',
        'client_id': clientId,
        'id_karyawan_target': targetId,
        'new_shift_id': newShiftId,
      };

      final response = await sendRequest('update_default_shift', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) return {'success': true};
        throw Exception(data['message']);
      }
      throw Exception('Gagal menyimpan setelan default.');
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // =================================================================
  // ABSENSI HARI INI (Admin View)
  // =================================================================
  Future<List<dynamic>> getTodayAttendance(String clientId) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'get_today_attendance',
        'client_id': clientId,
      };

      final response = await sendRequest('get_today_attendance', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return data['message'] as List<dynamic>;
        }
        throw Exception(data['message']);
      }
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      d.log('==== ERROR GET TODAY ATTENDANCE ==== $e');
      throw Exception('Gagal mengambil data absensi hari ini: $e');
    }
  }
}
