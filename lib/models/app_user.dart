class AppUser {
  final int id;
  final String usuario;
  final String email;
  final String rm;

  const AppUser({
    required this.id,
    required this.usuario,
    required this.email,
    required this.rm,
  });

  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      id: json['id'] as int,
      usuario: json['usuario'] as String,
      email: json['email'] as String,
      rm: json['rm'].toString(),
    );
  }
}
