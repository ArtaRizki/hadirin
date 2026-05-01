// =============================================================================
// BACKEND HADIRIN - v3.7 (Unified - Dynamic Groups & Time Fix)
// =============================================================================
const MASTER_API_TOKEN = "smpit-palu";
const MASTER_REGISTRY_ID = "1hTh660vp0AbPn8D37Yg7XE-5HBRDXYA2xSJErORfZ3w";
const ID_TEMPLATE_SS = "1JmD2p1p_gNXUXDiXPmj4REy9vafSsNmo4J1MoNwfaSA"; //done
const ID_MASTER_FOLDER = "1k-MxGPlAUPCFra-2nC3i3g03JvZG5KNr"; //done
const SUPER_ADMIN_PASSWORD = "HADIRIN_MASTER_2026_AHHH";

// =============================================================================
// 1. ROUTING & UI (WEB DASHBOARD)
// =============================================================================

function doGet(e) {
  var template = HtmlService.createTemplateFromFile("Index");
  return template
    .evaluate()
    .setTitle("Hadir.in Dashboard v3.7")
    .addMetaTag("viewport", "width=device-width, initial-scale=1")
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

function loginWeb(clientId, id, pin) {
  try {
    if (id.toUpperCase() === "ADMIN" && pin === SUPER_ADMIN_PASSWORD) {
      return {
        success: true,
        user: {
          id: "ADMIN",
          nama: "Super Admin",
          role: "superAdmin",
          clientId: clientId || "GLOBAL",
        },
      };
    }
    var allConfigs = getSemuaConfig();
    var lookupId = String(clientId || "")
      .trim()
      .toUpperCase();
    var config = allConfigs[lookupId];
    if (!config)
      return { success: false, message: "Kode Instansi tidak terdaftar." };

    var ss = SpreadsheetApp.openById(config.spreadsheetId);
    var data = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
    for (var i = 1; i < data.length; i++) {
      var rowId = String(data[i][0]).trim().toLowerCase();
      if (rowId === id.trim().toLowerCase()) {
        return {
          success: true,
          user: {
            id: rowId,
            nama: String(data[i][1]),
            role: String(data[i][2] || "Anggota"),
            clientId: clientId,
            faceWeb: data[i][4] || "",
          },
        };
      }
    }
    return { success: false, message: "ID Anggota tidak ditemukan." };
  } catch (e) {
    return { success: false, message: "Error: " + e.toString() };
  }
}

function registerFaceWeb(clientId, id, descriptor) {
  try {
    var config = getSemuaConfig()[clientId];
    var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
      "Master_Karyawan",
    );
    var data = sheet.getDataRange().getValues();
    for (var i = 1; i < data.length; i++) {
      if (String(data[i][0]).trim().toLowerCase() === id.trim().toLowerCase()) {
        sheet.getRange(i + 1, 5).setValue(descriptor);
        return { success: true, message: "Wajah berhasil didaftarkan!" };
      }
    }
    return { success: false, message: "User tidak ditemukan." };
  } catch (e) {
    return { success: false, message: e.toString() };
  }
}

function submitAbsenWeb(payload) {
  try {
    var result = handleAbsensi(payload);
    return JSON.parse(result.getContent());
  } catch (e) {
    return { code: 500, status: "error", message: e.toString() };
  }
}

function getDashboardStats(clientId, id) {
  try {
    var config = getSemuaConfig()[clientId.toUpperCase()];
    if (!config)
      return {
        present: 0,
        leave: 0,
        late: 0,
        trendLabels: [],
        trendValues: [],
      };
    var ss = SpreadsheetApp.openById(config.spreadsheetId);
    var data = ss.getSheetByName("Log_Absensi").getDataRange().getValues();
    var today = new Date();
    today.setHours(0, 0, 0, 0);
    var stats = {
      present: 0,
      leave: 0,
      late: 0,
      trendLabels: [],
      trendValues: [],
    };

    for (var i = 1; i < data.length; i++) {
      if (!data[i][0]) continue;
      var rDate = new Date(data[i][0]);
      rDate.setHours(0, 0, 0, 0);
      if (rDate.getTime() === today.getTime()) {
        if (data[i][6] === "Tepat Waktu") stats.present++;
        if (data[i][6] === "Terlambat") {
          stats.present++;
          stats.late++;
        }
        if (["Izin", "Sakit", "Cuti"].indexOf(data[i][6]) !== -1) stats.leave++;
      }
    }
    for (var d = 6; d >= 0; d--) {
      var date = new Date();
      date.setDate(date.getDate() - d);
      date.setHours(0, 0, 0, 0);
      stats.trendLabels.push(Utilities.formatDate(date, "GMT+7", "dd MMM"));
      var count = 0;
      for (var j = 1; j < data.length; j++) {
        if (!data[j][0]) continue;
        var rD = new Date(data[j][0]);
        rD.setHours(0, 0, 0, 0);
        if (
          rD.getTime() === date.getTime() &&
          (data[j][6] === "Tepat Waktu" || data[j][6] === "Terlambat")
        )
          count++;
      }
      stats.trendValues.push(count);
    }
    return stats;
  } catch (e) {
    return { present: 0, leave: 0, late: 0, trendLabels: [], trendValues: [] };
  }
}

function getAttendanceHistory(clientId, id) {
  try {
    var config = getSemuaConfig()[clientId.toUpperCase()];
    var data = SpreadsheetApp.openById(config.spreadsheetId)
      .getSheetByName("Log_Absensi")
      .getDataRange()
      .getValues();
    var history = [];
    var searchId = id.trim().toLowerCase();
    for (var i = data.length - 1; i >= 1; i--) {
      if (
        String(data[i][1]).toLowerCase() === searchId ||
        searchId === "admin"
      ) {
        history.push({
          waktu: data[i][0],
          tipe: data[i][2],
          status: data[i][6],
        });
        if (history.length >= 50) break;
      }
    }
    return history;
  } catch (e) {
    return [];
  }
}

// =============================================================================
// 2. MOBILE API (doPost)
// =============================================================================

