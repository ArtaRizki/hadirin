// =============================================================================
// BACKEND HADIRIN - v3.7 (Unified - Dynamic Groups & Time Fix)
// =============================================================================
const MASTER_API_TOKEN = "kicau-mania";
const MASTER_REGISTRY_ID = "1hTh660vp0AbPn8D37Yg7XE-5HBRDXYA2xSJErORfZ3w";
const ID_TEMPLATE_SS = "1z5ODh4qPVdgQYabmV7Po8tDSh_WukagY2r7iD7pUfXI";
const ID_MASTER_FOLDER = "1NP8DaptYXosSWo06p4CDWEJMpkZ2SAsM";
const SUPER_ADMIN_PASSWORD = "HADIRIN_MASTER_2026_AHHH";

// =============================================================================
// 1. ROUTING & UI (WEB DASHBOARD)
// =============================================================================

function doGet(e) {
  var template = HtmlService.createTemplateFromFile('Index');
  return template.evaluate()
    .setTitle('Hadir.in Dashboard v3.7')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

function loginWeb(clientId, id, pin) {
  try {
    if (id.toUpperCase() === "ADMIN" && pin === SUPER_ADMIN_PASSWORD) {
      return { success: true, user: { id: "ADMIN", nama: "Super Admin", role: "superAdmin", clientId: clientId || "GLOBAL" } };
    }
    var allConfigs = getSemuaConfig();
    var lookupId = String(clientId || "").trim().toUpperCase();
    var config = allConfigs[lookupId];
    if (!config) return { success: false, message: "Kode Instansi tidak terdaftar." };

    var ss = SpreadsheetApp.openById(config.spreadsheetId);
    var data = ss.getSheetByName('Master_Karyawan').getDataRange().getValues();
    for (var i = 1; i < data.length; i++) {
      var rowId = String(data[i][0]).trim().toLowerCase();
      if (rowId === id.trim().toLowerCase()) {
        return {
          success: true,
          user: { id: rowId, nama: String(data[i][1]), role: String(data[i][2] || "Anggota"), clientId: clientId, faceWeb: data[i][4] || "" }
        };
      }
    }
    return { success: false, message: "ID Anggota tidak ditemukan." };
  } catch (e) { return { success: false, message: "Error: " + e.toString() }; }
}

function registerFaceWeb(clientId, id, descriptor) {
  try {
    var config = getSemuaConfig()[clientId];
    var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName('Master_Karyawan');
    var data = sheet.getDataRange().getValues();
    for (var i = 1; i < data.length; i++) {
      if (String(data[i][0]).trim().toLowerCase() === id.trim().toLowerCase()) {
        sheet.getRange(i + 1, 5).setValue(descriptor);
        return { success: true, message: "Wajah berhasil didaftarkan!" };
      }
    }
    return { success: false, message: "User tidak ditemukan." };
  } catch (e) { return { success: false, message: e.toString() }; }
}

function submitAbsenWeb(payload) {
  try {
    var result = handleAbsensi(payload);
    return JSON.parse(result.getContent());
  } catch (e) { return { code: 500, status: "error", message: e.toString() }; }
}

function getDashboardStats(clientId, id) {
  try {
    var config = getSemuaConfig()[clientId.toUpperCase()];
    if (!config) return { present: 0, leave: 0, late: 0, trendLabels: [], trendValues: [] };
    var ss = SpreadsheetApp.openById(config.spreadsheetId);
    var data = ss.getSheetByName('Log_Absensi').getDataRange().getValues();
    var today = new Date(); today.setHours(0,0,0,0);
    var stats = { present: 0, leave: 0, late: 0, trendLabels: [], trendValues: [] };
    
    for (var i = 1; i < data.length; i++) {
      if (!data[i][0]) continue;
      var rDate = new Date(data[i][0]); rDate.setHours(0,0,0,0);
      if (rDate.getTime() === today.getTime()) {
        if (data[i][6] === "Tepat Waktu") stats.present++;
        if (data[i][6] === "Terlambat") { stats.present++; stats.late++; }
        if (["Izin", "Sakit", "Cuti"].indexOf(data[i][6]) !== -1) stats.leave++;
      }
    }
    for (var d = 6; d >= 0; d--) {
      var date = new Date(); date.setDate(date.getDate() - d); date.setHours(0,0,0,0);
      stats.trendLabels.push(Utilities.formatDate(date, "GMT+7", "dd MMM"));
      var count = 0;
      for (var j = 1; j < data.length; j++) {
        if (!data[j][0]) continue;
        var rD = new Date(data[j][0]); rD.setHours(0,0,0,0);
        if (rD.getTime() === date.getTime() && (data[j][6] === "Tepat Waktu" || data[j][6] === "Terlambat")) count++;
      }
      stats.trendValues.push(count);
    }
    return stats;
  } catch (e) { return { present: 0, leave: 0, late: 0, trendLabels: [], trendValues: [] }; }
}

function getAttendanceHistory(clientId, id) {
  try {
    var config = getSemuaConfig()[clientId.toUpperCase()];
    var data = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName('Log_Absensi').getDataRange().getValues();
    var history = [];
    var searchId = id.trim().toLowerCase();
    for (var i = data.length - 1; i >= 1; i--) {
      if (String(data[i][1]).toLowerCase() === searchId || searchId === "admin") {
        history.push({ waktu: data[i][0], tipe: data[i][2], status: data[i][6] });
        if (history.length >= 50) break;
      }
    }
    return history;
  } catch (e) { return []; }
}

// =============================================================================
// 2. MOBILE API (doPost)
// =============================================================================

function doPost(e) {
  var lock = LockService.getScriptLock();
  if (!lock.tryLock(60000)) return responseJSON(429, "error", "Server Busy.");

  try {
    var payload = JSON.parse(e.postData.contents);
    if (payload.api_token !== MASTER_API_TOKEN) return responseJSON(401, "error", "Unauthorized.");

    const skipCheck = ["register_klien", "verify_super_admin"];
    if (skipCheck.indexOf(payload.action) === -1) {
      var config = getSemuaConfig()[payload.client_id];
      if (!config || !config.spreadsheetId) return responseJSON(404, "error", "Kode Instansi tidak ditemukan.");
    }

    switch (payload.action) {
      // --- CORE ABSENSI ---
      case "absen": return handleAbsensi(payload);
      case "register_klien": return handleRegisterInstansi(payload);
      case "get_history": return handleGetHistory(payload);
      case "get_office_config": return handleGetOfficeConfig(payload);
      case "update_lokasi": return handleUpdateLokasi(payload);
      case "update_jam_kerja": return handleUpdateJamKerja(payload);
      case "enroll_device": return handleEnrollDevice(payload);
      case "register_face": return handleRegisterFace(payload);
      case "get_face": return handleGetFace(payload);
      case "add_karyawan": return handleAddAnggota(payload);
      case "delete_karyawan": return handleDeleteKaryawan(payload);
      case "ajukan_izin": return handleAjukanIzin(payload);
      case "get_all_approvals": return responseJSON(200, "success", handleGetAllApprovals(payload));
      case "update_leave_status": return responseJSON(200, "success", handleUpdateLeaveStatus(payload));
      case "reset_device": return responseJSON(200, "success", handleResetDevice(payload));
      case "get_all_karyawan": return responseJSON(200, "success", handleGetAllAnggota(payload));
      case "cek_status_hari_ini": return handleCekStatusHariIni(payload);
      case "verify_super_admin": return handleVerifySuperAdmin(payload);
      case "get_leave_history": return handleGetLeaveHistory(payload);
      case "get_monthly_report": return handleGetMonthlyReport(payload);

      // --- JADWAL KEGIATAN & RAPAT ---
      case "get_jadwal_kegiatan": return handleGetJadwalKegiatan(payload);
      case "add_jadwal_kegiatan": return handleAddJadwalKegiatan(payload);
      case "edit_jadwal_kegiatan": return handleEditJadwalKegiatan(payload);
      case "absen_kegiatan": return handleAbsenKegiatan(payload);

      // --- PENGAJIAN GURU (DINAMIS) ---
      case "get_kelompok_ngaji": return handleGetKelompokNgaji(payload);
      case "add_kelompok_ngaji": return handleAddKelompokNgaji(payload);
      case "submit_laporan_ngaji": return handleSubmitLaporanNgaji(payload);
      case "get_laporan_ngaji": return handleGetLaporanNgaji(payload);

      // --- BANNER PENGUMUMAN ---
      case "get_banners": return handleGetBanners(payload);
      case "add_banner": return handleAddBanner(payload);
      case "delete_banner": return handleDeleteBanner(payload);
      case "edit_banner": return handleEditBanner(payload);

      // --- PENILAIAN AL-QURAN ---
      case "get_master_quran": return handleGetMasterQuran(payload);
      case "submit_nilai_quran": return handleSubmitNilaiQuran(payload);
      case "get_nilai_siswa": return handleGetNilaiSiswa(payload);

      default: return responseJSON(400, "error", "Action Unknown.");
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
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Log_Ngaji_Guru");
  sheet.appendRow([
    Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"),
    payload.id_guru, payload.nama_kelompok, payload.lokasi, payload.materi_keterangan
  ]);
  return responseJSON(200, "success", "Laporan pengajian tersimpan.");
}

function handleGetLaporanNgaji(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Log_Ngaji_Guru").getDataRange().getDisplayValues();
  var results = [];
  for (var i = 1; i < data.length; i++) {
    if (payload.id_guru === "SEMUA" || String(data[i][1]) === String(payload.id_guru)) {
      results.push({ waktu: data[i][0], id_guru: data[i][1], kelompok: data[i][2], lokasi: data[i][3], materi: data[i][4] });
    }
  }
  return responseJSON(200, "success", results.reverse());
}

// =============================================================================
// HANDLERS JADWAL & KEGIATAN (FIX JAM GESER)
// =============================================================================

function handleGetJadwalKegiatan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Jadwal_Kegiatan").getDataRange().getDisplayValues();
  var results = [];
  for (var i = 1; i < data.length; i++) {
    results.push({
      id_kegiatan: data[i][0], nama_kegiatan: data[i][1], tipe: data[i][2],
      tanggal_waktu: data[i][3], deskripsi: data[i][4]
    });
  }
  return responseJSON(200, "success", results.reverse());
}

function handleAddJadwalKegiatan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Jadwal_Kegiatan");
  sheet.appendRow(["KEG-" + new Date().getTime(), payload.nama_kegiatan, payload.tipe, payload.tanggal_waktu, payload.deskripsi, payload.id_admin]);
  return responseJSON(200, "success", "Jadwal berhasil ditambahkan.");
}

function handleEditJadwalKegiatan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Jadwal_Kegiatan");
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_kegiatan)) {
      if (payload.nama_kegiatan) sheet.getRange(i + 1, 2).setValue(payload.nama_kegiatan);
      if (payload.tipe) sheet.getRange(i + 1, 3).setValue(payload.tipe);
      if (payload.tanggal_waktu) sheet.getRange(i + 1, 4).setValue(payload.tanggal_waktu);
      if (payload.deskripsi) sheet.getRange(i + 1, 5).setValue(payload.deskripsi);
      return responseJSON(200, "success", "Berhasil.");
    }
  }
  return responseJSON(404, "error", "Tidak ditemukan.");
}

