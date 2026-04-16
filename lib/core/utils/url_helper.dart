import 'package:url_launcher/url_launcher.dart';
import 'dart:io';

class UrlHelper {
  /// Membuka chat WhatsApp dengan nomor tertentu.
  /// Format nomor: "08123..." atau "628123..."
  static Future<void> launchWhatsApp({
    required String phone,
    String message = "Halo, saya menghubungi Anda dari aplikasi Hadir.in",
  }) async {
    if (phone.isEmpty) return;

    // Bersihkan karakter non-digit
    String cleanNumber = phone.replaceAll(RegExp(r'\D'), '');

    // Konversi format Indonesia (08 -> 628)
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    }

    // Gunakan tautan wa.me yang diakui secara universal (lebih stabil daripada skema khusus aplikasi)
    final String url =
        "https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}";
    final Uri uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $url';
      }
    } catch (e) {
      // Fallback: coba buka di browser sistem
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Mengonversi tautan berbagi Google Drive menjadi tautan tayangan langsung (direct view).
  /// Mendukung format: /file/d/[ID]/view, ?id=[ID], /open?id=[ID]
  static String getDirectDriveUrl(String originalUrl) {
    if (!originalUrl.contains("drive.google.com")) return originalUrl;

    String? fileId;

    // Pola 1: /file/d/[ID]/view
    if (originalUrl.contains("/file/d/")) {
      fileId = originalUrl.split("/file/d/")[1].split("/")[0].split("?")[0];
    }
    // Pola 2: /d/[ID]/view
    else if (originalUrl.contains("/d/")) {
      fileId = originalUrl.split("/d/")[1].split("/")[0].split("?")[0];
    }
    // Pola 3: ?id=[ID] atau &id=[ID]
    else if (originalUrl.contains("id=")) {
      final uri = Uri.parse(originalUrl);
      fileId = uri.queryParameters['id'];
    }

    if (fileId != null && fileId.isNotEmpty) {
      // Endpoint ekspor/view untuk menampilkan gambar langsung di Image.network
      return "https://docs.google.com/uc?export=view&id=$fileId";
    }

    return originalUrl;
  }
}
