import 'package:flutter/material.dart';
import 'cadastro_page.dart';

const Color kPrimary = Color(0xFF900C00);
const Color kPanel = Color(0xFFEBEBEB);
const Color kField = Color(0xFFF7F7F7);
const Color kHint = Color(0xFF9E9E9E);

// Fonte usada no app. Se você não adicionou a Poppins no pubspec.yaml,
// o Flutter usa a fonte padrão automaticamente (sem erro).
const String kFont = 'Poppins';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _userController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _userController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    // TODO: integrar com o auth_repository.dart
    debugPrint('Usuário: ${_userController.text}');
    debugPrint('Email: ${_emailController.text}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.2,
              child: const Center(child: _Logo()),
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: kPanel,
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                child: Column(
                  children: [
                    const Text(
                      'Bem vindo(a)!',
                      style: TextStyle(
                        fontFamily: kFont,
                        color: kPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 48),
                    _InputField(
                      controller: _userController,
                      hint: 'Usuário',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: _emailController,
                      hint: 'Email',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    _InputField(
                      controller: _passwordController,
                      hint: 'Senha',
                      icon: Icons.verified_user_outlined,
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
                    const SizedBox(height: 6),
                    Text(
                      'Confira se os dados estão corretos',
                      style: TextStyle(
                        fontFamily: kFont,
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Entrar',
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
                          'Não possui conta?  ',
                          style: TextStyle(
                            fontFamily: kFont,
                            color: Colors.grey.shade600,
                            fontSize: 11,
                          ),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const CadastroPage(),
                              ),
                            );
                          },
                          child: Text(
                            'Cadastre-se',
                            style: TextStyle(
                              fontFamily: kFont,
                              color: Colors.grey.shade700,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
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
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      style: const TextStyle(fontFamily: kFont, fontSize: 13),
      decoration: InputDecoration(
        filled: true,
        fillColor: kField,
        hintText: hint,
        hintStyle: const TextStyle(fontFamily: kFont, color: kHint, fontSize: 12),
        prefixIcon: Icon(icon, color: kPrimary, size: 22),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
