import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:latlong2/latlong.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/ui/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:hadirin/ui/screens/set_location_screen.dart'; // Import ini

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _namaController = TextEditingController();

  // Default jika belum pilih
  LatLng _pickedLocation = const LatLng(-7.9713634, 112.5847634);
  double _radius = 100.0;
  String _pickedAddress = "";
  bool _isLocationPicked = false; // Penanda apakah user sudah memilih lokasi

  bool _isLoading = false;
  String? _newClientId;

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  // Fungsi untuk membuka SetLocationScreen dan menunggu hasilnya
  Future<void> _bukaMapPilihLokasi() async {
    // Navigasi dengan return value berupa Map
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        // Kirim state awal (berguna jika sebelumnya sudah pilih tapi mau diubah)
        builder: (_) => SetLocationScreen(
          isSelectionMode:
              true, // Beritahu bahwa ini mode pilih, bukan update langsung
          initialLocation: _pickedLocation,
          initialRadius: _radius,
        ),
      ),
    );

    // Tangkap kembalian dari SetLocationScreen
    if (result != null && result is Map<String, dynamic>) {
      setState(() {
        _pickedLocation = result['location'] as LatLng;
        _radius = result['radius'] as double;
        _pickedAddress = result['address'] as String;
        _isLocationPicked = true;
      });
    }
  }

  void _submitDaftar() async {
    if (_namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Nama UMKM tidak boleh kosong"),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (!_isLocationPicked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Harap tentukan lokasi kantor terlebih dahulu!"),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AttendanceService().registerKlien(
      namaUmkm: _namaController.text.trim(),
      lat: _pickedLocation.latitude,
      lng: _pickedLocation.longitude,
      radius: _radius,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('office_lat', _pickedLocation.latitude);
      await prefs.setDouble('office_lng', _pickedLocation.longitude);
      await prefs.setDouble('office_radius', _radius);

      setState(() => _newClientId = result['client_id']);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FluidColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: FluidColors.onSurface),
        title: const Text(
          "Pendaftaran UMKM Baru",
          style: TextStyle(
            color: FluidColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout, color: Colors.redAccent),
            tooltip: "Keluar",
            onPressed: () {
              context.read<AuthProvider>().logout();
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
            },
          ),
        ],
      ),
      body: _newClientId != null ? _buildSuccessCard() : _buildForm(),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        const Text(
          "Detail UMKM",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: FluidColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Masukkan nama perusahaan / toko yang akan didaftarkan.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),

        TextFormField(
          controller: _namaController,
          decoration: const InputDecoration(
            labelText: "Nama UMKM / Klien",
            prefixIcon: Icon(Icons.business),
          ),
          textInputAction: TextInputAction.done,
        ),

        const SizedBox(height: 40),

        const Text(
          "Lokasi Absensi",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: FluidColors.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "Pilih titik akurat di peta untuk batas absensi.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 16),

        // CARD INDIKATOR LOKASI
        Card(
          color: FluidColors.surfaceContainerLow,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FluidRadii.md),
            side: BorderSide(
              color: _isLocationPicked
                  ? FluidColors.primary
                  : Colors.grey.shade300,
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _isLocationPicked
                              ? Icons.check_circle
                              : Icons.location_off,
                          color: _isLocationPicked
                              ? FluidColors.primary
                              : Colors.grey,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _isLocationPicked
                                ? "Lokasi Disimpan"
                                : "Belum ditentukan",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isLocationPicked) ...[
                      const SizedBox(height: 8),
                      Text(
                        _pickedAddress,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade800,
                          fontWeight: FontWeight.w500,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Lat: ${_pickedLocation.latitude.toStringAsFixed(5)}\nLng: ${_pickedLocation.longitude.toStringAsFixed(5)}",
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Radius: ${_radius.toInt()} meter",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: FluidColors.primary,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 45,
                  child: OutlinedButton.icon(
                    onPressed: _bukaMapPilihLokasi,
                    icon: const Icon(Icons.map),
                    label: Text(
                      _isLocationPicked ? "Ubah Lokasi" : "Buka Peta",
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: FluidColors.primary,
                      side: const BorderSide(color: FluidColors.primary),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FluidRadii.sm),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 40),

        SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitDaftar,
            style: ElevatedButton.styleFrom(
              backgroundColor: FluidColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(FluidRadii.sm),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : const Text(
                    "Daftarkan & Buat Database",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildSuccessCard() {
    return Center(
      child: Card(
        color: FluidColors.surfaceContainerLow,
        margin: const EdgeInsets.all(24),
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: FluidColors.primary,
                size: 80,
              ),
              const SizedBox(height: 24),
              const Text(
                "UMKM Didaftarkan!",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: FluidColors.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Berikan Client ID ini kepada klien untuk didaftarkan di aplikasi mereka:",
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey.shade600),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.symmetric(
                  vertical: 16,
                  horizontal: 20,
                ),
                decoration: BoxDecoration(
                  color: FluidColors.primaryGhost,
                  borderRadius: BorderRadius.circular(FluidRadii.sm),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _newClientId!,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 2,
                        color: FluidColors.primary,
                      ),
                    ),
                    Flexible(
                      child: IconButton(
                        icon: const Icon(Icons.copy, color: FluidColors.primary),
                        onPressed: () {
                          Clipboard.setData(ClipboardData(text: _newClientId!));
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text("Client ID disalin!"),
                              backgroundColor: FluidColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  FluidRadii.sm,
                                ),
                              ),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () {
                    _newClientId = null;
                    setState(() {});
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: FluidColors.primary,
                    side: const BorderSide(color: FluidColors.primary),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FluidRadii.sm),
                    ),
                  ),
                  child: const Text(
                    "Selesai & Kembali",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
