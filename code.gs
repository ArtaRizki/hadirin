/**
 * HADIRIN UNIFIED BACKEND - v3.5 (Mobile API + Web Dashboard - Full Parity)
 *
 * Tanggung Jawab:
 * 1. doPost(e) - Melayani API Mobile App (Attendance, Enroll, etc.)
 * 2. doGet(e)  - Melayani Web Dashboard (UI Frontend)
 * 3. Shared Functions - Keamanan, Registry, & Data Handling
 */

// =============================================================================
// KONFIGURASI MASTER
// =============================================================================
const MASTER_API_TOKEN = "SUPER_SECRET_UMKM001_8xZ2";
const MASTER_REGISTRY_ID = "1hTh660vp0AbPn8D37Yg7XE-5HBRDXYA2xSJErORfZ3w";
const ID_TEMPLATE_SS = "1z-KQ0NqtYixVb4kNSDPay8zQL19kQMeS7xjrqyCsw64";
const ID_MASTER_FOLDER = "1y_AVJaVYWWP2ktlIJo2njCy1vL8ImWol";
const SUPER_ADMIN_PASSWORD = "HADIRIN_MASTER_2026_AHHH";

// =============================================================================
// 1. ROUTING & UI (WEB DASHBOARD)
// =============================================================================

function doGet(e) {
  var template = HtmlService.createTemplateFromFile("Index");
  return template
    .evaluate()
    .setTitle("Hadir.in Dashboard v3.5")
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
    // 1. Cek Super Admin Global (Harus pakai Password)
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

    // 2. Resolve Client Config (Case Insensitive)
    var allConfigs = getSemuaConfig();
    var lookupId = String(clientId || "")
      .trim()
      .toUpperCase();
    var config = allConfigs[lookupId];
    if (!config)
      return { success: false, message: "Kode Instansi tidak terdaftar." };

    // 3. Verifikasi di Spreadsheet Klien (Master_Karyawan)
    var ss = SpreadsheetApp.openById(config.spreadsheetId);
    var data = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();

    for (var i = 1; i < data.length; i++) {
      var rowId = String(data[i][0]).trim().toLowerCase();
      var rowNama = String(data[i][1] || "Tanpa Nama");
      var rowRole = String(data[i][2] || "Anggota");
      var searchId = id.trim().toLowerCase();

      // Sinkronisasi Mobile: Login Anggota HANYA pakai ID & ClientID
      if (rowId === searchId) {
        return {
          success: true,
          user: {
            id: rowId,
            nama: rowNama,
            role: rowRole,
            clientId: clientId,
            faceWeb: data[i][4] || "", // Kolom E (Index 4) untuk Embedding Web
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

/**
 * DAFTARKAN WAJAH VERSI WEB (Descriptor dari face-api.js)
 */
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
        sheet.getRange(i + 1, 5).setValue(descriptor); // Simpan di Kolom E (Status)
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

/**
 * SUBMIT ABSEN DARI WEB
 */
function submitAbsenWeb(payload) {
  try {
    var result = handleAbsensi(payload);
    var jsonStr = result.getContent();
    return JSON.parse(jsonStr);
  } catch (e) {
    return { code: 500, status: "error", message: e.toString() };
  }
}

/**
 * AMBIL STATISTIK DASHBOARD (Web)
 */
function getDashboardStats(clientId, id) {
  try {
    var allConfigs = getSemuaConfig();
    var lookupId = String(clientId || "").trim().toUpperCase();
    var config = allConfigs[lookupId];
    var ss = SpreadsheetApp.openById(config.spreadsheetId);
    var data = ss.getSheetByName("Log_Absensi").getDataRange().getValues();
    var sId = String(id || "").trim().toLowerCase();
    var isAdmin = (sId === "admin" || sId === clientId.toLowerCase()); 
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
      var rowStatus = String(data[i][6]);
      var rowEmpId = String(data[i][1]).trim().toLowerCase();

      rowDate.setHours(0, 0, 0, 0);
      if (rowDate.getTime() === today.getTime()) {
        if (!isAdmin && rowEmpId !== sId) continue;

        if (rowStatus === "Tepat Waktu" || rowStatus.startsWith("TL") || rowStatus.startsWith("PSW"))
          stats.present++;
        if (rowStatus.startsWith("TL")) stats.late++;
        if (["Izin", "Sakit", "Cuti"].indexOf(rowStatus) !== -1 || rowStatus === "Menunggu Approval")
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
        var rEmpId = String(data[j][1]).trim().toLowerCase();
        rDate.setHours(0, 0, 0, 0);
        var s = String(data[j][6]);
        if (rDate.getTime() === date.getTime()) {
          if (!isAdmin && rEmpId !== sId) continue;
          if (s === "Tepat Waktu" || s.startsWith("TL") || s.startsWith("PSW")) count++;
        }
      }
      stats.trendValues.push(count);
    }
    return stats;
  } catch (e) {
    return { present: 0, leave: 0, late: 0, trendLabels: [], trendValues: [] };
  }
}

/**
 * AMBIL DATA DASHBOARD LENGKAP (Web Member)
 */
function getDashboardDataWeb(clientId, id) {
  try {
    var stats = getDashboardStats(clientId, id);
    var allConfigs = getSemuaConfig();
    var config = allConfigs[clientId.toUpperCase()];
    var ss = SpreadsheetApp.openById(config.spreadsheetId);

    var schedule = getEffectiveSchedule(ss, config, id);

    // LOGIC OVERNIGHT DASHBOARD: Jika dini hari, tampilkan shift kemarin jika overnight
    var now = new Date();
    if (now.getHours() < 8) {
      var yesterday = new Date();
      yesterday.setDate(yesterday.getDate() - 1);
      var schYest = getEffectiveSchedule(ss, config, id, yesterday);
      if (!schYest.is_off && toMinutes(schYest.masuk) > toMinutes(schYest.pulang)) {
        var pulM = toMinutes(schYest.pulang);
        var curM = now.getHours() * 60 + now.getMinutes();
        if (curM < (pulM + 120)) schedule = schYest; // Toleransi 2 jam
      }
    }

    var officeRaw = ss.getSheetByName("Config_Kantor").getRange("A2:I2").getValues()[0];

    // Gunakan Jam Buka dari shift jika ada
    var openGate = formatTime(officeRaw[4], "04:00");
    var displayMasuk = schedule.masuk;
    if (schedule.shifting || schedule.is_khusus) {
      openGate = schedule.jam_masuk_mulai || openGate;
      displayMasuk = schedule.jam_masuk || schedule.masuk;
    }

    return {
      stats: stats,
      schedule: {
        shift_name: schedule.shift_name || (schedule.is_off ? "LIBUR" : "Normal"),
        masuk: displayMasuk,
        pulang: schedule.pulang,
        is_off: schedule.is_off,
        jam_masuk_mulai: openGate
      },
      office: {
        lat: officeRaw[1],
        lng: officeRaw[2],
        radius: officeRaw[3] || 100
      }
    };
  } catch (e) {
    return { error: e.toString() };
  }
}

/**
 * ABSENSI HARI INI — ADMIN VIEW (Web & Mobile)
 */
function getTodayAttendanceAdmin(clientId) {
  try {
    var allConfigs = getSemuaConfig();
    var lookupId = String(clientId || "").trim().toUpperCase();
    var config = allConfigs[lookupId];
    if (!config) throw new Error("Config not found for: " + lookupId);

    var ss = SpreadsheetApp.openById(config.spreadsheetId);
    var todayStr = Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd");

    var employees = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
    var result = [];
    var empMap = {}; 

    for (var i = 1; i < employees.length; i++) {
      if (employees[i][0] === "" || employees[i][0] === null) continue;
      var emp = {
        id: String(employees[i][0]),
        nama: String(employees[i][1] || "-"),
        bagian: String(employees[i][2] || "-"),
        masuk: null,
        pulang: null,
        status_masuk: null,
        status_pulang: null,
        tipe_izin: null,
        status_absen: "Belum Absen"
      };
      empMap[emp.id.toLowerCase()] = result.length;
      result.push(emp);
    }

    var logs = ss.getSheetByName("Log_Absensi").getDataRange().getValues();
    for (var j = 1; j < logs.length; j++) {
      var logWaktu = logs[j][0];
      if (!logWaktu) continue;
      var logDateStr = (logWaktu instanceof Date) ? Utilities.formatDate(logWaktu, "GMT+7", "yyyy-MM-dd") : String(logWaktu).substring(0, 10);
      if (logDateStr !== todayStr) continue;

      var logId = String(logs[j][1] || "").trim().toLowerCase();
      var logTipe = String(logs[j][2] || "");
      var logStatus = String(logs[j][6] || "");
      var logJam = (logWaktu instanceof Date) ? Utilities.formatDate(logWaktu, "GMT+7", "HH:mm") : String(logWaktu).substring(11, 16);

      if (!(logId in empMap)) continue;
      var idx = empMap[logId];

      if (logTipe === "Masuk") {
        result[idx].masuk = logJam;
        result[idx].status_masuk = logStatus;
        result[idx].status_absen = logStatus.startsWith("TL") ? "Terlambat" : "Hadir";
      } else if (logTipe === "Pulang") {
        result[idx].pulang = logJam;
        result[idx].status_pulang = logStatus;
      } else if (["Izin", "Sakit", "Cuti"].indexOf(logTipe) !== -1) {
        result[idx].tipe_izin = logTipe;
        result[idx].status_absen = logTipe;
      }
    }
    return result;
  } catch (e) {
    return [{ error: e.toString() }];
  }
}

function handleGetTodayAttendance(payload) {
  var clientId = String(payload.client_id || "").trim().toUpperCase();
  var results = getTodayAttendanceAdmin(clientId);
  return responseJSON(200, "success", results);
}

/**
 * AMBIL RIWAYAT ABSENSI (Web)
 */
function getAttendanceHistory(clientId, id) {
  try {
    var allConfigs = getSemuaConfig();
    var lookupId = String(clientId || "").trim().toUpperCase();
    var config = allConfigs[lookupId];
    var ss = SpreadsheetApp.openById(config.spreadsheetId);
    var sheet = ss.getSheetByName("Log_Absensi");
    var data = sheet.getDataRange().getValues();
    var history = [];
    var searchId = String(id || "").trim().toLowerCase();

    for (var i = data.length - 1; i >= 1; i--) {
      var rowId = String(data[i][1] || "").trim().toLowerCase();
      if (rowId === searchId) {
        var waktu = data[i][0];
        if (waktu instanceof Date) waktu = Utilities.formatDate(waktu, "GMT+7", "yyyy-MM-dd HH:mm:ss");
        else waktu = String(waktu || "");
        history.push({
          id: i,
          waktu: waktu,
          tipe: data[i][2] || "-",
          status: data[i][6] || "Tepat Waktu",
          keterangan: data[i][5] || "-"
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
// 2. MOBILE API (doPost)
// =============================================================================

function doPost(e) {
  var lock = LockService.getScriptLock();
  if (!lock.tryLock(60000)) return responseJSON(429, "error", "Server Busy.");
  try {
    var payload = JSON.parse(e.postData.contents);
    if (payload.api_token !== MASTER_API_TOKEN)
      return responseJSON(401, "error", "Unauthorized.");

    // Sanitasi Action
    var action = String(payload.action || "").trim().toLowerCase();

    const skipCheck = ["register_klien", "verify_super_admin"];
    if (skipCheck.indexOf(action) === -1) {
      var config = getSemuaConfig()[payload.client_id];
      if (!config || !config.spreadsheetId)
        return responseJSON(404, "error", "Kode Instansi tidak ditemukan.");
    }

    switch (action) {
      case "absen": return handleAbsensi(payload);
      case "register_klien": return handleRegisterInstansi(payload);
      case "get_history": return handleGetHistory(payload);
      case "get_office_config": return handleGetOfficeConfig(payload);
      case "update_lokasi": return handleUpdateLokasi(payload);
      case "get_shift_list":
        var resShift = getShiftSettings(payload.client_id, payload.year || 2026, payload.month || 4);
        return responseJSON(resShift.success ? 200 : 400, resShift.success ? "success" : "error", resShift);
      case "save_shifts":
        var resSaveS = saveShiftDefinitions(payload.client_id, payload.shift_list);
        return responseJSON(resSaveS.success ? 200 : 400, resSaveS.success ? "success" : "error", resSaveS.message);
      case "save_plotting":
        var resSaveP = savePlottingAssignments(payload.client_id, payload.plotting_list);
        return responseJSON(resSaveP.success ? 200 : 400, resSaveP.success ? "success" : "error", resSaveP.message);
      case "update_default_shift":
        var resUpdD = updateDefaultShift(payload.client_id, payload.id_karyawan_target, payload.new_shift_id);
        return responseJSON(resUpdD.success ? 200 : 400, resUpdD.success ? "success" : "error", resUpdD.message);
      case "update_jam_kerja": return handleUpdateJamKerja(payload);
      case "enroll_device": return handleEnrollDevice(payload);
      case "register_face": return handleRegisterFace(payload);
      case "get_face": return handleGetFace(payload);
      case "add_karyawan": return handleAddAnggota(payload);
      case "ajukan_izin": return handleAjukanIzin(payload);
      case "get_all_approvals": return responseJSON(200, "success", handleGetAllApprovals(payload));
      case "update_leave_status": return responseJSON(200, "success", handleUpdateLeaveStatus(payload));
      case "reset_device": return responseJSON(200, "success", handleResetDevice(payload));
      case "get_all_karyawan": return responseJSON(200, "success", handleGetAllAnggota(payload));
      case "cek_status_hari_ini": return handleCekStatusHariIni(payload);
      case "verify_super_admin": return handleVerifySuperAdmin(payload);
      case "get_leave_history": return handleGetLeaveHistory(payload);
      case "get_monthly_report": return handleGetMonthlyReport(payload);
      case "delete_karyawan": return responseJSON(200, "success", handleDeleteKaryawan(payload));
      case "get_today_attendance": return handleGetTodayAttendance(payload);
      default: return responseJSON(400, "error", "Action Unknown: " + action);
    }
  } catch (err) {
    return responseJSON(500, "error", err.message);
  } finally {
    lock.releaseLock();
  }
}

// =============================================================================
// 3. HANDLERS & HELPERS (Shared)
// =============================================================================

function getSemuaConfig() {
  try {
    var rows = SpreadsheetApp.openById(MASTER_REGISTRY_ID).getSheetByName("Klien").getDataRange().getValues();
    var result = {};
    for (var i = 1; i < rows.length; i++) {
      result[rows[i][0]] = { spreadsheetId: rows[i][2], folderDriveId: rows[i][3], batasJam: rows[i][4], radius: rows[i][5] };
    }
    return result;
  } catch (e) { return {}; }
}

function getEffectiveSchedule(ss, config, idKaryawan, targetDate) {
  var now = targetDate || new Date();
  var todayStr = Utilities.formatDate(now, "GMT+7", "yyyy-MM-dd");

  var sheetJadwal = ss.getSheetByName("Jadwal_Khusus");
  if (sheetJadwal) {
    var dataJadwal = sheetJadwal.getDataRange().getValues();
    for (var i = 1; i < dataJadwal.length; i++) {
      var tglCell = dataJadwal[i][0];
      if (!tglCell) continue;
      var tglStr = (tglCell instanceof Date) ? Utilities.formatDate(tglCell, "GMT+7", "yyyy-MM-dd") : String(tglCell);
      if (tglStr === todayStr) {
        return { masuk: formatTime(dataJadwal[i][1], "08:00"), pulang: formatTime(dataJadwal[i][2], "17:00"), is_khusus: true, keterangan: dataJadwal[i][3], is_off: String(dataJadwal[i][1]).toUpperCase() === "LIBUR" };
      }
    }
  }

  var sheetPlot = ss.getSheetByName("Jadwal_Shift");
  if (sheetPlot) {
    var plottingData = sheetPlot.getDataRange().getValues();
    var plottingKey = todayStr + "_" + idKaryawan;
    for (var j = 1; j < plottingData.length; j++) {
      if (String(plottingData[j][0]) === plottingKey) return getShiftDetails(ss, plottingData[j][3], config);
    }
  }

  var masterSheet = ss.getSheetByName("Master_Karyawan");
  var masterData = masterSheet.getDataRange().getValues();
  for (var k = 1; k < masterData.length; k++) {
    if (String(masterData[k][0]) === String(idKaryawan)) {
      var defaultShiftId = masterData[k][6] || "S1"; 
      return getShiftDetails(ss, defaultShiftId, config);
    }
  }

  var configData = ss.getSheetByName("Config_Kantor").getRange("A2:G2").getValues()[0];
  return { masuk: formatTime(configData[5], config.batasJam), pulang: formatTime(configData[6], "17:00"), is_khusus: false, is_off: false };
}

function getShiftDetails(ss, shiftId, config) {
  if (!shiftId || ["LIBUR", "OFF"].indexOf(String(shiftId).toUpperCase()) !== -1) {
    return { masuk: "00:00", pulang: "00:00", is_off: true, shift_name: "LIBUR" };
  }
  var sheetShift = ss.getSheetByName("Config_Shift");
  var data = sheetShift.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(shiftId)) {
      return { 
        jam_masuk_mulai: formatTime(data[i][2], "04:00"), 
        jam_masuk: formatTime(data[i][3], "08:00"),
        masuk: formatTime(data[i][4], "08:00"), 
        pulang: formatTime(data[i][5], "16:00"), 
        shift_name: data[i][1], 
        shifting: true 
      };
    }
  }
  return { jam_masuk_mulai: "04:00", jam_masuk: "08:00", masuk: "08:00", pulang: "17:00", is_off: false, shift_name: "Shift 1" };
}

function handleAbsensi(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  
  var now = new Date();
  var currentMinutes = now.getHours() * 60 + now.getMinutes();
  var schedule = getEffectiveSchedule(ss, config, payload.id_karyawan);

  // LOGIC OVERNIGHT: Menentukan apakah absen ini untuk shift kemarin atau hari ini
  if (now.getHours() < 10) { 
    var yesterday = new Date();
    yesterday.setDate(yesterday.getDate() - 1);
    var schYest = getEffectiveSchedule(ss, config, payload.id_karyawan, yesterday);
    
    var isYestOvernight = !schYest.is_off && toMinutes(schYest.masuk) > toMinutes(schYest.pulang);
    
    if (isYestOvernight) {
      if (payload.tipe_absen === "Pulang") {
        // Jika pulang di pagi hari, hampir pasti ini untuk shift malam kemarin
        schedule = schYest;
      } else if (payload.tipe_absen === "Masuk" && schedule.is_off) {
        // Jika masuk di pagi hari DAN hari ini libur, mungkin ini telat parah untuk shift kemarin
        if (currentMinutes < (toMinutes(schYest.pulang) + 240)) {
          schedule = schYest;
        }
      }
      // Jika Masuk dan hari ini TIDAK libur, biarkan pakai jadwal hari ini (prioritas shift pagi hari ini)
    }
  }

  if (schedule.is_off) return responseJSON(403, "error", "Hari ini LIBUR.");

  var configData = ss.getSheetByName("Config_Kantor").getRange("A2:I2").getValues()[0];
  var interval = parseInt(configData[7]) || 30;
  var maxTier = parseInt(configData[8]) || 0;

  var status = "Tepat Waktu";
  var masM = toMinutes(schedule.masuk);
  var pulM = toMinutes(schedule.pulang);
  var isOvernight = masM > pulM;

  if (payload.tipe_absen === "Masuk") {
    var diff = currentMinutes - masM;
    // Jika overnight dan absen dilakukan dini hari (misal jam 1 pagi untuk shift jam 6 sore)
    if (isOvernight && currentMinutes < pulM) diff += 1440; 
    
    if (diff > 0) {
      var tier = Math.ceil(diff / interval);
      if (maxTier > 0 && tier > maxTier) tier = maxTier;
      status = "TL" + tier;
    }
  } else if (payload.tipe_absen === "Pulang") {
    var diff = pulM - currentMinutes;
    // Jika overnight dan pulang sebelum tengah malam (misal jam 11 malam untuk shift yang harusnya pulang jam 5 pagi)
    if (isOvernight && currentMinutes > masM) diff += 1440;

    if (diff > 0) {
      var tier = Math.ceil(diff / interval);
      if (maxTier > 0 && tier > maxTier) tier = maxTier;
      status = "PSW" + tier;
    }
  }

  var fotoUrl = "No Photo";
  if (payload.foto_base64) {
    try {
      var folder = DriveApp.getFolderById(config.folderDriveId);
      var blob = Utilities.newBlob(Utilities.base64Decode(payload.foto_base64), "image/jpeg", "Absen_" + payload.id_karyawan + "_" + Date.now() + ".jpg");
      var file = folder.createFile(blob);
      file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
      fotoUrl = "https://docs.google.com/uc?export=view&id=" + file.getId();
    } catch (e) {}
  }

  ss.getSheetByName("Log_Absensi").appendRow([
    Utilities.formatDate(now, "GMT+7", "yyyy-MM-dd HH:mm:ss"),
    payload.id_karyawan,
    payload.tipe_absen,
    payload.lat_long,
    fotoUrl,
    "Valid",
    status
  ]);

  return responseJSON(200, "success", "Absen Berhasil (" + status + ")");
}

function handleGetAllAnggota(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan").getDataRange().getValues();
  var results = [];
  for (var i = 1; i < data.length; i++) {
    if (data[i][0] !== "") {
      results.push({ 
        id: String(data[i][0]), 
        nama: String(data[i][1]), 
        bagian: String(data[i][2] || "-"), 
        sudah_enroll: data[i][3] !== "", 
        wajah_terdaftar: !!(data[i][4] && String(data[i][4]).length > 20), 
        id_shift_default: String(data[i][6] || "S1"), 
        no_hp: String(data[i][5] || "") 
      });
    }
  }
  return results;
}

function handleGetAllApprovals(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var logs = ss.getSheetByName("Log_Absensi").getDataRange().getValues();
  var employees = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
  var namaMap = {};
  for (var j = 1; j < employees.length; j++) namaMap[String(employees[j][0])] = String(employees[j][1]);
  var results = [];
  for (var i = logs.length - 1; i >= 1; i--) {
    if (logs[i][6] === "Menunggu Approval") {
      results.push({ waktu_pengajuan: logs[i][0], id_karyawan: String(logs[i][1]), nama: namaMap[String(logs[i][1])] || "Unknown", tipe: logs[i][2], rentang: logs[i][3], foto: logs[i][4], alasan: logs[i][5], row_index: i + 1 });
    }
  }
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
  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]) === String(payload.target_id_karyawan)) {
      sheet.getRange(i + 1, 4).setValue("");
      return true;
    }
  }
  return false;
}

function handleDeleteKaryawan(payload) {
  try {
    var config = getSemuaConfig()[payload.client_id];
    var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan");
    var data = sheet.getDataRange().getValues();
    var targetId = String(payload.target_id).trim().toLowerCase();
    for (var i = 1; i < data.length; i++) {
      if (String(data[i][0]).trim().toLowerCase() === targetId) {
        sheet.deleteRow(i + 1);
        return { success: true, message: "Anggota Dihapus" };
      }
    }
    return { success: false, message: "ID tidak ditemukan" };
  } catch (e) { return { success: false, message: e.toString() }; }
}

function handleRegisterInstansi(payload) {
  var sheetRegistry = SpreadsheetApp.openById(MASTER_REGISTRY_ID).getSheetByName("Klien");
  var newInstansiId = "INST-" + Math.floor(Math.random() * 900000 + 100000);
  var ssId = DriveApp.getFileById(ID_TEMPLATE_SS).makeCopy("DB - " + payload.nama_umkm).getId();
  var folderId = DriveApp.getFolderById(ID_MASTER_FOLDER).createFolder("Assets - " + payload.nama_umkm).getId();
  var ss = SpreadsheetApp.openById(ssId);
  ss.getSheetByName("Config_Kantor").getRange("A2:I2").setValues([[payload.nama_umkm, payload.lat, payload.lng, payload.radius || 100, "'04:00", "'07:00", "'13:00", 30, 0]]);
  ss.getSheetByName("Master_Karyawan").appendRow([newInstansiId, "Admin " + payload.nama_umkm, "ADMIN", "", "", payload.admin_phone || ""]);
  sheetRegistry.appendRow([newInstansiId, payload.nama_umkm, ssId, folderId, payload.batas_jam || 7, payload.radius || 100]);
  return responseJSON(200, "success", { client_id: newInstansiId });
}

function handleUpdateJamKerja(payload) {
  var config = getSemuaConfig()[payload.client_id];
  SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Config_Kantor").getRange("E2:I2").setValues([["'"+payload.jam_masuk_mulai, "'"+payload.batas_jam_masuk, "'"+payload.jam_pulang_mulai, payload.tl_interval || 30, payload.max_tier || 0]]);
  return responseJSON(200, "success", "Updated");
}

function handleUpdateLokasi(payload) {
  var config = getSemuaConfig()[payload.client_id];
  SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Config_Kantor").getRange("B2:D2").setValues([[payload.lat, payload.lng, payload.radius]]);
  return responseJSON(200, "success", "Updated");
}

function handleEnrollDevice(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var data = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
  var targetId = String(payload.id_karyawan).trim().toLowerCase();

  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]).trim().toLowerCase() === targetId) {
      if (data[i][3] === "" || data[i][3] === payload.device_id) {
        if (data[i][3] === "") ss.getSheetByName("Master_Karyawan").getRange(i+1, 4).setValue(payload.device_id);
        return responseJSON(200, "success", {
          nama_karyawan: data[i][1],
          client_id: payload.client_id,
          divisi: data[i][2],
          no_hp: data[i][5] || "",
          admin_phone: data[1][5] || "",
          wajah_terdaftar: !!(data[i][4] && String(data[i][4]).length > 20) // Anggap terdaftar jika > 20 karakter (embedding)
        });
      }
    }
  }
  return responseJSON(404, "error", "User not found");
}