// =============================================================================
// CORE & UTILS (ABSENSI, FACE, DEVICE, DLL)
// =============================================================================

function handleAbsensi(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var status = (parseInt(Utilities.formatDate(new Date(), "GMT+7", "HH")) >= config.batasJam && payload.tipe_absen === "Masuk") ? "Terlambat" : "Tepat Waktu";
  var fotoUrl = "No Photo";
  if (payload.foto_base64 && payload.foto_base64.length > 0) {
    try {
      var folder = DriveApp.getFolderById(config.folderDriveId);
      var blob = Utilities.newBlob(Utilities.base64Decode(payload.foto_base64), "image/jpeg", "Absen_" + payload.id_karyawan + "_" + new Date().getTime() + ".jpg");
      fotoUrl = folder.createFile(blob).getUrl();
    } catch (e) { fotoUrl = "Error: " + e.message; }
  }
  ss.getSheetByName("Log_Absensi").appendRow([Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"), payload.id_karyawan, payload.tipe_absen, payload.lat_long, fotoUrl, "Valid", status]);
  return responseJSON(200, "success", "Berhasil.");
}

function handleGetOfficeConfig(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Config_Kantor").getRange("A2:G2").getValues();
  return responseJSON(200, "success", {
    nama: data[0][0], lat: data[0][1], lng: data[0][2], radius: data[0][3] || config.radius,
    jam_masuk_mulai: formatTime(data[0][4], "04:00"), batas_jam_masuk: formatTime(data[0][5], "07:00"), jam_pulang_mulai: formatTime(data[0][6], "13:00")
  });
}

function getSemuaConfig() {
  try {
    var rows = SpreadsheetApp.openById(MASTER_REGISTRY_ID).getSheetByName("Klien").getDataRange().getValues();
    var result = {};
    for (var i = 1; i < rows.length; i++) { result[rows[i][0]] = { spreadsheetId: rows[i][2], folderDriveId: rows[i][3], batasJam: rows[i][4], radius: rows[i][5] }; }
    return result;
  } catch (e) { return {}; }
}

function responseJSON(code, status, message) { return ContentService.createTextOutput(JSON.stringify({ code: code, status: status, message: message })).setMimeType(ContentService.MimeType.JSON); }
function formatTime(val, def) { if (!val) return def; var s = String(val); return s.indexOf(':') !== -1 ? s : (parseInt(s) < 10 ? "0" + s : s) + ":00"; }

function handleEnrollDevice(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan");
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_karyawan)) {
      if (data[i][3] === "" || data[i][3] === payload.device_id) {
        if (data[i][3] === "") sheet.getRange(i + 1, 4).setValue(payload.device_id);
        return responseJSON(200, "success", { nama_karyawan: data[i][1], client_id: payload.client_id, divisi: data[i][2], no_hp: data[i][5] || "" });
      }
    }
  }
  return responseJSON(404, "error", "User not found.");
}

