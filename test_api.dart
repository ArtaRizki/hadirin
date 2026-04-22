import 'dart:convert';
import 'package:http/http.dart' as http;

const endpoint = 'https://script.google.com/macros/s/AKfycbzG4Y6KPvMjKkcuB6OmUwqXGNmcg9d0x3riZlEpFGT5R7af2IgkBVLppbYR7KCP14Xq/exec';
const apiToken = 'SUPER_SECRET_UMKM001_8xZ2';

Future<http.Response> sendRequest(String action, Map<String, dynamic> payload) async {
  payload['api_token'] = apiToken;
  payload['action'] = action;
  
  var response = await http.post(
    Uri.parse(endpoint),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(payload),
  );

  if (response.statusCode == 302 || response.statusCode == 303) {
    var url = response.headers['location'];
    if (url == null) {
      final match = RegExp(r'HREF="([^"]+)"').firstMatch(response.body);
      url = match?.group(1)?.replaceAll('&amp;', '&');
    }
    if (url != null) {
      response = await http.get(Uri.parse(url));
    }
  }

  print('Action: $action');
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}\n');
  return response;
}

void main() async {
  print('--- TESTING ADMIN LOGIN ---');
  await sendRequest('get_office_config', {
    'client_id': 'INST-244385',
  });

  print('--- TESTING GET ALL KARYAWAN ---');
  await sendRequest('get_all_karyawan', {
    'client_id': 'INST-244385',
  });

  print('--- TESTING GET TODAY ATTENDANCE ---');
  await sendRequest('get_today_attendance', {
    'client_id': 'INST-244385',
  });

  print('--- TESTING ENROLL DEVICE (KARYAWAN LOGIN) ---');
  await sendRequest('enroll_device', {
    'client_id': 'INST-244385',
    'id_karyawan': 'KRY-001',
    'device_id': 'TESTING_DEVICE_ID_123',
  });
}
