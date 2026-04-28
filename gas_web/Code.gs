// =============================================================================
// BACKEND HADIRIN - v2.5 (Fixed Drive Access & Folder Permissions - SIPARJO)
// =============================================================================
const MASTER_API_TOKEN = "SUPER_SECRET_SIPARJO_8xZ2";
const MASTER_REGISTRY_ID = "1hTh660vp0AbPn8D37Yg7XE-5HBRDXYA2xSJErORfZ3w";
const ID_TEMPLATE_SS = "16EIwrw5nEvghKfc_jX52Vo76hXpU0YyBc3pQHVRsU_Q";
const ID_MASTER_FOLDER = "1IJcGNoOF7WQZAaHiA9flJ2C-1Bm6gVOU";
const SUPER_ADMIN_PASSWORD = "HADIRIN_MASTER_2026_AHHH";

// =============================================================================
// 1. ROUTING & UI (WEB DASHBOARD - Kept from v3.5)
// =============================================================================

function doGet(e) {
  var template = HtmlService.createTemplateFromFile("Index");
  return template
    .evaluate()
    .setTitle("Siparjo Dashboard v3.5")
    .addMetaTag("viewport", "width=device-width, initial-scale=1")
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

/**
 * LOGIKA LOGIN WEB DASHBOARD
 */
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
    var lookupId = String(clientId || "").trim().toUpperCase();
    var config = allConfigs[lookupId];
    if (!config) return { success: false, message: "Kode Instansi tidak terdaftar." };

    var ss = SpreadsheetApp.openById(config.spreadsheetId);
    var data = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();

    for (var i = 1; i < data.length; i++) {
      var rowId = String(data[i][0]).trim().toLowerCase();
      var rowNama = String(data[i][1] || "Tanpa Nama");
      var rowRole = String(data[i][2] || "Anggota");
      var searchId = id.trim().toLowerCase();

      if (rowId === searchId) {
        return {
          success: true,
          user: {
            id: rowId,
            nama: rowNama,
            role: rowRole,
            clientId: clientId,
            faceWeb: data[i][4] || "",
          },
        };
      }
    }
    return { success: false, message: "ID Anggota tidak ditemukan di instansi ini." };
  } catch (e) {
    return { success: false, message: "Server Error: " + e.toString() };
  }
}

