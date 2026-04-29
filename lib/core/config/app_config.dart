abstract class AppConfig {
  static const gasEndpoint = String.fromEnvironment('GAS_ENDPOINT');
  static const apiToken = String.fromEnvironment('API_TOKEN');
  static const appLogo = String.fromEnvironment(
    'APP_LOGO',
    defaultValue: 'assets/icons/sdit.png',
  );
  static const appName = String.fromEnvironment(
    'APP_NAME',
    defaultValue: 'SD IT AL FAHMI',
  );

  static void validate() {
    assert(gasEndpoint.isNotEmpty, 'GAS_ENDPOINT belum di-set');
    assert(apiToken.isNotEmpty, 'API_TOKEN belum di-set');
  }
}
