import 'dart:convert';
import 'dart:developer' as d;
import 'dart:math';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:primkopasindo_labojon/core/config/app_config.dart';
import 'package:primkopasindo_labojon/core/service/api_client.dart';

/// Tanggung jawab: Pendaftaran wajah, pengambilan embedding,
/// verifikasi kemiripan wajah via TFLite native & server.
class FaceService extends ApiClient {
  static const _platform = MethodChannel('com.primkopasindo.labojon/face_recognition');
  final _picker = ImagePicker();

  // =================================================================
  // DAFTARKAN WAJAH MASTER (ENROLLMENT — sekali saat pertama kali)
  // =================================================================
  Future<Map<String, dynamic>> daftarWajahMaster(String idAnggota, String clientId) async {
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
        'id_karyawan': idAnggota,
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
  Future<List<double>> getWajahMasterDariServer(String idAnggota, String clientId) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'get_face',
        'client_id': clientId,
        'id_karyawan': idAnggota,
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
  // HITUNG KEMIRIPAN (COSINE SIMILARITY) ANTARA DUA EMBEDDING
  //
  // Menggunakan Cosine Similarity agar invarian terhadap magnitudo vektor.
  // Nilai 1.0 berarti sangat mirip, -1.0 berarti berlawanan.
  // =================================================================
  double hitungKemiripan(List<double> wajah1, List<double> wajah2) {
    if (wajah1.length != wajah2.length) return 0.0;
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;
    for (int i = 0; i < wajah1.length; i++) {
      dotProduct += wajah1[i] * wajah2[i];
      norm1 += wajah1[i] * wajah1[i];
      norm2 += wajah2[i] * wajah2[i];
    }
    if (norm1 == 0 || norm2 == 0) return 0.0;
    return dotProduct / (sqrt(norm1) * sqrt(norm2));
  }
}