function handleGetBanners(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Banner_Pengumuman").getDataRange().getValues();
  return responseJSON(200, "success", data.slice(1).filter(r => r[3] === "Aktif").map(r => ({ id_banner: r[0], judul: r[1], url_gambar: r[2] })));
}

function handleGetMasterQuran(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var siswa = ss.getSheetByName("Master_Siswa").getDataRange().getValues().slice(1).map(r => ({ nis: r[0], nama: r[1], kelas: r[2] }));
  var materi = ss.getSheetByName("Master_Materi_Quran").getDataRange().getValues().slice(1).map(r => ({ id_materi: r[0], tipe: r[1], nama_materi: r[2] }));
  return responseJSON(200, "success", { siswa: siswa, materi: materi });
}

function handleSubmitNilaiQuran(payload) {
  var config = getSemuaConfig()[payload.client_id];
  SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Log_Nilai_Quran").appendRow([Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"), payload.nis, payload.id_guru, payload.id_materi, payload.halaman_ayat, payload.nilai, payload.keterangan]);
  return responseJSON(200, "success", "OK");
}

function handleRegisterInstansi(payload) {
  var sheetRegistry = SpreadsheetApp.openById(MASTER_REGISTRY_ID).getSheetByName("Klien");
  var id = "INST-" + Math.floor(Math.random() * 900000 + 100000);
  var ssId = DriveApp.getFileById(ID_TEMPLATE_SS).makeCopy("DB - " + payload.nama_umkm).getId();
  var folderId = DriveApp.getFolderById(ID_MASTER_FOLDER).createFolder("Assets - " + payload.nama_umkm).getId();
  sheetRegistry.appendRow([id, payload.nama_umkm, ssId, folderId, 8, 100]);
  return responseJSON(200, "success", { client_id: id });
}

