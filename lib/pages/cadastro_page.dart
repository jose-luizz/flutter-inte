import 'package:flutter/material.dart';

import '../data/api_client.dart';
import '../data/auth_repository.dart';
import 'home_page.dart';
import 'login_page.dart'; // usa kPrimary, kField, kHint e kFont

class CadastroPage extends StatefulWidget {
  const CadastroPage({super.key});

  @override
  State<CadastroPage> createState() => _CadastroPageState();
}

class _CadastroPageState extends State<CadastroPage> {
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _rmController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _userController.dispose();
    _emailController.dispose();
    _rmController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _mostrarMensagem(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg)));
  }

  /// Retorna a mensagem de erro, ou null se tudo estiver válido.
  String? _validar() {
    final usuario = _userController.text.trim();
    final email = _emailController.text.trim();
    final rm = _rmController.text.trim();
    final senha = _passwordController.text;

    if (usuario.isEmpty || email.isEmpty || rm.isEmpty || senha.isEmpty) {
      return 'Preencha todos os campos.';
    }
    if (usuario.length < 3) {
      return 'O nome de usuário deve ter pelo menos 3 caracteres.';
    }
    if (!RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$').hasMatch(email)) {
      return 'Informe um email válido.';
    }
    if (!RegExp(r'^\d{3,20}$').hasMatch(rm)) {
      return 'O RM deve conter apenas números.';
    }
    if (senha.length < 6) {
      return 'A senha deve ter pelo menos 6 caracteres.';
    }
    return null;
  }

  Future<void> _cadastrar() async {
    final erro = _validar();
    if (erro != null) {
      _mostrarMensagem(erro);
      return;
    }

    setState(() => _loading = true);
    try {
      await AuthRepository.instance.cadastrar(
        usuario: _userController.text,
        email: _emailController.text,
        rm: _rmController.text,
        senha: _passwordController.text,
      );
      if (!mounted) return;
      // Conta criada e já logada: vai para a home e limpa o histórico
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomePage()),
        (route) => false,
      );
    } on ApiException catch (e) {
      _mostrarMensagem(e.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF0F0F0),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          Container(
            width: double.infinity,
            height: MediaQuery.of(context).size.height * 0.225,
            color: kPrimary,
            child: const SafeArea(
              bottom: false,
              child: Center(child: _Logo()),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
              child: Column(
                children: [
                  const Text(
                    'Cadastrar',
                    style: TextStyle(
                      fontFamily: kFont,
                      color: kPrimary,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 24),
                  _InputField(
                    controller: _userController,
                    hint: 'Nome de Usuário',
                    icon: Icons.person,
                  ),
                  const SizedBox(height: 14),
                  _InputField(
                    controller: _emailController,
                    hint: 'Email Educacional',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),
                  _InputField(
                    controller: _rmController,
                    hint: 'RM (Registro de Matrícula)',
                    icon: Icons.badge_outlined,
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  _InputField(
                    controller: _passwordController,
                    hint: 'Senha',
                    icon: Icons.lock_outline,
                    obscureText: _obscure,
                    suffix: IconButton(
                      icon: Icon(
                        _obscure
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    width: 200,
                    height: 46,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _cadastrar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kPrimary,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: kPrimary.withOpacity(0.7),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                      child: _loading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Cadastrar',
                              style: TextStyle(
                                fontFamily: kFont,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Já possui Cadastro?  ',
                        style: TextStyle(
                          fontFamily: kFont,
                          color: Colors.grey.shade600,
                          fontSize: 11,
                        ),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: Text(
                          'Entrar',
                          style: TextStyle(
                            fontFamily: kFont,
                            color: Colors.grey.shade700,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            decoration: TextDecoration.underline,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
          TextSpan(
            text: '+',
            style: TextStyle(
              fontFamily: kFont,
              color: Color(0xFFFF3131),
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: -1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool obscureText;
  final Widget? suffix;
  final TextInputType? keyboardType;

  const _InputField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.obscureText = false,
    this.suffix,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(18),
      borderSide: BorderSide(color: Colors.grey.shade400),
    );

    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: kFont, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: kField,
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: kFont, color: kHint, fontSize: 11),
        prefixIcon: Icon(icon, color: Colors.grey.shade500, size: 22),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(vertical: 18),
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: kPrimary, width: 1.2),
        ),
      ),
    );
  }
}
