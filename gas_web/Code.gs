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
      var rowNama = String(data[i][1] || "Tanpa Nama");
      var rowRole = String(data[i][2] || "Anggota");
      var searchId = id.trim().toLowerCase();

      // Jadikan kalinggo (Kepala Desa) sebagai admin otomatis
      if (rowId.indexOf("kalinggo") !== -1 || rowNama.toLowerCase().indexOf("kalinggo") !== -1) {
        rowRole = "admin";
      }

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
    return {
      success: false,
      message: "ID Anggota tidak ditemukan di instansi ini.",
    };
  } catch (e) {
    return { success: false, message: "Server Error: " + e.toString() };
  }
}

function registerFaceWeb(clientId, id, descriptor) {
  try {
    var config = getSemuaConfig()[clientId];
    var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
      "Master_Karyawan",
    );
    var data = sheet.getDataRange().getValues();
    var searchId = id.trim().toLowerCase();
    for (var i = 1; i < data.length; i++) {
      if (String(data[i][0]).trim().toLowerCase() === searchId) {
        sheet.getRange(i + 1, 5).setValue(descriptor);
        return {
          success: true,
          message: "Pola wajah web berhasil didaftarkan!",
        };
      }
    }
    return { success: false, message: "User tidak ditemukan." };
  } catch (e) {
    return { success: false, message: e.toString() };
  }
}

function submitAbsenWeb(payload) {
  try {
    return processAction(payload);
  } catch (e) {
    return { code: 500, status: "error", message: e.toString() };
  }
}

function webApiCall(payload) {
  try {
    return processAction(payload);
  } catch (e) {
    return { code: 500, status: "error", message: e.toString() };
  }
}

