import 'dart:convert';
import 'dart:developer' as d;
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:math';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:hadirin/core/config/app_config.dart';

abstract class _Config {
  static String get gasEndpoint => AppConfig.gasEndpoint;
  static String get apiToken => AppConfig.apiToken;
  static const httpTimeout = Duration(seconds: 20);
}

class AttendanceService {
  static const platform = MethodChannel('com.example.hadirin/face_recognition');
  final _auth = LocalAuthentication();
  final _picker = ImagePicker();
  final _deviceInfo = DeviceInfoPlugin();

  // =================================================================
  // SKENARIO B: ABSENSI HARIAN (CLOCK IN / CLOCK OUT)
  // =================================================================
  Future<Map<String, dynamic>> submitAbsen({
    required String idKaryawan,
    required String namaKaryawan,
    required String tipeAbsen,
  }) async {
    try {
      // 1. LAPIS KEAMANAN: BIOMETRIK / PIN LAYAR
      bool biometricPassed = false;
      try {
        final canAuthBiometrics = await _auth.canCheckBiometrics;
        final isDeviceSupported = await _auth.isDeviceSupported();

        if (canAuthBiometrics || isDeviceSupported) {
          biometricPassed = await _auth.authenticate(
            localizedReason:
                'Gunakan Sidik Jari atau PIN layar Anda untuk absen $tipeAbsen',
            biometricOnly: false,
            persistAcrossBackgrounding: true,
          );
        }
      } catch (e) {
        d.log("Autentikasi perangkat dilewati: $e");
      }

      // 2. DEVICE ID
      final androidInfo = await _deviceInfo.androidInfo;
      final deviceId = androidInfo.id;

      // 3. LOKASI & FAKE GPS CHECK
      final isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) throw Exception("Harap aktifkan GPS terlebih dahulu.");

      final permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        throw Exception("Izin lokasi belum diberikan.");
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      // ========================================================
      // 4. CEK IZIN KAMERA (Pencegahan Force Close)
      // ========================================================
      var cameraStatus = await Permission.camera.status;

      if (cameraStatus.isDenied) {
        // Minta izin jika belum pernah ditanya atau baru sekali ditolak
        cameraStatus = await Permission.camera.request();
      }

      if (cameraStatus.isPermanentlyDenied) {
        // Jika user klik "Jangan tanya lagi", arahkan ke Settings
        throw Exception(
          "Izin kamera ditolak permanen. Harap aktifkan di pengaturan HP.",
        );
      }

      if (!cameraStatus.isGranted) {
        throw Exception(
          "Aplikasi butuh izin kamera untuk melakukan absen wajah.",
        );
      }

      // 4b. AMBIL FOTO SELFIE
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality:
            100, // Biarkan 100% untuk deteksi Face Recognition yang akurat
        preferredCameraDevice: CameraDevice.front,
      );
      if (image == null) {
        throw Exception("Foto wajah wajib diambil untuk absen.");
      }

      // ---------------------------------------------------------
      // 5. PROSES FACE RECOGNITION (PENCOCOKAN WAJAH)
      // ---------------------------------------------------------
      d.log("Mengekstrak vektor wajah dari foto...");
      List<double> wajahHariIni = await getFaceEmbeddingFromNative(image.path);
      if (wajahHariIni.isEmpty) {
        throw Exception(
          "Gagal mendeteksi wajah di foto. Coba lagi di tempat yang terang.",
        );
      }

      d.log("Mengambil wajah master dari server...");
      List<double> wajahMaster = await getWajahMasterDariServer(idKaryawan);
      if (wajahMaster.isEmpty) {
        throw Exception(
          "Wajah Anda belum terdaftar. Daftarkan wajah di menu Profil terlebih dahulu.",
        );
      }

      // Hitung Jarak Euclidean (Threshold batas aman = 1.0)
      double jarakWajah = hitungKemiripanWajah(wajahHariIni, wajahMaster);
      d.log("Jarak Kemiripan Wajah: $jarakWajah");

