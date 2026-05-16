import 'dart:developer' as d;
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:hadirin/core/config/app_config.dart';

/// Kelas dasar yang menyimpan logika HTTP untuk Laravel Backend.
class ApiClient {
  static const _timeout = Duration(seconds: 45);

  // =================================================================
  // HTTP POST Standar Laravel
  // =================================================================
  Future<http.Response> sendRequest(
    String endpoint,
    Map<String, dynamic> payload, {
    Duration? timeout,
  }) async {
    final effectiveTimeout = timeout ?? _timeout;
    final url = '${AppConfig.baseUrl}/$endpoint';

    // Sembunyikan data besar dari log
    final logPayload = Map<String, dynamic>.from(payload);
    if (logPayload.containsKey('foto_base64')) logPayload['foto_base64'] = '[IMAGE]';
    if (logPayload.containsKey('face_embedding')) logPayload['face_embedding'] = '[EMBEDDING]';
    if (logPayload.containsKey('face_descriptor')) logPayload['face_descriptor'] = '[DESCRIPTOR]';

    d.log('==== [REQUEST: $endpoint] ====\nURL: $url\nPayload: ${jsonEncode(logPayload)}');

    try {
      final response = await http
          .post(
            Uri.parse(url),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
              'X-Tenant-ID': payload['client_id'] ?? '', // Kirim tenant_id via Header untuk keamanan Laravel
            },
            body: jsonEncode(payload),
          )
          .timeout(effectiveTimeout);

      d.log('==== [RESPONSE: $endpoint] ====\nStatus: ${response.statusCode}\nBody: ${response.body}');

      return response;
    } catch (e) {
      d.log('==== [HTTP ERROR: $endpoint] ==== $e');
      rethrow;
    }
  }

  // =================================================================
  // Parse response JSON standar Laravel { code, message }
  // =================================================================
  Map<String, dynamic> parseResponse(String body) {
    try {
      final data = jsonDecode(body) as Map<String, dynamic>;
      
      // Handle Laravel Success (200, 201)
      if (data['code'] == 200 || data['code'] == 201 || data['status'] == 'success') {
        return {'success': true, 'message': data['message']};
      }
      
      throw Exception(data['message'] ?? 'Respons tidak valid dari server.');
    } catch (e) {
      d.log("==== PARSE ERROR ====\n$body");
      if (body.contains('<!DOCTYPE html>')) {
        throw Exception("Server Error (500). Silakan hubungi admin.");
      }
      rethrow;
    }
  }
}
