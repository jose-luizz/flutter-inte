import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/chat_repository.dart';
import '../models/chat_models.dart';
import 'login_page.dart'; // usa kPrimary, kHint e kFont

/// Escolher com quem conversar. Fecha devolvendo o [Contato] escolhido.
class NovoChatPage extends StatefulWidget {
  const NovoChatPage({super.key});

  @override
  State<NovoChatPage> createState() => _NovoChatPageState();
}

class _NovoChatPageState extends State<NovoChatPage> {
  final _repo = ChatRepository.instance;
  final _controller = TextEditingController();

  Timer? _debounce;
  int _requestId = 0; // descarta respostas antigas

  List<Contato> _contatos = [];
  bool _loading = true;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _buscar('');
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String value) {
    _debounce?.cancel();
    setState(() {}); // atualiza o botão de limpar
    _debounce = Timer(const Duration(milliseconds: 400), () => _buscar(value));
  }

  Future<void> _buscar(String termo) async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _erro = null;
    });
    try {
      final contatos = await _repo.listarContatos(busca: termo);
      if (!mounted || id != _requestId) return;
      setState(() {
        _contatos = contatos;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted || id != _requestId) return;
      setState(() {
        _erro = e.message;
        _loading = false;
      });
    }
  }

  Widget _mensagem(String texto) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Text(
          texto,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontFamily: kFont,
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ),
    );
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
                onPressed: () => _buscar(_controller.text),
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

    if (_contatos.isEmpty) {
      return _mensagem('Nenhuma pessoa encontrada.');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _contatos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final c = _contatos[i];
        return Material(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          elevation: 1.5,
          shadowColor: Colors.black26,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => Navigator.of(context).pop(c),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const CircleAvatar(
                    radius: 18,
                    backgroundColor: kPrimary,
                    child: Icon(Icons.person, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      c.usuario,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: kFont,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 20, 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_ios_new, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                  const Text(
                    'Nova conversa',
                    style: TextStyle(
                      fontFamily: kFont,
                      color: kPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: TextField(
                  controller: _controller,
                  autofocus: true,
                  onChanged: _onChanged,
                  style: const TextStyle(fontFamily: kFont, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar pessoa pelo nome...',
                    hintStyle: const TextStyle(
                      fontFamily: kFont,
                      color: kHint,
                      fontSize: 12,
                    ),
                    prefixIcon: const Icon(Icons.search, color: kPrimary),
                    suffixIcon: _controller.text.isEmpty
                        ? null
                        : IconButton(
                            icon: Icon(
                              Icons.close,
                              size: 20,
                              color: Colors.grey.shade500,
                            ),
                            onPressed: () {
                              _controller.clear();
                              _onChanged('');
                            },
                          ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),
            ),
            Expanded(child: _buildLista()),
          ],
        ),
      ),
    );
  }
}
