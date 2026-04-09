import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _idKaryawan;
  String? _namaKaryawan;
  bool _isLoggedIn = false;
  bool _isInitialized = false; // ← BARU: cegah flash ke LoginScreen

  String? get idKaryawan => _idKaryawan;
  String? get namaKaryawan => _namaKaryawan;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _idKaryawan = prefs.getString('id_karyawan');
    _namaKaryawan = prefs.getString('nama_karyawan');
    _isLoggedIn = _idKaryawan != null && _idKaryawan!.isNotEmpty;
    _isInitialized = true; // ← set setelah cek selesai
    notifyListeners();
  }

  Future<void> login(String id, String nama) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('id_karyawan', id.trim());
    await prefs.setString('nama_karyawan', nama.trim());
    _idKaryawan = id.trim();
    _namaKaryawan = nama.trim();
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _idKaryawan = null;
    _namaKaryawan = null;
    _isLoggedIn = false;
    notifyListeners();
  }
}
