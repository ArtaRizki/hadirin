import 'dart:async';
import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:hadirin/core/service/admin_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:provider/provider.dart';
import 'package:hadirin/core/providers/auth_provider.dart';

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

  // SOLUSI UTAMA: Tambahkan FocusNode agar focus tidak hilang saat rebuild
  final FocusNode _searchFocusNode = FocusNode();

  String _currentAddress = "Mencari alamat...";
  Timer? _debounce;
  bool _isSearching = false;
  bool _isGettingLocation = false;
  bool _isMapReady = false;
  double _currentRotation = 0.0;
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
    _searchFocusNode.dispose(); // Jangan lupa di-dispose
    super.dispose();
  }

  // --- Fungsi API & Logika Tetap Sama ---

  Future<void> _loadSavedLocation() async {
    final prefs = await SharedPreferences.getInstance();
    final lat = prefs.getDouble('office_lat');
    final lng = prefs.getDouble('office_lng');
    final rad = prefs.getDouble('office_radius');
    if (lat != null && lng != null) {
      _pickedLocation = LatLng(lat, lng);
      _radius = rad ?? 100.0;
    }
    if (mounted) setState(() => _isMapReady = true);
    _getAddressFromLatLng(_pickedLocation);
  }

  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty && mounted) {
        Placemark place = placemarks[0];
        setState(() {
          _currentAddress =
              "${place.street}, ${place.subLocality}, ${place.locality}";
        });
      }
    } catch (e) {
      if (mounted) setState(() => _currentAddress = "Alamat tidak ditemukan");
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
      if (response.statusCode == 200 && mounted) {
        setState(() => _searchResults = json.decode(response.body) as List);
      }
    } catch (e) {
      log("Search error: $e");
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onLocationSelected(double lat, double lon, String displayName) {
    _searchFocusNode.unfocus(); // Tutup keyboard saat lokasi dipilih
    final newLoc = LatLng(lat, lon);
    _mapController.move(newLoc, 17.0);
    setState(() {
      _pickedLocation = newLoc;
      _currentAddress = displayName.split(',').take(3).join(',');
      _searchResults.clear();
      _searchController.clear();
    });
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
    final auth = context.read<AuthProvider>();
    bool sukses = await AdminService().updateLokasi(
      auth.clientId ?? "",
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
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
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
      log("GPS error: $e");
    } finally {
      if (mounted) setState(() => _isGettingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_isMapReady)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    // Deteksi keyboard aktif menggunakan viewInsets
    final double keyboardHeight = MediaQuery.of(context).viewInsets.bottom;
    final bool isKeyboardVisible = keyboardHeight > 0;

    return Scaffold(
      backgroundColor: Colors.white,
      // SOLUSI: Set false agar elemen tidak bergeser saat keyboard muncul
      resizeToAvoidBottomInset: false,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text(
          widget.isSelectionMode ? "Pilih Lokasi" : "Update Lokasi",
          style: const TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                // 1. LAYER PETA (Paling Bawah)
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
                          _currentRotation =
                              position.rotation; // ← TAMBAHKAN INI
                        });
                        if (_debounce?.isActive ?? false) _debounce!.cancel();
                        _debounce = Timer(
                          const Duration(milliseconds: 800),
                          () => _getAddressFromLatLng(position.center),
                        );
                      }
                    },
                  ),
                  children: [
                    TileLayer(
                      urlTemplate:
                          'https://{s}.basemaps.cartocdn.com/rastertiles/voyager/{z}/{x}/{y}.png',
                      subdomains: const ['a', 'b', 'c', 'd'],
                      userAgentPackageName: 'com.mobile.hadirin',
                      maxZoom: 19,
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
 
                // Atribusi OSM (Penting untuk legalitas)
                Positioned(
                  bottom: 6,
                  left: 6,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Text(
                      "© OpenStreetMap",
                      style: TextStyle(
                        fontSize: 9,
                        color: Colors.black54,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                // 2. PIN CENTRAL (Hanya muncul jika tidak sedang mencari di list)
                if (_searchResults.isEmpty)
                  Center(
                    child: Transform.translate(
                      // Geser Y ke atas sejauh 22 (sedikit lebih rendah dari 24)
                      // agar ujung lancip pin tepat di tengah lingkaran
                      offset: const Offset(0, -22),
                      child: const Icon(
                        Icons.location_on_rounded,
                        size: 48,
                        color: Colors.redAccent,
                      ),
                    ),
                  ),

                // 3. UI SEARCH BAR (Diposisikan paling atas)
                Positioned(
                  top: 16,
                  left: 16,
                  right: 16,
                  child: Column(
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 10,
                              offset: Offset(0, 4),
                            ),
                          ],
                        ),
                        child: TextField(
                          controller: _searchController,
                          focusNode:
                              _searchFocusNode, // TAUTKAN FOCUSNODE DI SINI
                          decoration: InputDecoration(
                            hintText: "Cari nama jalan / kota...",
                            prefixIcon: const Icon(
                              Icons.search_rounded,
                              color: FluidColors.primary,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              vertical: 15,
                            ),
                            suffixIcon: _searchController.text.isNotEmpty
                                ? IconButton(
                                    icon: const Icon(Icons.cancel_rounded),
                                    onPressed: () {
                                      _searchController.clear();
                                      setState(() => _searchResults.clear());
                                    },
                                  )
                                : null,
                          ),
                          onChanged: (val) {
                            if (_debounce?.isActive ?? false)
                              _debounce!.cancel();
                            _debounce = Timer(
                              const Duration(milliseconds: 800),
                              () => _searchAddress(val),
                            );
                          },
                        ),
                      ),
                      // HASIL PENCARIAN
                      if (_searchResults.isNotEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 8),
                          constraints: const BoxConstraints(maxHeight: 300),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Colors.black12, blurRadius: 10),
                            ],
                          ),
                          child: ListView.separated(
                            shrinkWrap: true,
                            itemCount: _searchResults.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 1),
                            itemBuilder: (context, index) {
                              final item = _searchResults[index];
                              return ListTile(
                                title: Text(
                                  item['display_name'],
                                  style: const TextStyle(fontSize: 13),
                                ),
                                onTap: () => _onLocationSelected(
                                  double.parse(item['lat']),
                                  double.parse(item['lon']),
                                  item['display_name'],
                                ),
                              );
                            },
                          ),
                        ),
                    ],
                  ),
                ),

                // 4. FLOATING BUTTONS
                if (!isKeyboardVisible)
                  // KOMPAS — reset ke utara saat di-tap
                  Positioned(
                    right: 16,
                    bottom: 170, // Disesuaikan untuk visible area
                    child: FloatingActionButton.small(
                      heroTag: "compass_btn",
                      backgroundColor: Colors.white,
                      elevation: 4,
                      onPressed: () {
                        _mapController.rotate(0);
                        setState(() => _currentRotation = 0);
                      },
                      child: Transform.rotate(
                        angle: -_currentRotation * (3.14159265 / 180),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: const [
                            Icon(
                              Icons.navigation_rounded,
                              color: Colors.red,
                              size: 18,
                            ),
                            Text(
                              "U",
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                // ZOOM IN
                if (!isKeyboardVisible)
                  Positioned(
                    right: 16,
                    bottom: 120, // Disesuaikan untuk visible area
                    child: FloatingActionButton.small(
                      heroTag: "zoom_in_btn",
                      backgroundColor: Colors.white,
                      elevation: 4,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          (currentZoom + 1).clamp(1.0, 19.0),
                        );
                      },
                      child: const Icon(
                        Icons.add_rounded,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),

                // ZOOM OUT
                if (!isKeyboardVisible)
                  Positioned(
                    right: 16,
                    bottom: 70, // Disesuaikan untuk visible area
                    child: FloatingActionButton.small(
                      heroTag: "zoom_out_btn",
                      backgroundColor: Colors.white,
                      elevation: 4,
                      onPressed: () {
                        final currentZoom = _mapController.camera.zoom;
                        _mapController.move(
                          _mapController.camera.center,
                          (currentZoom - 1).clamp(1.0, 19.0),
                        );
                      },
                      child: const Icon(
                        Icons.remove_rounded,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                  ),

                // GPS — lokasi saat ini
                if (!isKeyboardVisible)
                  Positioned(
                    right: 16,
                    bottom: 20, // Disesuaikan untuk visible area
                    child: FloatingActionButton.small(
                      heroTag: "gps_btn",
                      backgroundColor: Colors.white,
                      elevation: 4,
                      onPressed: _isGettingLocation
                          ? null
                          : _getCurrentLocation,
                      child: _isGettingLocation
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(
                              Icons.my_location,
                              color: FluidColors.primary,
                            ),
                    ),
                  ),
              ],
            ),
          ),

          // 5. PANEL BAWAH (Hanya muncul jika keyboard tertutup)
          if (!isKeyboardVisible)
            Container(
              padding: EdgeInsets.fromLTRB(
                20, // Sebelumnya 20
                12, // Sebelumnya 20
                20, // Sebelumnya 20
                MediaQuery.of(context).padding.bottom + 18,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(32),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle bar kecil di atas
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header & Alamat
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.location_on_rounded,
                          size: 18,
                          color: Colors.red.shade600,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        "Pilih Lokasi Instansi",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF0F172A),
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFE2E8F0)),
                    ),
                    child: Text(
                      _currentAddress,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.blueGrey.shade700,
                        height: 1.5,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),

                  const SizedBox(height: 16),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Radius Absensi",
                        style: TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: FluidColors.primary.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "${_radius.toInt()} Meter",
                          style: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 12,
                            color: FluidColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  SliderTheme(
                    data: SliderTheme.of(context).copyWith(
                      trackHeight: 4,
                      activeTrackColor: FluidColors.primary,
                      inactiveTrackColor: FluidColors.primary.withOpacity(0.1),
                      thumbColor: FluidColors.primary,
                      overlayColor: FluidColors.primary.withOpacity(0.2),
                      thumbShape: const RoundSliderThumbShape(
                        enabledThumbRadius: 10,
                        elevation: 4,
                      ),
                    ),
                    child: Slider(
                      value: _radius,
                      min: 20,
                      max: 500,
                      onChanged: (val) => setState(() => _radius = val),
                    ),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: FluidColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                        elevation: 4,
                        shadowColor: FluidColors.primary.withOpacity(0.3),
                      ),
                      onPressed: _isSaving ? null : _simpanLokasi,
                      child: _isSaving
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,
                              ),
                            )
                          : const Text(
                              "Simpan Lokasi Baru",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