function doPost(e) {
  var lock = LockService.getScriptLock();
  if (!lock.tryLock(60000)) return responseJSON(429, "error", "Server Busy.");

  try {
    var payload = JSON.parse(e.postData.contents);
    if (payload.api_token !== MASTER_API_TOKEN)
      return responseJSON(401, "error", "Unauthorized.");

    const skipCheck = ["register_klien", "verify_super_admin"];
    if (skipCheck.indexOf(payload.action) === -1) {
      var config = getSemuaConfig()[payload.client_id];
      if (!config || !config.spreadsheetId)
        return responseJSON(404, "error", "Kode Instansi tidak ditemukan.");
    }

    switch (payload.action) {
      // --- CORE ABSENSI ---
      case "absen":
        return handleAbsensi(payload);
      case "register_klien":
        return handleRegisterInstansi(payload);
      case "get_history":
        return handleGetHistory(payload);
      case "get_office_config":
        return handleGetOfficeConfig(payload);
      case "update_lokasi":
        return handleUpdateLokasi(payload);
      case "update_jam_kerja":
        return handleUpdateJamKerja(payload);
      case "enroll_device":
        return handleEnrollDevice(payload);
      case "register_face":
        return handleRegisterFace(payload);
      case "get_face":
        return handleGetFace(payload);
      case "add_karyawan":
        return handleAddAnggota(payload);
      case "delete_karyawan":
        return handleDeleteKaryawan(payload);
      case "ajukan_izin":
        return handleAjukanIzin(payload);
      case "get_all_approvals":
        return responseJSON(200, "success", handleGetAllApprovals(payload));
      case "update_leave_status":
        return responseJSON(200, "success", handleUpdateLeaveStatus(payload));
      case "reset_device":
        return responseJSON(200, "success", handleResetDevice(payload));
      case "get_all_karyawan":
        return responseJSON(200, "success", handleGetAllAnggota(payload));
      case "cek_status_hari_ini":
        return handleCekStatusHariIni(payload);
      case "verify_super_admin":
        return handleVerifySuperAdmin(payload);
      case "get_leave_history":
        return handleGetLeaveHistory(payload);
      case "get_monthly_report":
        return handleGetMonthlyReport(payload);
      case "update_karyawan":
        return responseJSON(200, "success", handleUpdateAnggota(payload));

      // --- JADWAL KEGIATAN & RAPAT ---
      case "get_jadwal_kegiatan":
        return handleGetJadwalKegiatan(payload);
      case "add_jadwal_kegiatan":
        return handleAddJadwalKegiatan(payload);
      case "edit_jadwal_kegiatan":
        return handleEditJadwalKegiatan(payload);
      case "absen_kegiatan":
        return handleAbsenKegiatan(payload);

      // --- PENGAJIAN GURU (DINAMIS) ---
      case "get_kelompok_ngaji":
        return handleGetKelompokNgaji(payload);
      case "add_kelompok_ngaji":
        return handleAddKelompokNgaji(payload);
      case "submit_laporan_ngaji":
        return handleSubmitLaporanNgaji(payload);
      case "get_laporan_ngaji":
        return handleGetLaporanNgaji(payload);

      // --- BANNER PENGUMUMAN ---
      case "get_banners":
        return handleGetBanners(payload);
      case "add_banner":
        return handleAddBanner(payload);
      case "delete_banner":
        return handleDeleteBanner(payload);
      case "edit_banner":
        return handleEditBanner(payload);

      // --- PENILAIAN AL-QURAN ---
      case "get_master_quran":
        return handleGetMasterQuran(payload);
      case "submit_nilai_quran":
        return handleSubmitNilaiQuran(payload);
      case "get_nilai_siswa":
        return handleGetNilaiSiswa(payload);

      case "get_app_settings":
        return handleGetAppSettings(payload);

      // --- MASTER JABATAN ---
      case "get_jabatan":
        return handleGetJabatan(payload);
      case "add_jabatan":
        return handleAddJabatan(payload);
      case "delete_jabatan":
        return handleDeleteJabatan(payload);

      // --- ABSENSI BRIEFING ---
      case "absen_briefing":
        return handleAbsenBriefing(payload);
      case "get_briefing":
        return handleGetBriefing(payload);

      // --- FEEDBACK ANONIM ---
      case "submit_feedback":
        return handleSubmitFeedback(payload);
      case "get_feedback":
        return handleGetFeedback(payload);

      // --- REKAP EXCEL (BRIEFING, PENGAJIAN, KEGIATAN) ---
      case "get_briefing_report":
        return handleGetBriefingReport(payload);
      case "get_pengajian_report":
        return handleGetPengajianReport(payload);
      case "get_kegiatan_report":
        return handleGetKegiatanReport(payload);

      // --- AYAT PILIHAN ---
      case "get_ayat_pilihan":
        return handleGetAyatPilihan(payload);
      case "update_ayat_pilihan":
        return handleUpdateAyatPilihan(payload);

      // --- STATISTIK ENHANCED ---
      case "get_enhanced_stats":
        return handleGetEnhancedStats(payload);
      case "get_employee_stats":
        return handleGetEmployeeStats(payload);

      // --- FOTO PROFIL ---
      case "upload_profile_photo":
        return handleUploadProfilePhoto(payload);

      default:
        return responseJSON(400, "error", "Action Unknown.");
    }
  } catch (err) {
    return responseJSON(500, "error", err.message);
  } finally {
    lock.releaseLock();
  }
}

// =============================================================================
// HANDLERS PENGAJIAN GURU (DINAMIS)
// =============================================================================

function handleGetKelompokNgaji(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("Master_Kelompok_Ngaji");
  if (!sheet) {
    sheet = ss.insertSheet("Master_Kelompok_Ngaji");
    sheet.appendRow(["Nama Kelompok"]);
    return responseJSON(200, "success", []);
  }
  var data = sheet.getDataRange().getValues();
  var results = [];
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] !== "") results.push(data[i][0]);
  }
  return responseJSON(200, "success", results);
}

function handleAddKelompokNgaji(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("Master_Kelompok_Ngaji");
  if (!sheet) {
    sheet = ss.insertSheet("Master_Kelompok_Ngaji");
    sheet.appendRow(["Nama Kelompok"]);
  }
  sheet.appendRow([payload.nama_kelompok]);
  return responseJSON(200, "success", "Kelompok berhasil ditambahkan.");
}

function handleSubmitLaporanNgaji(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Log_Ngaji_Guru",
  );
  sheet.appendRow([
    Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"),
    payload.id_guru,
    payload.nama_kelompok,
    payload.lokasi,
    payload.materi_keterangan,
  ]);
  return responseJSON(200, "success", "Laporan pengajian tersimpan.");
}

function handleGetLaporanNgaji(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Log_Ngaji_Guru")
    .getDataRange()
    .getDisplayValues();
  var results = [];
  for (var i = 1; i < data.length; i++) {
    if (
      payload.id_guru === "SEMUA" ||
      String(data[i][1]) === String(payload.id_guru)
    ) {
      results.push({
        waktu: data[i][0],
        id_guru: data[i][1],
        kelompok: data[i][2],
        lokasi: data[i][3],
        materi: data[i][4],
      });
    }
  }
  return responseJSON(200, "success", results.reverse());
}

// =============================================================================
// HANDLERS JADWAL & KEGIATAN (FIX JAM GESER)
// =============================================================================

function handleGetJadwalKegiatan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Jadwal_Kegiatan")
    .getDataRange()
    .getDisplayValues();
  var results = [];
  for (var i = 1; i < data.length; i++) {
    results.push({
      id_kegiatan: data[i][0],
      nama_kegiatan: data[i][1],
      tipe: data[i][2],
      tanggal_waktu: data[i][3],
      deskripsi: data[i][4],
    });
  }
  return responseJSON(200, "success", results.reverse());
}

function handleAddJadwalKegiatan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Jadwal_Kegiatan",
  );
  sheet.appendRow([
    "KEG-" + new Date().getTime(),
    payload.nama_kegiatan,
    payload.tipe,
    payload.tanggal_waktu,
    payload.deskripsi,
    payload.id_admin,
  ]);
  return responseJSON(200, "success", "Jadwal berhasil ditambahkan.");
}

