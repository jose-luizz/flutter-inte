import '../models/app_user.dart';
import 'api_client.dart';

class AuthRepository {
  AuthRepository._();
  static final AuthRepository instance = AuthRepository._();

  final ApiClient _api = ApiClient.instance;

  /// Usuário logado no momento (null se ninguém entrou).
  AppUser? currentUser;

  bool get isLoggedIn => _api.token != null;

  /// Entra com email, RM e senha.
  Future<AppUser> login({
    required String email,
    required String rm,
    required String senha,
  }) async {
    final data = await _api.post('/login', {
      'email': email.trim(),
      'rm': rm.trim(),
      'senha': senha,
    });
    return _salvarSessao(data);
  }

  /// Cria a conta e já deixa o usuário logado.
  Future<AppUser> cadastrar({
    required String usuario,
    required String email,
    required String rm,
    required String senha,
  }) async {
    final data = await _api.post('/cadastro', {
      'usuario': usuario.trim(),
      'email': email.trim(),
      'rm': rm.trim(),
      'senha': senha,
    });
    return _salvarSessao(data);
  }

  void logout() {
    _api.token = null;
    currentUser = null;
  }

  AppUser _salvarSessao(dynamic data) {
    _api.token = data['token'] as String;
    currentUser = AppUser.fromJson(data['usuario'] as Map<String, dynamic>);
    return currentUser!;
  }
}
