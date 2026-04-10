import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:hadirin/ui/screens/admin_register_screen.dart';
import 'package:provider/provider.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/services.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idController = TextEditingController();
  final _namaController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // ← BARU: validasi form
  bool _isLoading = false; // ← BARU: loading state
  String _myDeviceId = "Memuat...";

  @override
  void initState() {
    super.initState();
    _loadDeviceId();
  }

  void _loadDeviceId() async {
    final androidInfo = await DeviceInfoPlugin().androidInfo;
    setState(() => _myDeviceId = androidInfo.id);
  }

  @override
  void dispose() {
    // ← BARU: cegah memory leak
    _idController.dispose();
    _namaController.dispose();
    super.dispose();
  }

  void _submitLogin() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _isLoading = true);

    await context.read<AuthProvider>().login(
      _idController.text,
      _namaController.text,
    );

    // RootNavigator otomatis pindah ke AttendanceScreen
    // setState di bawah hanya jika widget masih mounted
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Aktivasi Perangkat")),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: _idController,
                decoration: const InputDecoration(labelText: "ID Karyawan"),
                textInputAction: TextInputAction.next,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'ID tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _namaController,
                decoration: const InputDecoration(labelText: "Nama Lengkap"),
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submitLogin(),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Nama tidak boleh kosong'
                    : null,
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitLogin,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text("Daftarkan Perangkat"),
                ),
              ),
              const SizedBox(height: 40),
              // PINTU MASUK ADMIN SAAS
              TextButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AdminRegisterScreen(),
                    ),
                  );
                },
                icon: const Icon(
                  Icons.admin_panel_settings,
                  color: Colors.grey,
                ),
                label: const Text(
                  "Portal Admin SaaS",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                "Device ID Anda: $_myDeviceId",
                style: const TextStyle(color: Colors.grey),
              ),
              TextButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: _myDeviceId));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Device ID Disalin! Kirimkan ke Admin."),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, size: 16),
                label: const Text("Salin Device ID"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