function handleEditJadwalKegiatan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Jadwal_Kegiatan",
  );
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_kegiatan)) {
      if (payload.nama_kegiatan)
        sheet.getRange(i + 1, 2).setValue(payload.nama_kegiatan);
      if (payload.tipe) sheet.getRange(i + 1, 3).setValue(payload.tipe);
      if (payload.tanggal_waktu)
        sheet.getRange(i + 1, 4).setValue(payload.tanggal_waktu);
      if (payload.deskripsi)
        sheet.getRange(i + 1, 5).setValue(payload.deskripsi);
      return responseJSON(200, "success", "Berhasil.");
    }
  }
  return responseJSON(404, "error", "Tidak ditemukan.");
}

function handleAbsenKegiatan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);

  // Perbaikan nama sheet menjadi "Absen_Kegiatan"
  var sheet = ss.getSheetByName("Absen_Kegiatan");

  if (!sheet) {
    return responseJSON(
      404,
      "error",
      "Sheet Absen_Kegiatan tidak ditemukan di database.",
    );
  }

  sheet.appendRow([
    Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"),
    payload.id_kegiatan,
    payload.id_karyawan,
    // Mengambil status_kehadiran dari payload mobile
    payload.status_kehadiran || payload.status || "Hadir",
  ]);

  return responseJSON(200, "success", "Absen kegiatan tersimpan.");
}

// =============================================================================
// CORE & UTILS (ABSENSI, FACE, DEVICE, DLL)
// =============================================================================

function handleAbsensi(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var status =
    parseInt(Utilities.formatDate(new Date(), "GMT+7", "HH")) >=
      config.batasJam && payload.tipe_absen === "Masuk"
      ? "Terlambat"
      : "Tepat Waktu";
  var fotoUrl = "No Photo";
  if (payload.foto_base64 && payload.foto_base64.length > 0) {
    try {
      var folder = DriveApp.getFolderById(config.folderDriveId);
      var fileName =
        "Absen_" +
        payload.id_karyawan +
        "_" +
        Utilities.formatDate(new Date(), "GMT+7", "yyyyMMdd_HHmmss") +
        ".jpg";
      var blob = Utilities.newBlob(
        Utilities.base64Decode(payload.foto_base64),
        "image/jpeg",
        fileName,
      );
      var file = folder.createFile(blob);
      fotoUrl = file.getUrl();
    } catch (e) {
      fotoUrl = "Error GDrive: " + e.message;
    }
  }
  ss.getSheetByName("Log_Absensi").appendRow([
    Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"),
    payload.id_karyawan,
    payload.tipe_absen,
    payload.lat_long,
    fotoUrl,
    "Valid",
    status,
  ]);
  return responseJSON(200, "success", "Berhasil.");
}

function handleAjukanIzin(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Log_Absensi",
  );
  var fotoUrl = "";
  if (payload.foto_base64 && payload.foto_base64.length > 0) {
    try {
      var folder = DriveApp.getFolderById(config.folderDriveId);
      var fileName =
        "Lampiran_" +
        payload.id_karyawan +
        "_" +
        Utilities.formatDate(new Date(), "GMT+7", "yyyyMMdd_HHmmss") +
        ".jpg";
      var blob = Utilities.newBlob(
        Utilities.base64Decode(payload.foto_base64),
        "image/jpeg",
        fileName,
      );
      fotoUrl = folder.createFile(blob).getUrl();
    } catch (e) {
      fotoUrl = "ERROR GDrive: " + e.message;
    }
  }

  // MENYIMPAN GURU PENGGANTI KE KOLOM H
  sheet.appendRow([
    Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"),
    payload.id_karyawan,
    payload.tipe_izin,
    payload.rentang_tanggal,
    fotoUrl,
    payload.alasan,
    payload.is_admin ? "Disetujui" : "Menunggu Approval",
    payload.guru_pengganti || "-",
  ]);
  return responseJSON(200, "success", "Sent");
}

function handleGetOfficeConfig(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Config_Kantor")
    .getRange("A2:G2")
    .getValues();
  return responseJSON(200, "success", {
    nama: data[0][0],
    lat: data[0][1],
    lng: data[0][2],
    radius: data[0][3] || config.radius,
    jam_masuk_mulai: formatTime(data[0][4], "04:00"),
    batas_jam_masuk: formatTime(data[0][5], "07:00"),
    jam_pulang_mulai: formatTime(data[0][6], "13:00"),
  });
}

function getSemuaConfig() {
  var cache = CacheService.getScriptCache();
  var cachedConfig = cache.get("MASTER_CONFIG");

  // 1. Jika data ada di memori, kembalikan langsung (Sangat Cepat!)
  if (cachedConfig) {
    return JSON.parse(cachedConfig);
  }

  // 2. Jika tidak ada di memori, baca dari Spreadsheet lalu simpan ke Cache
  try {
    var rows = SpreadsheetApp.openById(MASTER_REGISTRY_ID)
      .getSheetByName("Klien")
      .getDataRange()
      .getValues();
    var result = {};
    for (var i = 1; i < rows.length; i++) {
      result[rows[i][0]] = {
        spreadsheetId: rows[i][2],
        folderDriveId: rows[i][3],
        batasJam: rows[i][4],
        radius: rows[i][5],
      };
    }

    // Simpan ke cache selama 6 jam (21600 detik)
    cache.put("MASTER_CONFIG", JSON.stringify(result), 21600);
    return result;
  } catch (e) {
    return {};
  }
}

function responseJSON(code, status, message) {
  return ContentService.createTextOutput(
    JSON.stringify({ code: code, status: status, message: message }),
  ).setMimeType(ContentService.MimeType.JSON);
}
function formatTime(val, def) {
  if (!val) return def;
  var s = String(val);
  return s.indexOf(":") !== -1 ? s : (parseInt(s) < 10 ? "0" + s : s) + ":00";
}

function handleEnrollDevice(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var data = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
  var adminPhone = data[1][5] || "";

  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_karyawan)) {
      if (data[i][3] === "" || data[i][3] === payload.device_id) {
        if (data[i][3] === "")
          ss.getSheetByName("Master_Karyawan")
            .getRange(i + 1, 4)
            .setValue(payload.device_id);

        // MENGAMBIL ROLE AKSES DARI KOLOM G (Index 6)
        var roleAkses =
          data[i][6] && data[i][6] !== "" ? data[i][6] : "Anggota";
        var profilePhoto = data[i][7] || "";

        return responseJSON(200, "success", {
          nama_karyawan: data[i][1],
          client_id: payload.client_id,
          divisi: data[i][2],
          no_hp: data[i][5] || "",
          admin_phone: adminPhone,
          role_akses: roleAkses, // Dikirim ke Mobile
          profile_photo: profilePhoto,
        });
      }
    }
  }
  return responseJSON(
    404,
    "error",
    "User tidak ditemukan atau Device ID berbeda.",
  );
}

function handleGetBanners(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Banner_Pengumuman")
    .getDataRange()
    .getValues();
  var results = [];
  for (var i = 1; i < data.length; i++) {
    if (data[i][3] === "Aktif") {
      results.push({
        id_banner: data[i][0],
        judul: data[i][1],
        url_gambar: data[i][2],
      });
    }
  }
  return responseJSON(200, "success", results);
}

