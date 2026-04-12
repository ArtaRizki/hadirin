import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Pengganti LatLng dari Google Maps
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _namaController = TextEditingController();

  // State untuk Map & Lokasi menggunakan latlong2
  LatLng _pickedLocation = const LatLng(-7.9713634, 112.5847634); // Titik awal
  double _radius = 100.0;
  final MapController _mapController = MapController();

  bool _isLoading = false;
  String? _newClientId;

  void _submitDaftar() async {
    if (_namaController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text("Nama UMKM tidak boleh kosong"),
          backgroundColor: Colors.red,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(FluidRadii.sm),
          ),
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
      setState(() => _newClientId = result['client_id']);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(FluidRadii.sm),
            ),
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
          "Masukkan nama dan tentukan titik lokasi kantor.",
          style: TextStyle(color: Colors.grey.shade600),
        ),
        const SizedBox(height: 24),

        // Input Nama UMKM
        TextFormField(
          controller: _namaController,
          decoration: const InputDecoration(
            labelText: "Nama UMKM / Klien",
            prefixIcon: Icon(Icons.business),
          ),
          textInputAction: TextInputAction.done,
        ),

        const SizedBox(height: FluidSpacing.section),
        const Text(
          "Lokasi & Radius Absensi",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: FluidColors.onSurface,
          ),
        ),
        const SizedBox(height: 16),

        // KARTU MAP INTERAKTIF (OPEN STREET MAP)
        Card(
          color: FluidColors.surfaceContainerLow,
          child: Column(
            children: [
              // Area flutter_map
              ClipRRect(
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(FluidRadii.md),
                ),
                child: SizedBox(
                  height: 300,
                  width: double.infinity,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      FlutterMap(
                        mapController: _mapController,
                        options: MapOptions(
                          initialCenter: _pickedLocation,
                          initialZoom: 16.0,
                          // Update posisi state saat map digeser
                          onPositionChanged:
                              (MapCamera position, bool hasGesture) {
                                setState(() {
                                  _pickedLocation = position.center;
                                });
                              },
                        ),
                        children: [
                          TileLayer(
                            urlTemplate:
                                'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                            userAgentPackageName:
                                'com.mobile.hadirin', // Ganti dengan nama package Anda
                          ),
                          CircleLayer(
                            circles: [
                              CircleMarker(
                                point: _pickedLocation,
                                color: FluidColors.primary.withOpacity(0.15),
                                borderStrokeWidth: 2,
                                borderColor: FluidColors.primary,
                                useRadiusInMeter:
                                    true, // Radius akurat sesuai meter
                                radius: _radius,
                              ),
                            ],
                          ),
                        ],
                      ),
                      // PIN Merah Statis di Tengah Layar
                      const Padding(
                        padding: EdgeInsets.only(bottom: 40.0),
                        child: Icon(
                          Icons.location_on,
                          size: 50,
                          color: Colors.redAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Area Kontrol Radius di bawah Peta
              Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Radius Absensi:",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: FluidColors.onSurface,
                          ),
                        ),
                        Text(
                          "${_radius.toInt()} meter",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: FluidColors.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Slider(
                      value: _radius,
                      min: 20,
                      max: 500,
                      divisions: 48,
                      activeColor: FluidColors.primary,
                      inactiveColor: FluidColors.primaryGhost,
                      onChanged: (val) => setState(() => _radius = val),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: FluidSpacing.section),

        // TOMBOL SUBMIT
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
                    IconButton(
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
                  ],
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
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
