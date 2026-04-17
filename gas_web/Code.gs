/**
 * Hadirin Web Dashboard Backend (Google Apps Script)
 * 
 * Tanggung Jawab:
 * 1. Melayani Frontend (HtmlService)
 * 2. Menyediakan API internal untuk Dashboard (Login, Stats, History)
 */

function doGet(e) {
  var template = HtmlService.createTemplateFromFile('Index');
  return template.evaluate()
      .setTitle('Hadir.in Dashboard')
      .addMetaTag('viewport', 'width=device-width, initial-scale=1')
      .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

/**
 * LOGIKA LOGIN WEB
 */
function login(id, pin) {
  try {
    // 1. CARI USER DI SHEET 'AN_LIST' (Sesuai logic AdminService mobile)
    // Asumsi: Anda punya fungsi untuk memverifikasi user di script utama
    // Jika tidak, kita gunakan logika pencarian standar:
    
    // NOTE: Gantikan 'DATABASE_ID' atau gunakan SpreadsheetApp.getActive()
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var sheet = ss.getSheetByName('AN_LIST'); 
    var data = sheet.getDataRange().getValues();
    
    for (var i = 1; i < data.length; i++) {
      var rowId = data[i][0].toString(); // Kolom A: ID
      var rowPin = data[i][1].toString(); // Kolom B: PIN/Pass
      var rowNama = data[i][2].toString(); // Kolom C: Nama
      var rowRole = data[i][4].toString().toLowerCase(); // Kolom E: Role
      var rowClientId = data[i][5].toString(); // Kolom F: Client ID
      
      if (rowId === id && rowPin === pin) {
        return {
          success: true,
          user: {
            id: rowId,
            nama: rowNama,
            role: rowRole,
            clientId: rowClientId
          }
        };
      }
    }
    
    return { success: false, message: "ID atau PIN tidak terdaftar." };
  } catch (e) {
    return { success: false, message: "Error Server: " + e.toString() };
  }
}

/**
 * AMBIL STATISTIK DASHBOARD & TREN
 */
function getDashboardStats(id, clientId) {
  try {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var sheetHistory = ss.getSheetByName('LOG_ABSEN'); 
    var data = sheetHistory.getDataRange().getValues();
    
    var today = new Date();
    today.setHours(0,0,0,0);
    
    var stats = {
      present: 0,
      leave: 0,
      late: 0,
      trendLabels: [],
      trendValues: []
    };
    
    // 1. HITUNG STATS HARI INI
    for (var i = 1; i < data.length; i++) {
      var rowDate = new Date(data[i][2]); // Kolom C: Waktu
      var rowClientId = data[i][1].toString(); // Kolom B: Client ID
      var rowStatus = data[i][7].toString(); // Kolom H: Status (Hadir/Terlambat)
      
      if (rowClientId === clientId) {
        rowDate.setHours(0,0,0,0);
        if (rowDate.getTime() === today.getTime()) {
           if (rowStatus === "Hadir") stats.present++;
           if (rowStatus === "Terlambat") { stats.present++; stats.late++; }
        }
      }
    }
    
    // 2. GENERATE TREN 7 HARI TERAKHIR (Simple version)
    var days = 7;
    for (var d = days - 1; d >= 0; d--) {
      var date = new Date();
      date.setDate(date.getDate() - d);
      date.setHours(0,0,0,0);
      
      stats.trendLabels.push(date.toLocaleDateString('id-ID', { day: '2-digit', month: 'short' }));
      
      var count = 0;
      for (var j = 1; j < data.length; j++) {
        var rDate = new Date(data[j][2]);
        var rClientId = data[j][1].toString();
        rDate.setHours(0,0,0,0);
        
        if (rClientId === clientId && rDate.getTime() === date.getTime()) {
          count++;
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
 * AMBIL RIWAYAT ABSENSI
 */
function getAttendanceHistory(id, clientId) {
  try {
    var ss = SpreadsheetApp.getActiveSpreadsheet();
    var sheet = ss.getSheetByName('LOG_ABSEN');
    var data = sheet.getDataRange().getValues();
    
    var history = [];
    // Ambil 50 data terbaru
    for (var i = data.length - 1; i >= 1; i--) {
       if (data[i][1].toString() === clientId && data[i][3].toString() === id) {
         history.push({
           id: i,
           waktu: data[i][2], // Kolom C: Jam/Tgl
           tipe: data[i][6],  // Kolom G: Masuk/Pulang
           status: data[i][7] // Kolom H: Hadir/Terlambat
         });
         if (history.length >= 50) break;
       }
    }
    return history;
  } catch (e) {
    return [];
  }
}
