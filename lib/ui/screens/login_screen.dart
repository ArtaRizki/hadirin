import 'package:flutter/material.dart';
import 'package:hadirin/core/providers/auth_provider.dart';
import 'package:provider/provider.dart';

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
            ],
          ),
        ),
      ),
    );
  }
}
