abstract class AppConfig {
  static const gasEndpoint = String.fromEnvironment('GAS_ENDPOINT');
  static const apiToken = String.fromEnvironment('API_TOKEN');

  static void validate() {
    assert(gasEndpoint.isNotEmpty, 'GAS_ENDPOINT belum di-set');
    assert(apiToken.isNotEmpty, 'API_TOKEN belum di-set');
  }
}
