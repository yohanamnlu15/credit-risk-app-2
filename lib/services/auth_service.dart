import 'api_client.dart';

class AuthResult {
  final String token;
  final String role;
  final String nama;
  final String username;

  const AuthResult({
    required this.token,
    required this.role,
    required this.nama,
    required this.username,
  });

  factory AuthResult.fromJson(Map<String, dynamic> json) {
    return AuthResult(
      token: json['token'] as String,
      role: json['role'] as String,
      nama: json['nama'] as String,
      username: json['username'] as String,
    );
  }
}

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  AuthResult? currentUser;

  Future<AuthResult> login(String username, String password) async {
    final response = await ApiClient.instance.post('/login', {
      'username': username,
      'password': password,
    });

    final result = AuthResult.fromJson(response as Map<String, dynamic>);
    ApiClient.instance.setToken(result.token);
    currentUser = result;
    return result;
  }

  Future<void> logout() async {
    try {
      await ApiClient.instance.post('/logout', {});
    } catch (_) {
      // abaikan error logout (mis. token sudah kedaluwarsa)
    } finally {
      ApiClient.instance.setToken(null);
      currentUser = null;
    }
  }

  Future<Map<String, dynamic>> fetchMe() async {
    final response = await ApiClient.instance.get('/me');
    return response as Map<String, dynamic>;
  }

  Future<void> changePassword({
    required String oldPassword,
    required String newPassword,
  }) async {
    await ApiClient.instance.put('/me/password', {
      'old_password': oldPassword,
      'new_password': newPassword,
    });
  }
} 