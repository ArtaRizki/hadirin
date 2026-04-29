class TimeFormatter {
  static String format(String? val) {
    if (val == null || val == "null" || val.isEmpty) return "-";
    
    // Jika string dari Google Apps Script / Sheets berisi tanggal panjang
    // cth: "Sat Dec 30 1899 04:00:00 GMT+0707 (Waktu Indonesia Barat)"
    if (val.contains("GMT") || val.contains("1899")) {
      try {
        // Cari pola HH:mm (contoh: 04:00)
        final match = RegExp(r'\d{2}:\d{2}').firstMatch(val);
        if (match != null) {
          return match.group(0)!;
        }
      } catch (_) {
        // Fallback ke aslinya jika regex gagal
      }
    }
    
    // Jika hanya jam, misal "04:00:00", potong jadi "04:00"
    if (val.length >= 5 && RegExp(r'^\d{2}:\d{2}').hasMatch(val)) {
      return val.substring(0, 5);
    }
    
    return val;
  }
}