function handleGetMasterQuran(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);

  var siswaData = ss.getSheetByName("Master_Siswa").getDataRange().getValues();
  var listSiswa = [];
  for (var i = 1; i < siswaData.length; i++) {
    listSiswa.push({
      nis: siswaData[i][0],
      nama: siswaData[i][1],
      kelas: siswaData[i][2],
    });
  }

  var materiData = ss
    .getSheetByName("Master_Materi_Quran")
    .getDataRange()
    .getValues();
  var listMateri = [];
  for (var j = 1; j < materiData.length; j++) {
    listMateri.push({
      id_materi: materiData[j][0],
      tipe: materiData[j][1],
      nama_materi: materiData[j][2],
    });
  }

  return responseJSON(200, "success", { siswa: listSiswa, materi: listMateri });
}

function handleSubmitNilaiQuran(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Log_Nilai_Quran",
  );
  sheet.appendRow([
    Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"),
    payload.nis,
    payload.id_guru,
    payload.id_materi,
    payload.halaman_ayat,
    payload.nilai,
    payload.keterangan,
  ]);
  return responseJSON(200, "success", "Nilai berhasil disimpan.");
}

function handleRegisterInstansi(payload) {
  var sheetRegistry =
    SpreadsheetApp.openById(MASTER_REGISTRY_ID).getSheetByName("Klien");
  var newInstansiId = "INST-" + Math.floor(Math.random() * 900000 + 100000);
  var ssId = DriveApp.getFileById(ID_TEMPLATE_SS)
    .makeCopy("DB - " + payload.nama_umkm)
    .getId();
  var folderId = DriveApp.getFolderById(ID_MASTER_FOLDER)
    .createFolder("Assets - " + payload.nama_umkm)
    .getId();
  var ss = SpreadsheetApp.openById(ssId);
  ss.getSheetByName("Config_Kantor")
    .getRange("A2:D2")
    .setValues([
      [payload.nama_umkm, payload.lat, payload.lng, payload.radius || 100],
    ]);
  ss.getSheetByName("Master_Karyawan").appendRow([
    newInstansiId,
    "Admin " + payload.nama_umkm,
    "ADMIN",
    "",
    "",
    payload.admin_phone || "",
  ]);
  sheetRegistry.appendRow([
    newInstansiId,
    payload.nama_umkm,
    ssId,
    folderId,
    payload.batas_jam || 8,
    payload.radius || 100,
  ]);
  CacheService.getScriptCache().remove("MASTER_CONFIG");
  return responseJSON(200, "success", { client_id: newInstansiId });
}

function handleVerifySuperAdmin(payload) {
  return payload.password === SUPER_ADMIN_PASSWORD
    ? responseJSON(200, "success", "OK")
    : responseJSON(401, "error", "Fail");
}

function handleGetAllAnggota(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Master_Karyawan")
    .getDataRange()
    .getValues();
  var results = [];
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] !== "")
      results.push({
        id: String(data[i][0]),
        nama: String(data[i][1]),
        bagian: String(data[i][2] || "-"),
        sudah_enroll: data[i][3] !== "",
        wajah_terdaftar: data[i][4] !== "",
        no_hp: String(data[i][5] || ""),
        id_shift_default: String(data[i][6] || ""),
      });
  }
  return results;
}

function handleAddAnggota(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Master_Karyawan",
  );
  sheet.appendRow([
    payload.id_karyawan_baru,
    payload.nama_karyawan_baru,
    payload.divisi_baru || "-",
    "",
    "",
    payload.no_hp || "",
    payload.id_shift || "Anggota",
  ]);
  return responseJSON(200, "success", "Anggota Ditambahkan.");
}

function handleDeleteKaryawan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Master_Karyawan",
  );
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.target_id)) {
      sheet.deleteRow(i + 1);
      return responseJSON(200, "success", "Berhasil dihapus.");
    }
  }
  return responseJSON(404, "error", "Tidak ditemukan.");
}

function handleGetAllApprovals(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var logs = ss.getSheetByName("Log_Absensi").getDataRange().getValues();
  var employees = ss
    .getSheetByName("Master_Karyawan")
    .getDataRange()
    .getValues();
  var hpMap = {};
  var namaMap = {};
  for (var j = 1; j < employees.length; j++) {
    hpMap[String(employees[j][0])] = String(employees[j][5] || "");
    namaMap[String(employees[j][0])] = String(employees[j][1]);
  }

  var results = [];
  for (var i = logs.length - 1; i >= 1; i--) {
    if (logs[i][6] === "Menunggu Approval") {
      var idKry = String(logs[i][1]);
      results.push({
        waktu_pengajuan: logs[i][0],
        id_karyawan: idKry,
        nama: namaMap[idKry] || "Unknown",
        no_hp: hpMap[idKry] || "",
        tipe: logs[i][2],
        rentang: logs[i][3],
        foto: logs[i][4],
        alasan: logs[i][5],
        guru_pengganti: logs[i][7] || "-", // Menampilkan Guru Pengganti
        row_index: i + 1,
      });
    }
  }
  return results;
}

function handleUpdateLeaveStatus(payload) {
  var config = getSemuaConfig()[payload.client_id];
  SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Log_Absensi")
    .getRange(payload.row_index, 7)
    .setValue(payload.new_status);
  return true;
}

function handleResetDevice(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Master_Karyawan",
  );
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.target_id_karyawan)) {
      sheet.getRange(i + 1, 4).setValue("");
      return true;
    }
  }
  return false;
}

function handleUpdateJamKerja(payload) {
  var config = getSemuaConfig()[payload.client_id];
  SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Config_Kantor")
    .getRange("E2:G2")
    .setValues([
      [
        payload.jam_masuk_mulai,
        payload.batas_jam_masuk,
        payload.jam_pulang_mulai,
      ],
    ]);
  return responseJSON(200, "success", "Jam kerja diperbarui.");
}

function handleUpdateLokasi(payload) {
  var config = getSemuaConfig()[payload.client_id];
  SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Config_Kantor")
    .getRange("B2:D2")
    .setValues([[payload.lat, payload.lng, payload.radius]]);
  var sheetRegistry =
    SpreadsheetApp.openById(MASTER_REGISTRY_ID).getSheetByName("Klien");
  var dataM = sheetRegistry.getDataRange().getValues();
  for (var i = 1; i < dataM.length; i++) {
    if (dataM[i][0] === payload.client_id) {
      sheetRegistry.getRange(i + 1, 6).setValue(payload.radius);
      break;
    }
  }
  return responseJSON(200, "success", "Lokasi diperbarui.");
}

function handleRegisterFace(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Master_Karyawan",
  );
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_karyawan)) {
      sheet
        .getRange(i + 1, 5)
        .setValue(payload.face_descriptor || payload.face_embedding);
      return responseJSON(200, "success", "Wajah terdaftar.");
    }
  }
  return responseJSON(404, "error", "User not found.");
}

function handleGetFace(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Master_Karyawan")
    .getDataRange()
    .getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_karyawan)) {
      return responseJSON(200, "success", data[i][4] || "");
    }
  }
  return responseJSON(404, "error", "Not found.");
}

