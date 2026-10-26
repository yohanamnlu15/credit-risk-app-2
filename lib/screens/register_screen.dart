import 'package:flutter/material.dart';
import '../services/api_client.dart';
import '../services/user_service.dart';
import '../widgets/app_card.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _namaController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  final _kodeAdminController = TextEditingController();

  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _namaController.dispose();
    _usernameController.dispose();
    _passwordController.dispose();
    _confirmController.dispose();
    _kodeAdminController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await UserService.instance.registerAdmin(
        username: _usernameController.text.trim(),
        password: _passwordController.text,
        nama: _namaController.text.trim(),
        kodeAdmin: _kodeAdminController.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registrasi berhasil. Silakan login.')),
      );
      Navigator.of(context).pop();
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terjadi kesalahan tak terduga. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrasi Admin')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Buat Akun Admin Baru',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B2A41)),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Registrasi memerlukan Kode Admin yang hanya diketahui pihak berwenang.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 20),
                    TextFormField(
                      controller: _namaController,
                      decoration: const InputDecoration(
                        labelText: 'Nama Lengkap',
                        prefixIcon: Icon(Icons.badge_outlined, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _usernameController,
                      decoration: const InputDecoration(
                        labelText: 'Username',
                        prefixIcon: Icon(Icons.person_outline_rounded, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        if (v.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _confirmController,
                      obscureText: _obscurePassword,
                      decoration: const InputDecoration(
                        labelText: 'Konfirmasi Password',
                        prefixIcon: Icon(Icons.lock_outline_rounded, size: 20),
                      ),
                      validator: (v) {
                        if (v != _passwordController.text) return 'Password tidak cocok';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _kodeAdminController,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Kode Admin',
                        prefixIcon: Icon(Icons.vpn_key_outlined, size: 20),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleRegister,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                      )
                    : const Text('Daftar'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}