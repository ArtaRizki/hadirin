import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
// Tambahkan ini

// Enum untuk membedakan level akses
enum LoginRole { none, superAdmin, admin, anggota }

class AuthProvider extends ChangeNotifier {
  String? _idUser; // Bisa berisi ID Anggota ATAU Client ID (INST-xxxx)
  String? _namaUser; // Nama anggota ATAU Nama Instansi
  String? _clientId; // Disimpan dengan aman di state
  LoginRole _role = LoginRole.none; // Ubah default jadi none
  bool _isInitialized = false;

  String? get idUser => _idUser;
  String? get namaUser => _namaUser;
  String? get clientId => _clientId; // Akses dari UI
  LoginRole get role => _role;
  bool get isInitialized => _isInitialized;

  // Getter bantuan untuk kompatibilitas dengan UI yang sudah ada
  bool get isLoggedIn => _role != LoginRole.none;
  bool get isSuperAdmin => _role == LoginRole.superAdmin;
  bool get isAdmin => _role == LoginRole.admin || _role == LoginRole.superAdmin;
  bool get isAnggota => _role == LoginRole.anggota;

  // Alias untuk kompatibilitas kode lama
  String? get idAnggota => _idUser;
  String? get namaAnggota => _namaUser;
  String? get idKaryawan => _idUser;
  String? get namaKaryawan => _namaUser;
  bool get isAdminInstansi => _role == LoginRole.admin;
  bool get isAdminUmkm => _role == LoginRole.admin;

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _idUser = prefs.getString('id_user');
    _namaUser = prefs.getString('nama_user');

    // 👇 BACA CLIENT_ID DARI DEVICE 👇
    final savedClientId = prefs.getString('client_id');
    if (savedClientId != null && savedClientId.isNotEmpty) {
      _clientId = savedClientId;
    }

    // Membaca string role dari SharedPreferences
    String savedRole = prefs.getString('login_role') ?? 'none';
    _role = LoginRole.values.firstWhere(
      (e) => e.toString() == savedRole,
      orElse: () => LoginRole.none,
    );

    _isInitialized = true;
    notifyListeners();
  }

  // 👇 FUNGSI LOGIN DITAMBAH PARAMETER clientId 👇
  Future<void> login(
    String id,
    String nama,
    LoginRole role,
    String clientId,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('id_user', id.trim());
    await prefs.setString('nama_user', nama.trim());
    await prefs.setString('login_role', role.toString());
    await prefs.setString('client_id', clientId.trim()); // Simpan permanen

    _idUser = id.trim();
    _namaUser = nama.trim();
    _clientId = clientId.trim();
    _role = role;
    notifyListeners();
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _idUser = null;
    _namaUser = null;
    _clientId = null;
    _role = LoginRole.none;
    notifyListeners();
  }
}
