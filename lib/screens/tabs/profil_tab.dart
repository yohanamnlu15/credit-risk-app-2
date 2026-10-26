import 'package:flutter/material.dart';
import '../../routes/app_routes.dart';
import '../../services/api_client.dart';
import '../../services/auth_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';

class ProfilTab extends StatefulWidget {
  final String role;

  const ProfilTab({super.key, required this.role});

  @override
  State<ProfilTab> createState() => _ProfilTabState();
}

class _ProfilTabState extends State<ProfilTab> {
  late Future<Map<String, dynamic>> _meFuture;

  bool get _isAdmin => widget.role == 'Admin';

  @override
  void initState() {
    super.initState();
    _meFuture = AuthService.instance.fetchMe();
  }

  Future<void> _showChangePasswordSheet() async {
    final formKey = GlobalKey<FormState>();
    final oldPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmController = TextEditingController();
    bool isSaving = false;
    bool obscureOld = true;
    bool obscureNew = true;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (sheetContext, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 20,
                bottom: MediaQuery.of(sheetContext).viewInsets.bottom + 20,
              ),
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Ubah Kata Sandi', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      'Gunakan password sendiri agar akun lebih aman.',
                      style: TextStyle(fontSize: 12.5, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 18),
                    TextFormField(
                      controller: oldPasswordController,
                      obscureText: obscureOld,
                      decoration: InputDecoration(
                        labelText: 'Password Saat Ini',
                        prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureOld ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                          onPressed: () => setSheetState(() => obscureOld = !obscureOld),
                        ),
                      ),
                      validator: (v) => (v == null || v.isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: newPasswordController,
                      obscureText: obscureNew,
                      decoration: InputDecoration(
                        labelText: 'Password Baru',
                        prefixIcon: const Icon(Icons.lock_reset_rounded, size: 20),
                        suffixIcon: IconButton(
                          icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20),
                          onPressed: () => setSheetState(() => obscureNew = !obscureNew),
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        if (v.length < 6) return 'Minimal 6 karakter';
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: confirmController,
                      obscureText: obscureNew,
                      decoration: const InputDecoration(
                        labelText: 'Konfirmasi Password Baru',
                        prefixIcon: Icon(Icons.lock_reset_rounded, size: 20),
                      ),
                      validator: (v) {
                        if (v != newPasswordController.text) return 'Password tidak cocok';
                        return null;
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: isSaving
                            ? null
                            : () async {
                                if (!formKey.currentState!.validate()) return;
                                setSheetState(() => isSaving = true);
                                try {
                                  await AuthService.instance.changePassword(
                                    oldPassword: oldPasswordController.text,
                                    newPassword: newPasswordController.text,
                                  );
                                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                                  if (mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Password berhasil diperbarui.')),
                                    );
                                  }
                                } on ApiException catch (e) {
                                  setSheetState(() => isSaving = false);
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(e.message)));
                                } catch (_) {
                                  setSheetState(() => isSaving = false);
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(content: Text('Gagal memperbarui password.')),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                            : const Text('Simpan Password Baru'),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Konfirmasi Keluar'),
        content: const Text('Apakah Anda yakin ingin keluar dari akun ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Ya'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await AuthService.instance.logout();
      if (!mounted) return;
      Navigator.of(context).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _meFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snapshot.data;
        final nama = data?['nama'] as String? ?? '-';
        final username = data?['username'] as String? ?? '-';
        final createdAt = data?['createdAt'] != null ? DateTime.tryParse(data!['createdAt'] as String) : null;
        final stats = data?['stats'] as Map<String, dynamic>? ?? {};

        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              AppCard(
                padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
                child: Column(
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: const BoxDecoration(color: Color(0xFF0A2647), shape: BoxShape.circle),
                      alignment: Alignment.center,
                      child: Text(
                        nama.isNotEmpty ? nama[0].toUpperCase() : '?',
                        style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(nama, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1B2A41))),
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                      decoration: BoxDecoration(color: const Color(0xFF0A2647).withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        _isAdmin ? 'Administrator Sistem' : 'Analis Kredit',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF0A2647)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Informasi Akun', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Color(0xFF1B2A41))),
                    const SizedBox(height: 14),
                    _infoRow(Icons.person_outline_rounded, 'Username', username),
                    _infoRow(
                      Icons.event_outlined,
                      'Bergabung Sejak',
                      createdAt != null ? AppFormatters.formatDate(createdAt) : '-',
                      isLast: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AppCard(
                child: Row(
                  children: [
                    Expanded(
                      child: _statItem(
                        icon: Icons.fact_check_outlined,
                        label: _isAdmin ? 'Total Evaluasi (Semua)' : 'Total Evaluasi Saya',
                        value: '${stats['totalEvaluasi'] ?? 0}',
                      ),
                    ),
                    if (_isAdmin) ...[
                      Container(width: 1, height: 42, color: const Color(0xFFE4E8EE)),
                      Expanded(
                        child: _statItem(
                          icon: Icons.people_outline_rounded,
                          label: 'Total Analis',
                          value: '${stats['totalAnalis'] ?? 0}',
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _showChangePasswordSheet,
                icon: const Icon(Icons.lock_reset_rounded, size: 19),
                label: const Text('Ubah Kata Sandi'),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, size: 19),
                label: const Text('Keluar'),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _infoRow(IconData icon, String label, String value, {bool isLast = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 19, color: const Color(0xFF5B6B79)),
          const SizedBox(width: 12),
          Expanded(flex: 2, child: Text(label, style: const TextStyle(fontSize: 12.5, color: Color(0xFF5B6B79)))),
          Expanded(flex: 3, child: Text(value, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1B2A41)), textAlign: TextAlign.right)),
        ],
      ),
    );
  }

  Widget _statItem({required IconData icon, required String label, required String value}) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF0A2647), size: 22),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Color(0xFF1B2A41))),
        const SizedBox(height: 3),
        Text(label, style: const TextStyle(fontSize: 11, color: Color(0xFF5B6B79)), textAlign: TextAlign.center),
      ],
    );
  }
}