function getDashboardStats(clientId, id) {
  try {
    var allConfigs = getSemuaConfig();
    var lookupId = String(clientId || "")
      .trim()
      .toUpperCase();
    var config = allConfigs[lookupId];
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
      var logWaktu = data[i][0];
      if (!logWaktu || logWaktu === "") continue;
      var rowDate = new Date(logWaktu);
      var rowStatus = String(data[i][7]);
      if (
        rowStatus === "Valid" ||
        rowStatus === "" ||
        String(data[i][6]) === "Tepat Waktu" ||
        String(data[i][6]) === "Terlambat" ||
        String(data[i][6]).toLowerCase().indexOf("izin") !== -1 ||
        ["Izin", "Sakit", "Cuti"].indexOf(String(data[i][6])) !== -1
      ) {
        rowStatus = String(data[i][6]);
      }
      rowDate.setHours(0, 0, 0, 0);
      if (rowDate.getTime() === today.getTime()) {
        if (rowStatus === "Tepat Waktu") stats.present++;
        if (rowStatus === "Terlambat") {
          stats.present++;
          stats.late++;
        }
        if (
          ["Izin", "Sakit", "Cuti"].indexOf(rowStatus) !== -1 ||
          rowStatus.toLowerCase().indexOf("izin") !== -1
        )
          stats.leave++;
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
        var rStatus = String(data[j][7]);
        if (
          rStatus === "Valid" ||
          rStatus === "" ||
          String(data[j][6]) === "Tepat Waktu" ||
          String(data[j][6]) === "Terlambat"
        ) {
          rStatus = String(data[j][6]);
        }
        if (
          rDate.getTime() === date.getTime() &&
          (rStatus === "Tepat Waktu" || rStatus === "Terlambat")
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
  var debug = [];
  try {
    var allConfigs = getSemuaConfig();
    var lookupId = String(clientId || "")
      .trim()
      .toUpperCase();
    var config = allConfigs[lookupId];
    if (!config) throw new Error("Config not found");

    var ss = SpreadsheetApp.openById(config.spreadsheetId);
    var sheet = ss.getSheetByName("Log_Absensi");
    if (!sheet) {
      var sheets = ss.getSheets();
      for (var s = 0; s < sheets.length; s++) {
        if (sheets[s].getName().trim().toLowerCase() === "log_absensi") {
          sheet = sheets[s];
          break;
        }
      }
    }
    if (!sheet) throw new Error("Sheet 'Log_Absensi' not found");

    var data = sheet.getDataRange().getValues();
    var history = [];
    var searchId = String(id).trim().toLowerCase();
    for (var i = data.length - 1; i >= 1; i--) {
      var rawId = String(data[i][8] || data[i][2] || data[i][1] || "");
      var rowId = rawId.trim().toLowerCase();

      var tStatus = String(data[i][7] || "");
      var tTipe = String(data[i][3] || "");
      var tTugas = String(data[i][8] || "");

      if (
        tStatus === "Valid" ||
        tStatus === "" ||
        String(data[i][6]) === "Tepat Waktu" ||
        String(data[i][6]) === "Terlambat" ||
        String(data[i][6]).indexOf("Disetujui") !== -1 ||
        String(data[i][6]).indexOf("Menunggu") !== -1
      ) {
        tStatus = String(data[i][6] || "");
        tTipe = String(data[i][2] || "");
        tTugas = String(data[i][7] || "");
      }
      if (tTugas === "Valid") tTugas = "";

      if (rowId === searchId || searchId === "admin") {
        history.push({
          id: i,
          waktu: data[i][0],
          tipe: tTipe || "-",
          status: tStatus || "Tepat Waktu",
          tugas: tTugas || "",
        });
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

    var result = processAction(payload);
    return responseJSON(result.code, result.status, result.message);
  } catch (err) {
    return responseJSON(500, "error", err.message);
  } finally {
    lock.releaseLock();
  }
}

function processAction(payload) {
  const skipCheck = ["register_klien", "verify_super_admin"];
  if (skipCheck.indexOf(payload.action) === -1) {
    var config = getSemuaConfig()[payload.client_id];
    if (!config || !config.spreadsheetId) {
      return {
        code: 404,
        status: "error",
        message: "Kode Instansi tidak ditemukan.",
      };
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
    case "update_karyawan":
      return handleUpdateAnggota(payload);
    case "delete_karyawan":
      return handleDeleteAnggota(payload);
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
      return { code: 400, status: "error", message: "Action Unknown." };
  }
}

function handleAbsensi(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);

  // Ambil config kantor langsung dari spreadsheet klien
  var officeData = ss
    .getSheetByName("Config_Kantor")
    .getRange("A2:G2")
    .getValues()[0];
  var officeLat = officeData[1];
  var officeLng = officeData[2];
  var officeRadius = officeData[3] || config.radius;
  var batasMasuk = officeData[5] || "08:00"; // Format HH:mm

  // 1. Validasi Radius (Jika koordinat tersedia)
  if (payload.lat_long && payload.lat_long.indexOf(",") !== -1) {
    var coords = payload.lat_long.split(",");
    var userLat = parseFloat(coords[0]);
    var userLng = parseFloat(coords[1]);

    var distance = getDistance(userLat, userLng, officeLat, officeLng);
    if (distance > officeRadius) {
      return {
        code: 400,
        status: "error",
        message:
          "Gagal! Anda berada di luar radius (" +
          Math.round(distance) +
          "m). Maksimal radius: " +
          officeRadius +
          "m.",
      };
    }
  }

  // 2. Tentukan Status (Tepat Waktu / Terlambat)
  var status = "Tepat Waktu";
  if (payload.tipe_absen === "Masuk") {
    var now = new Date();
    var currentTime = Utilities.formatDate(now, "GMT+7", "HH:mm");
    // Bandingkan string format "HH:mm"
    if (currentTime > batasMasuk) {
      status = "Terlambat";
    }
  }

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

  // Lookup nama langsung dari Master_Karyawan
  var namaKaryawan = "";
  var resolvedId = payload.id_karyawan || payload.id || "";
  var pNama = String(payload.nama || "").trim();
  
  // Jika resolvedId kosong tapi pNama ada (mungkin app lama kirim ID di field nama)
  if (!resolvedId && pNama) {
      resolvedId = pNama;
  }
  
  try {
    var masterData = ss
      .getSheetByName("Master_Karyawan")
      .getDataRange()
      .getValues();
    var searchId = String(resolvedId).trim().toLowerCase();
      
    for (var mk = 1; mk < masterData.length; mk++) {
      var mkId = String(masterData[mk][0]).trim().toLowerCase();
      var mkIdClean = mkId.replace(/[^a-z0-9]/g, "");
      var mkName = String(masterData[mk][1]).trim().toLowerCase();
      var searchIdClean = searchId.replace(/[^a-z0-9]/g, "");
      var pNamaClean = pNama ? String(pNama).toLowerCase().replace(/[^a-z0-9]/g, "") : "";
      
      if ((searchIdClean && mkIdClean === searchIdClean) || 
          mkId === searchId || 
          mkName === searchId || 
          (searchId.length > 3 && mkName.indexOf(searchId) !== -1) || 
          (pNamaClean && mkIdClean === pNamaClean) ||
          (pNama && (mkName === pNama.toLowerCase() || (pNama.length > 3 && mkName.indexOf(pNama.toLowerCase()) !== -1)))) {
        namaKaryawan = String(masterData[mk][1] || "").trim();
        // Pastikan resolvedId menggunakan ID yang benar dari sheet
        resolvedId = String(masterData[mk][0]).trim();
        break;
      }
    }
  } catch (e) {
    Logger.log("Lookup nama error: " + e.message);
  }
  
  // Jika namaKaryawan masih kosong, kita coba fallback ke payload.nama HANYA JIKA payload.nama BUKAN ID.
  if (!namaKaryawan || namaKaryawan.toLowerCase() === String(resolvedId).toLowerCase()) {
      if (pNama && pNama.toLowerCase() !== String(resolvedId).toLowerCase()) {
          namaKaryawan = pNama;
      }
  }
  
  if (!namaKaryawan) namaKaryawan = resolvedId || "Tanpa Nama";
  Logger.log(
    "Absen - ID Karyawan: " +
      payload.id_karyawan +
      " | Nama Final: " +
      namaKaryawan,
  );

  ss.getSheetByName("Log_Absensi").appendRow([
    Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"), // A - Waktu
    namaKaryawan, // B - Nama
    payload.tipe_absen, // C - Tipe Absen
    payload.lat_long, // D - GPS
    fotoUrl, // E - Foto
    "Valid", // F - Biometrik
    status, // G - Status
    payload.tugas || "", // H - Tugas
    resolvedId, // I - ID Karyawan (dipindah ke akhir)
  ]);

  return { code: 200, status: "success", message: "Absen " + status + "!" };
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

  // Lookup nama langsung dari Master_Karyawan
  var namaKaryawan = "";
  var resolvedId = payload.id_karyawan || payload.id || "";
  var pNama = String(payload.nama || "").trim();
  
  if (!resolvedId && pNama) {
      resolvedId = pNama;
  }
  
  try {
    var masterData2 = ss
      .getSheetByName("Master_Karyawan")
      .getDataRange()
      .getValues();
    var searchId2 = String(resolvedId).trim().toLowerCase();
      
    for (var mk2 = 1; mk2 < masterData2.length; mk2++) {
      var mk2Id = String(masterData2[mk2][0]).trim().toLowerCase();
      var mk2IdClean = mk2Id.replace(/[^a-z0-9]/g, "");
      var mk2Name = String(masterData2[mk2][1]).trim().toLowerCase();
      var searchId2Clean = searchId2.replace(/[^a-z0-9]/g, "");
      var pNamaClean = pNama ? String(pNama).toLowerCase().replace(/[^a-z0-9]/g, "") : "";
      
      if ((searchId2Clean && mk2IdClean === searchId2Clean) || 
          mk2Id === searchId2 || 
          mk2Name === searchId2 || 
          (searchId2.length > 3 && mk2Name.indexOf(searchId2) !== -1) || 
          (pNamaClean && mk2IdClean === pNamaClean) ||
          (pNama && (mk2Name === pNama.toLowerCase() || (pNama.length > 3 && mk2Name.indexOf(pNama.toLowerCase()) !== -1)))) {
        namaKaryawan = String(masterData2[mk2][1] || "").trim();
        resolvedId = String(masterData2[mk2][0]).trim();
        break;
      }
    }
  } catch (e) {
    Logger.log("Lookup nama izin error: " + e.message);
  }
  
  if (!namaKaryawan || namaKaryawan.toLowerCase() === String(resolvedId).toLowerCase()) {
      if (pNama && pNama.toLowerCase() !== String(resolvedId).toLowerCase()) {
          namaKaryawan = pNama;
      }
  }
  
  if (!namaKaryawan) namaKaryawan = resolvedId || "Tanpa Nama";
  Logger.log(
    "Izin - ID Karyawan: " +
      payload.id_karyawan +
      " | Nama Final: " +
      namaKaryawan,
  );

  sheet.appendRow([
    Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"), // A - Waktu
    namaKaryawan, // B - Nama
    payload.tipe_izin, // C - Tipe Izin
    payload.rentang_tanggal, // D - Rentang Tanggal
    fotoUrl, // E - Foto
    payload.alasan, // F - Alasan
    payload.is_admin ? "Disetujui" : "Menunggu Approval", // G - Status
    payload.tugas || "", // H - Tugas
    resolvedId, // I - ID Karyawan
  ]);
  return { code: 200, status: "success", message: "Sent" };
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

  return {
    code: 200,
    status: "success",
    message: { client_id: newInstansiId },
  };
}

function handleUpdateLokasi(payload) {
  var config = getSemuaConfig()[payload.client_id];
  if (!config) return responseJSON(404, "error", "Instansi tidak ditemukan.");
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
  return { code: 200, status: "success", message: "Lokasi diperbarui." };
}

function handleGetOfficeConfig(payload) {
  var config = getSemuaConfig()[payload.client_id];
  if (!config) return responseJSON(404, "error", "Instansi tidak ditemukan.");
  var data = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Config_Kantor")
    .getRange("A2:G2")
    .getValues();
  return {
    code: 200,
    status: "success",
    message: {
      nama: data[0][0],
      lat: data[0][1],
      lng: data[0][2],
      radius: data[0][3] || config.radius,
      jam_masuk_mulai: data[0][4] || "04:00",
      batas_jam_masuk: data[0][5] || "07:00",
      jam_pulang_mulai: data[0][6] || "13:00",
    },
  };
}

function handleUpdateJamKerja(payload) {
  var config = getSemuaConfig()[payload.client_id];
  if (!config) return responseJSON(404, "error", "Instansi tidak ditemukan.");
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
  return { code: 200, status: "success", message: "Jam kerja diperbarui." };
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

/**
 * HELPER: Hitung Jarak (Haversine Formula)
 */
function getDistance(lat1, lon1, lat2, lon2) {
  var R = 6371000; // Radius bumi dalam Meter
  var dLat = deg2rad(lat2 - lat1);
  var dLon = deg2rad(lon2 - lon1);
  var a =
    Math.sin(dLat / 2) * Math.sin(dLat / 2) +
    Math.cos(deg2rad(lat1)) *
      Math.cos(deg2rad(lat2)) *
      Math.sin(dLon / 2) *
      Math.sin(dLon / 2);
  var c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
  var d = R * c;
  return d;
}

function deg2rad(deg) {
  return deg * (Math.PI / 180);
}

function handleVerifySuperAdmin(payload) {
  return payload.password === SUPER_ADMIN_PASSWORD
    ? { code: 200, status: "success", message: "Verified" }
    : { code: 401, status: "error", message: "Invalid" };
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
  ]);
  return { code: 200, status: "success", message: "Anggota Ditambahkan." };
}

function handleUpdateAnggota(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Master_Karyawan",
  );
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_karyawan)) {
      sheet.getRange(i + 1, 2).setValue(payload.nama);
      sheet.getRange(i + 1, 3).setValue(payload.divisi);
      sheet.getRange(i + 1, 6).setValue(payload.no_hp);
      return {
        code: 200,
        status: "success",
        message: "Data Anggota Diperbarui.",
      };
    }
  }
  return { code: 404, status: "error", message: "Anggota tidak ditemukan." };
}

