import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Enum untuk membedakan level akses
enum LoginRole { none, superAdmin, adminUmkm, karyawan }

class AuthProvider extends ChangeNotifier {
  String? _idUser; // Bisa berisi ID Karyawan ATAU Client ID (UMKM-xxxx)
  String? _namaUser; // Nama karyawan ATAU Nama UMKM
  LoginRole _role = LoginRole.adminUmkm;
  bool _isInitialized = false;

  String? get idUser => _idUser;
  String? get namaUser => _namaUser;
  LoginRole get role => _role;
  bool get isInitialized => _isInitialized;

  // Getter bantuan untuk kompatibilitas dengan UI yang sudah ada
  bool get isLoggedIn => _role != LoginRole.none;
  bool get isSuperAdmin => _role == LoginRole.superAdmin;
  bool get isAdminUmkm => _role == LoginRole.adminUmkm;
  bool get isKaryawan => _role == LoginRole.karyawan;

  // Alias untuk kompatibilitas kode lama (attendance_screen dll)
  String? get idKaryawan => _idUser;
  String? get namaKaryawan => _namaUser;
  bool get isAdmin =>
      _role == LoginRole.adminUmkm || _role == LoginRole.superAdmin;

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _idUser = prefs.getString('id_user');
    _namaUser = prefs.getString('nama_user');

    // Membaca string role dari SharedPreferences
    String savedRole = prefs.getString('login_role') ?? 'none';
    _role = LoginRole.values.firstWhere(
      (e) => e.toString() == savedRole,
      orElse: () => LoginRole.adminUmkm,
    );

    _isInitialized = true;
    notifyListeners();
  }

  // Fungsi Login Universal Baru
  Future<void> login(String id, String nama, LoginRole role) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('id_user', id.trim());
    await prefs.setString('nama_user', nama.trim());
    await prefs.setString('login_role', role.toString());

    _idUser = id.trim();
    _namaUser = nama.trim();
    _role = role;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    _idUser = null;
    _namaUser = null;
    _role = LoginRole.none;
    notifyListeners();
  }
}
