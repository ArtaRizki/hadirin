import 'dart:convert';
import 'dart:developer' as d;
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:hadirin/core/config/app_config.dart';
import 'package:hadirin/core/service/api_client.dart';

/// Tanggung jawab: Pendaftaran wajah, pengambilan embedding,
/// verifikasi kemiripan wajah via TFLite native & server.
class FaceService extends ApiClient {
  static const _platform = MethodChannel('com.mobile.hadirin/face_recognition');
  final _picker = ImagePicker();

  // =================================================================
  // DAFTARKAN WAJAH MASTER (ENROLLMENT — sekali saat pertama kali)
  // =================================================================
  Future<Map<String, dynamic>> daftarWajahMaster(String idKaryawan, String clientId) async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        preferredCameraDevice: CameraDevice.front,
      );
      if (image == null) throw Exception('Pendaftaran wajah dibatalkan.');

      final embedding = await getEmbeddingFromNative(_platform, image.path);
      if (embedding.isEmpty) {
        throw Exception(
          'Gagal mengekstrak pola wajah. Pastikan wajah terlihat jelas.',
        );
      }

      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'register_face',
        'client_id': clientId,
        'id_karyawan': idKaryawan,
        'face_embedding': jsonEncode(embedding),
      };

      final response = await sendRequest('register_face', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return {'success': true, 'message': 'Wajah berhasil didaftarkan!'};
        }
        throw Exception(data['message']);
      }
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      d.log('==== ERROR REGISTER FACE ==== $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // =================================================================
  // AMBIL EMBEDDING WAJAH MASTER DARI SERVER
  // =================================================================
  Future<List<double>> getWajahMasterDariServer(String idKaryawan, String clientId) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'get_face',
        'client_id': clientId,
        'id_karyawan': idKaryawan,
      };

      final response = await sendRequest('get_face', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200 && data['message'] != null) {
          final parsed = jsonDecode(data['message']) as List<dynamic>;
          return parsed.cast<double>();
        }
      }
      return [];
    } catch (e) {
      d.log('==== ERROR GET FACE ==== $e');
      return [];
    }
  }

  // =================================================================
  // EKSTRAK EMBEDDING DARI GAMBAR VIA NATIVE KOTLIN (TFLite)
  // Dipanggil oleh AttendanceService saat absen — method channel ke Android
  // =================================================================
  Future<List<double>> getEmbeddingFromNative(
    MethodChannel platform,
    String imagePath,
  ) async {
    try {
      final result = await platform.invokeMethod('getEmbedding', {
        'imagePath': imagePath,
      });
      if (result == null) return [];
      return (result as List).map((e) => (e as num).toDouble()).toList();
    } catch (e) {
      d.log('==== ERROR DARI NATIVE KOTLIN TFLITE ====\n$e');
      return [];
    }
  }

  // =================================================================
  // HITUNG JARAK EUCLIDEAN ANTARA DUA EMBEDDING
  //
  // Threshold: 1.0 (dari benchmark MobileFaceNet pada dataset internal).
  // < 1.0 = wajah sama, > 1.0 = wajah berbeda.
  // Jangan ubah nilai ini tanpa pengujian ulang.
  // =================================================================
  double hitungKemiripan(List<double> wajah1, List<double> wajah2) {
    if (wajah1.length != wajah2.length) return 999.0;
    double sum = 0.0;
    for (int i = 0; i < wajah1.length; i++) {
      final diff = wajah1[i] - wajah2[i];
      sum += diff * diff;
    }
    return sqrt(sum);
  }
}
