import 'dart:convert';
import 'package:http/http.dart' as http;

const endpoint = 'https://script.google.com/macros/s/AKfycbzG4Y6KPvMjKkcuB6OmUwqXGNmcg9d0x3riZlEpFGT5R7af2IgkBVLppbYR7KCP14Xq/exec';
const apiToken = 'SUPER_SECRET_UMKM001_8xZ2';

Future<void> main() async {
  var payload = {
    'api_token': apiToken,
    'action': 'get_office_config',
    'client_id': 'INST-244385',
    'id_karyawan': 'KRY-001'
  };
  
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

  print('Action: get_office_config with idKaryawan');
  print('Status: ${response.statusCode}');
  print('Body: ${response.body}\n');
}
