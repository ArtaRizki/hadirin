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

    final String url = Platform.isIOS
        ? "https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}"
        : "whatsapp://send?phone=$cleanNumber&text=${Uri.encodeComponent(message)}";

    final Uri uri = Uri.parse(url);

    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback ke browser jika aplikasi WA tidak terinstall (atau di iOS emulator)
        final fallbackUri = Uri.parse("https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}");
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      // Jika masih gagal, lari ke web link
      final webUri = Uri.parse("https://wa.me/$cleanNumber?text=${Uri.encodeComponent(message)}");
      await launchUrl(webUri, mode: LaunchMode.externalApplication);
    }
  }

  /// Konversi URL Google Drive ke Direct Link agar bisa ditampilkan di Image.network
  static String getDirectUrl(String originalUrl) {
    if (originalUrl.contains("drive.google.com")) {
      final fileId = _extractFileId(originalUrl);
      if (fileId != null) {
        return "https://drive.google.com/thumbnail?id=$fileId&sz=w1000";
      }
    }
    return originalUrl;
  }

  static String? _extractFileId(String url) {
    final regExp = RegExp(r"(?:id=|\/d\/)([a-zA-Z0-9_-]+)");
    final match = regExp.firstMatch(url);
    return match?.group(1);
  }
}