function handleCekStatusHariIni(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var logs = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Log_Absensi")
    .getDataRange()
    .getValues();
  var today = Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd");
  for (var i = logs.length - 1; i >= 1; i--) {
    var rowDate = Utilities.formatDate(
      new Date(logs[i][0]),
      "GMT+7",
      "yyyy-MM-dd",
    );
    if (
      String(logs[i][1]) === String(payload.id_karyawan) &&
      rowDate === today &&
      logs[i][6] === "Disetujui"
    )
      return responseJSON(200, "success", true);
  }
  return responseJSON(200, "success", false);
}

function handleGetHistory(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var logs = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Log_Absensi")
    .getDataRange()
    .getValues();
  var results = [];
  for (var i = 1; i < logs.length; i++) {
    if (String(logs[i][1]) === String(payload.id_karyawan)) {
      results.push({
        waktu: logs[i][0],
        tipe: logs[i][2],
        lat_long: logs[i][3],
        foto: logs[i][4],
        biometrik: logs[i][5],
        status: logs[i][6],
      });
    }
  }
  return responseJSON(200, "success", results.reverse());
}

function handleGetLeaveHistory(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var logs = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Log_Absensi")
    .getDataRange()
    .getValues();
  var employees = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Master_Karyawan")
    .getDataRange()
    .getValues();
  var namaMap = {};
  var hpMap = {};
  for (var j = 1; j < employees.length; j++) {
    namaMap[String(employees[j][0])] = String(employees[j][1]);
    hpMap[String(employees[j][0])] = String(employees[j][5]);
  }

  var results = [];
  var keywords = ["Sakit", "Izin", "Cuti"];
  for (var i = 1; i < logs.length; i++) {
    var idLog = String(logs[i][1]);
    var tipeLog = String(logs[i][2]);
    if (payload.is_admin === true || idLog === String(payload.id_karyawan)) {
      if (
        keywords.some(function (k) {
          return tipeLog.indexOf(k) !== -1;
        })
      ) {
        results.push({
          waktu_pengajuan: logs[i][0],
          id_karyawan: idLog,
          nama: namaMap[idLog] || "-",
          no_hp: hpMap[idLog] || "",
          tipe: logs[i][2],
          rentang: logs[i][3],
          foto: logs[i][4],
          alasan: logs[i][5],
          status: logs[i][6],
          guru_pengganti: logs[i][7] || "-", // Menampilkan Guru Pengganti
        });
      }
    }
  }
  return responseJSON(200, "success", results.reverse());
}
function handleGetMonthlyReport(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var logs = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Log_Absensi")
    .getDataRange()
    .getValues();
  var employees = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Master_Karyawan")
    .getDataRange()
    .getValues();
  var namaMap = {};
  for (var j = 1; j < employees.length; j++) {
    namaMap[String(employees[j][0])] = String(employees[j][1]);
  }
  var results = [];
  for (var i = 1; i < logs.length; i++) {
    if (!logs[i][0]) continue;
    var d = new Date(logs[i][0]);
    var logBulan =
      (d.getMonth() + 1).toString().padStart(2, "0") + "-" + d.getFullYear();
    if (logBulan === payload.bulan_tahun) {
      if (
        payload.id_karyawan_target === "SEMUA" ||
        String(logs[i][1]) === payload.id_karyawan_target
      ) {
        results.push({
          waktu: Utilities.formatDate(d, "GMT+7", "yyyy-MM-dd HH:mm:ss"),
          id_karyawan: logs[i][1],
          nama: namaMap[logs[i][1]] || "-",
          tipe: logs[i][2],
          status: logs[i][6],
        });
      }
    }
  }
  return responseJSON(200, "success", results);
}

// =============================================================================
// MANAJEMEN BANNER (ADD, DELETE, EDIT)
// =============================================================================

function handleAddBanner(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Banner_Pengumuman",
  );
  var fotoUrl = "";

  if (payload.foto_base64 && payload.foto_base64.length > 0) {
    try {
      var folder = DriveApp.getFolderById(config.folderDriveId);
      var fileName =
        "Banner_" +
        Utilities.formatDate(new Date(), "GMT+7", "yyyyMMdd_HHmmss") +
        ".jpg";
      var blob = Utilities.newBlob(
        Utilities.base64Decode(payload.foto_base64),
        "image/jpeg",
        fileName,
      );
      var file = folder.createFile(blob);
      fotoUrl = file.getUrl();
    } catch (e) {
      return responseJSON(500, "error", "Gagal upload gambar: " + e.message);
    }
  } else if (payload.url) {
    // Fallback: jika tidak ada foto_base64, gunakan URL langsung
    fotoUrl = payload.url;
  } else {
    return responseJSON(400, "error", "Foto banner wajib diisi.");
  }

  var idBanner = "BNR-" + new Date().getTime();
  sheet.appendRow([idBanner, payload.judul, fotoUrl, "Aktif"]);
  return responseJSON(200, "success", "Banner berhasil ditambahkan.");
}

function handleDeleteBanner(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Banner_Pengumuman",
  );
  var data = sheet.getDataRange().getValues();

  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_banner)) {
      var fotoUrl = data[i][2];

      // Proses hapus file di Google Drive
      if (fotoUrl && fotoUrl !== "" && fotoUrl !== "No Photo") {
        try {
          var idMatch = fotoUrl.match(/[-\w]{25,}/);
          if (idMatch && idMatch.length > 0) {
            DriveApp.getFileById(idMatch[0]).setTrashed(true);
          }
        } catch (e) {
          console.log("Gagal hapus foto Drive: " + e.message);
        }
      }

      sheet.deleteRow(i + 1);
      return responseJSON(
        200,
        "success",
        "Banner beserta fotonya berhasil dihapus.",
      );
    }
  }
  return responseJSON(404, "error", "Banner tidak ditemukan.");
}

function handleEditBanner(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Banner_Pengumuman",
  );
  var data = sheet.getDataRange().getValues();

  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_banner)) {
      // Support judul_baru (File 2) atau payload.status (File 1)
      if (payload.judul_baru)
        sheet.getRange(i + 1, 2).setValue(payload.judul_baru);
      if (payload.status_baru)
        sheet.getRange(i + 1, 4).setValue(payload.status_baru);
      if (payload.status) sheet.getRange(i + 1, 4).setValue(payload.status);
      return responseJSON(200, "success", "Data banner berhasil diupdate.");
    }
  }
  return responseJSON(404, "error", "Banner tidak ditemukan.");
}

// =============================================================================
// PENILAIAN AL-QURAN
// =============================================================================

function handleGetNilaiSiswa(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var logData = ss
    .getSheetByName("Log_Nilai_Quran")
    .getDataRange()
    .getDisplayValues();
  var materiData = ss
    .getSheetByName("Master_Materi_Quran")
    .getDataRange()
    .getValues();

  // Mapping nama materi untuk kemudahan mobile
  var mapMateri = {};
  for (var m = 1; m < materiData.length; m++) {
    mapMateri[materiData[m][0]] = materiData[m][2];
  }

  var results = [];
  for (var i = 1; i < logData.length; i++) {
    if (String(logData[i][1]) === String(payload.nis)) {
      results.push({
        waktu: logData[i][0],
        guru: logData[i][2],
        id_materi: logData[i][3],
        nama_materi: mapMateri[logData[i][3]] || "-",
        hal: logData[i][4],
        halaman_ayat: logData[i][4],
        nilai: logData[i][5],
        ket: logData[i][6],
        keterangan: logData[i][6],
      });
    }
  }
  return responseJSON(200, "success", results.reverse());
}

