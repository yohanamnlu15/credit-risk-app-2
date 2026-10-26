import '../models/app_user.dart';
import 'api_client.dart';

class UserService {
  UserService._();
  static final UserService instance = UserService._();

  Future<void> registerAdmin({
    required String username,
    required String password,
    required String nama,
    required String kodeAdmin,
  }) async {
    await ApiClient.instance.post('/register', {
      'username': username,
      'password': password,
      'nama': nama,
      'kode_admin': kodeAdmin,
    });
  }

  Future<List<AppUser>> fetchAnalisList() async {
    final response = await ApiClient.instance.get('/users');
    final list = response as List<dynamic>;
    return list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<void> createAnalis({
    required String username,
    required String password,
    required String nama,
  }) async {
    await ApiClient.instance.post('/users', {
      'username': username,
      'password': password,
      'nama': nama,
    });
  }

  Future<void> deleteAnalis(int id) async {
    await ApiClient.instance.delete('/users/$id');
  }

  Future<void> resetAnalisPassword(int id, String newPassword) async {
    await ApiClient.instance.put('/users/$id/password', {
      'new_password': newPassword,
    });
  }
}