abstract class AppConfig {
  // Gunakan baseUrl untuk Laravel API
  static const baseUrl = String.fromEnvironment(
    'BASE_URL', 
    defaultValue: 'https://strong-horses-tell.loca.lt/api'
  );

  static const apiToken = String.fromEnvironment('API_TOKEN', defaultValue: 'HADIRIN_SECRET_2024');
  static const appLogo = String.fromEnvironment('APP_LOGO', defaultValue: 'assets/icons/sdit.png');
  static const appName = String.fromEnvironment('APP_NAME', defaultValue: 'SDIT AL-FAHMI PALU');

  static void validate() {
    assert(baseUrl.isNotEmpty, 'BASE_URL belum di-set');
  }
}