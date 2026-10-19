import 'dart:async';

import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/reading_repository.dart';
import '../models/post.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/post_card.dart';
import 'login_page.dart'; // usa kPrimary, kHint e kFont

class BuscarPage extends StatefulWidget {
  const BuscarPage({super.key});

  @override
  State<BuscarPage> createState() => _BuscarPageState();
}

class _BuscarPageState extends State<BuscarPage> {
  final _repo = ReadingRepository.instance;
  final _controller = TextEditingController();

  Timer? _debounce;
  int _requestId = 0; // descarta respostas antigas

  List<Post> _resultados = [];
  String _termoBuscado = '';
  bool _loading = false;
  String? _erro;

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  /// Espera 400 ms depois da última tecla antes de buscar.
  void _onChanged(String value) {
    _debounce?.cancel();
    final termo = value.trim();

    if (termo.isEmpty) {
      _requestId++;
      setState(() {
        _resultados = [];
        _termoBuscado = '';
        _loading = false;
        _erro = null;
      });
      return;
    }

    setState(() => _loading = true);
    _debounce = Timer(const Duration(milliseconds: 400), () => _buscar(termo));
  }

  Future<void> _buscar(String termo) async {
    final id = ++_requestId;
    setState(() {
      _loading = true;
      _erro = null;
    });

    try {
      final resultados = await _repo.buscar(termo);
      if (!mounted || id != _requestId) return;
      setState(() {
        _resultados = resultados;
        _termoBuscado = termo;
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

  void _limpar() {
    _controller.clear();
    _onChanged('');
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

  Widget _buildResultados() {
    final termo = _controller.text.trim();

    if (termo.isEmpty) {
      return _mensagem(
        'Digite algo para buscar publicações\npelo texto ou pelo autor.',
      );
    }

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
                onPressed: () => _buscar(termo),
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

    if (_resultados.isEmpty) {
      return _mensagem('Nenhuma publicação encontrada\npara "$_termoBuscado".');
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: _resultados.length,
      separatorBuilder: (_, __) => const SizedBox(height: 20),
      itemBuilder: (_, i) => PostCard(post: _resultados[i]),
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
            const Padding(
              padding: EdgeInsets.only(top: 12, bottom: 12),
              child: _Logo(),
            ),
            // Campo de busca
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
                  textInputAction: TextInputAction.search,
                  onChanged: _onChanged,
                  onSubmitted: (value) {
                    _debounce?.cancel();
                    final termo = value.trim();
                    if (termo.isNotEmpty) _buscar(termo);
                  },
                  style: const TextStyle(fontFamily: kFont, fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Buscar publicações...',
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
                            onPressed: _limpar,
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
            Expanded(child: _buildResultados()),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 8, 28, 14),
              child: const AppBottomNav(currentIndex: 1),
            ),
          ],
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