function handleDeleteAnggota(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Master_Karyawan",
  );
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_karyawan)) {
      sheet.deleteRow(i + 1);
      return { code: 200, status: "success", message: "Anggota Dihapus." };
    }
  }
  return { code: 404, status: "error", message: "Anggota tidak ditemukan." };
}

function handleEnrollDevice(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var data = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
  var adminPhone = data[1][5] || "";
  var searchId = String(payload.id_karyawan).trim().toLowerCase();
  var searchIdClean = searchId.replace(/[^a-z0-9]/g, "");
  for (var i = 1; i < data.length; i++) {
    var mkId = String(data[i][0]).trim().toLowerCase();
    var mkIdClean = mkId.replace(/[^a-z0-9]/g, "");
    var mkName = String(data[i][1]).trim().toLowerCase();
    
    if ((searchIdClean && mkIdClean === searchIdClean) || mkId === searchId || mkName === searchId || (searchId.length > 3 && mkName.indexOf(searchId) !== -1)) {
      if (data[i][3] === "" || data[i][3] === payload.device_id) {
        if (data[i][3] === "")
          ss.getSheetByName("Master_Karyawan")
            .getRange(i + 1, 4)
            .setValue(payload.device_id);
            
        var rowRole = String(data[i][2] || "Anggota");
        if (mkId.indexOf("kalinggo") !== -1 || mkName.indexOf("kalinggo") !== -1) {
            rowRole = "admin";
        }
            
        return {
          code: 200,
          status: "success",
          message: {
            id_karyawan: data[i][0],
            nama_karyawan: data[i][1],
            client_id: payload.client_id,
            divisi: data[i][2],
            no_hp: data[i][5] || "",
            admin_phone: adminPhone,
            role: rowRole
          },
        };
      }
    }
  }
  return { code: 404, status: "error", message: "User tidak ditemukan." };
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
  return { code: 200, status: "success", message: results };
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
    var statusApproval = String(logs[i][7] || logs[i][6]);
    if (statusApproval === "Menunggu Approval") {
      var idKry = String(logs[i][8] || logs[i][2] || logs[i][1]);
      var tipeLog = String(logs[i][3] || logs[i][2]);
      results.push({
        waktu_pengajuan: logs[i][0],
        id_karyawan: idKry,
        nama: namaMap[idKry] || "Unknown",
        no_hp: hpMap[idKry] || "",
        tipe: tipeLog,
        rentang: String(logs[i][4] || logs[i][3]),
        foto: String(logs[i][5] || logs[i][4]),
        alasan: String(logs[i][6] || logs[i][5]),
        tugas: String(logs[i][8] ? logs[i][7] : logs[i][7] || ""),
        row_index: i + 1,
      });
    }
  }
  return { code: 200, status: "success", message: results };
}

