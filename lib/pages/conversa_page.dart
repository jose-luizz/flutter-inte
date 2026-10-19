import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import '../data/chat_repository.dart';
import '../models/chat_models.dart';
import 'login_page.dart'; // usa kPrimary, kHint e kFont

/// Conversa com uma pessoa (mensagens + campo para enviar).
class ConversaPage extends StatefulWidget {
  final int usuarioId;
  final String usuario;

  const ConversaPage({
    super.key,
    required this.usuarioId,
    required this.usuario,
  });

  @override
  State<ConversaPage> createState() => _ConversaPageState();
}

class _ConversaPageState extends State<ConversaPage> {
  final _repo = ChatRepository.instance;
  final _controller = TextEditingController();
  final _scroll = ScrollController();

  final List<Mensagem> _mensagens = [];
  bool _loading = true;
  bool _enviando = false;
  bool _atualizando = false;
  String? _erro;
  Timer? _timer;

  int? get _meuId => AuthRepository.instance.currentUser?.id;

  @override
  void initState() {
    super.initState();
    _carregar();
    // Busca mensagens novas a cada 3 segundos
    _timer = Timer.periodic(const Duration(seconds: 3), (_) => _atualizar());
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  bool get _pertoDoFim =>
      !_scroll.hasClients ||
      _scroll.position.maxScrollExtent - _scroll.offset < 120;

  void _irParaFim({bool animar = true}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      final fim = _scroll.position.maxScrollExtent;
      if (animar) {
        _scroll.animateTo(
          fim,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      } else {
        _scroll.jumpTo(fim);
      }
    });
  }

  Future<void> _carregar() async {
    try {
      final mensagens = await _repo.listarMensagens(widget.usuarioId);
      if (!mounted) return;
      setState(() {
        _mensagens
          ..clear()
          ..addAll(mensagens);
        _erro = null;
        _loading = false;
      });
      _irParaFim(animar: false);
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.message;
        _loading = false;
      });
    }
  }

  /// Chamada pelo timer: busca só o que chegou depois da última mensagem.
  Future<void> _atualizar() async {
    if (_atualizando || _loading || _enviando) return;
    if (_erro != null) {
      await _carregar();
      return;
    }

    _atualizando = true;
    try {
      final novas = await _repo.listarMensagens(
        widget.usuarioId,
        depoisDe: _mensagens.isEmpty ? null : _mensagens.last.id,
      );
      if (!mounted) return;
      _adicionar(novas);
    } on ApiException {
      // falha de rede na atualização automática: tenta de novo no próximo ciclo
    } finally {
      _atualizando = false;
    }
  }

  void _adicionar(List<Mensagem> novas) {
    final ids = _mensagens.map((m) => m.id).toSet();
    final ineditas = novas.where((m) => !ids.contains(m.id)).toList();
    if (ineditas.isEmpty) return;

    final seguir = _pertoDoFim || ineditas.any((m) => m.remetenteId == _meuId);
    setState(() => _mensagens.addAll(ineditas));
    if (seguir) _irParaFim();
  }

  Future<void> _enviar() async {
    final texto = _controller.text.trim();
    if (texto.isEmpty || _enviando) return;

    setState(() => _enviando = true);
    try {
      final msg = await _repo.enviar(widget.usuarioId, texto);
      if (!mounted) return;
      _controller.clear();
      _adicionar([msg]);
    } on ApiException catch (e) {
      _mostrarMensagem(e.message);
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  Widget _buildMensagens() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }

    if (_erro != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _erro!,
                textAlign: TextAlign.center,
                style: const TextStyle(fontFamily: kFont, fontSize: 12),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  setState(() => _loading = true);
                  _carregar();
                },
                child: const Text(
                  'Tentar novamente',
                  style: TextStyle(fontFamily: kFont, color: kPrimary),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_mensagens.isEmpty) {
      return Center(
        child: Text(
          'Nenhuma mensagem ainda.\nDiga olá! 👋',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFont,
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      );
    }

    return ListView.builder(
      controller: _scroll,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      itemCount: _mensagens.length,
      itemBuilder: (_, i) {
        final m = _mensagens[i];
        return _Bolha(mensagem: m, minha: m.remetenteId == _meuId);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: Column(
          children: [
            // Cabeçalho
            Container(
              padding: const EdgeInsets.fromLTRB(4, 8, 16, 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(16)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const CircleAvatar(
                    radius: 16,
                    backgroundColor: kPrimary,
                    child: Icon(Icons.person, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      widget.usuario,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kFont,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildMensagens()),
            // Campo de envio
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      maxLength: 1000,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (_) => _enviar(),
                      buildCounter: (_,
                              {required currentLength,
                              required isFocused,
                              maxLength}) =>
                          null,
                      style: const TextStyle(fontFamily: kFont, fontSize: 13),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: Colors.white,
                        hintText: 'Digite uma mensagem...',
                        hintStyle: const TextStyle(
                          fontFamily: kFont,
                          color: kHint,
                          fontSize: 12,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 18,
                          vertical: 14,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(24),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Material(
                    color: kPrimary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _enviando ? null : _enviar,
                      child: SizedBox(
                        height: 46,
                        width: 46,
                        child: Center(
                          child: _enviando
                              ? const SizedBox(
                                  height: 18,
                                  width: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Icon(
                                  Icons.send,
                                  color: Colors.white,
                                  size: 20,
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Bolha extends StatelessWidget {
  final Mensagem mensagem;
  final bool minha;

  const _Bolha({required this.mensagem, required this.minha});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: minha ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        decoration: BoxDecoration(
          color: minha ? kPrimary : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(minha ? 16 : 4),
            bottomRight: Radius.circular(minha ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              mensagem.texto,
              style: TextStyle(
                fontFamily: kFont,
                fontSize: 12.5,
                height: 1.3,
                color: minha ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatarHora(mensagem.criadoEm),
              style: TextStyle(
                fontFamily: kFont,
                fontSize: 9,
                color: minha ? Colors.white70 : Colors.grey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
