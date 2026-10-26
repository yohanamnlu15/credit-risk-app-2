/// Konfigurasi base URL API.
///
/// GANTI `useEmulator` ke false kalau menjalankan di device fisik,
/// lalu sesuaikan `_lanIp` dengan IP yang tertampil di log Flask
/// (mis. "Running on http://192.168.1.18:5000" -> isi "192.168.1.18").
class ApiConfig {
  ApiConfig._();

  static const bool useEmulator = true;
  static const String _lanIp = '192.168.1.18';
  static const int _port = 5000;

  static String get baseUrl {
    final host = useEmulator ? '10.0.2.2' : _lanIp;
    return 'http://$host:$_port/api';
  }
}