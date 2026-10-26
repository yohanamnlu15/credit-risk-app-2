import 'package:flutter/material.dart';
import 'tabs/admin_dashboard_tab.dart';
import 'tabs/analis_dashboard_tab.dart';
import 'tabs/analis_form_tab.dart';
import 'tabs/riwayat_tab.dart';
import 'tabs/kelola_analis_tab.dart';
import 'tabs/profil_tab.dart';

class MainShell extends StatefulWidget {
  final String role; // 'Admin' atau 'Analis'

  const MainShell({super.key, required this.role});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  late final PageController _pageController;
  int _currentIndex = 0;

  bool get _isAdmin => widget.role == 'Admin';

  void _goToTab(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  List<Widget> get _tabs => _isAdmin
      ? [
          AdminDashboardTab(onGoToRiwayat: () => _goToTab(1)),
          const RiwayatTab(role: 'Admin'),
          const KelolaAnalisTab(),
          const ProfilTab(role: 'Admin'),
        ]
      : [
          AnalisDashboardTab(onGoToForm: () => _goToTab(1)),
          const AnalisFormTab(),
          const RiwayatTab(role: 'Analis'),
          const ProfilTab(role: 'Analis'),
        ];

  List<String> get _titles => _isAdmin
      ? const ['Dashboard Admin', 'Riwayat Klasifikasi', 'Kelola Analis', 'Profil Saya']
      : const ['Dashboard Saya', 'Form Prediksi Risiko', 'Riwayat Klasifikasi', 'Profil Saya'];

  List<BottomNavigationBarItem> get _navItems => _isAdmin
      ? const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline_rounded), activeIcon: Icon(Icons.people_rounded), label: 'Analis'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profil'),
        ]
      : const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), activeIcon: Icon(Icons.dashboard), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.fact_check_outlined), activeIcon: Icon(Icons.fact_check), label: 'Prediksi'),
          BottomNavigationBarItem(icon: Icon(Icons.history_outlined), activeIcon: Icon(Icons.history), label: 'Riwayat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), activeIcon: Icon(Icons.person_rounded), label: 'Profil'),
        ];

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _currentIndex = index);
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  void _onPageChanged(int index) {
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false, // MainShell TIDAK PERNAH punya tombol back
        title: Text(_titles[_currentIndex]),
      ),
      body: PageView(
        controller: _pageController,
        onPageChanged: _onPageChanged,
        children: _tabs, // PageView sudah swipeable kiri-kanan secara default
      ),
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        currentIndex: _currentIndex,
        onTap: _onNavTap,
        selectedItemColor: const Color(0xFF0A2647),
        unselectedItemColor: const Color(0xFF8A94A6),
        items: _navItems,
      ),
    );
  }
}