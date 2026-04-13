import 'dart:convert';
import 'dart:developer' as d;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:hadirin/core/config/app_config.dart';
import 'package:hadirin/core/service/api_client.dart';

/// Tanggung jawab: Semua operasi yang hanya bisa dilakukan admin UMKM —
/// kelola karyawan, lokasi kantor, perangkat, laporan, dan registrasi klien.
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
  // TAMBAH KARYAWAN BARU KE DATABASE UMKM
  // =================================================================
  Future<Map<String, dynamic>> tambahKaryawan({
    required String clientId,
    required String idKaryawanBaru,
    required String namaKaryawanBaru,
    required String divisi,
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'add_karyawan',
        'client_id': clientId,
        'id_karyawan_baru': idKaryawanBaru,
        'nama_karyawan_baru': namaKaryawanBaru,
        'divisi_baru': divisi,
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
      d.log('==== ERROR ADD KARYAWAN ==== $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // =================================================================
  // AMBIL SEMUA DATA KARYAWAN SATU UMKM
  // =================================================================
  Future<List<dynamic>> getAllKaryawan(String clientId) async {
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
      d.log('==== ERROR GET ALL KARYAWAN ==== $e');
      throw Exception('Gagal mengambil data karyawan: $e');
    }
  }

  // =================================================================
  // LAPORAN BULANAN (bisa semua karyawan atau 1 karyawan tertentu)
  // =================================================================
  Future<List<dynamic>> getMonthlyReport(
    String clientId,
    String bulanTahun,
    String idKaryawanTarget,
  ) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'get_monthly_report',
        'client_id': clientId,
        'bulan_tahun': bulanTahun,
        'id_karyawan_target': idKaryawanTarget,
      };

      final response = await sendRequest(
        'get_monthly_report',
        payload,
        timeout: const Duration(seconds: 30),
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
  // RESET DEVICE ID KARYAWAN (jika karyawan ganti HP)
  // =================================================================
  Future<Map<String, dynamic>> resetDeviceID(
    String clientId,
    String targetId,
  ) async {
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
  // DAFTARKAN KLIEN UMKM BARU (dipakai di AdminRegisterScreen)
  // =================================================================
  Future<Map<String, dynamic>> registerKlien({
    required String namaUmkm,
    required double lat,
    required double lng,
    required double radius,
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'register_klien',
        'nama_umkm': namaUmkm,
        'lat': lat,
        'lng': lng,
        'radius': radius,
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
        throw Exception(data['message'] ?? 'Gagal mendaftarkan UMKM');
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
  // ENROLL PERANGKAT KARYAWAN (dipakai di LoginScreen)
  // =================================================================
  Future<Map<String, dynamic>> enrollDevice(
    String clientId,
    String idKaryawan,
  ) async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final deviceId = androidInfo.id;

      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'enroll_device',
        'client_id': clientId,
        'id_karyawan': idKaryawan,
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
}