function handleGetAppSettings(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "App_Settings",
  );

  if (!sheet)
    return responseJSON(404, "error", "Sheet Settings tidak ditemukan.");

  var data = sheet.getDataRange().getValues();
  var settings = {};

  // Melewati header (i=1), masukkan data ke object
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] !== "") {
      settings[data[i][0]] = data[i][1];
    }
  }

  return responseJSON(200, "success", settings);
}

// =============================================================================
// FITUR TAHAP 1 (MASTER JABATAN & ABSENSI BRIEFING)
// =============================================================================

function handleGetJabatan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Master_Jabatan",
  );
  if (!sheet) return responseJSON(200, "success", []);

  var data = sheet.getDataRange().getValues();
  var results = [];
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] !== "")
      results.push({ id_jabatan: data[i][0], nama_jabatan: data[i][1] });
  }
  return responseJSON(200, "success", results);
}

function handleAddJabatan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Master_Jabatan",
  );
  var idJabatan = "JBT-" + new Date().getTime();
  sheet.appendRow([idJabatan, payload.nama_jabatan]);
  return responseJSON(200, "success", "Jabatan berhasil ditambahkan.");
}

function handleDeleteJabatan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Master_Jabatan",
  );
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_jabatan)) {
      sheet.deleteRow(i + 1);
      return responseJSON(200, "success", "Jabatan berhasil dihapus.");
    }
  }
  return responseJSON(404, "error", "Jabatan tidak ditemukan.");
}

function handleAbsenBriefing(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Log_Briefing",
  );

  var fotoUrl = "";
  if (payload.foto_base64 && payload.foto_base64.length > 0) {
    try {
      var folder = DriveApp.getFolderById(config.folderDriveId);
      var fileName =
        "Briefing_" + payload.id_karyawan + "_" + new Date().getTime() + ".jpg";
      var blob = Utilities.newBlob(
        Utilities.base64Decode(payload.foto_base64),
        "image/jpeg",
        fileName,
      );
      fotoUrl = folder.createFile(blob).getUrl();
    } catch (e) {
      fotoUrl = "Error: " + e.message;
    }
  }

  sheet.appendRow([
    Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"),
    payload.id_karyawan,
    payload.status_kehadiran, // contoh: Hadir, Izin, Sakit
    fotoUrl,
    payload.catatan || "",
  ]);
  return responseJSON(200, "success", "Absen briefing tersimpan.");
}

function handleGetBriefing(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Log_Briefing",
  );
  if (!sheet) return responseJSON(200, "success", []);

  var data = sheet.getDataRange().getValues();
  var results = [];
  for (var i = 1; i < data.length; i++) {
    if (
      payload.id_karyawan === "SEMUA" ||
      String(data[i][1]) === String(payload.id_karyawan)
    ) {
      results.push({
        waktu: data[i][0],
        id_karyawan: data[i][1],
        status: data[i][2],
        foto: data[i][3],
        catatan: data[i][4],
      });
    }
  }
  return responseJSON(200, "success", results.reverse());
}
function handleUpdateAnggota(payload) {
  try {
    var config = getSemuaConfig()[payload.client_id];
    var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
      "Master_Karyawan",
    );
    var data = sheet.getDataRange().getValues();
    for (var i = 1; i < data.length; i++) {
      if (
        String(data[i][0]).trim().toLowerCase() ===
        String(payload.id_karyawan).trim().toLowerCase()
      ) {
        sheet.getRange(i + 1, 2).setValue(payload.nama);
        sheet.getRange(i + 1, 3).setValue(payload.divisi);
        sheet.getRange(i + 1, 6).setValue(payload.no_hp);
        if (payload.id_shift) {
          sheet.getRange(i + 1, 7).setValue(payload.id_shift);
        }
        return {
          code: 200,
          status: "success",
          message: "Data Anggota Diperbarui.",
        };
      }
    }
    return { code: 404, status: "error", message: "Anggota tidak ditemukan." };
  } catch (e) {
    return { code: 500, status: "error", message: e.toString() };
  }
}

/**
 * Proxy function for web dashboard to call doPost logic without HTTP request
 */
function handleWebApiProxy(payload) {
  // Simple check
  if (payload.api_token && payload.api_token !== MASTER_API_TOKEN) {
    // We allow call from web if user is logged in
  }

  // Reuse doPost logic but returns object
  switch (payload.action) {
    case "update_karyawan":
      return handleUpdateAnggota(payload);
    case "add_karyawan":
      return handleAddAnggota(payload);
    default:
      return { code: 400, message: "Action not supported via proxy" };
  }
}

// =============================================================================
// WEB DASHBOARD HELPER FUNCTIONS (Called from scripts.html)
// =============================================================================

function handleGetEnhancedStatsWeb(clientId) {
  var payload = {
    api_token: MASTER_API_TOKEN,
    action: "get_enhanced_stats",
    client_id: clientId,
  };
  var result = handleGetEnhancedStats(payload);
  return JSON.parse(result.getContent());
}

function handleGetBriefingReport(payload) {
  payload.api_token = MASTER_API_TOKEN;
  payload.action = "get_briefing_report";
  var result = handleGetBriefingReport_internal(payload);
  return result;
}

function handleGetBriefingReport_internal(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("Log_Briefing");
  if (!sheet) return { status: "success", message: [] };
  var data = sheet.getDataRange().getDisplayValues();
  var employees = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
  var namaMap = {};
  for (var j = 1; j < employees.length; j++) {
    namaMap[String(employees[j][0])] = String(employees[j][1]);
  }
  var results = [];
  for (var i = 1; i < data.length; i++) {
    if (!data[i][0]) continue;
    var d = new Date(data[i][0]);
    var logBulan = (d.getMonth() + 1).toString().padStart(2, "0") + "-" + d.getFullYear();
    if (logBulan === payload.bulan_tahun || !payload.bulan_tahun) {
      results.push({
        waktu: data[i][0], id_karyawan: data[i][1],
        nama: namaMap[data[i][1]] || data[i][1],
        status: data[i][2], catatan: data[i][4] || "-",
      });
    }
  }
  return { status: "success", message: results };
}

function handleGetPengajianReport(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("Log_Ngaji_Guru");
  if (!sheet) return { status: "success", message: [] };
  var data = sheet.getDataRange().getDisplayValues();
  var employees = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
  var namaMap = {};
  for (var j = 1; j < employees.length; j++) {
    namaMap[String(employees[j][0])] = String(employees[j][1]);
  }
  var results = [];
  for (var i = 1; i < data.length; i++) {
    if (!data[i][0]) continue;
    var d = new Date(data[i][0]);
    var logBulan = (d.getMonth() + 1).toString().padStart(2, "0") + "-" + d.getFullYear();
    if (logBulan === payload.bulan_tahun || !payload.bulan_tahun) {
      results.push({
        waktu: data[i][0], id_guru: data[i][1],
        nama_guru: namaMap[data[i][1]] || data[i][1],
        kelompok: data[i][2], lokasi: data[i][3], materi: data[i][4] || "-",
      });
    }
  }
  return { status: "success", message: results };
}