function handleRegisterFace(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var sheet = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan");
  var data = sheet.getDataRange().getValues();
  var targetId = String(payload.id_karyawan).trim().toLowerCase();

  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]).trim().toLowerCase() === targetId) {
      sheet.getRange(i + 1, 5).setValue(payload.face_embedding); // Kolom E
      return responseJSON(200, "success", "Wajah Berhasil Didaftarkan");
    }
  }
  return responseJSON(404, "error", "Karyawan tidak ditemukan");
}

function handleGetFace(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var data = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan").getDataRange().getValues();
  var targetId = String(payload.id_karyawan).trim().toLowerCase();

  for (var i = 1; i < data.length; i++) {
    if (String(data[i][0]).trim().toLowerCase() === targetId) {
      var faceData = data[i][4];
      if (!faceData || faceData === "") return responseJSON(404, "error", "Face not registered");
      return responseJSON(200, "success", faceData);
    }
  }
  return responseJSON(404, "error", "User Not Found");
}

function handleAddAnggota(payload) {
  var config = getSemuaConfig()[payload.client_id];
  SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Master_Karyawan").appendRow([payload.id_karyawan_baru, payload.nama_karyawan_baru, payload.divisi_baru || "-", "", "", payload.no_hp || "", payload.default_shift || "S1"]);
  return responseJSON(200, "success", "Added");
}

