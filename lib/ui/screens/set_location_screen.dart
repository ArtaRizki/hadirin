import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:hadirin/core/service/attendance_service.dart';

class SetLocationScreen extends StatefulWidget {
  const SetLocationScreen({super.key});

  @override
  State<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  // Titik awal peta (Bisa disesuaikan dengan default kota Anda)
  LatLng _pickedLocation = const LatLng(-7.9713634, 112.5847634);
  double _radius = 100.0;
  bool _isSaving = false;
  GoogleMapController? _mapController;

  void _simpanLokasi() async {
    setState(() => _isSaving = true);

    bool sukses = await AttendanceService().updateLokasi(
      _pickedLocation.latitude,
      _pickedLocation.longitude,
      _radius,
    );

    setState(() => _isSaving = false);

    if (sukses) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Lokasi berhasil diperbarui!"),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Kembali ke dashboard admin setelah sukses
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Gagal memperbarui lokasi."),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Tentukan Lokasi Kantor")),
      body: Stack(
        alignment: Alignment.center,
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _pickedLocation,
              zoom: 17,
            ),
            onMapCreated: (controller) => _mapController = controller,
            // Saat map digeser, update titik lokasi yang dipilih (posisi tengah kamera)
            onCameraMove: (position) {
              setState(() {
                _pickedLocation = position.target;
              });
            },
            circles: {
              Circle(
                circleId: const CircleId("radius_kantor"),
                center: _pickedLocation,
                radius: _radius,
                fillColor: Colors.blue.withOpacity(0.2),
                strokeWidth: 2,
                strokeColor: Colors.blue,
              ),
            },
          ),

          // PIN Lokasi statis di tengah layar (mengikuti pergeseran peta)
          const Padding(
            padding: EdgeInsets.only(
              bottom: 40.0,
            ), // Angkat sedikit agar pas di tengah
            child: Icon(Icons.location_on, size: 50, color: Colors.red),
          ),

          // Panel Pengaturan Radius di bagian bawah
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: Card(
              elevation: 8,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      "Radius Absensi: ${_radius.toInt()} meter",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Slider(
                      value: _radius,
                      min: 20,
                      max: 500,
                      divisions: 48,
                      label: "${_radius.toInt()} m",
                      onChanged: (val) => setState(() => _radius = val),
                    ),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _simpanLokasi,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          foregroundColor: Colors.white,
                        ),
                        child: _isSaving
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                ),
                              )
                            : const Text("Simpan Koordinat & Radius"),
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
