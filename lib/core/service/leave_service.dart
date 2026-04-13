import 'dart:convert';
import 'dart:developer' as d;
import 'dart:io';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:hadirin/core/config/app_config.dart';
import 'package:hadirin/core/service/api_client.dart';

/// Tanggung jawab: Pengajuan izin/cuti/sakit oleh karyawan
/// dan persetujuan/penolakan izin oleh admin.
class LeaveService extends ApiClient {
  // =================================================================
  // AJUKAN IZIN / SAKIT / CUTI (dari karyawan)
  // =================================================================
  Future<Map<String, dynamic>> submitIzin({
    required String clientId,
    required String idKaryawan,
    required String tipeIzin,
    required String rentangTanggal,
    required String alasan,
    required bool isAdmin,
    String? imagePath,
  }) async {
    try {
      String base64Image = '';

      // Kompresi lampiran foto/surat dokter jika ada
      if (imagePath != null && imagePath.isNotEmpty) {
        final targetPath = '${imagePath}_compressed_doc.jpg';
        final compressed = await FlutterImageCompress.compressAndGetFile(
          imagePath,
          targetPath,
          quality: 40,
          minWidth: 800,
          minHeight: 800,
          format: CompressFormat.jpeg,
        );

        if (compressed != null) {
          final bytes = await compressed.readAsBytes();
          base64Image = base64Encode(bytes);
          try {
            File(targetPath).deleteSync();
          } catch (_) {}
        }
      }

      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'ajukan_izin',
        'client_id': clientId,
        'id_karyawan': idKaryawan,
        'tipe_izin': tipeIzin,
        'rentang_tanggal': rentangTanggal,
        'alasan': alasan,
        'foto_base64': base64Image,
        'is_admin': isAdmin,
      };

      final response = await sendRequest('ajukan_izin', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return {'success': true, 'message': data['message']};
        }
        throw Exception(data['message']);
      }
      throw Exception('Gagal terhubung ke server.');
    } catch (e) {
      d.log('==== ERROR SUBMIT IZIN ==== $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  // =================================================================
  // AMBIL SEMUA PENGAJUAN YANG MENUNGGU PERSETUJUAN (untuk admin)
  // =================================================================
  Future<List<dynamic>> getPendingApprovals(String clientId) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'get_all_approvals',
        'client_id': clientId,
      };

      final response = await sendRequest('get_all_approvals', payload);
      final data = jsonDecode(response.body);
      return data['code'] == 200 ? data['message'] : [];
    } catch (e) {
      d.log('==== ERROR GET APPROVALS ==== $e');
      return [];
    }
  }

  // =================================================================
  // UPDATE STATUS PENGAJUAN: Disetujui / Ditolak (untuk admin)
  // =================================================================
  Future<bool> updateLeaveStatus(
    String clientId,
    int rowIndex,
    String status,
  ) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'action': 'update_leave_status',
        'client_id': clientId,
        'row_index': rowIndex,
        'new_status': status,
      };

      final response = await sendRequest('update_leave_status', payload);
      return jsonDecode(response.body)['code'] == 200;
    } catch (e) {
      d.log('==== ERROR UPDATE LEAVE ==== $e');
      return false;
    }
  }
}
