import 'dart:convert';
import 'dart:developer' as d;
import 'package:hadirin/core/config/app_config.dart';
import 'package:hadirin/core/service/api_client.dart';
import 'package:hadirin/core/models/school_models.dart';
import 'package:hadirin/core/service/cache_service.dart';

class SchoolService extends ApiClient {
  // =================================================================
  // 1. BANNER PENGUMUMAN
  // =================================================================
  Future<List<BannerModel>> getBanners(String clientId,
      {bool forceRefresh = false}) async {
    // 1. Coba baca dari cache
    if (!forceRefresh) {
      final cached = await CacheService.getBanners();
      if (cached != null) {
        return cached.map((e) => BannerModel.fromJson(e)).toList();
      }
    }

    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'get_banners',
      };

      final response = await sendRequest('get_banners', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final List list = data['message'];
          // 2. Simpan ke cache
          await CacheService.setBanners(list);
          return list.map((e) => BannerModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      d.log('==== ERROR GET BANNERS ==== $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addBanner({
    required String clientId,
    required String judul,
    required String fotoBase64,
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'add_banner',
        'judul': judul,
        'foto_base64': fotoBase64,
      };

      final response = await sendRequest('add_banner', payload);
      return parseResponse(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteBanner({
    required String clientId,
    required String idBanner,
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'delete_banner',
        'id_banner': idBanner,
      };

      final response = await sendRequest('delete_banner', payload);
      return parseResponse(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> editBanner({
    required String clientId,
    required String idBanner,
    String? judulBaru,
    String? statusBaru,
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'edit_banner',
        'id_banner': idBanner,
        if (judulBaru != null) 'judul_baru': judulBaru,
        if (statusBaru != null) 'status_baru': statusBaru,
      };

      final response = await sendRequest('edit_banner', payload);
      return parseResponse(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // =================================================================
  // 2. JADWAL & ABSEN KEGIATAN
  // =================================================================
  Future<List<JadwalKegiatanModel>> getJadwalKegiatan(String clientId) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'get_jadwal_kegiatan',
      };

      final response = await sendRequest('get_jadwal_kegiatan', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final List list = data['message'];
          return list.map((e) => JadwalKegiatanModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      d.log('==== ERROR GET JADWAL ==== $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addJadwalKegiatan({
    required String clientId,
    required String namaKegiatan,
    required String tipe,
    required String tanggalWaktu,
    required String deskripsi,
    required String idAdmin,
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'add_jadwal_kegiatan',
        'nama_kegiatan': namaKegiatan,
        'tipe': tipe,
        'tanggal_waktu': tanggalWaktu,
        'deskripsi': deskripsi,
        'id_admin': idAdmin,
      };

      final response = await sendRequest('add_jadwal_kegiatan', payload);
      return parseResponse(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> editJadwalKegiatan({
    required String clientId,
    required String idKegiatan,
    String? namaKegiatan,
    String? tipe,
    String? tanggalWaktu,
    String? deskripsi,
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'edit_jadwal_kegiatan',
        'id_kegiatan': idKegiatan,
        if (namaKegiatan != null) 'nama_kegiatan': namaKegiatan,
        if (tipe != null) 'tipe': tipe,
        if (tanggalWaktu != null) 'tanggal_waktu': tanggalWaktu,
        if (deskripsi != null) 'deskripsi': deskripsi,
      };

      final response = await sendRequest('edit_jadwal_kegiatan', payload);
      return parseResponse(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> absenKegiatan({
    required String clientId,
    required String idKegiatan,
    required String idKaryawan,
    required String statusKehadiran,
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'absen_kegiatan',
        'id_kegiatan': idKegiatan,
        'id_karyawan': idKaryawan,
        'status_kehadiran': statusKehadiran,
      };

      final response = await sendRequest('absen_kegiatan', payload);
      return parseResponse(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  // =================================================================
  // 3. PENGAJIAN GURU
  // =================================================================
  Future<List<String>> getKelompokNgaji(String clientId) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'get_kelompok_ngaji',
      };

      final response = await sendRequest('get_kelompok_ngaji', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          return (data['message'] as List).map((e) => e.toString()).toList();
        }
      }
      return [];
    } catch (e) {
      d.log('==== ERROR GET KELOMPOK ==== $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> addKelompokNgaji({
    required String clientId,
    required String namaKelompok,
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'add_kelompok_ngaji',
        'nama_kelompok': namaKelompok,
      };

      final response = await sendRequest('add_kelompok_ngaji', payload);
      return parseResponse(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<Map<String, dynamic>> submitLaporanNgaji({
    required String clientId,
    required String idGuru,
    required String namaKelompok,
    required String lokasi,
    required String materiKeterangan,
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'submit_laporan_ngaji',
        'id_guru': idGuru,
        'nama_kelompok': namaKelompok,
        'lokasi': lokasi,
        'materi_keterangan': materiKeterangan,
      };

      final response = await sendRequest(
        'submit_laporan_ngaji',
        payload,
        timeout: const Duration(seconds: 45),
      );
      d.log(
        '==== [RESPONSE BODY submit_laporan_ngaji] ==== ${response.statusCode}: ${response.body}',
      );
      return parseResponse(response.body);
    } catch (e) {
      d.log('==== ERROR submitLaporanNgaji ==== $e');
      return {
        'success': false,
        'message': e.toString().replaceAll('Exception: ', ''),
      };
    }
  }

  Future<List<LaporanNgajiModel>> getLaporanNgaji(
    String clientId,
    String idGuru,
  ) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'get_laporan_ngaji',
        'id_guru': idGuru,
      };

      final response = await sendRequest('get_laporan_ngaji', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final List list = data['message'];
          // DEBUG: cetak key dari item pertama
          if (list.isNotEmpty) {
            d.log(
              '==== LAPORAN NGAJI KEYS ==== ${(list.first as Map).keys.toList()}',
            );
            d.log('==== LAPORAN NGAJI FIRST ==== ${list.first}');
          }
          return list.map((e) => LaporanNgajiModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      d.log('==== ERROR GET LAPORAN NGAJI ==== $e');
      return [];
    }
  }

  // =================================================================
  // 4. PENILAIAN AL-QURAN
  // =================================================================
  Future<Map<String, List<dynamic>>> getMasterQuran(String clientId,
      {bool forceRefresh = false}) async {
    // 1. Coba baca dari cache
    if (!forceRefresh) {
      final cached = await CacheService.getMasterQuran();
      if (cached != null) {
        return {
          'siswa': (cached['siswa'] as List)
              .map((e) => SiswaModel.fromJson(e))
              .toList(),
          'materi': (cached['materi'] as List)
              .map((e) => MateriModel.fromJson(e))
              .toList(),
        };
      }
    }

    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'get_master_quran',
      };

      final response = await sendRequest('get_master_quran', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final Map<String, dynamic> msg = data['message'];
          // 2. Simpan ke cache
          await CacheService.setMasterQuran(msg);
          return {
            'siswa': (msg['siswa'] as List)
                .map((e) => SiswaModel.fromJson(e))
                .toList(),
            'materi': (msg['materi'] as List)
                .map((e) => MateriModel.fromJson(e))
                .toList(),
          };
        }
      }
      return {'siswa': [], 'materi': []};
    } catch (e) {
      return {'siswa': [], 'materi': []};
    }
  }

  Future<Map<String, dynamic>> submitNilaiQuran({
    required String clientId,
    required String nis,
    required String idGuru,
    required String idMateri,
    required String halamanAyat,
    required String nilai,
    required String keterangan,
  }) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'submit_nilai_quran',
        'nis': nis,
        'id_guru': idGuru,
        'id_materi': idMateri,
        'halaman_ayat': halamanAyat,
        'nilai': nilai,
        'keterangan': keterangan,
      };

      final response = await sendRequest('submit_nilai_quran', payload);
      return parseResponse(response.body);
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<List<NilaiQuranModel>> getNilaiSiswa(
    String clientId,
    String nis,
  ) async {
    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'get_nilai_siswa',
        'nis': nis,
      };

      final response = await sendRequest('get_nilai_siswa', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final List list = data['message'];
          return list.map((e) => NilaiQuranModel.fromJson(e)).toList();
        }
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  // =================================================================
  // 5. APP SETTINGS
  // =================================================================
  Future<Map<String, dynamic>?> getAppSettings(String clientId,
      {bool forceRefresh = false}) async {
    // 1. Coba baca dari cache
    if (!forceRefresh) {
      final cached = await CacheService.getAppSettings();
      if (cached != null) return cached;
    }

    try {
      final payload = {
        'api_token': AppConfig.apiToken,
        'client_id': clientId,
        'action': 'get_app_settings',
      };

      final response = await sendRequest('get_app_settings', payload);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['code'] == 200) {
          final settings = data['message'] as Map<String, dynamic>;
          // 2. Simpan ke cache
          await CacheService.setAppSettings(settings);
          return settings;
        }
      }
      return null;
    } catch (e) {
      d.log('==== ERROR GET APP SETTINGS ==== $e');
      return null;
    }
  }
}
