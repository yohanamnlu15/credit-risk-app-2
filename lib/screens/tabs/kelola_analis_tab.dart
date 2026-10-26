import 'package:flutter/material.dart';
import '../../models/app_user.dart';
import '../../services/api_client.dart';
import '../../services/user_service.dart';
import '../../utils/formatters.dart';
import '../../widgets/app_card.dart';

class KelolaAnalisTab extends StatefulWidget {
  const KelolaAnalisTab({super.key});

  @override
  State<KelolaAnalisTab> createState() => _KelolaAnalisTabState();
}

class _KelolaAnalisTabState extends State<KelolaAnalisTab> {
  late Future<List<AppUser>> _analisFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _analisFuture = UserService.instance.fetchAnalisList();
    _searchController.addListener(() {
      setState(() => _searchQuery = _searchController.text.trim().toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _analisFuture = UserService.instance.fetchAnalisList();
    });
    await _analisFuture;
  }

  List<AppUser> _applySearch(List<AppUser> users) {
    if (_searchQuery.isEmpty) return users;
    return users.where((u) {
      return u.nama.toLowerCase().contains(_searchQuery) || u.username.toLowerCase().contains(_searchQuery);
    }).toList();
  }

  Future<void> _showAddAnalisSheet() async {
    final formKey = GlobalKey<FormState>();
    final namaController = TextEditingController();
    final usernameController = TextEditingController();
    final passwordController = TextEditingController();
    bool isSaving = false;

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
                    const Text('Tambah Akun Analis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: namaController,
                      decoration: const InputDecoration(labelText: 'Nama Lengkap', prefixIcon: Icon(Icons.badge_outlined, size: 20)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: usernameController,
                      decoration: const InputDecoration(labelText: 'Username', prefixIcon: Icon(Icons.person_outline_rounded, size: 20)),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Wajib diisi' : null,
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passwordController,
                      obscureText: true,
                      decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline_rounded, size: 20)),
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Wajib diisi';
                        if (v.length < 6) return 'Minimal 6 karakter';
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
                                  await UserService.instance.createAnalis(
                                    username: usernameController.text.trim(),
                                    password: passwordController.text,
                                    nama: namaController.text.trim(),
                                  );
                                  if (sheetContext.mounted) Navigator.of(sheetContext).pop();
                                  _refresh();
                                } on ApiException catch (e) {
                                  setSheetState(() => isSaving = false);
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(SnackBar(content: Text(e.message)));
                                } catch (_) {
                                  setSheetState(() => isSaving = false);
                                  ScaffoldMessenger.of(sheetContext).showSnackBar(
                                    const SnackBar(content: Text('Gagal menyimpan akun.')),
                                  );
                                }
                              },
                        child: isSaving
                            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                            : const Text('Simpan'),
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

  Future<void> _confirmDelete(AppUser user) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Hapus Akun Analis'),
        content: Text('Yakin ingin menghapus akun "${user.nama}"? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFC62828)),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await UserService.instance.deleteAnalis(user.id);
        _refresh();
      } on ApiException catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refresh,
      child: FutureBuilder<List<AppUser>>(
        future: _analisFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              children: [
                const SizedBox(height: 80),
                Center(child: Text('Gagal memuat data: ${snapshot.error}', textAlign: TextAlign.center)),
              ],
            );
          }

          final allUsers = snapshot.data ?? [];
          final users = _applySearch(allUsers);

          return ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Daftar Akun Analis', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF1B2A41))),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(color: const Color(0xFF0A2647).withOpacity(0.08), borderRadius: BorderRadius.circular(20)),
                    child: Text('${users.length} Akun', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF0A2647))),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Cari nama atau username Analis...',
                  hintStyle: const TextStyle(fontSize: 13),
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => _searchController.clear(),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _showAddAnalisSheet,
                  icon: const Icon(Icons.person_add_alt_1_rounded, size: 19),
                  label: const Text('Tambah Akun Analis'),
                ),
              ),
              const SizedBox(height: 16),
              if (users.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: Center(
                    child: Text(
                      _searchQuery.isEmpty ? 'Belum ada akun Analis.' : 'Tidak ada hasil untuk "$_searchQuery".',
                      style: TextStyle(color: Colors.grey.shade500),
                      textAlign: TextAlign.center,
                    ),
                  ),
                )
              else
                ...users.map(
                  (user) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: AppCard(
                      padding: EdgeInsets.zero,
                      child: ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF0A2647).withOpacity(0.1),
                          child: Text(
                            user.nama.isNotEmpty ? user.nama[0].toUpperCase() : '?',
                            style: const TextStyle(color: Color(0xFF0A2647), fontWeight: FontWeight.bold),
                          ),
                        ),
                        title: Text(user.nama, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14.5)),
                        subtitle: Text(
                          '@${user.username} • Sejak ${AppFormatters.formatDate(user.createdAt)}',
                          style: const TextStyle(fontSize: 12, color: Color(0xFF5B6B79)),
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFC62828)),
                          onPressed: () => _confirmDelete(user),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}