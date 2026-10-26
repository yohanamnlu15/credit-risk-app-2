import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/api_config.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, {this.statusCode});

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  String? _token;

  void setToken(String? token) {
    _token = token;
  }

  String? get token => _token;

  Map<String, String> get _headers {
    final headers = {'Content-Type': 'application/json'};
    if (_token != null) headers['Authorization'] = 'Bearer $_token';
    return headers;
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(Uri.parse('${ApiConfig.baseUrl}$path'), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server. Pastikan backend aktif dan device satu jaringan.');
    }
  }

  Future<dynamic> put(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .put(Uri.parse('${ApiConfig.baseUrl}$path'), headers: _headers, body: jsonEncode(body))
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server. Pastikan backend aktif dan device satu jaringan.');
    }
  }

  Future<dynamic> get(String path) async {
    try {
      final response = await http
          .get(Uri.parse('${ApiConfig.baseUrl}$path'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server. Pastikan backend aktif dan device satu jaringan.');
    }
  }

  Future<dynamic> delete(String path) async {
    try {
      final response = await http
          .delete(Uri.parse('${ApiConfig.baseUrl}$path'), headers: _headers)
          .timeout(const Duration(seconds: 15));
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } catch (e) {
      throw ApiException('Tidak dapat terhubung ke server. Pastikan backend aktif dan device satu jaringan.');
    }
  }

  dynamic _handleResponse(http.Response response) {
    final decoded = response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    final message = decoded is Map && decoded['error'] != null
        ? decoded['error'].toString()
        : 'Terjadi kesalahan pada server (${response.statusCode}).';

    throw ApiException(message, statusCode: response.statusCode);
  }
}