import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hadirin/core/service/attendance_service.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';

class SetLocationScreen extends StatefulWidget {
  // Tambahan property untuk mendukung mode pemilihan dari RegisterScreen
  final bool isSelectionMode;
  final LatLng? initialLocation;
  final double? initialRadius;

  const SetLocationScreen({
    super.key,
    this.isSelectionMode = false,
    this.initialLocation,
    this.initialRadius,
  });

  @override
  State<SetLocationScreen> createState() => _SetLocationScreenState();
}

class _SetLocationScreenState extends State<SetLocationScreen> {
  late LatLng _pickedLocation;
  late double _radius;

  bool _isSaving = false;
  final MapController _mapController = MapController();

  final TextEditingController _searchController = TextEditingController();
  String _currentAddress = "Mencari alamat...";
  Timer? _debounce;
  bool _isSearching = false;
  bool _isGettingLocation = false;

  bool _isMapReady = false;
  List<dynamic> _searchResults = [];

  @override
  void initState() {
    super.initState();
    // Inisialisasi awal berdasarkan parameter yang dilempar
    _pickedLocation =
        widget.initialLocation ?? const LatLng(-7.9713634, 112.5847634);
    _radius = widget.initialRadius ?? 100.0;

    if (widget.isSelectionMode) {
      // Jika mode pilih, langsung render peta dengan titik bawaan
      _isMapReady = true;
      _getAddressFromLatLng(_pickedLocation);
    } else {
      // Jika mode update (dari profil), baca storage dulu
      _loadSavedLocation();
    }
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('office_lat');
    final lng = prefs.getDouble('office_lng');
    final rad = prefs.getDouble('office_radius');

    if (lat != null && lng != null) {
      _pickedLocation = LatLng(lat, lng);
      _radius = rad ?? 100.0;
    }

    if (mounted) {
      setState(() => _isMapReady = true);
    }
    _getAddressFromLatLng(_pickedLocation);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks[0];
        if (mounted) {
          setState(() {
            _currentAddress =
                "${place.street}, ${place.subLocality}, ${place.locality}, ${place.administrativeArea}";
          });
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentAddress = "Alamat tidak ditemukan";
        });
      }
    }
  }

  Future<void> _searchAddress(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults.clear();
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final url = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query&format=json&limit=5&addressdetails=1',
      );
      final response = await http.get(
        url,
        headers: {'User-Agent': 'com.mobile.hadirin'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (mounted) {
          setState(() => _searchResults = data);
        }
      }
    } catch (e) {
      log("Error searching location: $e");
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onLocationSelected(double lat, double lon, String displayName) {
    FocusScope.of(context).unfocus();
    final newLoc = LatLng(lat, lon);

    _mapController.move(newLoc, 17.0);

    setState(() {
      _pickedLocation = newLoc;
      _currentAddress = displayName;
      _searchResults.clear();
      _searchController.clear();
    });
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      bool isEnabled = await Geolocator.isLocationServiceEnabled();
      if (!isEnabled) throw Exception("Harap aktifkan GPS HP Anda.");

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Izin lokasi ditolak.");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Izin lokasi diblokir permanen.");
      }

      Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
        ),
      );

      final newLoc = LatLng(position.latitude, position.longitude);

      _mapController.moveAndRotate(newLoc, 17.0, 0.0);

      setState(() => _pickedLocation = newLoc);
      _getAddressFromLatLng(newLoc);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll("Exception: ", "")),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _simpanLokasi() async {
    // 👇 CEK MODE 👇
    // Jika diakses dari pendaftaran Admin, kembalikan saja nilainya (Pop)
    if (widget.isSelectionMode) {
      Navigator.pop(context, {
        'location': _pickedLocation,
        'radius': _radius,
        'address': _currentAddress,
      });
      return;
    }

    // Logika asli (Kirim API jika dari profil)
    setState(() => _isSaving = true);
    bool sukses = await AttendanceService().updateLokasi(
      _pickedLocation.latitude,
      _pickedLocation.longitude,
      _radius,
    );
    setState(() => _isSaving = false);

    if (sukses && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('office_lat', _pickedLocation.latitude);
      await prefs.setDouble('office_lng', _pickedLocation.longitude);
      await prefs.setDouble('office_radius', _radius);

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
    if (!_isMapReady) {
      return Scaffold(
        backgroundColor: FluidColors.background,
        body: const Center(
          child: CircularProgressIndicator(color: FluidColors.primary),
        ),
      );
    }

    final bool isKeyboardVisible =
        MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      backgroundColor: FluidColors.background,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: FluidColors.onSurface),
        title: Text(
          widget.isSelectionMode ? "Pilih Lokasi" : "Tentukan Lokasi",
          style: const TextStyle(
            color: FluidColors.onSurface,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _mapController,
            options: MapOptions(
              initialCenter: _pickedLocation,
              initialZoom: 17.0,
              onPositionChanged: (MapCamera position, bool hasGesture) {
                if (hasGesture) {
                  setState(() {
                    _pickedLocation = position.center;
                    _currentAddress = "Menyesuaikan...";
                    _searchResults.clear();
                  });

                  if (_debounce?.isActive ?? false) _debounce!.cancel();
                  _debounce = Timer(const Duration(milliseconds: 800), () {
                    _getAddressFromLatLng(position.center);
                  });
                }
              },
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'com.mobile.hadirin',
              ),
              CircleLayer(
                circles: [
                  CircleMarker(
                    point: _pickedLocation,
                    color: FluidColors.primary.withOpacity(0.2),
                    borderStrokeWidth: 2,
                    borderColor: FluidColors.primary,
                    useRadiusInMeter: true,
                    radius: _radius,
                  ),
                ],
              ),
            ],
          ),

          if (!isKeyboardVisible && _searchResults.isEmpty)
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: const [
                        BoxShadow(color: Colors.black26, blurRadius: 4),
                      ],
                    ),
                    constraints: const BoxConstraints(maxWidth: 250),
                    child: Text(
                      _currentAddress,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
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

          Column(
            children: [
              const Spacer(),
              SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (!isKeyboardVisible && _searchResults.isEmpty)
                        Column(
                          children: [
                            FloatingActionButton.small(
                              heroTag: "myLocationBtn_Loc",
                              backgroundColor: Colors.white,
                              onPressed: _isGettingLocation
                                  ? null
                                  : _getCurrentLocation,
                              child: _isGettingLocation
                                  ? const Padding(
                                      padding: EdgeInsets.all(8.0),
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: FluidColors.primary,
                                      ),
                                    )
                                  : const Icon(
                                      Icons.my_location,
                                      color: Colors.blueAccent,
                                    ),
                            ),
                            const SizedBox(height: 16),
                            FloatingActionButton.small(
                              heroTag: "zoomInBtn_Loc",
                              backgroundColor: Colors.white,
                              child: const Icon(
                                Icons.add,
                                color: FluidColors.primary,
                              ),
                              onPressed: () {
                                _mapController.move(
                                  _pickedLocation,
                                  _mapController.camera.zoom + 1,
                                );
                              },
                            ),
                            const SizedBox(height: 8),
                            FloatingActionButton.small(
                              heroTag: "zoomOutBtn_Loc",
                              backgroundColor: Colors.white,
                              child: const Icon(
                                Icons.remove,
                                color: FluidColors.primary,
                              ),
                              onPressed: () {
                                _mapController.move(
                                  _pickedLocation,
                                  _mapController.camera.zoom - 1,
                                );
                              },
                            ),
                          ],
                        ),

                      const SizedBox(height: 16),

                      Container(
                        margin: EdgeInsets.only(
                          bottom: isKeyboardVisible ? 16 : 32,
                        ),
                        decoration: BoxDecoration(
                          color: FluidColors.surfaceContainerLow,
                          borderRadius: BorderRadius.circular(FluidRadii.md),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
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
                                onChanged: (val) =>
                                    setState(() => _radius = val),
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
                                      borderRadius: BorderRadius.circular(
                                        FluidRadii.sm,
                                      ),
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
                                      : Text(
                                          widget.isSelectionMode
                                              ? "Gunakan Lokasi Ini"
                                              : "Simpan Koordinat",
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),

          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(FluidRadii.md),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _searchController,
                              decoration: InputDecoration(
                                hintText: "Cari nama jalan / kota...",
                                border: InputBorder.none,
                                prefixIcon: const Icon(Icons.search),
                                suffixIcon: _searchController.text.isNotEmpty
                                    ? IconButton(
                                        icon: const Icon(Icons.clear, size: 18),
                                        onPressed: () {
                                          _searchController.clear();
                                          setState(() {
                                            _searchResults.clear();
                                          });
                                          FocusScope.of(context).unfocus();
                                        },
                                      )
                                    : null,
                              ),
                              onChanged: (val) {
                                if (_debounce?.isActive ?? false)
                                  _debounce!.cancel();
                                _debounce = Timer(
                                  const Duration(milliseconds: 800),
                                  () {
                                    _searchAddress(val);
                                  },
                                );
                              },
                              onSubmitted: (val) => _searchAddress(val),
                            ),
                          ),
                          if (_isSearching)
                            const Padding(
                              padding: EdgeInsets.all(12.0),
                              child: SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  if (_searchResults.isNotEmpty)
                    Card(
                      elevation: 4,
                      margin: const EdgeInsets.only(top: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(FluidRadii.md),
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: EdgeInsets.zero,
                        itemCount: _searchResults.length > 5
                            ? 5
                            : _searchResults.length,
                        separatorBuilder: (context, index) =>
                            const Divider(height: 1),
                        itemBuilder: (context, index) {
                          final place = _searchResults[index];
                          return ListTile(
                            leading: const Icon(
                              Icons.location_on,
                              color: FluidColors.primary,
                            ),
                            title: Text(
                              place['display_name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13),
                            ),
                            onTap: () {
                              _onLocationSelected(
                                double.parse(place['lat']),
                                double.parse(place['lon']),
                                place['display_name'],
                              );
                            },
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
