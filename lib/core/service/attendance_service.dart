import 'dart:convert';
import 'dart:developer' as d;
import 'dart:io';
import 'package:hadirin/core/config/office_config.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:local_auth/local_auth.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'dart:math';

// ← Pisahkan konstanta agar mudah diubah tanpa menyentuh logika service
import 'package:hadirin/core/config/app_config.dart';

// abstract class _Config {
//   static const gasEndpoint =
//       "https://script.google.com/macros/s/AKfycbyV2KrJddqHizRDdlwgCT-00XdTyIrfZo4kULOccaHk6Y4-tjHQfZdZzVLxxHrQ6G2p/exec";
//   static const apiToken = "SUPER_SECRET_UMKM001_8xZ2";
//   static const httpTimeout = Duration(seconds: 20); // ← sedikit lebih longgar
// }
// Hapus abstract class _Config yang lama, ganti jadi:
abstract class _Config {
  static String get gasEndpoint => AppConfig.gasEndpoint;
  static String get apiToken => AppConfig.apiToken;
  static const httpTimeout = Duration(seconds: 20);
}

class AttendanceService {
  final _auth = LocalAuthentication();
  final _picker = ImagePicker();
  final _deviceInfo = DeviceInfoPlugin();

  Future<Map<String, dynamic>> submitAbsen({
    required String idKaryawan,
    required String namaKaryawan,
    required String tipeAbsen,
  }) async {
    try {
      // 1. Cek & jalankan biometrik
      final canCheck = await _auth.canCheckBiometrics;
      if (!canCheck) throw Exception("Perangkat tidak mendukung biometrik.");

      // ← `biometricOnly` dan `persistAcrossBackgrounding` sudah deprecated

      bool didAuth = await _auth.authenticate(
        localizedReason: 'Pindai sidik jari Anda untuk absen $tipeAbsen',
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
      if (!didAuth) throw Exception("Autentikasi biometrik dibatalkan.");

      // 2. Device ID
      final androidInfo = await _deviceInfo.androidInfo;
      final deviceId = androidInfo.id;

      // 3. Lokasi & deteksi fake GPS
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
      // maka sistem lokal Flutter akan bertabrakan dengan sistem GAS.
      // ── Validasi geofence (lapis 1, sisi Flutter) ──────────────────
      // final jarak = _hitungJarak(
      //   position.latitude,
      //   position.longitude,
      //   OfficeConfig.lat,
      //   OfficeConfig.lng,
      // );

      // if (jarak > OfficeConfig.radiusMeter) {
      //   throw Exception(
      //     "Lokasi Anda terlalu jauh dari kantor "
      //     "(${jarak.toStringAsFixed(0)} m). "
      //     "Maksimal ${OfficeConfig.radiusMeter.toInt()} m.",
      //   );
      // }
      // 4. Selfie
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
        preferredCameraDevice: CameraDevice.front,
        maxWidth: 800,
        maxHeight: 800,
      );
      if (image == null) throw Exception("Foto wajah wajib diambil.");

      // 5. Base64
      final imageBytes = await File(image.path).readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // 6. Payload
      final payload = {
        "api_token": _Config.apiToken,
        "client_id": AppConfig.clientId,
        "client_timestamp": DateTime.now().millisecondsSinceEpoch,
        "id_karyawan": idKaryawan,
        "nama": namaKaryawan,
        "device_id": deviceId,
        "tipe_absen": tipeAbsen,
        "lat_long": "${position.latitude}, ${position.longitude}",
        "is_mock_location": position.isMocked,
        "biometric_passed": true,
        "foto_base64": base64Image,
      };

      // 7. HTTP POST
      d.log('==== REQUEST ==== POST ${_Config.gasEndpoint}');
      var response = await http
          .post(
            Uri.parse(_Config.gasEndpoint),
            headers: {"Content-Type": "application/json"},
            body: jsonEncode(payload),
          )
          .timeout(_Config.httpTimeout);

      d.log('==== RESPONSE ==== STATUS: ${response.statusCode}');
      d.log(utf8.decode(response.bodyBytes, allowMalformed: true));

      // 8. Handle redirect Google (302/303)
      if (response.statusCode == 302 || response.statusCode == 303) {
        final redirectUrl = _extractRedirectUrl(response);
        if (redirectUrl == null) {
          throw Exception("Gagal mengekstrak URL redirect dari Google.");
        }
        response = await http
            .get(Uri.parse(redirectUrl))
            .timeout(_Config.httpTimeout);
      }

      // 9. Parse response
      if (response.statusCode != 200) {
        throw Exception(
          "Gagal terhubung ke server (HTTP ${response.statusCode}).",
        );
      }

      return _parseResponse(response.body);
    } catch (e) {
      d.log('==== ERROR ==== $e');
      return {"success": false, "message": e.toString()};
    }
  }

  // =================================================================
  // FUNGSI BARU: AMBIL RIWAYAT ABSEN KARYAWAN
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
        if (data['code'] == 200) {
          return data['message'] as List<dynamic>; // Array riwayat dari GAS
        } else {
          throw Exception(data['message']);
        }
      }
      throw Exception("Gagal terhubung ke server.");
    } catch (e) {
      d.log('==== ERROR GET HISTORY ==== $e');
      throw Exception("Gagal mengambil riwayat: $e");
    }
  }

  // =================================================================
  // FUNGSI BARU: UPDATE LOKASI KANTOR (Khusus Admin)
  // =================================================================
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
  // FUNGSI BARU: REGISTRASI UMKM BARU (SaaS Admin)
  // =================================================================
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
          .timeout(
            const Duration(seconds: 30),
          ); // Timeout lebih lama karena kloning file GAS butuh waktu

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
        } else {
          throw Exception(data['message'] ?? "Gagal mendaftarkan UMKM");
        }
      }
      throw Exception("Gagal terhubung ke server.");
    } catch (e) {
      d.log('==== ERROR REGISTER KLIEN ==== $e');
      return {"success": false, "message": e.toString()};
    }
  }

  /// Ekstrak URL redirect dari header atau body HTML
  String? _extractRedirectUrl(http.Response response) {
    var url = response.headers['location'];
    if (url != null) return url;

    // Fallback: cari di body HTML
    final match = RegExp(r'HREF="([^"]+)"').firstMatch(response.body);
    return match?.group(1)?.replaceAll('&amp;', '&');
  }

  /// Parse body JSON dan kembalikan result map
  Map<String, dynamic> _parseResponse(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['code'] == 200) {
        return {"success": true, "message": data['message']};
      }
      throw Exception(data['message'] ?? 'Respons tidak valid dari server.');
    } on FormatException {
      // Fallback jika GAS mengembalikan plain text
      if (body.contains("Absen berhasil dicatat")) {
        return {"success": true, "message": "Absen berhasil dicatat."};
      }
      throw Exception("Respons server bukan JSON valid. Cek konfigurasi GAS.");
    }
  }

  /// Hitung jarak dua koordinat GPS dalam meter (Haversine)
  double _hitungJarak(double lat1, double lng1, double lat2, double lng2) {
    const r = 6371000.0; // radius bumi dalam meter
    final dLat = (lat2 - lat1) * pi / 180;
    final dLng = (lng2 - lng1) * pi / 180;
    final a =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1 * pi / 180) *
            cos(lat2 * pi / 180) *
            sin(dLng / 2) *
            sin(dLng / 2);
    return r * 2 * atan2(sqrt(a), sqrt(1 - a));
  }
}
