import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider extends ChangeNotifier {
  String? _idKaryawan;
  String? _namaKaryawan;
  bool _isLoggedIn = false;
  bool _isInitialized = false;
  bool _isAdmin = false; // ← BARU: State untuk Admin

  String? get idKaryawan => _idKaryawan;
  String? get namaKaryawan => _namaKaryawan;
  bool get isLoggedIn => _isLoggedIn;
  bool get isInitialized => _isInitialized;
  bool get isAdmin => _isAdmin; // ← BARU: Getter untuk Admin

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _idKaryawan = prefs.getString('id_karyawan');
    _namaKaryawan = prefs.getString('nama_karyawan');
    _isAdmin = prefs.getBool('is_admin') ?? false; // ← BARU: Baca status admin

    _isLoggedIn = _idKaryawan != null && _idKaryawan!.isNotEmpty;
    _isInitialized = true;
    notifyListeners();
  }

  Future<void> login(String id, String nama) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('id_karyawan', id.trim());
    await prefs.setString('nama_karyawan', nama.trim());

    // ← BARU: Logika penentu Admin (Jika ID diawali/mengandung kata ADMIN)
    bool checkAdmin = id.trim().toUpperCase().contains('ADMIN');
    await prefs.setBool('is_admin', checkAdmin);

    _idKaryawan = id.trim();
    _namaKaryawan = nama.trim();
    _isAdmin = checkAdmin;
    _isLoggedIn = true;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _idKaryawan = null;
    _namaKaryawan = null;
    _isAdmin = false; // ← BARU: Reset admin
    _isLoggedIn = false;
    notifyListeners();
  }
}