function handleGetHistory(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var logs = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Log_Absensi")
    .getDataRange()
    .getValues();
  var results = [];
  for (var i = 1; i < logs.length; i++) {
    var rowIdKry = String(logs[i][8] || logs[i][2] || logs[i][1]);
    if (
      rowIdKry === String(payload.id_karyawan) ||
      String(logs[i][1]) === String(payload.id_karyawan) ||
      String(logs[i][2]) === String(payload.id_karyawan)
    ) {
      results.push({
        waktu: logs[i][0],
        tipe: String(logs[i][3] || logs[i][2]),
        lat_long: String(logs[i][4] || logs[i][3]),
        foto: String(logs[i][5] || logs[i][4]),
        biometrik: String(logs[i][6] || logs[i][5]),
        status: String(logs[i][7] || logs[i][6]),
      });
    }
  }
  return { code: 200, status: "success", message: results.reverse() };
}

function handleGetFace(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Master_Karyawan")
    .getDataRange()
    .getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_karyawan))
      return { code: 200, status: "success", message: data[i][4] };
  }
  return { code: 404, status: "error", message: "None" };
}

function handleRegisterFace(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName(
    "Master_Karyawan",
  );
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.id_karyawan)) {
      sheet.getRange(i + 1, 5).setValue(payload.face_embedding);
      return { code: 200, status: "success", message: "Registered" };
    }
  }
  return { code: 404, status: "error", message: "Fail" };
}