function handleGetKegiatanReport(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("Absen_Kegiatan");
  if (!sheet) return { status: "success", message: [] };
  var data = sheet.getDataRange().getDisplayValues();
  var employees = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
  var namaMap = {};
  for (var j = 1; j < employees.length; j++) {
    namaMap[String(employees[j][0])] = String(employees[j][1]);
  }
  var results = [];
  for (var i = 1; i < data.length; i++) {
    if (!data[i][0]) continue;
    var d = new Date(data[i][0]);
    var logBulan = (d.getMonth() + 1).toString().padStart(2, "0") + "-" + d.getFullYear();
    if (logBulan === payload.bulan_tahun || !payload.bulan_tahun) {
      results.push({
        waktu: data[i][0], id_kegiatan: data[i][1],
        nama_kegiatan: data[i][1], id_karyawan: data[i][2],
        nama: namaMap[data[i][2]] || data[i][2],
        status: data[i][3] || "Hadir",
      });
    }
  }
  return { status: "success", message: results };
}

function handleGetFeedbackWeb(clientId) {
  var config = getSemuaConfig()[clientId];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("Log_Feedback");
  if (!sheet) return { status: "success", message: [] };
  var data = sheet.getDataRange().getDisplayValues();
  var results = [];
  for (var i = 1; i < data.length; i++) {
    results.push({ waktu: data[i][0], tipe: data[i][1], isi: data[i][2] });
  }
  return { status: "success", message: results.reverse() };
}


function handleSubmitFeedback(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("Log_Feedback");
  if (!sheet) {
    sheet = ss.insertSheet("Log_Feedback");
    sheet.appendRow(["Waktu", "Tipe", "Isi"]);
  }
  sheet.appendRow([
    Utilities.formatDate(new Date(), "GMT+8", "yyyy-MM-dd HH:mm:ss"),
    payload.tipe || "Saran",
    payload.isi || "",
  ]);
  return responseJSON(200, "success", "Terima kasih atas masukan Anda.");
}

function handleGetFeedback(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("Log_Feedback");
  if (!sheet) return responseJSON(200, "success", []);
  var data = sheet.getDataRange().getDisplayValues();
  var results = [];
  for (var i = 1; i < data.length; i++) {
    results.push({ waktu: data[i][0], tipe: data[i][1], isi: data[i][2] });
  }
  return responseJSON(200, "success", results.reverse());
}

// =============================================================================
// REKAP LAPORAN (BRIEFING, PENGAJIAN, KEGIATAN)
// =============================================================================

function handleGetBriefingReport(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("Log_Briefing");
  if (!sheet) return responseJSON(200, "success", []);
  var data = sheet.getDataRange().getDisplayValues();
  var employees = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
  var namaMap = {};
  for (var j = 1; j < employees.length; j++) {
    namaMap[String(employees[j][0])] = String(employees[j][1]);
  }
  var results = [];
  for (var i = 1; i < data.length; i++) {
    if (!data[i][0]) continue;
    var d = new Date(data[i][0]);
    var logBulan = (d.getMonth() + 1).toString().padStart(2, "0") + "-" + d.getFullYear();
    if (logBulan === payload.bulan_tahun || !payload.bulan_tahun) {
      results.push({
        waktu: data[i][0],
        id_karyawan: data[i][1],
        nama: namaMap[data[i][1]] || data[i][1],
        status: data[i][2],
        catatan: data[i][4] || "-",
      });
    }
  }
  return responseJSON(200, "success", results);
}

function handleGetPengajianReport(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("Log_Ngaji_Guru");
  if (!sheet) return responseJSON(200, "success", []);
  var data = sheet.getDataRange().getDisplayValues();
  var employees = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
  var namaMap = {};
  for (var j = 1; j < employees.length; j++) {
    namaMap[String(employees[j][0])] = String(employees[j][1]);
  }
  var results = [];
  for (var i = 1; i < data.length; i++) {
    if (!data[i][0]) continue;
    var d = new Date(data[i][0]);
    var logBulan = (d.getMonth() + 1).toString().padStart(2, "0") + "-" + d.getFullYear();
    if (logBulan === payload.bulan_tahun || !payload.bulan_tahun) {
      results.push({
        waktu: data[i][0],
        id_guru: data[i][1],
        nama_guru: namaMap[data[i][1]] || data[i][1],
        kelompok: data[i][2],
        lokasi: data[i][3],
        materi: data[i][4] || "-",
      });
    }
  }
  return responseJSON(200, "success", results);
}

function handleGetKegiatanReport(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("Absen_Kegiatan");
  if (!sheet) return responseJSON(200, "success", []);
  var data = sheet.getDataRange().getDisplayValues();
  var employees = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
  var namaMap = {};
  for (var j = 1; j < employees.length; j++) {
    namaMap[String(employees[j][0])] = String(employees[j][1]);
  }
  var kegSheet = ss.getSheetByName("Jadwal_Kegiatan");
  var kegMap = {};
  if (kegSheet) {
    var kegData = kegSheet.getDataRange().getValues();
    for (var k = 1; k < kegData.length; k++) {
      kegMap[String(kegData[k][0])] = String(kegData[k][1]);
    }
  }
  var results = [];
  for (var i = 1; i < data.length; i++) {
    if (!data[i][0]) continue;
    var d = new Date(data[i][0]);
    var logBulan = (d.getMonth() + 1).toString().padStart(2, "0") + "-" + d.getFullYear();
    if (logBulan === payload.bulan_tahun || !payload.bulan_tahun) {
      results.push({
        waktu: data[i][0],
        id_kegiatan: data[i][1],
        nama_kegiatan: kegMap[data[i][1]] || data[i][1],
        id_karyawan: data[i][2],
        nama: namaMap[data[i][2]] || data[i][2],
        status: data[i][3] || "Hadir",
      });
    }
  }
  return responseJSON(200, "success", results);
}

// =============================================================================
// AYAT PILIHAN
// =============================================================================

function handleGetAyatPilihan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("App_Settings");
  if (!sheet) return responseJSON(200, "success", { ayat: "", sumber: "" });
  var data = sheet.getDataRange().getValues();
  var ayat = "", sumber = "";
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] === "ayat_pilihan") ayat = String(data[i][1]);
    if (data[i][0] === "sumber_ayat") sumber = String(data[i][1]);
  }
  return responseJSON(200, "success", { ayat: ayat, sumber: sumber });
}

function handleUpdateAyatPilihan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("App_Settings");
  if (!sheet) {
    sheet = ss.insertSheet("App_Settings");
    sheet.appendRow(["key", "value"]);
  }
  var data = sheet.getDataRange().getValues();
  var foundAyat = false, foundSumber = false;
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] === "ayat_pilihan") {
      sheet.getRange(i + 1, 2).setValue(payload.ayat);
      foundAyat = true;
    }
    if (data[i][0] === "sumber_ayat") {
      sheet.getRange(i + 1, 2).setValue(payload.sumber);
      foundSumber = true;
    }
  }
  if (!foundAyat) sheet.appendRow(["ayat_pilihan", payload.ayat]);
  if (!foundSumber) sheet.appendRow(["sumber_ayat", payload.sumber]);
  return responseJSON(200, "success", "Ayat pilihan diperbarui.");
}

