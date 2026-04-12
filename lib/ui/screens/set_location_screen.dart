import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart'; // Pengganti LatLng dari Google Maps
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';

class SetLocationScreen extends StatefulWidget {
  const SetLocationScreen({super.key});

  @override
  State<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  // Titik awal peta
  LatLng _pickedLocation = const LatLng(-7.9713634, 112.5847634);
  double _radius = 100.0;
  bool _isSaving = false;
  final MapController _mapController = MapController();

  void _simpanLokasi() async {
    setState(() => _isSaving = true);
    bool sukses = await AttendanceService().updateLokasi(
      _pickedLocation.latitude,
      _pickedLocation.longitude,
      _radius,
    );
    setState(() => _isSaving = false);

    if (sukses && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Lokasi diperbarui!"),
          backgroundColor: FluidColors.primary,
        ),
      );
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Gagal memperbarui."),
          backgroundColor: Colors.red,
        ),
      );
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
          "Tentukan Lokasi",
          style: TextStyle(
            color: FluidColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // ==========================================
          // PETA OPENSTREETMAP (Gratis)
          // ==========================================
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickedLocation,
              initialZoom: 17.0,
              // Update state koordinat saat peta digeser
              onPositionChanged: (MapCamera position, bool hasGesture) {
                setState(() => _pickedLocation = position.center);
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName:
                    'com.mobile.hadirin', // Sesuaikan package name Anda
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _pickedLocation,
                    color: FluidColors.primary.withOpacity(
                      0.2,
                    ), // Warna Emerald transparan
                    borderStrokeWidth: 2,
                    borderColor: FluidColors.primary,
                    useRadiusInMeter:
                        true, // Pastikan radius dihitung dalam meter sungguhan
                    radius: _radius,
                  ),
                ],
              ),
            ],
          ),

          // ==========================================
          // PIN CENTER (Statis di tengah layar)
          // ==========================================
          const Padding(
            padding: EdgeInsets.only(
              bottom: 40.0,
            ), // Diangkat sedikit agar ujung pin pas di tengah bidikan
            child: Icon(Icons.location_on, size: 50, color: Colors.redAccent),
          ),

          // ==========================================
          // KARTU KONTROL BAWAH (Fluid Design)
          // ==========================================
          Positioned(
            bottom: 24,
            left: 24,
            right: 24,
            child: Container(
              decoration: BoxDecoration(
                color: FluidColors.surfaceContainerLow,
                borderRadius: BorderRadius.circular(FluidRadii.md),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ), // Soft overlay shadow
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Radius: ${_radius.toInt()} meter",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: FluidColors.onSurface,
                      ),
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
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _simpanLokasi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: FluidColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(FluidRadii.sm),
                          ),
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text(
                                "Simpan Koordinat",
                                style: TextStyle(fontWeight: FontWeight.bold),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
