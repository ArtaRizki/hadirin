import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  final endpoint = 'https://script.google.com/macros/s/AKfycbwSdR27-09J6nRF_cWvClFJDS6ZsLId81r_UjfGttSoT_UgLdKlRIWcidoayT_0J3hlWw/exec';
  final apiToken = 'HADIRIN';

  print('Memulai Testing UAT...');

  // 1. Test update_meal_config
  print('\n[1] Testing update_meal_config...');
  try {
    var response = await http.post(Uri.parse(endpoint), body: {
      'action': 'update_meal_config',
      'api_token': apiToken,
      'late_1h_deduction': '10000',
      'late_more_deduction': '50000',
      'meal_allowance': '50000',
    });
    
    // Handle redirect
    if (response.statusCode == 302 || response.statusCode == 303) {
      final location = response.headers['location'];
      if (location != null) {
        response = await http.get(Uri.parse(location));
      }
    }
    print('Status Code: ${response.statusCode}');
    print('Response: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }

  // 2. Test get_meal_deduction_report
  print('\n[2] Testing get_meal_deduction_report...');
  try {
    var response = await http.post(Uri.parse(endpoint), body: {
      'action': 'get_meal_deduction_report',
      'api_token': apiToken,
      'start_date': '2023-01-01',
      'end_date': '2026-12-31',
    });
    
    // Handle redirect
    if (response.statusCode == 302 || response.statusCode == 303) {
      final location = response.headers['location'];
      if (location != null) {
        response = await http.get(Uri.parse(location));
      }
    }
    print('Status Code: ${response.statusCode}');
    print('Response: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }

  // 3. Test get_leave_balance
  print('\n[3] Testing get_leave_balance...');
  try {
    var response = await http.post(Uri.parse(endpoint), body: {
      'action': 'get_leave_balance',
      'api_token': apiToken,
      'email': 'test@example.com',
    });
    
    // Handle redirect
    if (response.statusCode == 302 || response.statusCode == 303) {
      final location = response.headers['location'];
      if (location != null) {
        response = await http.get(Uri.parse(location));
      }
    }
    print('Status Code: ${response.statusCode}');
    print('Response: ${response.body}');
  } catch (e) {
    print('Error: $e');
  }

  print('\nTesting Selesai.');
}
