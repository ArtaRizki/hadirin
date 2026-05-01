import 'dart:io';
import 'package:excel/excel.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportService {
  Future<void> generateMonthlyExcel(
    String namaInstansi,
    String bulan,
    List<dynamic> data,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Rekap Absensi'];
    excel.delete('Sheet1'); // Hapus sheet default

    // 1. Styling Header
    CellStyle headerStyle = CellStyle(
      bold: true,
      italic: false,
      fontFamily: getFontFamily(FontFamily.Arial),
    );

    // 2. Buat Header Kolom
    List<String> headers = [
      "Waktu",
      "ID Anggota",
      "Nama Anggota",
      "Tipe",
      "Status",
    ];
    for (var i = 0; i < headers.length; i++) {
      var cell = sheetObject.cell(
        CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0),
      );
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    // 3. Masukkan Data Absensi
    for (int i = 0; i < data.length; i++) {
      sheetObject.appendRow([
        TextCellValue(data[i]['waktu'].toString()),
        TextCellValue(data[i]['id_karyawan'].toString()),
        TextCellValue(data[i]['nama'].toString()),
        TextCellValue(data[i]['tipe'].toString()),
        TextCellValue(data[i]['status'].toString()),
      ]);
    }

    // 4. Simpan ke File Sementara
    var fileBytes = excel.save();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/Rekap_Absen_${namaInstansi}_$bulan.xlsx');

    await file.writeAsBytes(fileBytes!);

    // 5. Bagikan (Share) ke WhatsApp/Email
    await Share.shareXFiles([
      XFile(file.path),
    ], text: 'Laporan Absensi $namaInstansi Bulan $bulan');
  }

  // =================================================================
  // REKAP BRIEFING → EXCEL
  // =================================================================
  Future<void> generateBriefingExcel(
    String namaInstansi,
    String bulan,
    List<dynamic> data,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Rekap Briefing'];
    excel.delete('Sheet1');

    CellStyle headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Arial),
    );

    List<String> headers = ["Waktu", "ID Anggota", "Nama", "Status", "Catatan"];
    for (var i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (int i = 0; i < data.length; i++) {
      sheet.appendRow([
        TextCellValue(data[i]['waktu'].toString()),
        TextCellValue(data[i]['id_karyawan'].toString()),
        TextCellValue(data[i]['nama'].toString()),
        TextCellValue(data[i]['status'].toString()),
        TextCellValue(data[i]['catatan'].toString()),
      ]);
    }

    var fileBytes = excel.save();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/Rekap_Briefing_${namaInstansi}_$bulan.xlsx');
    await file.writeAsBytes(fileBytes!);

    await Share.shareXFiles([XFile(file.path)], text: 'Rekap Briefing $namaInstansi Bulan $bulan');
  }

  // =================================================================
  // REKAP PENGAJIAN → EXCEL
  // =================================================================
  Future<void> generatePengajianExcel(
    String namaInstansi,
    String bulan,
    List<dynamic> data,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Rekap Pengajian'];
    excel.delete('Sheet1');

    CellStyle headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Arial),
    );

    List<String> headers = ["Waktu", "ID Guru", "Nama Guru", "Kelompok", "Lokasi", "Materi"];
    for (var i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (int i = 0; i < data.length; i++) {
      sheet.appendRow([
        TextCellValue(data[i]['waktu'].toString()),
        TextCellValue(data[i]['id_guru'].toString()),
        TextCellValue(data[i]['nama_guru'].toString()),
        TextCellValue(data[i]['kelompok'].toString()),
        TextCellValue(data[i]['lokasi'].toString()),
        TextCellValue(data[i]['materi'].toString()),
      ]);
    }

    var fileBytes = excel.save();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/Rekap_Pengajian_${namaInstansi}_$bulan.xlsx');
    await file.writeAsBytes(fileBytes!);

    await Share.shareXFiles([XFile(file.path)], text: 'Rekap Pengajian $namaInstansi Bulan $bulan');
  }

  // =================================================================
  // REKAP KEGIATAN → EXCEL
  // =================================================================
  Future<void> generateKegiatanExcel(
    String namaInstansi,
    String bulan,
    List<dynamic> data,
  ) async {
    var excel = Excel.createExcel();
    Sheet sheet = excel['Rekap Kegiatan'];
    excel.delete('Sheet1');

    CellStyle headerStyle = CellStyle(
      bold: true,
      fontFamily: getFontFamily(FontFamily.Arial),
    );

    List<String> headers = ["Waktu", "Kegiatan", "ID Anggota", "Nama", "Status"];
    for (var i = 0; i < headers.length; i++) {
      var cell = sheet.cell(CellIndex.indexByColumnRow(columnIndex: i, rowIndex: 0));
      cell.value = TextCellValue(headers[i]);
      cell.cellStyle = headerStyle;
    }

    for (int i = 0; i < data.length; i++) {
      sheet.appendRow([
        TextCellValue(data[i]['waktu'].toString()),
        TextCellValue(data[i]['nama_kegiatan'].toString()),
        TextCellValue(data[i]['id_karyawan'].toString()),
        TextCellValue(data[i]['nama'].toString()),
        TextCellValue(data[i]['status'].toString()),
      ]);
    }

    var fileBytes = excel.save();
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/Rekap_Kegiatan_${namaInstansi}_$bulan.xlsx');
    await file.writeAsBytes(fileBytes!);

    await Share.shareXFiles([XFile(file.path)], text: 'Rekap Kegiatan $namaInstansi Bulan $bulan');
  }
}
