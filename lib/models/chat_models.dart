/// Pessoa com quem dá para iniciar uma conversa.
class Contato {
  final int id;
  final String usuario;

  const Contato({required this.id, required this.usuario});

  factory Contato.fromJson(Map<String, dynamic> json) {
    return Contato(
      id: json['id'] as int,
      usuario: json['usuario'] as String,
    );
  }
}

/// Item da lista de conversas (última mensagem trocada com alguém).
class Conversa {
  final int usuarioId;
  final String usuario;
  final String ultimaMensagem;
  final DateTime? criadoEm;
  final bool minha; // a última mensagem foi enviada por mim?

  const Conversa({
    required this.usuarioId,
    required this.usuario,
    required this.ultimaMensagem,
    required this.criadoEm,
    required this.minha,
  });

  factory Conversa.fromJson(Map<String, dynamic> json) {
    return Conversa(
      usuarioId: json['usuarioId'] as int,
      usuario: json['usuario'] as String,
      ultimaMensagem: json['ultimaMensagem'] as String,
      criadoEm: DateTime.tryParse(json['criadoEm']?.toString() ?? '')?.toLocal(),
      minha: json['minha'] == true,
    );
  }
}

class Mensagem {
  final int id;
  final int remetenteId;
  final String texto;
  final DateTime? criadoEm;

  const Mensagem({
    required this.id,
    required this.remetenteId,
    required this.texto,
    required this.criadoEm,
  });

  factory Mensagem.fromJson(Map<String, dynamic> json) {
    return Mensagem(
      id: json['id'] as int,
      remetenteId: json['remetenteId'] as int,
      texto: json['texto'] as String,
      criadoEm: DateTime.tryParse(json['criadoEm']?.toString() ?? '')?.toLocal(),
    );
  }
}

/// "14:05"
String formatarHora(DateTime? d) {
  if (d == null) return '';
  final h = d.hour.toString().padLeft(2, '0');
  final m = d.minute.toString().padLeft(2, '0');
  return '$h:$m';
}

/// Hoje mostra a hora ("14:05"); outros dias mostram a data ("09/10").
String formatarDataLista(DateTime? d) {
  if (d == null) return '';
  final agora = DateTime.now();
  if (d.year == agora.year && d.month == agora.month && d.day == agora.day) {
    return formatarHora(d);
  }
  final dia = d.day.toString().padLeft(2, '0');
  final mes = d.month.toString().padLeft(2, '0');
  return '$dia/$mes';
}
