class Post {
  final int id;
  final String autor;
  final String texto;
  final DateTime? criadoEm;

  const Post({
    required this.id,
    required this.autor,
    required this.texto,
    this.criadoEm,
  });

  factory Post.fromJson(Map<String, dynamic> json) {
    return Post(
      id: json['id'] as int,
      autor: json['autor'] as String,
      texto: json['texto'] as String,
      criadoEm: DateTime.tryParse(json['criadoEm']?.toString() ?? ''),
    );
  }
}
