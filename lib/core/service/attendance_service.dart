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
import 'package:hadirin/core/config/app_config.dart';
import 'package:hadirin/core/service/api_client.dart';
import 'package:hadirin/core/service/face_service.dart';

/// Tanggung jawab: Absen masuk/pulang & riwayat absensi karyawan.
class AttendanceService extends ApiClient {
  static const _platform = MethodChannel('com.mobile.hadirin/face_recognition');

  final _auth = LocalAuthentication();
  final _picker = ImagePicker();
  final _deviceInfo = DeviceInfoPlugin();
  final _faceService = FaceService();

  // =================================================================
  // ABSEN MASUK / PULANG
  // =================================================================
  Future<Map<String, dynamic>> submitAbsen({
    required String idKaryawan,
    required String namaKaryawan,
    required String tipeAbsen,
    required String clientId,
  }) async {
    try {
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

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception('Izin lokasi belum diberikan.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      // 4. IZIN KAMERA
      var cameraStatus = await Permission.camera.status;
      if (cameraStatus.isDenied)
        cameraStatus = await Permission.camera.request();
      if (cameraStatus.isPermanentlyDenied) {
        throw Exception(
          'Izin kamera ditolak permanen. Harap aktifkan di pengaturan HP.',
        );
      }
      if (!cameraStatus.isGranted) {
        throw Exception(
          'Aplikasi butuh izin kamera untuk melakukan absen wajah.',
        );
      }

      // 5. AMBIL FOTO SELFIE
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 100,
        preferredCameraDevice: CameraDevice.front,
      );
      if (image == null)
        throw Exception('Foto wajah wajib diambil untuk absen.');

      // 6. FACE RECOGNITION (delegasi ke FaceService)
      d.log('Mengekstrak vektor wajah dari foto...');
      final wajahHariIni = await _faceService.getEmbeddingFromNative(
        _platform,
        image.path,
      );
      if (wajahHariIni.isEmpty) {
        throw Exception(
          'Gagal mendeteksi wajah di foto. Coba lagi di tempat yang terang.',
        );
      }

      d.log('Mengambil wajah master dari server...');
      final wajahMaster = await _faceService.getWajahMasterDariServer(
        idKaryawan,
        clientId,
      );
      if (wajahMaster.isEmpty) {
        throw Exception(
          'Wajah Anda belum terdaftar. Daftarkan wajah di menu Profil terlebih dahulu.',
        );
      }

      final jarak = _faceService.hitungKemiripan(wajahHariIni, wajahMaster);
      d.log('Jarak Kemiripan Wajah: $jarak');

      // Threshold 1.0 berdasarkan benchmark model MobileFaceNet — jangan ubah
      // tanpa menguji ulang dengan dataset wajah karyawan.
      if (jarak > 1.0) {
        throw Exception(
          'Wajah tidak cocok! (Jarak: ${jarak.toStringAsFixed(2)}). Pastikan Anda absen sendiri.',
        );
      }

      // 7. KOMPRESI & BASE64 FOTO
      final targetPath = '${image.path}_compressed.jpg';
      final compressedFile = await FlutterImageCompress.compressAndGetFile(
        image.path,
        targetPath,
        quality: 30,
        minWidth: 600,
        minHeight: 600,
        format: CompressFormat.jpeg,
      );
      if (compressedFile == null) {
        throw Exception('Gagal mengompres gambar sebelum upload.');
      }

      final imageBytes = await compressedFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      try {
        File(targetPath).deleteSync();
      } catch (e) {
        d.log('Gagal menghapus file temp: $e');
      }

      // 8. KIRIM KE SERVER
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'absen',
        'client_id': clientId,
        'client_timestamp': DateTime.now().millisecondsSinceEpoch,
        'id_karyawan': idKaryawan,
        'nama': namaKaryawan,
        'device_id': deviceId,
        'tipe_absen': tipeAbsen,
        'lat_long': '${position.latitude}, ${position.longitude}',
        'is_mock_location': position.isMocked,
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
  // RIWAYAT ABSENSI KARYAWAN
  // =================================================================
  Future<List<dynamic>> getHistory(String idKaryawan, String clientId) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'get_history',
        'client_id': clientId,
        'id_karyawan': idKaryawan,
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
  Future<bool> cekStatusCutiHariIni(String idKaryawan, String clientId) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'cek_status_hari_ini',
        'client_id': clientId,
        'id_karyawan': idKaryawan,
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