function handleUpdateLeaveStatus(payload) {
  var config = getSemuaConfig()[payload.client_id];
  SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Log_Absensi")
    .getRange(payload.row_index, 8)
    .setValue(payload.new_status);
  return { code: 200, status: "success", message: "Status Updated" };
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
      return { code: 200, status: "success", message: "Device Reset" };
    }
  }
  return { code: 404, status: "error", message: "Not Found" };
}

function handleCekStatusHariIni(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var logs = SpreadsheetApp.openById(config.spreadsheetId)
    .getSheetByName("Log_Absensi")
    .getDataRange()
    .getValues();
  var today = new Date();
  today.setHours(0, 0, 0, 0);
  var res = { status: false };
  for (var i = logs.length - 1; i >= 1; i--) {
    try {
      var rowDate = new Date(logs[i][0]);
      rowDate.setHours(0, 0, 0, 0);
      var rowIdKry = String(logs[i][8] || logs[i][2] || logs[i][1]);
      if (
        rowDate.getTime() === today.getTime() &&
        (rowIdKry === String(payload.id_karyawan) ||
          String(logs[i][1]) === String(payload.id_karyawan) ||
          String(logs[i][2]) === String(payload.id_karyawan))
      ) {
        res.status = logs[i][7] || logs[i][6];
        break;
      }
    } catch (e) {
      continue;
    }
  }
  return { code: 200, status: "success", message: res };
}