function registerFaceWeb(clientId, id, descriptor) {
  try {
    var config = getSemuaConfig()[clientId];
    var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan");
    var data = sheet.getDataRange().getValues();
    var searchId = id.trim().toLowerCase();
    for (var i = 1; i < data.length; i++) {
      if (String(data[i][0]).trim().toLowerCase() === searchId) {
        sheet.getRange(i + 1, 5).setValue(descriptor);
        return { success: true, message: "Pola wajah web berhasil didaftarkan!" };
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
    var jsonStr = result.getContent();
    return JSON.parse(jsonStr);
  } catch (e) {
    return { code: 500, status: "error", message: e.toString() };
  }
}

function getDashboardStats(clientId, id) {
  try {
    var allConfigs = getSemuaConfig();
    var lookupId = String(clientId || "").trim().toUpperCase();
    var config = allConfigs[lookupId];
    if (!config) return { present: 0, leave: 0, late: 0, trendLabels: [], trendValues: [] };

    var ss = SpreadsheetApp.openById(config.spreadsheetId);
    var data = ss.getSheetByName("Log_Absensi").getDataRange().getValues();
    var today = new Date();
    today.setHours(0, 0, 0, 0);

    var stats = { present: 0, leave: 0, late: 0, trendLabels: [], trendValues: [] };
    for (var i = 1; i < data.length; i++) {
      var logWaktu = data[i][0];
      if (!logWaktu || logWaktu === "") continue;
      var rowDate = new Date(logWaktu);
      var rowStatus = String(data[i][6]);
      rowDate.setHours(0, 0, 0, 0);
      if (rowDate.getTime() === today.getTime()) {
        if (rowStatus === "Tepat Waktu") stats.present++;
        if (rowStatus === "Terlambat") { stats.present++; stats.late++; }
        if (["Izin", "Sakit", "Cuti"].indexOf(rowStatus) !== -1 || rowStatus.toLowerCase().indexOf("izin") !== -1) stats.leave++;
      }
    }
    for (var d = 6; d >= 0; d--) {
      var date = new Date();
      date.setDate(date.getDate() - d);
      date.setHours(0, 0, 0, 0);
      stats.trendLabels.push(Utilities.formatDate(date, "GMT+7", "dd MMM"));
      var count = 0;
      for (var j = 1; j < data.length; j++) {
        var logW = data[j][0];
        if (!logW || logW === "") continue;
        var rDate = new Date(logW);
        rDate.setHours(0, 0, 0, 0);
        if (rDate.getTime() === date.getTime() && (data[j][6] === "Tepat Waktu" || data[j][6] === "Terlambat")) count++;
      }
      stats.trendValues.push(count);
    }
    return stats;
  } catch (e) {
    return { present: 0, leave: 0, late: 0, trendLabels: [], trendValues: [] };
  }
}

function getAttendanceHistory(clientId, id) {
  var debug = [];
  try {
    var allConfigs = getSemuaConfig();
    var lookupId = String(clientId || "").trim().toUpperCase();
    var config = allConfigs[lookupId];
    if (!config) throw new Error("Config not found");

    var ss = SpreadsheetApp.openById(config.spreadsheetId);
    var sheet = ss.getSheetByName("Log_Absensi");
    if (!sheet) {
      var sheets = ss.getSheets();
      for (var s = 0; s < sheets.length; s++) {
        if (sheets[s].getName().trim().toLowerCase() === "log_absensi") {
          sheet = sheets[s]; break;
        }
      }
    }
    if (!sheet) throw new Error("Sheet 'Log_Absensi' not found");

    var data = sheet.getDataRange().getValues();
    var history = [];
    var searchId = String(id).trim().toLowerCase();
    for (var i = data.length - 1; i >= 1; i--) {
      var rowId = String(data[i][1] || "").trim().toLowerCase();
      if (rowId === searchId || searchId === "admin") {
        history.push({ id: i, waktu: data[i][0], tipe: data[i][2] || "-", status: data[i][6] || "Tepat Waktu" });
        if (history.length >= 50) break;
      }
    }
    return history;
  } catch (e) {
    return [{ error: e.toString() }];
  }
}

// =============================================================================
// 2. MOBILE API (doPost - Updated to v2.5)
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
      if (!config || !config.spreadsheetId) {
        return responseJSON(404, "error", "Kode Instansi tidak ditemukan.");
      }
    }

    switch (payload.action) {
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
      case "enroll_device":
        return handleEnrollDevice(payload);
      case "register_face":
        return handleRegisterFace(payload);
      case "get_face":
        return handleGetFace(payload);
      case "add_karyawan":
        return handleAddAnggota(payload);
      case "ajukan_izin":
        return handleAjukanIzin(payload);
      case "get_all_approvals":
        return handleGetAllApprovals(payload);
      case "update_leave_status":
        return handleUpdateLeaveStatus(payload);
      case "reset_device":
        return handleResetDevice(payload);
      case "get_all_karyawan":
        return handleGetAllAnggota(payload);
      case "cek_status_hari_ini":
        return handleCekStatusHariIni(payload);
      case "verify_super_admin":
        return handleVerifySuperAdmin(payload);
      case "get_leave_history":
        return handleGetLeaveHistory(payload);
      case "get_monthly_report":
        return handleGetMonthlyReport(payload);
      case "update_jam_kerja":
        return handleUpdateJamKerja(payload);
      default:
        return responseJSON(400, "error", "Action Unknown.");
    }
  } catch (err) {
    return responseJSON(500, "error", err.message);
  } finally {
    lock.releaseLock();
  }
}

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
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var sheet = ss.getSheetByName("Log_Absensi");
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
      var file = folder.createFile(blob);
      fotoUrl = file.getUrl();
    } catch (e) {
      fotoUrl = "ERROR GDrive: " + e.message;
    }
  }

  sheet.appendRow([
    Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"),
    payload.id_karyawan,
    payload.tipe_izin,
    payload.rentang_tanggal,
    fotoUrl,
    payload.alasan,
    payload.is_admin ? "Disetujui" : "Menunggu Approval",
  ]);
  return responseJSON(200, "success", "Sent");
}