// =============================================================================
// STATISTIK ENHANCED (PIE CHART PER JABATAN)
// =============================================================================

function handleGetEnhancedStats(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var logs = ss.getSheetByName("Log_Absensi").getDataRange().getValues();
  var employees = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();

  // Build jabatan map from Master_Karyawan col C (bagian)
  var jabatanMap = {}; // id -> bagian
  var totalByJabatan = {};
  for (var j = 1; j < employees.length; j++) {
    var empId = String(employees[j][0]);
    var bagian = String(employees[j][2] || "Lainnya");
    jabatanMap[empId] = bagian;
    if (!totalByJabatan[bagian]) totalByJabatan[bagian] = 0;
    totalByJabatan[bagian]++;
  }

  var today = new Date();
  today.setHours(0, 0, 0, 0);

  // Per-jabatan hadir hari ini
  var hadirByJabatan = {};
  var totalHadir = 0, totalTerlambat = 0, totalIzin = 0;

  for (var i = 1; i < logs.length; i++) {
    if (!logs[i][0]) continue;
    var rDate = new Date(logs[i][0]);
    rDate.setHours(0, 0, 0, 0);
    if (rDate.getTime() === today.getTime()) {
      var status = logs[i][6];
      var idKry = String(logs[i][1]);
      var jbt = jabatanMap[idKry] || "Lainnya";

      if (status === "Tepat Waktu" || status === "Terlambat") {
        totalHadir++;
        if (!hadirByJabatan[jbt]) hadirByJabatan[jbt] = 0;
        hadirByJabatan[jbt]++;
      }
      if (status === "Terlambat") totalTerlambat++;
      if (["Izin", "Sakit", "Cuti"].indexOf(status) !== -1) totalIzin++;
    }
  }

  // Pie chart data: per jabatan
  var pieData = [];
  for (var key in totalByJabatan) {
    pieData.push({
      jabatan: key,
      total_anggota: totalByJabatan[key],
      hadir_hari_ini: hadirByJabatan[key] || 0,
    });
  }

  // Trend 7 hari
  var trendLabels = [], trendValues = [];
  for (var d = 6; d >= 0; d--) {
    var date = new Date();
    date.setDate(date.getDate() - d);
    date.setHours(0, 0, 0, 0);
    trendLabels.push(Utilities.formatDate(date, "GMT+8", "dd MMM"));
    var count = 0;
    for (var k = 1; k < logs.length; k++) {
      if (!logs[k][0]) continue;
      var rD = new Date(logs[k][0]);
      rD.setHours(0, 0, 0, 0);
      if (rD.getTime() === date.getTime() && (logs[k][6] === "Tepat Waktu" || logs[k][6] === "Terlambat")) count++;
    }
    trendValues.push(count);
  }

  return responseJSON(200, "success", {
    present: totalHadir,
    late: totalTerlambat,
    leave: totalIzin,
    total_anggota: employees.length - 1,
    pie_jabatan: pieData,
    trendLabels: trendLabels,
    trendValues: trendValues,
  });
}

function handleGetEmployeeStats(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var logs = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Log_Absensi").getDataRange().getValues();

  var now = new Date();
  var currentMonth = now.getMonth();
  var currentYear = now.getFullYear();

  var totalHadir = 0, totalTerlambat = 0, totalIzin = 0, totalMasuk = 0;
  var streak = 0, tempStreak = 0;
  var lastDate = null;

  for (var i = 1; i < logs.length; i++) {
    if (!logs[i][0]) continue;
    if (String(logs[i][1]) !== String(payload.id_karyawan)) continue;
    var d = new Date(logs[i][0]);
    if (d.getMonth() !== currentMonth || d.getFullYear() !== currentYear) continue;
    if (logs[i][2] !== "Masuk") continue;
    totalMasuk++;
    var status = logs[i][6];
    if (status === "Tepat Waktu") { totalHadir++; }
    if (status === "Terlambat") { totalTerlambat++; totalHadir++; }
    if (["Izin", "Sakit", "Cuti"].indexOf(status) !== -1) totalIzin++;
  }

  // Count streak (berturut-turut hadir, dari log terakhir mundur)
  var sortedLogs = [];
  for (var s = 1; s < logs.length; s++) {
    if (String(logs[s][1]) === String(payload.id_karyawan) && logs[s][2] === "Masuk") {
      sortedLogs.push({ date: new Date(logs[s][0]), status: logs[s][6] });
    }
  }
  sortedLogs.sort(function(a, b) { return b.date - a.date; });
  for (var x = 0; x < sortedLogs.length; x++) {
    if (sortedLogs[x].status === "Tepat Waktu" || sortedLogs[x].status === "Terlambat") {
      streak++;
    } else {
      break;
    }
  }

  // Working days in month (approx Mon-Fri)
  var workingDays = 0;
  var daysInMonth = new Date(currentYear, currentMonth + 1, 0).getDate();
  for (var dd = 1; dd <= Math.min(now.getDate(), daysInMonth); dd++) {
    var dayOfWeek = new Date(currentYear, currentMonth, dd).getDay();
    if (dayOfWeek !== 0 && dayOfWeek !== 6) workingDays++;
  }

  var percentage = workingDays > 0 ? Math.round((totalHadir / workingDays) * 100) : 0;

  return responseJSON(200, "success", {
    hadir: totalHadir,
    terlambat: totalTerlambat,
    izin: totalIzin,
    percentage: percentage,
    streak: streak,
    working_days: workingDays,
  });
}

// =============================================================================
// UPLOAD FOTO PROFIL
// =============================================================================

function handleUploadProfilePhoto(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("Master_Karyawan");
  var data = sheet.getDataRange().getValues();

  var fotoUrl = "";
  if (payload.foto_base64 && payload.foto_base64.length > 0) {
    try {
      var folder = DriveApp.getFolderById(config.folderDriveId);
      var fileName = "Profile_" + payload.id_karyawan + "_" + new Date().getTime() + ".jpg";
      var blob = Utilities.newBlob(Utilities.base64Decode(payload.foto_base64), "image/jpeg", fileName);
      var file = folder.createFile(blob);
      fotoUrl = file.getUrl();
    } catch (e) {
      return responseJSON(500, "error", "Gagal upload foto: " + e.message);
    }
  }

  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]).trim().toLowerCase() === String(payload.id_karyawan).trim().toLowerCase()) {
      // Hapus foto lama jika ada
      var oldUrl = data[i][7];
      if (oldUrl && oldUrl !== "") {
        try {
          var idMatch = oldUrl.match(/[-\w]{25,}/);
          if (idMatch) DriveApp.getFileById(idMatch[0]).setTrashed(true);
        } catch (e) { /* ignore */ }
      }
      sheet.getRange(i + 1, 8).setValue(fotoUrl); // Kolom H = foto profil
      return responseJSON(200, "success", { url: fotoUrl });
    }
  }
  return responseJSON(404, "error", "Anggota tidak ditemukan.");
}