function handleVerifySuperAdmin(payload) {
  return (payload.password === "HADIRIN_MASTER_2026_AHHH") ? responseJSON(200, "success", "OK") : responseJSON(401, "error", "Fail");
}

function handleGetAllAnggota(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan").getDataRange().getValues();
  var results = [];
  for (var i = 1; i < data.length; i++) { if (data[i][0] !== "") results.push({ id: String(data[i][0]), nama: String(data[i][1]), bagian: String(data[i][2] || "-"), sudah_enroll: (data[i][3] !== ""), wajah_terdaftar: (data[i][4] !== ""), no_hp: String(data[i][5] || "") }); }
  return results;
}

function handleAddAnggota(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan");
  sheet.appendRow([payload.id_karyawan_baru, payload.nama_karyawan_baru, payload.divisi_baru || "-", "", "", payload.no_hp || ""]);
  return responseJSON(200, "success", "Anggota Ditambahkan.");
}

function handleDeleteKaryawan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan");
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
  var employees = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
  var namaMap = {};
  for (var j = 1; j < employees.length; j++) { namaMap[String(employees[j][0])] = String(employees[j][1]); }
  var results = [];
  for (var i = logs.length - 1; i >= 1; i--) { if (logs[i][6] === "Menunggu Approval") { results.push({ waktu_pengajuan: logs[i][0], id_karyawan: String(logs[i][1]), nama: namaMap[String(logs[i][1])] || "Unknown", tipe: logs[i][2], rentang: logs[i][3], foto: logs[i][4], alasan: logs[i][5], row_index: i + 1 }); } }
  return results;
}