function handleRegisterInstansi(payload) {
  var sheetRegistry = SpreadsheetApp.openById(MASTER_REGISTRY_ID).getSheetByName("Klien");
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

  return responseJSON(200, "success", { client_id: newInstansiId });
}

function handleUpdateLokasi(payload) {
  var config = getSemuaConfig()[payload.client_id];
  if (!config) return responseJSON(404, "error", "Instansi tidak ditemukan.");
  SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Config_Kantor")
    .getRange("B2:D2")
    .setValues([[payload.lat, payload.lng, payload.radius]]);
  var sheetRegistry = SpreadsheetApp.openById(MASTER_REGISTRY_ID).getSheetByName("Klien");
  var dataM = sheetRegistry.getDataRange().getValues();
  for (var i = 1; i < dataM.length; i++) {
    if (dataM[i][0] === payload.client_id) {
      sheetRegistry.getRange(i + 1, 6).setValue(payload.radius);
      break;
    }
  }
  return responseJSON(200, "success", "Lokasi diperbarui.");
}

function handleGetOfficeConfig(payload) {
  var config = getSemuaConfig()[payload.client_id];
  if (!config) return responseJSON(404, "error", "Instansi tidak ditemukan.");
  var data = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Config_Kantor")
    .getRange("A2:G2")
    .getValues();
  return responseJSON(200, "success", {
    nama: data[0][0],
    lat: data[0][1],
    lng: data[0][2],
    radius: data[0][3] || config.radius,
    jam_masuk_mulai: data[0][4] || "04:00",
    batas_jam_masuk: data[0][5] || "07:00",
    jam_pulang_mulai: data[0][6] || "13:00",
  });
}

function handleUpdateJamKerja(payload) {
  var config = getSemuaConfig()[payload.client_id];
  if (!config) return responseJSON(404, "error", "Instansi tidak ditemukan.");
  SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Config_Kantor")
    .getRange("E2:G2")
    .setValues([[
      payload.jam_masuk_mulai,
      payload.batas_jam_masuk,
      payload.jam_pulang_mulai,
    ]]);
  return responseJSON(200, "success", "Jam kerja diperbarui.");
}

function getSemuaConfig() {
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

function handleVerifySuperAdmin(payload) {
  return payload.password === SUPER_ADMIN_PASSWORD
    ? responseJSON(200, "success", "Verified")
    : responseJSON(401, "error", "Invalid");
}

function handleAddAnggota(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan");
  sheet.appendRow([
    payload.id_karyawan_baru,
    payload.nama_karyawan_baru,
    payload.divisi_baru || "-",
    "",
    "",
    payload.no_hp || "",
  ]);
  return responseJSON(200, "success", "Anggota Ditambahkan.");
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
          ss.getSheetByName("Master_Karyawan").getRange(i + 1, 4).setValue(payload.device_id);
        return responseJSON(200, "success", {
          nama_karyawan: data[i][1],
          client_id: payload.client_id,
          divisi: data[i][2],
          no_hp: data[i][5] || "",
          admin_phone: adminPhone,
        });
      }
    }
  }
  return responseJSON(404, "error", "User tidak ditemukan.");
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
      });
  }
  return responseJSON(200, "success", results);
}

function handleGetAllApprovals(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var logs = ss.getSheetByName("Log_Absensi").getDataRange().getValues();
  var employees = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
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
        row_index: i + 1,
      });
    }
  }
  return responseJSON(200, "success", results);
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

function handleGetFace(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Master_Karyawan")
    .getDataRange()
    .getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_karyawan))
      return responseJSON(200, "success", data[i][4]);
  }
  return responseJSON(404, "error", "None");
}

function handleRegisterFace(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan");
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_karyawan)) {
      sheet.getRange(i + 1, 5).setValue(payload.face_embedding);
      return responseJSON(200, "success", "Registered");
    }
  }
  return responseJSON(404, "error", "Fail");
}

