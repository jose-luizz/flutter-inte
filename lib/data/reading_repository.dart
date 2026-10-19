import '../models/post.dart';
import 'api_client.dart';

/// Leitura e criação das publicações do feed.
class ReadingRepository {
  ReadingRepository._();
  static final ReadingRepository instance = ReadingRepository._();

  final ApiClient _api = ApiClient.instance;

  Future<List<Post>> listarPosts() async {
    final data = await _api.get('/posts');
    return (data as List)
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Busca publicações pelo texto ou pelo nome do autor.
  Future<List<Post>> buscar(String termo) async {
    final data = await _api.get('/posts?q=${Uri.encodeQueryComponent(termo)}');
    return (data as List)
        .map((e) => Post.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Post> publicar(String texto) async {
    final data = await _api.post('/posts', {'texto': texto});
    return Post.fromJson(data as Map<String, dynamic>);
  }
}
