/// Konfigurasi base URL API.
///
/// Prioritas:
/// 1. Jika dijalankan dengan --dart-define=API_BASE_URL=..., nilai itu dipakai.
///    Contoh (aplikasi web / device fisik):
///      flutter run --dart-define=API_BASE_URL=http://192.168.40.36:5000/api
/// 2. Jika tidak, pakai pengaturan manual di bawah:
///    GANTI `useEmulator` ke false kalau menjalankan di device fisik,
///    lalu sesuaikan `_lanIp` dengan IP laptop (cek dengan `ipconfig`).
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  static const bool useEmulator = true;
  static const String _lanIp = '192.168.40.36'; // IP laptop saat ini (ganti jika jaringan berubah)
  static const int _port = 5000;

  static String get baseUrl {
    if (_override.isNotEmpty) return _override;
    final host = useEmulator ? '10.0.2.2' : _lanIp;
    return 'http://$host:$_port/api';
  }
}