function handleUpdateLeaveStatus(payload) {
  var config = getSemuaConfig()[payload.client_id];
  SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Log_Absensi").getRange(payload.row_index, 7).setValue(payload.new_status);
  return true;
}

function handleResetDevice(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan");
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) { if (String(data[i][0]) === String(payload.target_id_karyawan)) { sheet.getRange(i + 1, 4).setValue(""); return true; } }
  return false;
}

function handleUpdateJamKerja(payload) {
  var config = getSemuaConfig()[payload.client_id];
  SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Config_Kantor").getRange("E2:G2").setValues([[payload.jam_masuk_mulai, payload.batas_jam_masuk, payload.jam_pulang_mulai]]);
  return responseJSON(200, "success", "Jam kerja diperbarui.");
}

function handleUpdateLokasi(payload) {
  var config = getSemuaConfig()[payload.client_id];
  SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Config_Kantor").getRange("B2:D2").setValues([[payload.lat, payload.lng, payload.radius]]);
  return responseJSON(200, "success", "Lokasi diperbarui.");
}

function handleRegisterFace(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan");
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_karyawan)) {
      sheet.getRange(i + 1, 5).setValue(payload.face_descriptor);
      return responseJSON(200, "success", "Wajah terdaftar.");
    }
  }
  return responseJSON(404, "error", "User not found.");
}

function handleGetFace(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan").getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_karyawan)) {
      return responseJSON(200, "success", data[i][4] || "");
    }
  }
  return responseJSON(404, "error", "Not found.");
}

function handleCekStatusHariIni(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var logs = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Log_Absensi").getDataRange().getValues();
  var today = Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd");
  for (var i = logs.length - 1; i >= 1; i--) { if (String(logs[i][1]) === String(payload.id_karyawan) && Utilities.formatDate(new Date(logs[i][0]), "GMT+7", "yyyy-MM-dd") === today && logs[i][6] === "Disetujui") return responseJSON(200, "success", true); }
  return responseJSON(200, "success", false);
}

