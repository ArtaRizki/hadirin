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
    _pickedLocation =
        widget.initialLocation ?? const LatLng(-7.9713634, 112.5847634);
    _radius = widget.initialRadius ?? 100.0;

    if (widget.isSelectionMode) {
      _isMapReady = true;
      _getAddressFromLatLng(_pickedLocation);
    } else {
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
                "${place.street}, ${place.subLocality}, ${place.locality}";
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
      _currentAddress = displayName
          .split(',')
          .take(3)
          .join(','); // Ambil 3 segmen pertama agar tidak terlalu panjang
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
      _showSnackBar(e.toString().replaceAll("Exception: ", ""), isError: true);
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  void _simpanLokasi() async {
    if (widget.isSelectionMode) {
      Navigator.pop(context, {
        'location': _pickedLocation,
        'radius': _radius,
        'address': _currentAddress,
      });
      return;
    }

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

      _showSnackBar("Lokasi berhasil diperbarui!", isError: false);
      Navigator.pop(context);
    } else if (mounted) {
      _showSnackBar("Gagal memperbarui lokasi.", isError: true);
    }
  }

  void _showSnackBar(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline_rounded
                  : Icons.check_circle_outline_rounded,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(msg)),
          ],
        ),
        backgroundColor: isError
            ? Colors.red.shade600
            : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // Komponen pembantu untuk tombol peta (Zoom / My Location)
  Widget _buildMapButton({
    required IconData icon,
    required VoidCallback onPressed,
    bool isLoading = false,
  }) {
    return InkWell(
      onTap: isLoading ? null : onPressed,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(12.0),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: FluidColors.primary,
                ),
              )
            : Icon(icon, color: const Color(0xFF0F172A), size: 20),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMapReady) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: FluidColors.primary),
        ),
      );
    }

    final bool isKeyboardVisible =
        MediaQuery.of(context).viewInsets.bottom != 0;

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pop(context),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A),
                size: 16,
              ),
            ),
          ),
        ),
        title: Text(
          widget.isSelectionMode ? "Pilih Lokasi" : "Update Lokasi",
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: Stack(
        children: [
          // 1. LAYER PETA
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
                    color: FluidColors.primary.withOpacity(0.15),
                    borderStrokeWidth: 2,
                    borderColor: FluidColors.primary,
                    useRadiusInMeter: true,
                    radius: _radius,
                  ),
                ],
              ),
            ],
          ),

          // 2. PIN LOKASI & TOOLTIP (DI TENGAH PETA)
          if (!isKeyboardVisible && _searchResults.isEmpty)
            Align(
              alignment: Alignment.center,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tooltip Alamat
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    constraints: const BoxConstraints(maxWidth: 280),
                    child: Text(
                      _currentAddress,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Ikon Pin
                  const Padding(
                    padding: EdgeInsets.only(
                      bottom: 48.0,
                    ), // Offset agar pas di titik tengah
                    child: Icon(
                      Icons.location_on_rounded,
                      size: 48,
                      color: Colors.redAccent,
                    ),
                  ),
                ],
              ),
            ),

          // 3. SEARCH BAR & HASIL PENCARIAN (DI ATAS PETA)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.08),
                          blurRadius: 15,
                          offset: const Offset(0, 5),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: "Cari nama jalan / kota...",
                        hintStyle: TextStyle(
                          color: Colors.grey.shade400,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: FluidColors.primary,
                        ),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(
                                  Icons.cancel_rounded,
                                  color: Colors.grey,
                                  size: 20,
                                ),
                                onPressed: () {
                                  _searchController.clear();
                                  setState(() => _searchResults.clear());
                                  FocusScope.of(context).unfocus();
                                },
                              )
                            : null,
                      ),
                      onChanged: (val) {
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 800),
                          () => _searchAddress(val),
                        );
                      },
                      onSubmitted: (val) => _searchAddress(val),
                    ),
                  ),
                  if (_isSearching)
                    const Padding(
                      padding: EdgeInsets.all(16.0),
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: FluidColors.primary,
                        ),
                      ),
                    ),
                  if (_searchResults.isNotEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 15,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: ListView.separated(
                        shrinkWrap: true,
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _searchResults.length > 5
                            ? 5
                            : _searchResults.length,
                        separatorBuilder: (_, __) =>
                            Divider(height: 1, color: Colors.grey.shade100),
                        itemBuilder: (context, index) {
                          final place = _searchResults[index];
                          return ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: FluidColors.primary.withOpacity(0.1),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.location_on_rounded,
                                color: FluidColors.primary,
                                size: 18,
                              ),
                            ),
                            title: Text(
                              place['display_name'],
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            onTap: () => _onLocationSelected(
                              double.parse(place['lat']),
                              double.parse(place['lon']),
                              place['display_name'],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ),

          // 4. MAP CONTROLS (My Location & Zoom)
          if (!isKeyboardVisible && _searchResults.isEmpty)
            Positioned(
              right: 16,
              bottom: 270, // Di atas panel bawah
              child: Column(
                children: [
                  _buildMapButton(
                    icon: Icons.my_location_rounded,
                    isLoading: _isGettingLocation,
                    onPressed: _getCurrentLocation,
                  ),
                  const SizedBox(height: 12),
                  _buildMapButton(
                    icon: Icons.add_rounded,
                    onPressed: () => _mapController.move(
                      _pickedLocation,
                      _mapController.camera.zoom + 1,
                    ),
                  ),
                  const SizedBox(height: 8),
                  _buildMapButton(
                    icon: Icons.remove_rounded,
                    onPressed: () => _mapController.move(
                      _pickedLocation,
                      _mapController.camera.zoom - 1,
                    ),
                  ),
                ],
              ),
            ),

          // 5. BOTTOM SHEET PANEL (Radius & Save)
          if (!isKeyboardVisible && _searchResults.isEmpty)
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 24,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Handle bar kecil di atas (seperti laci)
                      Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Radius Absensi",
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 16,
                              color: Color(0xFF0F172A),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: FluidColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              "${_radius.toInt()} Meter",
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                color: FluidColors.primary,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 6,
                          thumbShape: const RoundSliderThumbShape(
                            enabledThumbRadius: 12,
                          ),
                          overlayShape: const RoundSliderOverlayShape(
                            overlayRadius: 24,
                          ),
                        ),
                        child: Slider(
                          value: _radius,
                          min: 20,
                          max: 500,
                          divisions: 48,
                          activeColor: FluidColors.primary,
                          inactiveColor: FluidColors.primaryGhost,
                          onChanged: (val) => setState(() => _radius = val),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _simpanLokasi,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: FluidColors.primary,
                            foregroundColor: Colors.white,
                            elevation: 4,
                            shadowColor: FluidColors.primary.withOpacity(0.4),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2.5,
                                  ),
                                )
                              : Text(
                                  widget.isSelectionMode
                                      ? "Gunakan Lokasi Ini"
                                      : "Simpan Koordinat",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 0.5,
                                  ),
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
