abstract class AppConfig {
  static const gasEndpoint = String.fromEnvironment('GAS_ENDPOINT');
  static const apiToken = String.fromEnvironment('API_TOKEN');
  static var clientId = String.fromEnvironment('CLIENT_ID'); // ← BARU

  static void validate() {
    assert(gasEndpoint.isNotEmpty, 'GAS_ENDPOINT belum di-set');
    assert(apiToken.isNotEmpty, 'API_TOKEN belum di-set');
    assert(clientId.isNotEmpty, 'CLIENT_ID belum di-set');
  }
}
