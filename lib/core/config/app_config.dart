abstract class AppConfig {
  static String gasEndpoint = const String.fromEnvironment('GAS_ENDPOINT');
  static String apiToken = const String.fromEnvironment('API_TOKEN');

  // Daftar Cabang untuk Super Admin
  static const List<Map<String, String>> cabangs = [
    {
      'name': 'Cabang 1 (Hadirin June)',
      'endpoint': 'https://script.google.com/macros/s/AKfycbwSdR27-09J6nRF_cWvClFJDS6ZsLId81r_UjfGttSoT_UgLdKlRIWcidoayT_0J3hlWw/exec',
      'token': 'HADIRIN'
    },
    {
      'name': 'Cabang 2 (Hadirin June 2)',
      'endpoint': 'https://script.google.com/macros/s/AKfycbxjYsolh-WRyMbhkXNy63pHaZhiggu871sG-T8w8bMIpf9fUEs3MUgWnXCBedONaCIh/exec',
      'token': 'HADIRIN2'
    }
  ];

  static void validate() {
    assert(gasEndpoint.isNotEmpty, 'GAS_ENDPOINT belum di-set');
    assert(apiToken.isNotEmpty, 'API_TOKEN belum di-set');
  }
}
