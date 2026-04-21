class BannerModel {
  final String idBanner;
  final String judul;
  final String urlGambar;
  final String status;

  BannerModel({
    required this.idBanner,
    required this.judul,
    required this.urlGambar,
    this.status = "Aktif",
  });

  factory BannerModel.fromJson(Map<String, dynamic> json) {
    return BannerModel(
      idBanner: json['id_banner'].toString(),
      judul: json['judul'].toString(),
      urlGambar: json['url_gambar'].toString(),
      status: json['status']?.toString() ?? "Aktif",
    );
  }
}

class JadwalKegiatanModel {
  final String idKegiatan;
  final String namaKegiatan;
  final String tipe;
  final String tanggalWaktu;
  final String deskripsi;

  JadwalKegiatanModel({
    required this.idKegiatan,
    required this.namaKegiatan,
    required this.tipe,
    required this.tanggalWaktu,
    required this.deskripsi,
  });

  factory JadwalKegiatanModel.fromJson(Map<String, dynamic> json) {
    return JadwalKegiatanModel(
      idKegiatan: json['id_kegiatan'].toString(),
      namaKegiatan: json['nama_kegiatan'].toString(),
      tipe: json['tipe'].toString(),
      tanggalWaktu: json['tanggal_waktu'].toString(),
      deskripsi: json['deskripsi'].toString(),
    );
  }
}

class LaporanNgajiModel {
  final String idGuru;
  final String namaKelompok;
  final String lokasi;
  final String materiKeterangan;
  final String? tanggal;

  LaporanNgajiModel({
    required this.idGuru,
    required this.namaKelompok,
    required this.lokasi,
    required this.materiKeterangan,
    this.tanggal,
  });

  factory LaporanNgajiModel.fromJson(Map<String, dynamic> json) {
    return LaporanNgajiModel(
      idGuru: (json['id_guru'] ?? json['ID_Guru'] ?? '').toString(),
      namaKelompok: (json['kelompok'] ?? json['nama_kelompok'] ?? json['Nama_Kelompok'] ?? '').toString(),
      lokasi: (json['lokasi'] ?? json['Lokasi'] ?? '').toString(),
      materiKeterangan: (json['materi'] ?? json['materi_keterangan'] ?? json['Materi_Keterangan'] ?? '').toString(),
      tanggal: (json['waktu'] ?? json['tanggal'] ?? json['Timestamp'])?.toString(),
    );
  }
}

class SiswaModel {
  final String nis;
  final String nama;

  SiswaModel({required this.nis, required this.nama});

  factory SiswaModel.fromJson(Map<String, dynamic> json) {
    return SiswaModel(
      nis: json['NIS'].toString(),
      nama: json['Nama'].toString(),
    );
  }
}

class MateriModel {
  final String id;
  final String tipe;
  final String nama;

  MateriModel({required this.id, required this.tipe, required this.nama});

  factory MateriModel.fromJson(Map<String, dynamic> json) {
    return MateriModel(
      id: json['ID'].toString(),
      tipe: json['Tipe'].toString(),
      nama: json['Nama'].toString(),
    );
  }
}

class NilaiQuranModel {
  final String nis;
  final String idGuru;
  final String idMateri;
  final String halamanAyat;
  final String nilai;
  final String keterangan;
  final String? tanggal;

  NilaiQuranModel({
    required this.nis,
    required this.idGuru,
    required this.idMateri,
    required this.halamanAyat,
    required this.nilai,
    required this.keterangan,
    this.tanggal,
  });

  factory NilaiQuranModel.fromJson(Map<String, dynamic> json) {
    return NilaiQuranModel(
      nis: json['nis'].toString(),
      idGuru: json['id_guru']?.toString() ?? '',
      idMateri: json['id_materi']?.toString() ?? '',
      halamanAyat: json['halaman_ayat']?.toString() ?? '',
      nilai: json['nilai']?.toString() ?? '',
      keterangan: json['keterangan']?.toString() ?? '',
      tanggal: json['tanggal']?.toString(),
    );
  }
}