      // Jika jarak > 1.0, berarti orang berbeda
      if (jarakWajah > 1.0) {
        throw Exception(
          "Wajah tidak cocok! (Jarak: ${jarakWajah.toStringAsFixed(2)}). Pastikan Anda absen sendiri.",
        );
      }
      // ---------------------------------------------------------

      // ========================================================
      // 6. KOMPRESI GAMBAR UNTUK CLOUD (HEMAT KUOTA DRIVE)
      // ========================================================
      d.log("Mengompresi gambar untuk diupload...");
      final String targetPath = "${image.path}_compressed.jpg";

      final XFile? compressedFile =
          await FlutterImageCompress.compressAndGetFile(
            image.path,
            targetPath,
            quality: 30, // Turunkan kualitas ke 30%
            minWidth: 600, // Maksimal dimensi 600x600
            minHeight: 600,
            format: CompressFormat.jpeg,
          );

      if (compressedFile == null) {
        throw Exception("Gagal mengompres gambar sebelum upload.");
      }

      // 7. Base64 dari file yang SUDAH DIKOMPRESI
      final imageBytes = await compressedFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // Bersihkan file sementara dari memori HP
      try {
        File(targetPath).deleteSync();
      } catch (e) {
        d.log("Gagal menghapus file temp: $e");
      }
      // ========================================================

      // 8. PAYLOAD
      final payload = {
        "api_token": _Config.apiToken,
        "action": "absen",
        "client_id": AppConfig.clientId,
        "client_timestamp": DateTime.now().millisecondsSinceEpoch,
        "id_karyawan": idKaryawan,
        "nama": namaKaryawan,
        "device_id": deviceId,
        "tipe_absen": tipeAbsen,
        "lat_long": "${position.latitude}, ${position.longitude}",
        "is_mock_location": position.isMocked,
        "biometric_passed": biometricPassed,
        "foto_base64": base64Image, // Gambar yang dikirim sudah ukuran kecil!
      };

