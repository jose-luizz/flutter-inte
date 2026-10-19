import '../models/chat_models.dart';
import 'api_client.dart';

class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  final ApiClient _api = ApiClient.instance;

  List<T> _lista<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) {
    return (data as List).map((e) => fromJson(e as Map<String, dynamic>)).toList();
  }

  /// Pessoas para iniciar conversa (com [busca], filtra pelo nome).
  Future<List<Contato>> listarContatos({String busca = ''}) async {
    final q = Uri.encodeQueryComponent(busca.trim());
    final data = await _api.get('/usuarios?q=$q');
    return _lista(data, Contato.fromJson);
  }

  Future<List<Conversa>> listarConversas() async {
    final data = await _api.get('/conversas');
    return _lista(data, Conversa.fromJson);
  }

  /// Mensagens com [usuarioId]. Com [depoisDe], só as mais novas que esse id.
  Future<List<Mensagem>> listarMensagens(int usuarioId, {int? depoisDe}) async {
    final query = depoisDe == null ? '' : '?depois=$depoisDe';
    final data = await _api.get('/mensagens/$usuarioId$query');
    return _lista(data, Mensagem.fromJson);
  }

  Future<Mensagem> enviar(int destinatarioId, String texto) async {
    final data = await _api.post('/mensagens', {
      'destinatarioId': destinatarioId,
      'texto': texto,
    });
    return Mensagem.fromJson(data as Map<String, dynamic>);
  }
}
