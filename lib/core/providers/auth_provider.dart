import 'package:flutter/material.dart';
import 'package:hadirin/core/utils/color_utils.dart';
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
  bool _isFaceRegistered = false;
  Color _themeColor = const Color(0xFF005147); // Default Emerald Green
  String? _userPhone; // Nomor WA karyawan
  String? _adminPhone; // Nomor WA Admin Utama

  String? get idUser => _idUser;
  String? get namaUser => _namaUser;
  String? get clientId => _clientId; // Akses dari UI
  LoginRole get role => _role;
  bool get isInitialized => _isInitialized;
  bool get isFaceRegistered => _isFaceRegistered;
  Color get themeColor => _themeColor;
  String? get userPhone => _userPhone;
  String? get adminPhone => _adminPhone;

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

    if (_idUser != null) {
      _isFaceRegistered = prefs.getBool('is_face_registered_$_idUser') ?? false;
    } else {
      _isFaceRegistered = prefs.getBool('isFaceRegistered') ?? false;
    }

    // Load Theme Color
    final themeHex = prefs.getString('theme_color');
    if (themeHex != null) {
      _themeColor = ColorUtils.fromHex(themeHex);
    }

    _userPhone = prefs.getString('user_phone');
    _adminPhone = prefs.getString('admin_phone');

    _isInitialized = true;
    notifyListeners();
  }

  // 👇 FUNGSI LOGIN DITAMBAH PARAMETER clientId 👇
  Future<void> login(
    String id,
    String nama,
    LoginRole role,
    String clientId, {
    String? userPhone,
    String? adminPhone,
    bool? isFaceRegistered,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('id_user', id.trim());
    await prefs.setString('nama_user', nama.trim());
    await prefs.setString('login_role', role.toString());
    await prefs.setString('client_id', clientId.trim()); // Simpan permanen

    if (userPhone != null) await prefs.setString('user_phone', userPhone);
    if (adminPhone != null) await prefs.setString('admin_phone', adminPhone);

    _idUser = id.trim();
    _namaUser = nama.trim();
    _clientId = clientId.trim();
    _role = role;
    _userPhone = userPhone;
    _adminPhone = adminPhone;
    
    // Gunakan nilai dari server jika ada, jika tidak cek lokal
    final key = 'is_face_registered_${id.trim()}';
    if (isFaceRegistered != null) {
      _isFaceRegistered = isFaceRegistered;
      await prefs.setBool(key, isFaceRegistered);
    } else {
      _isFaceRegistered = prefs.getBool(key) ?? false;
    }
    notifyListeners();
  }

  Future<void> setFaceRegistered(bool registered) async {
    _isFaceRegistered = registered;
    final prefs = await SharedPreferences.getInstance();
    if (_idUser != null) {
      await prefs.setBool('is_face_registered_$_idUser', registered);
    }
    // Tetap simpan ke key lama untuk fallback/kompatibilitas
    await prefs.setBool('isFaceRegistered', registered);
    notifyListeners();
  }

  void updateThemeColor(String? hexString) async {
    if (hexString == null) return;
    final newColor = ColorUtils.fromHex(hexString);
    if (newColor.value != _themeColor.value) {
      _themeColor = newColor;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('theme_color', hexString);
      notifyListeners();
    }
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