      // 9. HTTP POST
      var response = await http
          .post(
            Uri.parse(_Config.gasEndpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(_Config.httpTimeout);

      if (response.statusCode == 302 || response.statusCode == 303) {
        final redirectUrl = _extractRedirectUrl(response);
        if (redirectUrl != null) {
          response = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_Config.httpTimeout);
        }
      }

      if (response.statusCode != 200) {
        throw Exception(
          "Gagal terhubung ke server (HTTP ${response.statusCode}).",
        );
      }

      return _parseResponse(response.body);
    } catch (e) {
      d.log('==== ERROR ABSEN ==== $e');
      return {
        "success": false,
        "message": e.toString().replaceAll("Exception: ", ""),
      };
    }
  }

  // =================================================================
  // FUNGSI BARU: PENGAJUAN IZIN / SAKIT / CUTI
  // =================================================================
  Future<Map<String, dynamic>> submitIzin({
    required String idKaryawan,
    required String tipeIzin,
    required String rentangTanggal,
    required String alasan,
    String? imagePath, // Path foto surat dokter (opsional)
  }) async {
    try {
      String base64Image = "";

      // Jika user memilih Sakit dan melampirkan foto
      if (imagePath != null && imagePath.isNotEmpty) {
        final String targetPath = "${imagePath}_compressed_doc.jpg";
        final XFile? compressedFile =
            await FlutterImageCompress.compressAndGetFile(
              imagePath,
              targetPath,
              quality: 40, // Kompresi khusus dokumen
              minWidth: 800,
              minHeight: 800,
              format: CompressFormat.jpeg,
            );

        if (compressedFile != null) {
          final imageBytes = await compressedFile.readAsBytes();
          base64Image = base64Encode(imageBytes);
          try {
            File(targetPath).deleteSync();
          } catch (_) {}
        }
      }

      final payload = {
        "api_token": _Config.apiToken,
        "action": "ajukan_izin",
        "client_id": AppConfig.clientId,
        "id_karyawan": idKaryawan,
        "tipe_izin": tipeIzin,
        "rentang_tanggal": rentangTanggal,
        "alasan": alasan,
        "foto_base64": base64Image,
      };

      var response = await http
          .post(
            Uri.parse(_Config.gasEndpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(_Config.httpTimeout);

      if (response.statusCode == 302 || response.statusCode == 303) {
        final redirectUrl = _extractRedirectUrl(response);
        if (redirectUrl != null) {
          response = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_Config.httpTimeout);
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200)
          return {"success": true, "message": data['message']};
        throw Exception(data['message']);
      }
      throw Exception("Gagal terhubung ke server.");
    } catch (e) {
      d.log('==== ERROR SUBMIT IZIN ==== $e');
      return {
        "success": false,
        "message": e.toString().replaceAll("Exception: ", ""),
      };
    }
  }

  // =================================================================
  // SKENARIO A: DAFTAR WAJAH PERTAMA KALI (ENROLLMENT)
  // =================================================================
  Future<Map<String, dynamic>> daftarWajahMaster(String idKaryawan) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front,
      );
      if (image == null) throw Exception("Pendaftaran wajah dibatalkan.");

      List<double> wajahMaster = await getFaceEmbeddingFromNative(image.path);
      if (wajahMaster.isEmpty) {
        throw Exception(
          "Gagal mengekstrak pola wajah. Pastikan wajah terlihat jelas.",
        );
      }

      final payload = {
        "api_token": _Config.apiToken,
        "action": "register_face",
        "client_id": AppConfig.clientId,
        "id_karyawan": idKaryawan,
        "face_embedding": jsonEncode(wajahMaster),
      };

      var response = await http
          .post(
            Uri.parse(_Config.gasEndpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(_Config.httpTimeout);

      if (response.statusCode == 302 || response.statusCode == 303) {
        final redirectUrl = _extractRedirectUrl(response);
        if (redirectUrl != null) {
          response = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_Config.httpTimeout);
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return {"success": true, "message": "Wajah berhasil didaftarkan!"};
        }
        throw Exception(data['message']);
      }
      throw Exception("Gagal terhubung ke server.");
    } catch (e) {
      d.log('==== ERROR REGISTER FACE ==== $e');
      return {
        "success": false,
        "message": e.toString().replaceAll("Exception: ", ""),
      };
    }
  }

  // =================================================================
  // FUNGSI BANTUAN: AMBIL WAJAH MASTER DARI SERVER
  // =================================================================
  Future<List<double>> getWajahMasterDariServer(String idKaryawan) async {
    try {
      final payload = {
        "api_token": _Config.apiToken,
        "action": "get_face",
        "client_id": AppConfig.clientId,
        "id_karyawan": idKaryawan,
      };

      var response = await http
          .post(
            Uri.parse(_Config.gasEndpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(_Config.httpTimeout);

      if (response.statusCode == 302 || response.statusCode == 303) {
        final redirectUrl = _extractRedirectUrl(response);
        if (redirectUrl != null) {
          response = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_Config.httpTimeout);
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200 && data['message'] != null) {
          List<dynamic> parsedList = jsonDecode(data['message']);
          return parsedList.cast<double>();
        }
      }
      return [];
    } catch (e) {
      d.log('==== ERROR GET FACE ==== $e');
      return [];
    }
  }

  // =================================================================
  // SISA FUNGSI LAINNYA (History, Lokasi, Enroll, dll)
  // =================================================================
  Future<List<dynamic>> getHistory(String idKaryawan) async {
    try {
      final payload = {
        "api_token": _Config.apiToken,
        "action": "get_history",
        "client_id": AppConfig.clientId,
        "id_karyawan": idKaryawan,
      };

      var response = await http
          .post(
            Uri.parse(_Config.gasEndpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(_Config.httpTimeout);

      if (response.statusCode == 302 || response.statusCode == 303) {
        final redirectUrl = _extractRedirectUrl(response);
        if (redirectUrl != null) {
          response = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_Config.httpTimeout);
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) return data['message'] as List<dynamic>;
        throw Exception(data['message']);
      }
      throw Exception("Gagal terhubung ke server.");
    } catch (e) {
      d.log('==== ERROR GET HISTORY ==== $e');
      throw Exception("Gagal mengambil riwayat: $e");
    }
  }

  Future<bool> updateLokasi(double lat, double lng, double radius) async {
    try {
      final payload = {
        "api_token": _Config.apiToken,
        "action": "update_lokasi",
        "client_id": AppConfig.clientId,
        "lat": lat,
        "lng": lng,
        "radius": radius,
      };

      var response = await http
          .post(
            Uri.parse(_Config.gasEndpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(_Config.httpTimeout);

      if (response.statusCode == 302 || response.statusCode == 303) {
        final redirectUrl = _extractRedirectUrl(response);
        if (redirectUrl != null) {
          response = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_Config.httpTimeout);
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['code'] == 200;
      }
      return false;
    } catch (e) {
      d.log('==== ERROR UPDATE LOKASI ==== $e');
      return false;
    }
  }

  // =================================================================
  // FUNGSI BARU: TAMBAH KARYAWAN (KHUSUS ADMIN UMKM)
  // =================================================================
  Future<Map<String, dynamic>> tambahKaryawan({
    required String clientId,
    required String idKaryawanBaru,
    required String namaKaryawanBaru,
    required String divisi,
  }) async {
    try {
      final payload = {
        "api_token": _Config.apiToken,
        "action": "add_karyawan",
        "client_id": clientId,
        "id_karyawan_baru": idKaryawanBaru,
        "nama_karyawan_baru": namaKaryawanBaru,
        "divisi_baru": divisi,
      };

      var response = await http
          .post(
            Uri.parse(_Config.gasEndpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(_Config.httpTimeout);

      if (response.statusCode == 302 || response.statusCode == 303) {
        final redirectUrl = _extractRedirectUrl(response);
        if (redirectUrl != null) {
          response = await http
              .get(Uri.parse(redirectUrl))
              .timeout(_Config.httpTimeout);
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return {"success": true, "message": data['message']};
        }
        throw Exception(data['message']);
      }
      throw Exception("Gagal terhubung ke server.");
    } catch (e) {
      d.log('==== ERROR ADD KARYAWAN ==== $e');
      return {
        "success": false,
        "message": e.toString().replaceAll("Exception: ", ""),
      };
    }
  }

  Future<Map<String, dynamic>> registerKlien({
    required String namaUmkm,
    required double lat,
    required double lng,
    required double radius,
  }) async {
    try {
      final payload = {
        "api_token": _Config.apiToken,
        "action": "register_klien",
        "nama_umkm": namaUmkm,
        "lat": lat,
        "lng": lng,
        "radius": radius,
      };

      var response = await http
          .post(
            Uri.parse(_Config.gasEndpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode == 302 || response.statusCode == 303) {
        final redirectUrl = _extractRedirectUrl(response);
        if (redirectUrl != null) {
          response = await http
              .get(Uri.parse(redirectUrl))
              .timeout(const Duration(seconds: 30));
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return {"success": true, "client_id": data['message']['client_id']};
        }
        throw Exception(data['message'] ?? "Gagal mendaftarkan UMKM");
      }
      throw Exception("Gagal terhubung ke server.");
    } catch (e) {
      d.log('==== ERROR REGISTER KLIEN ==== $e');
      return {
        "success": false,
        "message": e.toString().replaceAll("Exception: ", ""),
      };
    }
  }

  Future<Map<String, dynamic>> enrollDevice(String idKaryawan) async {
    try {
      final androidInfo = await _deviceInfo.androidInfo;
      final deviceId = androidInfo.id;

      final payload = {
        "api_token": _Config.apiToken,
        "action": "enroll_device",
        "client_id": AppConfig.clientId,
        "id_karyawan": idKaryawan,
        "device_id": deviceId,
      };

      var response = await http
          .post(
            Uri.parse(_Config.gasEndpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 302 || response.statusCode == 303) {
        final redirectUrl = _extractRedirectUrl(response);
        if (redirectUrl != null) {
          response = await http
              .get(Uri.parse(redirectUrl))
              .timeout(const Duration(seconds: 15));
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return {"success": true, "message": data['message']};
        }
        throw Exception(data['message']);
      }
      throw Exception("Gagal terhubung ke server.");
    } catch (e) {
      return {
        "success": false,
        "message": e.toString().replaceAll("Exception: ", ""),
      };
    }
  }

  Future<List<double>> getFaceEmbeddingFromNative(String imagePath) async {
    try {
      final result = await platform.invokeMethod('getEmbedding', {
        'imagePath': imagePath,
      });

      if (result == null) return [];

      // Konversi aman: Memaksa semua angka (baik int maupun double) dari Kotlin menjadi double di Dart
      List<double> embedding = (result as List)
          .map((e) => (e as num).toDouble())
          .toList();
      return embedding;
    } catch (e) {
      // Print tegas agar error dari Kotlin terlihat jelas di konsol Anda
      d.log("==== ERROR DARI NATIVE KOTLIN TFLITE ====");
      d.log(e.toString());
      return [];
    }
  }

  // =================================================================
  // FUNGSI BARU: AMBIL REKAP BULANAN (UNTUK EXCEL)
  // =================================================================
  Future<List<dynamic>> getMonthlyReport(
    String clientId,
    String bulanTahun,
  ) async {
    try {
      final payload = {
        "api_token": _Config.apiToken,
        "action": "get_monthly_report",
        "client_id": clientId,
        "bulan_tahun": bulanTahun, // Format: "04-2026"
      };

      var response = await http
          .post(
            Uri.parse(_Config.gasEndpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(
            const Duration(seconds: 30),
          ); // Timeout agak lama karena data banyak

      if (response.statusCode == 302 || response.statusCode == 303) {
        final redirectUrl = _extractRedirectUrl(response);
        if (redirectUrl != null) {
          response = await http
              .get(Uri.parse(redirectUrl))
              .timeout(const Duration(seconds: 30));
        }
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return data['message'] as List<dynamic>;
        }
        throw Exception(data['message']);
      }
      throw Exception("Gagal terhubung ke server.");
    } catch (e) {
      d.log('==== ERROR GET MONTHLY REPORT ==== $e');
      throw Exception("Gagal mengambil data bulanan: $e");
    }
  }

  Future<List<dynamic>> getPendingApprovals(String clientId) async {
    final response = await http.post(
      Uri.parse(_Config.gasEndpoint),
      body: jsonEncode({
        "api_token": _Config.apiToken,
        "action": "get_all_approvals",
        "client_id": clientId,
      }),
    );
    final data = jsonDecode(response.body);
    return data['code'] == 200 ? data['message'] : [];
  }

  Future<bool> updateLeaveStatus(
    String clientId,
    int rowIndex,
    String status,
  ) async {
    final response = await http.post(
      Uri.parse(_Config.gasEndpoint),
      body: jsonEncode({
        "api_token": _Config.apiToken,
        "action": "update_leave_status",
        "client_id": clientId,
        "row_index": rowIndex,
        "new_status": status,
      }),
    );
    return jsonDecode(response.body)['code'] == 200;
  }

  Future<Map<String, dynamic>> resetDeviceID(String targetId) async {
    final response = await http.post(
      Uri.parse(_Config.gasEndpoint),
      body: jsonEncode({
        "api_token": _Config.apiToken,
        "action": "reset_device",
        "client_id": AppConfig.clientId,
        "target_id_karyawan": targetId,
      }),
    );
    return jsonDecode(response.body);
  }

  double hitungKemiripanWajah(List<double> wajah1, List<double> wajah2) {
    if (wajah1.length != wajah2.length) return 999.0;
    double sum = 0.0;
    for (int i = 0; i < wajah1.length; i++) {
      double diff = wajah1[i] - wajah2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }

  String? _extractRedirectUrl(http.Response response) {
    var url = response.headers['location'];
    if (url != null) return url;
    final match = RegExp(r'HREF="([^"]+)"').firstMatch(response.body);
    return match?.group(1)?.replaceAll('&amp;', '&');
  }

  Map<String, dynamic> _parseResponse(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['code'] == 200) {
        return {"success": true, "message": data['message']};
      }
      throw Exception(data['message'] ?? 'Respons tidak valid dari server.');
    } on FormatException {
      if (body.contains("Absen berhasil dicatat")) {
        return {"success": true, "message": "Absen berhasil dicatat."};
      }
      throw Exception("Respons server bukan JSON valid. Cek konfigurasi GAS.");
    }
  }
}