function handleUpdateLeaveStatus(payload) {
  var config = getSemuaConfig()[payload.client_id];
  SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Log_Absensi")
    .getRange(payload.row_index, 7)
    .setValue(payload.new_status);
  return responseJSON(200, "success", "Updated");
}

function handleResetDevice(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan");
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.target_id_karyawan)) {
      sheet.getRange(i + 1, 4).setValue("");
      return responseJSON(200, "success", "Reset OK");
    }
  }
  return responseJSON(404, "error", "Not Found");
}

function handleCekStatusHariIni(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var logs = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Log_Absensi")
    .getDataRange()
    .getValues();
  var today = Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd");
  for (var i = logs.length - 1; i >= 1; i--) {
    var rowDate = Utilities.formatDate(new Date(logs[i][0]), "GMT+7", "yyyy-MM-dd");
    if (String(logs[i][1]) === String(payload.id_karyawan) && rowDate === today && logs[i][6] === "Disetujui")
      return responseJSON(200, "success", true);
  }
  return responseJSON(200, "success", false);
}

function handleGetLeaveHistory(payload) {
  var config = getSemuaConfig()[payload.client_id];
  if (!config) return responseJSON(404, "error", "Instansi tidak ditemukan.");
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var logs = ss.getSheetByName("Log_Absensi").getDataRange().getValues();
  var employees = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
  var namaMap = {};
  var hpMap = {};
  for (var j = 1; j < employees.length; j++) {
    namaMap[String(employees[j][0])] = String(employees[j][1]);
    hpMap[String(employees[j][0])] = String(employees[j][5]);
  }
  var results = [];
  var leaveKeywords = ["Sakit", "Izin", "Cuti"];
  for (var i = 1; i < logs.length; i++) {
    var idLog = String(logs[i][1]);
    var tipeLog = String(logs[i][2]);
    if (payload.is_admin === true || idLog === String(payload.id_karyawan)) {
      var isLeave = leaveKeywords.some(function (kw) { return tipeLog.indexOf(kw) !== -1; });
      if (isLeave) {
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
        });
      }
    }
  }
  return responseJSON(200, "success", results.reverse());
}

function handleGetMonthlyReport(payload) {
  var config = getSemuaConfig()[payload.client_id];
  if (!config) return responseJSON(404, "error", "Instansi tidak ditemukan.");
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var logs = ss.getSheetByName("Log_Absensi").getDataRange().getValues();
  var employees = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
  var namaMap = {};
  for (var j = 1; j < employees.length; j++) {
    namaMap[String(employees[j][0])] = String(employees[j][1]);
  }
  var results = [];
  var targetBulan = payload.bulan_tahun;
  for (var i = 1; i < logs.length; i++) {
    var logWaktu = logs[i][0];
    if (!logWaktu || logWaktu === "") continue;
    try {
      var dateObj = new Date(logWaktu);
      var mm = (dateObj.getMonth() + 1).toString().padLeft(2, "0");
      var yyyy = dateObj.getFullYear();
      var logBulan = mm + "-" + yyyy;
      if (logBulan === targetBulan) {
        var idKry = String(logs[i][1]);
        if (payload.id_karyawan_target === "SEMUA" || idKry === payload.id_karyawan_target) {
          results.push({
            waktu: Utilities.formatDate(dateObj, "GMT+7", "yyyy-MM-dd HH:mm:ss"),
            id_karyawan: idKry,
            nama: namaMap[idKry] || "Unknown",
            tipe: logs[i][2],
            status: logs[i][6],
          });
        }
      }
    } catch (e) { continue; }
  }
  return responseJSON(200, "success", results);
}

// Helpers Kept from v3.5
function toMinutes(val) {
  var s = String(val);
  if (s.indexOf(":") !== -1) {
    var p = s.split(":");
    return parseInt(p[0]) * 60 + parseInt(p[1]);
  }
  return parseInt(s) * 60;
}

function formatTime(val, def) {
  if (!val) return def;
  var s = String(val);
  if (s.indexOf(":") !== -1) return s;
  var h = parseInt(s);
  return (h < 10 ? "0" + h : h) + ":00";
}

String.prototype.padLeft = function (size, char) {
  var s = this;
  while (s.length < (size || 2)) {
    s = char + s;
  }
  return s;
};
