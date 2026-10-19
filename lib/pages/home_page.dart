import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/reading_repository.dart';
import '../models/post.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/post_card.dart';
import 'login_page.dart'; // usa kPrimary, kHint e kFont

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _repo = ReadingRepository.instance;
  final _postController = TextEditingController();

  List<Post> _posts = [];
  bool _loading = true;
  bool _publishing = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  @override
  void dispose() {
    _postController.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _carregar() async {
    try {
      final posts = await _repo.listarPosts();
      if (!mounted) return;
      setState(() {
        _posts = posts;
        _erro = null;
        _loading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _erro = e.message;
        _loading = false;
      });
    }
  }

  Future<void> _publicar() async {
    final texto = _postController.text.trim();
    if (texto.isEmpty || _publishing) return;

    setState(() => _publishing = true);
    try {
      final novo = await _repo.publicar(texto);
      if (!mounted) return;
      setState(() {
        _posts.insert(0, novo);
        _postController.clear();
      });
      FocusScope.of(context).unfocus();
    } on ApiException catch (e) {
      _mostrarMensagem(e.message);
    } finally {
      if (mounted) setState(() => _publishing = false);
    }
  }

  Widget _buildFeed() {
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
      child: _posts.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              children: const [
                SizedBox(height: 80),
                Center(
                  child: Text(
                    'Nenhuma publicação ainda.\nSeja o primeiro a compartilhar!',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontFamily: kFont, fontSize: 12),
                  ),
                ),
              ],
            )
          : ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              itemCount: _posts.length,
              separatorBuilder: (_, __) => const SizedBox(height: 20),
              itemBuilder: (_, i) => PostCard(post: _posts[i]),
            ),
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
            Expanded(child: _buildFeed()),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: _Composer(
                controller: _postController,
                publishing: _publishing,
                onPublish: _publicar,
              ),
            ),
            const SizedBox(height: 14),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 0, 28, 14),
              child: const AppBottomNav(currentIndex: 0),
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

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool publishing;
  final VoidCallback onPublish;

  const _Composer({
    required this.controller,
    required this.publishing,
    required this.onPublish,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
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
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: controller,
            minLines: 1,
            maxLines: 3,
            maxLength: 1000,
            buildCounter: (_, {required currentLength, required isFocused, maxLength}) => null,
            style: const TextStyle(fontFamily: kFont, fontSize: 11),
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFEDEDED),
              hintText: 'Compartilhe uma ideia, dúvida ou projeto...',
              hintStyle: const TextStyle(
                fontFamily: kFont,
                color: kHint,
                fontSize: 10,
              ),
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 24,
            child: ElevatedButton(
              onPressed: publishing ? null : onPublish,
              style: ElevatedButton.styleFrom(
                backgroundColor: kPrimary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: kPrimary.withOpacity(0.7),
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: publishing
                  ? const SizedBox(
                      height: 12,
                      width: 12,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        color: Colors.white,
                      ),
                    )
                  : const Text(
                      'Publicar',
                      style: TextStyle(
                        fontFamily: kFont,
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
