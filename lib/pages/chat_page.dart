import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/chat_repository.dart';
import '../models/chat_models.dart';
import '../widgets/app_bottom_nav.dart';
import 'conversa_page.dart';
import 'login_page.dart'; // usa kPrimary e kFont
import 'novo_chat_page.dart';

/// Lista de conversas.
class ChatPage extends StatefulWidget {
  const ChatPage({super.key});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _repo = ChatRepository.instance;

  List<Conversa> _conversas = [];
  bool _loading = true;
  String? _erro;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _carregar();
    // Atualiza a lista a cada 5 segundos
    _timer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _carregar(silencioso: true),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _carregar({bool silencioso = false}) async {
    try {
      final conversas = await _repo.listarConversas();
      if (!mounted) return;
      setState(() {
        _conversas = conversas;
        _erro = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      // Na atualização automática, não apaga o que já está na tela
      if (silencioso && _conversas.isNotEmpty) return;
      setState(() {
        _erro = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _abrir(int usuarioId, String usuario) async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ConversaPage(usuarioId: usuarioId, usuario: usuario),
      ),
    );
    _carregar(silencioso: true);
  }

  Future<void> _novaConversa() async {
    final contato = await Navigator.of(context).push<Contato>(
      MaterialPageRoute(builder: (_) => const NovoChatPage()),
    );
    if (contato == null || !mounted) return;
    await _abrir(contato.id, contato.usuario);
  }

  Widget _buildLista() {
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

    return RefreshIndicator(
      color: kPrimary,
      onRefresh: _carregar,
      child: _conversas.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: [
                const SizedBox(height: 80),
                Center(
                  child: Text(
                    'Você ainda não tem conversas.\nToque em + para começar uma.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: kFont,
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              itemCount: _conversas.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (_, i) {
                final c = _conversas[i];
                return _ConversaTile(
                  conversa: c,
                  onTap: () => _abrir(c.usuarioId, c.usuario),
                );
              },
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 12),
              child: _Logo(),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 20, 12),
              child: Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Conversas',
                      style: TextStyle(
                        fontFamily: kFont,
                        color: kPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Material(
                    color: kPrimary,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: _novaConversa,
                      child: const Padding(
                        padding: EdgeInsets.all(8),
                        child: Icon(Icons.add, color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(child: _buildLista()),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 8, 28, 14),
              child: AppBottomNav(currentIndex: 2),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConversaTile extends StatelessWidget {
  final Conversa conversa;
  final VoidCallback onTap;

  const _ConversaTile({required this.conversa, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final previa = conversa.minha
        ? 'Você: ${conversa.ultimaMensagem}'
        : conversa.ultimaMensagem;

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      elevation: 1.5,
      shadowColor: Colors.black26,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: kPrimary,
                child: Icon(Icons.person, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      conversa.usuario,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      previa,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontFamily: kFont,
                        fontSize: 11.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formatarDataLista(conversa.criadoEm),
                style: TextStyle(
                  fontFamily: kFont,
                  fontSize: 10,
                  color: Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Logo extends StatelessWidget {
  const _Logo();

  @override
  Widget build(BuildContext context) {
    return RichText(
      text: const TextSpan(
        children: [
          TextSpan(
            text: 'Integra',
            style: TextStyle(
              fontFamily: kFont,
              color: Colors.black,
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
          TextSpan(
            text: '+',
            style: TextStyle(
              fontFamily: kFont,
              color: Color(0xFFFF3131),
              fontSize: 26,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.2,
            ),
          ),
        ],
      ),
    );
  }
}
