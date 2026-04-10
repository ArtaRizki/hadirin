import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hadirin/core/service/attendance_service.dart';

class AdminRegisterScreen extends StatefulWidget {
  const AdminRegisterScreen({super.key});

  @override
  State<AdminRegisterScreen> createState() => _AdminRegisterScreenState();
}

class _AdminRegisterScreenState extends State<AdminRegisterScreen> {
  final _namaController = TextEditingController();
  final _latController = TextEditingController();
  final _lngController = TextEditingController();
  final _radiusController = TextEditingController(text: "100");
  
  bool _isLoading = false;
  String? _newClientId;

  void _submitDaftar() async {
    if (_namaController.text.isEmpty || _latController.text.isEmpty || _lngController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Harap isi semua kolom")));
      return;
    }

    setState(() => _isLoading = true);

    final result = await AttendanceService().registerKlien(
      namaUmkm: _namaController.text,
      lat: double.tryParse(_latController.text) ?? 0.0,
      lng: double.tryParse(_lngController.text) ?? 0.0,
      radius: double.tryParse(_radiusController.text) ?? 100.0,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      setState(() {
        _newClientId = result['client_id'];
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Dashboard SaaS Admin"), backgroundColor: Colors.blueGrey),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: _newClientId != null 
          ? _buildSuccessCard() 
          : _buildForm(),
      ),
    );
  }

  Widget _buildForm() {
    return ListView(
      children: [
        const Text("Daftarkan UMKM Baru", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text("Sistem akan otomatis membuat Spreadsheet & Folder Drive untuk klien ini."),
        const SizedBox(height: 20),
        TextField(
          controller: _namaController,
          decoration: const InputDecoration(labelText: "Nama UMKM", border: OutlineInputBorder()),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(child: TextField(controller: _latController, decoration: const InputDecoration(labelText: "Latitude", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
            const SizedBox(width: 16),
            Expanded(child: TextField(controller: _lngController, decoration: const InputDecoration(labelText: "Longitude", border: OutlineInputBorder()), keyboardType: TextInputType.number)),
          ],
        ),
        const SizedBox(height: 16),
        TextField(
          controller: _radiusController,
          decoration: const InputDecoration(labelText: "Radius Toleransi (Meter)", border: OutlineInputBorder()),
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity, height: 50,
          child: ElevatedButton(
            onPressed: _isLoading ? null : _submitDaftar,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blueGrey, foregroundColor: Colors.white),
            child: _isLoading 
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text("Buat Database Klien Otomatis", style: TextStyle(fontSize: 16)),
          ),
        ),
      ],
    );
  }

  Widget _buildSuccessCard() {
    return Center(
      child: Card(
        elevation: 8,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(30.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 80),
              const SizedBox(height: 20),
              const Text("UMKM Berhasil Didaftarkan!", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              const Text("Berikan Client ID ini kepada klien untuk dimasukkan ke aplikasi mereka:", textAlign: TextAlign.center),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                color: Colors.grey.shade200,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(_newClientId!, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, letterSpacing: 2)),
                    IconButton(
                      icon: const Icon(Icons.copy),
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _newClientId!));
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Client ID disalin!")));
                      },
                    )
                  ],
                ),
              ),
              const SizedBox(height: 30),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text("Selesai & Kembali"),
              )
            ],
          ),
        ),
      ),
    );
  }
}