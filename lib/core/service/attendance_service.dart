import 'dart:convert';
import 'dart:developer' as d;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:safe_device/safe_device.dart';
import 'package:hadirin/core/config/app_config.dart';
import 'package:hadirin/core/service/api_client.dart';
import 'package:hadirin/core/service/face_service.dart';

/// Tanggung jawab: Absen masuk/pulang & riwayat absensi karyawan.
class AttendanceService extends ApiClient {
  static const _platform = MethodChannel('com.alfahmi.absensi.sd/face_recognition');

  final _auth = LocalAuthentication();
  final _picker = ImagePicker();
  final _deviceInfo = DeviceInfoPlugin();
  final _faceService = FaceService();

  FaceService get faceService => _faceService;

  // =================================================================
  // KEAMANAN PERANGKAT (Root & Fake GPS)
  // =================================================================
  Future<void> _checkDeviceSecurity() async {
    try {
      bool isJailBroken = await SafeDevice.isJailBroken;
      if (isJailBroken) {
        throw Exception(
          'Keamanan Perangkat Lemah: Perangkat terdeteksi Root/Jailbreak. Aplikasi tidak dapat digunakan.',
        );
      }

      bool isMockLocation = await SafeDevice.isMockLocation;
      if (isMockLocation) {
        throw Exception(
          'Aktivitas Mencurigakan: Aplikasi Fake GPS terdeteksi. Harap matikan Mock Location Anda.',
        );
      }

      // Optional: Check if real device (not emulator)
      bool isRealDevice = await SafeDevice.isRealDevice;
      if (!isRealDevice) {
         throw Exception(
          'Perangkat Tidak Valid: Anda menggunakan Emulator. Absensi harus dilakukan dari ponsel asli.',
        );
      }

      // Check if developer mode is enabled
      bool isDevMode = await SafeDevice.isDevelopmentModeEnable;
      if (isDevMode) {
        throw Exception(
          'Keamanan Terdeteksi: Developer Options aktif. Harap matikan Developer Options di pengaturan HP agar bisa absen.',
        );
      }
    } catch (e) {
      if (e.toString().contains("Keamanan Perangkat") || e.toString().contains("Aktivitas Mencurigakan") || e.toString().contains("Perangkat Tidak Valid")) {
          rethrow;
      }
      d.log("Gagal mengecek keamanan perangkat: $e");
    }
  }

  // =================================================================
  // ABSEN MASUK / PULANG
  // =================================================================
  Future<Map<String, dynamic>> submitAbsen({
    required String idAnggota,
    required String namaAnggota,
    required String tipeAbsen,
    required String clientId,
  }) async {
    try {
      // 0. CEK KEAMANAN PERANGKAT (ROOT & FAKE GPS APP)
      await _checkDeviceSecurity();

      // 1. BIOMETRIK / PIN LAYAR
      bool biometricPassed = false;
      try {
        final canCheck = await _auth.canCheckBiometrics;
        final isSupported = await _auth.isDeviceSupported();
        if (canCheck || isSupported) {
          biometricPassed = await _auth.authenticate(
            localizedReason:
                'Gunakan Sidik Jari atau PIN layar Anda untuk absen $tipeAbsen',
            biometricOnly: false,
            persistAcrossBackgrounding: true,
          );
        }
      } catch (e) {
        d.log('Autentikasi perangkat dilewati: $e');
      }

      // 2. DEVICE ID
      final androidInfo = await _deviceInfo.androidInfo;
      final deviceId = androidInfo.id;

      // 3. LOKASI & VALIDASI GPS
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) throw Exception('Harap aktifkan GPS terlebih dahulu.');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      
      if (permission == LocationPermission.denied) {
        throw Exception('Izin lokasi ditolak. Aplikasi butuh akses GPS untuk validasi posisi.');
      }
      
      if (permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi ditolak permanen. Harap aktifkan di pengaturan HP.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      // Proteksi Tambahan Fake GPS bawaan Android (Geolocator)
      if (position.isMocked) {
          throw Exception(
          'Lokasi Palsu Terdeteksi: Anda terindikasi menggunakan Fake GPS. Absensi ditolak.',
        );
      }

      // 4. IZIN KAMERA (Dihapus)
      // 5. AMBIL FOTO SELFIE (Dihapus)
      // 6. FACE RECOGNITION (Dihapus)
      // 7. KOMPRESI & BASE64 FOTO (Dihapus)
      final base64Image = "";

      // 8. KIRIM KE SERVER
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'absen',
        'client_id': clientId,
        'client_timestamp': DateTime.now().millisecondsSinceEpoch,
        'id_karyawan': idAnggota,
        'nama': namaAnggota,
        'device_id': deviceId,
        'tipe_absen': tipeAbsen,
        'lat_long': '${position.latitude}, ${position.longitude}',
        'biometric_passed': biometricPassed,
        'foto_base64': base64Image,
      };

      final response = await sendRequest('absen', payload);
      if (response.statusCode != 200) {
        throw Exception(
          'Gagal terhubung ke server (HTTP ${response.statusCode}).',
        );
      }

      return parseResponse(response.body);
    } catch (e) {
      d.log('==== ERROR ABSEN ==== $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // =================================================================
  // RIWAYAT ABSENSI ANGGOTA
  // =================================================================
  Future<List<dynamic>> getHistory(String idAnggota, String clientId) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'get_history',
        'client_id': clientId,
        'id_karyawan': idAnggota,
      };

      final response = await sendRequest('get_history', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) return data['message'] as List<dynamic>;
        throw Exception(data['message']);
      }
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      d.log('==== ERROR GET HISTORY ==== $e');
      throw Exception('Gagal mengambil riwayat: $e');
    }
  }
  // =================================================================
  // CEK STATUS CUTI HARI INI
  // =================================================================
  Future<bool> cekStatusCutiHariIni(String idAnggota, String clientId) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'cek_status_hari_ini',
        'client_id': clientId,
        'id_karyawan': idAnggota,
      };

      final response = await sendRequest('cek_status_hari_ini', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return data['message'] == true || data['message'] == 'true';
        }
      }
      return false;
    } catch (e) {
      d.log('==== ERROR CEK STATUS CUTI ==== $e');
      return false;
    }
  }
}
