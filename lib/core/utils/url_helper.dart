import 'package:url_launcher/url_launcher.dart';
import 'package:hadirin/core/config/app_config.dart';

class UrlHelper {
  /// Membuka chat WhatsApp dengan nomor tertentu.
  /// Format nomor: "08123...", "628123...", atau "8123..."
  static Future<void> launchWhatsApp({
    required String phone,
    String message = "Halo, saya menghubungi Anda dari aplikasi ${AppConfig.appName}",
  }) async {
    if (phone.isEmpty) return;

    // Bersihkan karakter non-digit
    String cleanNumber = phone.replaceAll(RegExp(r'\D'), '');

    // Konversi format Indonesia
    // 08 -> 628
    if (cleanNumber.startsWith('0')) {
      cleanNumber = '62${cleanNumber.substring(1)}';
    }
    // 8 -> 628 (Jika user input tanpa 0 di depan)
    else if (cleanNumber.startsWith('8')) {
      cleanNumber = '62$cleanNumber';
    }

    // Gunakan tautan wa.me yang diakui secara universal
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
      // Fallback
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  /// Memastikan nomor HP memiliki awalan '62' untuk keperluan tampilan & WhatsApp.
  /// Misal: "813..." -> "62813...", "0813..." -> "62813..."
  static String formatPhoneNumber(String phone) {
    if (phone.isEmpty) return phone;
    String clean = phone.replaceAll(RegExp(r'\D'), '');
    if (clean.startsWith('8')) {
      return '62$clean';
    } else if (clean.startsWith('0')) {
      return '62${clean.substring(1)}';
    }
    return phone;
  }

  /// Mengonversi tautan berbagi Google Drive menjadi tautan tayangan langsung (direct view),
  /// serta mendukung penanganan path relatif dan pencocokan domain API.
  static String getDirectDriveUrl(String originalUrl) {
    if (originalUrl.isEmpty) return originalUrl;

    // Jika path relatif, misal: /storage/banners/... atau storage/banners/...
    if (originalUrl.startsWith("/") || originalUrl.startsWith("storage/")) {
      final String cleanPath = originalUrl.startsWith("/") ? originalUrl : "/$originalUrl";
      try {
        final uri = Uri.parse(AppConfig.baseUrl);
        final host = "${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}";
        return "$host$cleanPath";
      } catch (_) {
        return originalUrl;
      }
    }

    if (!originalUrl.contains("drive.google.com")) {
      // Jika absolute tapi menggunakan domain localhost, 127.0.0.1, atau localtunnel (.loca.lt) yang berbeda dengan domain saat ini
      if (originalUrl.startsWith("http://") || originalUrl.startsWith("https://")) {
        try {
          final currentUri = Uri.parse(AppConfig.baseUrl);
          final currentHost = "${currentUri.scheme}://${currentUri.host}${currentUri.hasPort ? ':${currentUri.port}' : ''}";
          
          final origUri = Uri.parse(originalUrl);
          if (origUri.host == "localhost" || origUri.host == "127.0.0.1" || origUri.host.contains(".loca.lt") || origUri.host != currentUri.host) {
            return originalUrl.replaceFirst("${origUri.scheme}://${origUri.host}${origUri.hasPort ? ':${origUri.port}' : ''}", currentHost);
          }
        } catch (_) {}
      }
      return originalUrl;
    }

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
      try {
        final uri = Uri.parse(originalUrl);
        fileId = uri.queryParameters['id'];
      } catch (_) {}
    }

    if (fileId != null && fileId.isNotEmpty) {
      // Endpoint ekspor/view untuk menampilkan gambar langsung di Image.network
      return "https://docs.google.com/uc?export=view&id=$fileId";
    }

    return originalUrl;
  }
}