function handleAjukanIzin(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var fotoUrl = "";
  if (payload.foto_base64) {
    try {
      var folder = DriveApp.getFolderById(config.folderDriveId);
      var blob = Utilities.newBlob(Utilities.base64Decode(payload.foto_base64), "image/jpeg", "Izin_" + payload.id_karyawan + "_" + Date.now() + ".jpg");
      var file = folder.createFile(blob);
      file.setSharing(DriveApp.Access.ANYONE_WITH_LINK, DriveApp.Permission.VIEW);
      fotoUrl = "https://docs.google.com/uc?export=view&id=" + file.getId();
    } catch(e) {}
  }
  ss.getSheetByName("Log_Absensi").appendRow([Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"), payload.id_karyawan, payload.tipe_izin, payload.rentang_tanggal, fotoUrl, payload.alasan, payload.is_admin ? "Disetujui" : "Menunggu Approval"]);
  return responseJSON(200, "success", "Sent");
}

function handleGetHistory(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var logs = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Log_Absensi").getDataRange().getValues();
  var res = [];
  for (var i = 1; i < logs.length; i++) if (String(logs[i][1]) === String(payload.id_karyawan)) res.push({ waktu: logs[i][0], tipe: logs[i][2], status: logs[i][6] });
  return responseJSON(200, "success", res.reverse());
}

function handleVerifySuperAdmin(payload) {
  return payload.password === SUPER_ADMIN_PASSWORD ? responseJSON(200, "success", "OK") : responseJSON(401, "error", "Fail");
}

function handleGetOfficeConfig(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var raw = ss.getSheetByName("Config_Kantor").getRange("A2:I2").getValues()[0];
  var resp = { nama: raw[0], lat: raw[1], lng: raw[2], radius: raw[3], jam_masuk_mulai: formatTime(raw[4], "04:00"), batas_jam_masuk: formatTime(raw[5], "07:00"), jam_pulang_mulai: formatTime(raw[6], "13:00"), tl_interval: parseInt(raw[7]) || 30, max_tier: parseInt(raw[8]) || 0 };
  if (payload.id_karyawan) {
    var sch = getEffectiveSchedule(ss, config, payload.id_karyawan);
    if (sch.shifting || sch.is_khusus) {
      resp.batas_jam_masuk = sch.masuk; 
      resp.jam_masuk = sch.jam_masuk;
      resp.jam_pulang_mulai = sch.pulang;
      resp.jam_masuk_mulai = sch.jam_masuk_mulai || "04:00";
    }
    resp.is_off = sch.is_off;
    resp.shift_name = sch.shift_name || "Normal";
    
    // Sinkronisasi status wajah
    var masterData = ss.getSheetByName("Master_Karyawan").getDataRange().getValues();
    var tid = String(payload.id_karyawan).trim().toLowerCase();
    for (var i = 1; i < masterData.length; i++) {
      if (String(masterData[i][0]).trim().toLowerCase() === tid) {
        resp.wajah_terdaftar = !!(masterData[i][4] && String(masterData[i][4]).length > 20);
        break;
      }
    }
  }
  return responseJSON(200, "success", resp);
}

function handleGetLeaveHistory(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var logs = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Log_Absensi").getDataRange().getValues();
  var res = [];
  logs.forEach(r => { if (String(r[1]) === String(payload.id_karyawan) && ["Izin", "Sakit", "Cuti"].indexOf(String(r[2])) !== -1) res.push({ waktu: r[0], tipe: r[2], status: r[6] }); });
  return responseJSON(200, "success", res.reverse());
}

function handleGetMonthlyReport(payload) {
  var config = getSemuaConfig()[payload.client_id];
  var logs = SpreadsheetApp.openById(config.spreadsheetId).getSheetByName("Log_Absensi").getDataRange().getValues();
  var res = [];
  logs.slice(1).forEach(r => {
    if (!r[0]) return;
    var d = new Date(r[0]); var b = (d.getMonth()+1).toString().padStart(2,"0") + "-" + d.getFullYear();
    if (b === payload.bulan_tahun && (payload.id_karyawan_target === "SEMUA" || String(r[1]) === payload.id_karyawan_target)) {
      res.push({ waktu: Utilities.formatDate(d, "GMT+7", "yyyy-MM-dd HH:mm:ss"), id_karyawan: String(r[1]), tipe: r[2], status: r[6] });
    }
  });
  return responseJSON(200, "success", res);
}

function responseJSON(code, status, message) {
  return ContentService.createTextOutput(JSON.stringify({ code: code, status: status, message: message })).setMimeType(ContentService.MimeType.JSON);
}

function toMinutes(v) {
  if (v instanceof Date) return v.getHours() * 60 + v.getMinutes();
  var s = String(v); if (s.indexOf(":") === -1) return 0;
  var p = s.split(":"); return parseInt(p[0]) * 60 + parseInt(p[1]);
}

function formatTime(v, d) {
  if (!v) return d;
  if (v instanceof Date) {
    var h = v.getHours();
    var m = v.getMinutes();
    return (h < 10 ? "0" + h : h) + ":" + (m < 10 ? "0" + m : m);
  }
  var s = String(v);
  if (s.indexOf("T") !== -1) return s.split("T")[1].substring(0, 5);
  var match = s.match(/(\d{2}:\d{2})/);
  return match ? match[1] : s.substring(0, 5);
}

function handleCekStatusHariIni(payload) {
  return responseJSON(200, "success", false);
}

function getShiftSettings(clientId, year, month) {
  var config = getSemuaConfig()[clientId];
  var ss = SpreadsheetApp.openById(config.spreadsheetId);
  var shifts = ss.getSheetByName("Config_Shift").getDataRange().getValues().slice(1).map(r => ({ 
    id: r[0], 
    nama: r[1], 
    jam_buka: formatTime(r[2], "04:00"),
    jam_masuk: formatTime(r[3], "08:00"),
    jam_batas: formatTime(r[4], "08:00"), 
    pulang: formatTime(r[5], "16:00") 
  }));
  var plots = ss.getSheetByName("Jadwal_Shift").getDataRange().getValues();
  var plotting = {};
  var prefix = year + "-" + String(month).padStart(2, "0");
  for (var i = 1; i < plots.length; i++) {
    var tgl = (plots[i][1] instanceof Date) ? Utilities.formatDate(plots[i][1], "GMT+7", "yyyy-MM-dd") : String(plots[i][1]);
    if (tgl.startsWith(prefix)) plotting[plots[i][0]] = plots[i][3];
  }
  return { success: true, shifts: shifts, plotting: plotting };
}

function saveShiftDefinitions(clientId, list) {
  var ss = SpreadsheetApp.openById(getSemuaConfig()[clientId].spreadsheetId);
  var s = ss.getSheetByName("Config_Shift"); 
  s.clear(); 
  s.appendRow(["ID_Shift", "Nama_Shift", "Jam_Buka", "Jam_Masuk", "Jam_Batas", "Jam_Pulang"]);
  list.forEach(i => s.appendRow([i.id, i.nama, "'" + i.jam_buka, "'" + i.jam_masuk, "'" + i.jam_batas, "'" + i.pulang]));
  return { success: true };
}

function savePlottingAssignments(clientId, list) {
  var sheet = SpreadsheetApp.openById(getSemuaConfig()[clientId].spreadsheetId).getSheetByName("Jadwal_Shift");
  var existing = sheet.getDataRange().getValues();
  var map = {}; existing.forEach((r, idx) => map[r[0]] = idx + 1);
  list.forEach(p => {
    if (map[p.key_id]) sheet.getRange(map[p.key_id], 4).setValue(p.id_shift);
    else if (p.id_shift !== "") sheet.appendRow([p.key_id, "'"+p.tanggal, p.id_karyawan, p.id_shift]);
  });
  return { success: true };
}

function updateDefaultShift(clientId, id, shiftId) {
  var ss = SpreadsheetApp.openById(getSemuaConfig()[clientId].spreadsheetId);
  var sheet = ss.getSheetByName("Master_Karyawan");
  var data = sheet.getDataRange().getValues();
  for (var i = 1; i < data.length; i++) if (String(data[i][0]) === String(id)) { sheet.getRange(i+1, 7).setValue(shiftId); return { success: true }; }
  return { success: false };
}