function handleGetLeaveHistory(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var logs = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Log_Absensi").getDataRange().getValues();
  var employees = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan").getDataRange().getValues();
  var namaMap = {}; var hpMap = {};
  for (var j = 1; j < employees.length; j++) { namaMap[String(employees[j][0])] = String(employees[j][1]); hpMap[String(employees[j][0])] = String(employees[j][5]); }
  var results = []; var keywords = ["Sakit", "Izin", "Cuti"];
  for (var i = 1; i < logs.length; i++) {
    var idLog = String(logs[i][1]); var tipeLog = String(logs[i][2]);
    if (payload.is_admin === true || idLog === String(payload.id_karyawan)) {
      if (keywords.some(function(k){return tipeLog.indexOf(k)!==-1;})) { results.push({ waktu_pengajuan: logs[i][0], id_karyawan: idLog, nama: namaMap[idLog] || "-", no_hp: hpMap[idLog] || "", tipe: logs[i][2], rentang: logs[i][3], foto: logs[i][4], alasan: logs[i][5], status: logs[i][6] }); }
    }
  }
  return responseJSON(200, "success", results.reverse());
}

function handleGetMonthlyReport(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var logs = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Log_Absensi").getDataRange().getValues();
  var employees = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan").getDataRange().getValues();
  var namaMap = {}; for (var j = 1; j < employees.length; j++) { namaMap[String(employees[j][0])] = String(employees[j][1]); }
  var results = [];
  for (var i = 1; i < logs.length; i++) {
    if (!logs[i][0]) continue;
    var d = new Date(logs[i][0]);
    var logBulan = (d.getMonth() + 1).toString().padStart(2, '0') + "-" + d.getFullYear();
    if (logBulan === payload.bulan_tahun) {
      if (payload.id_karyawan_target === "SEMUA" || String(logs[i][1]) === payload.id_karyawan_target) {
        results.push({ waktu: Utilities.formatDate(d, "GMT+7", "yyyy-MM-dd HH:mm:ss"), id_karyawan: logs[i][1], nama: namaMap[logs[i][1]] || "-", tipe: logs[i][2], status: logs[i][6] });
      }
    }
  }
  return responseJSON(200, "success", results);
}

function handleDeleteBanner(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Banner_Pengumuman");
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) { if (String(data[i][0]) === String(payload.id_banner)) { sheet.deleteRow(i + 1); return responseJSON(200, "success", "OK"); } }
  return responseJSON(404, "error", "Fail");
}

function handleAddBanner(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Banner_Pengumuman");
  sheet.appendRow(["BNR-" + new Date().getTime(), payload.judul, payload.url, "Aktif"]);
  return responseJSON(200, "success", "OK");
}

function handleEditBanner(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Banner_Pengumuman");
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) { if (String(data[i][0]) === String(payload.id_banner)) { sheet.getRange(i + 1, 4).setValue(payload.status); return responseJSON(200, "success", "OK"); } }
  return responseJSON(404, "error", "Fail");
}

function handleGetNilaiSiswa(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Log_Nilai_Quran").getDataRange().getDisplayValues();
  var results = [];
  for (var i = 1; i < data.length; i++) { if (data[i][1] === payload.nis) results.push({ waktu: data[i][0], guru: data[i][2], materi: data[i][3], hal: data[i][4], nilai: data[i][5], ket: data[i][6] }); }
  return responseJSON(200, "success", results.reverse());
}

function handleAbsenKegiatan(payload) {
  var config = getSemuaConfig()[payload.client_id];
  SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Log_Absen_Kegiatan").appendRow([Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"), payload.id_kegiatan, payload.id_karyawan, payload.status || "Hadir"]);
  return responseJSON(200, "success", "OK");
}