function handleGetLeaveHistory(payload) {
  var config = getSemuaConfig()[payload.client_id];
  if (!config)
    return { code: 404, status: "error", message: "Instansi tidak ditemukan." };
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var logs = ss.getSheetByName("Log_Absensi").getDataRange().getValues();
  var employees = ss
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
  var leaveKeywords = ["Sakit", "Izin", "Cuti"];
  for (var i = 1; i < logs.length; i++) {
    var idLog = String(logs[i][8] || logs[i][2] || logs[i][1]);
    var tipeLog = String(logs[i][3] || logs[i][2]);
    if (
      payload.is_admin === true ||
      idLog === String(payload.id_karyawan) ||
      String(logs[i][1]) === String(payload.id_karyawan) ||
      String(logs[i][2]) === String(payload.id_karyawan)
    ) {
      var isLeave = leaveKeywords.some(function (kw) {
        return tipeLog.indexOf(kw) !== -1;
      });
      if (isLeave) {
        results.push({
          waktu_pengajuan: logs[i][0],
          id_karyawan: idLog,
          nama: namaMap[idLog] || "-",
          no_hp: hpMap[idLog] || "",
          tipe: tipeLog,
          rentang: String(logs[i][4] || logs[i][3]),
          foto: String(logs[i][5] || logs[i][4]),
          alasan: String(logs[i][6] || logs[i][5]),
          tugas: String(logs[i][8] ? logs[i][7] : logs[i][7] || ""),
          status: String(logs[i][7] || logs[i][6]),
        });
      }
    }
  }
  return { code: 200, status: "success", message: results.reverse() };
}

function handleGetMonthlyReport(payload) {
  var config = getSemuaConfig()[payload.client_id];
  if (!config)
    return { code: 404, status: "error", message: "Instansi tidak ditemukan." };
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var logs = ss.getSheetByName("Log_Absensi").getDataRange().getValues();
  var employees = ss
    .getSheetByName("Master_Karyawan")
    .getDataRange()
    .getValues();
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
      if (!isNaN(dateObj.getTime())) {
        var mm = ("0" + (dateObj.getMonth() + 1)).slice(-2);
        var yyyy = dateObj.getFullYear();
        var logBulan = mm + "-" + yyyy;

        if (logBulan === targetBulan) {
          var idKry = String(logs[i][8] || logs[i][2] || logs[i][1]);
          if (
            payload.id_karyawan_target === "SEMUA" ||
            idKry === payload.id_karyawan_target ||
            String(logs[i][1]) === payload.id_karyawan_target ||
            String(logs[i][2]) === payload.id_karyawan_target
          ) {
            results.push({
              waktu: Utilities.formatDate(
                dateObj,
                "GMT+7",
                "yyyy-MM-dd HH:mm:ss",
              ),
              id_karyawan: idKry,
              nama: namaMap[idKry] || "Unknown",
              tipe: String(logs[i][3] || logs[i][2]),
              status: String(logs[i][7] || logs[i][6]),
              tugas: String(logs[i][8] ? logs[i][7] : logs[i][7] || ""),
            });
          }
        }
      }
    } catch (e) {
      continue;
    }
  }
  return { code: 200, status: "success", message: results };
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

