class AppUser {
  final int id;
  final String username;
  final String nama;
  final DateTime createdAt;

  const AppUser({
    required this.id,
    required this.username,
    required this.nama,
    required this.createdAt,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      username: json['username'] as String,
      nama: json['nama'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }
}