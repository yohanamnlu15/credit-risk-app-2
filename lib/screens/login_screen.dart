import 'package:flutter/material.dart';
import '../routes/app_routes.dart';
import '../services/api_client.dart';
import '../services/auth_service.dart';
import '../widgets/app_card.dart';
import 'main_shell.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  late final AnimationController _entranceController;
  late final Animation<double> _entranceFade;
  late final Animation<Offset> _entranceSlide;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 550));
    _entranceFade =
        CurvedAnimation(parent: _entranceController, curve: Curves.easeOut);
    _entranceSlide =
        Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero).animate(
            CurvedAnimation(
                parent: _entranceController, curve: Curves.easeOutCubic));
    _entranceController.forward();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final result = await AuthService.instance.login(
        _usernameController.text.trim(),
        _passwordController.text,
      );
      if (!mounted) return;
      // pushAndRemoveUntil membersihkan SELURUH stack (termasuk Splash/Login),
      // jadi MainShell tidak akan pernah punya tombol back yang nyasar.
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => MainShell(role: result.role)),
        (route) => false,
      );
    } on ApiException catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(e.message)));
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Terjadi kesalahan tak terduga. Coba lagi.')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openRegister() {
    Navigator.of(context).pushNamed(AppRoutes.register);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F9),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: FadeTransition(
                opacity: _entranceFade,
                child: SlideTransition(
                  position: _entranceSlide,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const SizedBox(height: 16),
                      Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0A2647),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0A2647).withOpacity(0.25),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.account_balance_rounded,
                            color: Colors.white, size: 38),
                      ),
                      const SizedBox(height: 20),
                      const Text(
                        'Prediksi Risiko Kredit',
                        style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF1B2A41)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Sistem Internal Analisis Kelayakan Debitur',
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      AppCard(
                        padding: const EdgeInsets.all(24),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Masuk ke Akun',
                                style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1B2A41)),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Khusus pegawai internal perusahaan',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.grey.shade600),
                              ),
                              const SizedBox(height: 22),
                              TextFormField(
                                controller: _usernameController,
                                decoration: const InputDecoration(
                                  labelText: 'Username',
                                  prefixIcon: Icon(Icons.person_outline_rounded,
                                      size: 20),
                                ),
                                validator: (value) =>
                                    (value == null || value.trim().isEmpty)
                                        ? 'Username wajib diisi'
                                        : null,
                              ),
                              const SizedBox(height: 16),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                decoration: InputDecoration(
                                  labelText: 'Password',
                                  prefixIcon: const Icon(
                                      Icons.lock_outline_rounded,
                                      size: 20),
                                  suffixIcon: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_off_outlined
                                          : Icons.visibility_outlined,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.isEmpty)
                                    return 'Password wajib diisi';
                                  return null;
                                },
                              ),
                              const SizedBox(height: 22),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed: _isLoading ? null : _handleLogin,
                                  child: _isLoading
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2.4,
                                              color: Colors.white),
                                        )
                                      : const Text('Login'),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: TextButton(
                                  onPressed: _isLoading ? null : _openRegister,
                                  child:
                                      const Text('Daftar sebagai Admin baru'),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Text(
                        '© 2026 Internal Credit Risk System',
                        style: TextStyle(
                            fontSize: 11.5, color: Colors.grey.shade500),
                      ),
                      const SizedBox(height: 12),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