function getTodayAttendanceAdmin(clientId) {
  try {
    var config = getSemuaConfig()[clientId];
    var ss = SpreadsheetApp.openById(config.spreadsheetId);
    var logs = ss.getSheetByName("Log_Absensi").getDataRange().getValues();
    var employees = ss
      .getSheetByName("Master_Karyawan")
      .getDataRange()
      .getValues();
    var namaMap = {};
    var bagianMap = {};
    var namaMapClean = {};
    for (var j = 1; j < employees.length; j++) {
      var idEmp = String(employees[j][0]).trim().toLowerCase();
      var idEmpClean = idEmp.replace(/[^a-z0-9]/g, "");
      namaMap[idEmp] = String(employees[j][1]);
      bagianMap[idEmp] = String(employees[j][2] || "-");
      namaMapClean[idEmpClean] = String(employees[j][1]);
      bagianMap[idEmpClean] = String(employees[j][2] || "-");
    }

    var today = new Date();
    today.setHours(0, 0, 0, 0);

    var results = [];
    for (var i = 1; i < logs.length; i++) {
      var logWaktu = logs[i][0];
      if (!logWaktu || logWaktu === "") continue;

      var dateObj = new Date(logWaktu);
      if (!isNaN(dateObj.getTime())) {
        var rowDate = new Date(dateObj);
        rowDate.setHours(0, 0, 0, 0);

        if (rowDate.getTime() === today.getTime()) {
          // Deteksi format baru (9 kolom) vs format lama
          // Format baru: [Waktu, Nama, Tipe, GPS, Foto, "Valid", Status, Tugas, ID]
          var hasCol9 =
            logs[i].length >= 9 &&
            logs[i][8] !== "" &&
            logs[i][8] !== undefined &&
            logs[i][8] !== null;
          var idKry, tStatus, tTipe, tTugas;

          if (hasCol9 && String(logs[i][5]) === "Valid") {
            // Format baru: kolom F = "Valid", G = Status, H = Tugas, I = ID
            idKry = String(logs[i][8]);
            tStatus = String(logs[i][6] || "");
            tTipe = String(logs[i][2] || "");
            tTugas = String(logs[i][7] || "");
          } else {
            // Format lama atau izin: coba ambil ID dari kolom yang masuk akal
            idKry = String(logs[i][8] || "");
            tStatus = String(logs[i][6] || "");
            tTipe = String(logs[i][2] || logs[i][3] || "");
            tTugas = String(logs[i][7] || "");

            // Jika idKry kosong, coba dari nama di kolom B (fallback)
            if (!idKry || idKry === "" || idKry === "undefined") {
              idKry = String(logs[i][1] || "");
            }
          }

          if (tTugas === "Valid") tTugas = "";

          // Lookup nama dengan case-insensitive
          var lookupKey = idKry.trim().toLowerCase();
          var lookupKeyClean = lookupKey.replace(/[^a-z0-9]/g, "");
          var nama = namaMap[lookupKey] || namaMapClean[lookupKeyClean] || "";
          var bagian = bagianMap[lookupKey] || bagianMap[lookupKeyClean] || "-";

          // Jika tidak ditemukan di namaMap, gunakan kolom Nama dari log (kolom B)
          if (!nama) {
            nama = String(logs[i][1] || "Tidak Dikenal");
          }

          results.push({
            id_karyawan: idKry,
            id: idKry,
            nama: nama,
            bagian: bagian,
            tipe: tTipe || "-",
            masuk: Utilities.formatDate(dateObj, "GMT+7", "HH:mm"),
            status_absen: tStatus,
            keterangan: tTugas,
          });
        }
      }
    }
    return results;
  } catch (e) {
    return [];
  }
}

String.prototype.padLeft = function (size, char) {
  var s = this;
  while (s.length < (size || 2)) {
    s = char + s;
  }
  return s;
};

function getNamaKaryawan(ss, idKaryawan, fallbackNama) {
  Logger.log(
    "getNamaKaryawan dipanggil untuk ID: " +
      idKaryawan +
      " | Fallback: " +
      fallbackNama,
  );
  if (!idKaryawan) return fallbackNama || "";
  try {
    var data = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
    var searchId = String(idKaryawan).trim().toLowerCase();
    for (var i = 1; i < data.length; i++) {
      var rowId = String(data[i][0]).trim().toLowerCase();
      if (rowId === searchId) {
        var foundName = data[i][1] || fallbackNama || "";
        Logger.log(
          "Ditemukan kecocokan di baris " + (i + 1) + ": " + foundName,
        );
        return foundName;
      }
    }
  } catch (e) {
    Logger.log("Error getNamaKaryawan: " + e.message);
  }
  Logger.log(
    "ID tidak ditemukan di Master_Karyawan, menggunakan fallback: " +
      fallbackNama,
  );
  return fallbackNama || "";
}
