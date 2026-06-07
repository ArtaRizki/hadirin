import 'dart:developer' as d;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hadirin/core/config/app_config.dart';

/// Kelas dasar yang menyimpan logika HTTP bersama.
/// Semua service mewarisi kelas ini — tidak perlu duplikasi kode.
abstract class ApiClient {
  static const _timeout = Duration(seconds: 20);

  // =================================================================
  // HTTP POST + handle redirect 302/303 khas Google Apps Script
  // =================================================================
  Future<http.Response> sendRequest(
    String actionName,
    Map<String, dynamic> payload, {
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? _timeout;

    // Sembunyikan data besar dari log agar konsol tidak lag
    final logPayload = Map<String, dynamic>.from(payload);
    if (logPayload.containsKey('foto_base64') &&
        logPayload['foto_base64'].toString().isNotEmpty) {
      logPayload['foto_base64'] = '[BASE64_IMAGE_HIDDEN]';
    }
    if (logPayload.containsKey('face_embedding')) {
      logPayload['face_embedding'] = '[FACE_EMBEDDING_HIDDEN]';
    }

    d.log(
      '==== [REQUEST: $actionName] ====\n'
      'URL: ${AppConfig.gasEndpoint}\n'
      'Payload: ${jsonEncode(logPayload)}',
    );

    var response = await http
        .post(
          Uri.parse(AppConfig.gasEndpoint),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(effectiveTimeout);

    // Google Apps Script sering redirect sebelum balas JSON
    if (response.statusCode == 302 || response.statusCode == 303) {
      final redirectUrl = _extractRedirectUrl(response);
      if (redirectUrl != null) {
        d.log('==== [REDIRECT: $actionName] ==== Mengikuti URL baru...');
        response = await http
            .get(Uri.parse(redirectUrl))
            .timeout(effectiveTimeout);
      }
    }

    d.log(
      '==== [RESPONSE: $actionName] ====\n'
      'Status: ${response.statusCode}\n'
      'Body: ${response.body}',
    );

    return response;
  }

  // =================================================================
  // Parse response JSON standar { code, message }
  // =================================================================
  Map<String, dynamic> parseResponse(String body) {
    try {
      // Jika body mengandung error JS yang khas, lempar exception ramah
      if (body.contains("cannot read properties of undefined") ||
          body.contains("spreadsheetId")) {
        throw const FormatException("KODE_INSTANSI_TIDAK_VALID");
      }

      final data = jsonDecode(body) as Map<String, dynamic>;
      if (data['code'] == 200 || data['code'] == 201) {
        return {'success': true, 'message': data['message']};
      }
      throw Exception(data['message'] ?? 'Respons tidak valid dari server.');
    } on FormatException catch (e) {
      if (e.toString().contains("KODE_INSTANSI_TIDAK_VALID")) {
        throw Exception(
          "Kode Instansi tidak ditemukan atau belum terdaftar di sistem.",
        );
      }
      if (body.contains('Absen berhasil dicatat')) {
        return {'success': true, 'message': 'Absen berhasil dicatat.'};
      }
      d.log("==== FORMAT ERROR: SERVER CRASH? ====\n$body");
      throw Exception(
        "Server sedang mengalami kendala teknis. Harap hubungi Admin.",
      );
    }
  }

  // =================================================================
  // Helper: ambil URL redirect dari header atau body HTML
  // =================================================================
  String? _extractRedirectUrl(http.Response response) {
    var url = response.headers['location'];
    if (url != null) return url;
    final match = RegExp(r'HREF="([^"]+)"').firstMatch(response.body);
    return match?.group(1)?.replaceAll('&amp;', '&');
  }
}
