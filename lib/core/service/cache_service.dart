import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  static const _keyBanners = 'cache_banners';
  static const _keyOfficeConfig = 'cache_office_config';
  static const _keyMasterQuran = 'cache_master_quran';

  // 1. BANNERS
  static Future<void> setBanners(List<dynamic> banners) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyBanners, jsonEncode(banners));
  }

  static Future<List<dynamic>?> getBanners() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyBanners);
    if (data != null) return jsonDecode(data);
    return null;
  }

  // 2. OFFICE CONFIG
  static Future<void> setOfficeConfig(Map<String, dynamic> config) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyOfficeConfig, jsonEncode(config));
  }

  static Future<Map<String, dynamic>?> getOfficeConfig() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyOfficeConfig);
    if (data != null) return jsonDecode(data);
    return null;
  }

  // 3. MASTER QURAN
  static Future<void> setMasterQuran(Map<String, dynamic> data) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyMasterQuran, jsonEncode(data));
  }

  static Future<Map<String, dynamic>?> getMasterQuran() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyMasterQuran);
    if (data != null) return jsonDecode(data);
    return null;
  }

  // 4. APP SETTINGS
  static const _keyAppSettings = 'cache_app_settings';

  static Future<void> setAppSettings(Map<String, dynamic> settings) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyAppSettings, jsonEncode(settings));
  }

  static Future<Map<String, dynamic>?> getAppSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString(_keyAppSettings);
    if (data != null) return jsonDecode(data);
    return null;
  }

  // CLEAR ALL CACHE (saat logout)
  static Future<void> clearCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyBanners);
    await prefs.remove(_keyOfficeConfig);
    await prefs.remove(_keyMasterQuran);
    await prefs.remove(_keyAppSettings);
  }
}
