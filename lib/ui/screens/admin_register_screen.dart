import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadirin/core/service/admin_service.dart';
import 'package:latlong2/latlong.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/ui/screens/login_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:hadirin/core/theme/fluid_theme.dart';
import 'package:hadirin/ui/screens/set_location_screen.dart';

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
  bool _isLocationPicked = false;

  bool _isLoading = false;
  String? _newClientId;

  @override
  void dispose() {
    _namaController.dispose();
    super.dispose();
  }

  Future<void> _bukaMapPilihLokasi() async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SetLocationScreen(
          isSelectionMode: true,
          initialLocation: _pickedLocation,
          initialRadius: _radius,
        ),
      ),
    );

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
          content: const Text("Nama Instansi tidak boleh kosong"),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await AdminService().registerKlien(
      namaInstansi: _namaController.text.trim(),
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
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FF), // Warna background modern
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: const Text(
          "Pendaftaran Instansi Baru",
          style: TextStyle(
            color: Color(0xFF0F172A),
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: InkWell(
            onTap: () => Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => LoginScreen()),
            ),
            borderRadius: BorderRadius.circular(12),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Color(0xFF0F172A),
                size: 16,
              ),
            ),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: InkWell(
              onTap: () {
                context.read<AuthProvider>().logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade600,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Stack(
          children: [
            // Dekorasi blob atas kiri
            Positioned(
              top: -50,
              left: -50,
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: context.primaryColor.withOpacity(0.06),
                ),
              ),
            ),
            // Dekorasi blob bawah kanan
            Positioned(
              bottom: -100,
              right: -50,
              child: Container(
                width: 250,
                height: 250,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF7C3AED).withOpacity(0.05),
                ),
              ),
            ),

            SafeArea(
              child: _newClientId != null ? _buildSuccessCard() : _buildForm(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      children: [
        // TITLE SECTION
        const Text(
          "Detail Instansi",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Masukkan nama instansi / kantor yang akan didaftarkan ke dalam sistem Hadir.in.",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 24),

        // INPUT FIELD
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: TextFormField(
            controller: _namaController,
            decoration: InputDecoration(
              labelText: "Nama Instansi / Kantor",
              labelStyle: TextStyle(color: Colors.grey.shade500),
              prefixIcon: Icon(
                Icons.business_rounded,
                color: context.primaryColor,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide(color: context.primaryColor, width: 1.5),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            textInputAction: TextInputAction.done,
          ),
        ),

        const SizedBox(height: 40),

        // LOCATION SECTION
        const Text(
          "Lokasi Absensi",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w900,
            color: Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Pilih titik koordinat akurat di peta sebagai pusat batas absensi karyawan.",
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
            height: 1.5,
          ),
        ),
        const SizedBox(height: 20),

        // CARD INDIKATOR LOKASI
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _isLocationPicked
                  ? context.primaryColor.withOpacity(0.3)
                  : Colors.grey.shade200,
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: _isLocationPicked
                    ? context.primaryColor.withOpacity(0.08)
                    : Colors.black.withOpacity(0.03),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _isLocationPicked
                          ? context.primaryColor.withOpacity(0.1)
                          : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      _isLocationPicked
                          ? Icons.check_circle_rounded
                          : Icons.location_off_rounded,
                      color: _isLocationPicked
                          ? context.primaryColor
                          : Colors.grey.shade500,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _isLocationPicked
                          ? "Lokasi Disimpan"
                          : "Belum ditentukan",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: _isLocationPicked
                            ? const Color(0xFF0F172A)
                            : Colors.grey.shade500,
                      ),
                    ),
                  ),
                ],
              ),
              if (_isLocationPicked) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _pickedAddress,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w500,
                          height: 1.4,
                        ),
                      ),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "Koordinat",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              Text(
                                "${_pickedLocation.latitude.toStringAsFixed(4)}, ${_pickedLocation.longitude.toStringAsFixed(4)}",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                "Radius",
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade500,
                                ),
                              ),
                              Text(
                                "${_radius.toInt()} meter",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: context.primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: OutlinedButton.icon(
                  onPressed: _bukaMapPilihLokasi,
                  icon: Icon(Icons.map_rounded),
                  label: Text(
                    _isLocationPicked ? "Ubah Lokasi" : "Buka Peta",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.primaryColor,
                    side: BorderSide(
                      color: context.primaryColor.withOpacity(0.5),
                      width: 1.5,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    backgroundColor: context.primaryColor.withOpacity(0.05),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 48),

        // SUBMIT BUTTON
        SizedBox(
          width: double.infinity,
          height: 60,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitDaftar,
            style: ElevatedButton.styleFrom(
              backgroundColor: context.primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: context.primaryColor.withOpacity(0.4),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: _isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2.5,
                    ),
                  )
                : const Text(
                    "Daftarkan & Buat Database",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCard() {
    return Center(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        padding: const EdgeInsets.all(32.0),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Color(0xFF16A34A),
                size: 64,
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              "Instansi Didaftarkan!",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Berikan Client ID ini kepada klien untuk digunakan saat login pertama kali.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.grey.shade600,
                height: 1.5,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 32),

            // CLIENT ID BOX
            Container(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
              decoration: BoxDecoration(
                color: context.primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: context.primaryColor.withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _newClientId!,
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.5,
                      color: context.primaryColor,
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.copy_rounded,
                        color: context.primaryColor,
                        size: 20,
                      ),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _newClientId!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Row(
                              children: const [
                                Icon(Icons.check_circle, color: Colors.white),
                                SizedBox(width: 8),
                                Text("Client ID disalin!"),
                              ],
                            ),
                            backgroundColor: const Color(0xFF16A34A),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
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
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  _newClientId = null;
                  setState(() {});
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(
                    0xFF0F172A,
                  ), // Warna gelap elegan
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: const Text(
                  "Selesai & Kembali",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
