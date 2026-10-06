import 'package:flutter/material.dart';
import 'login_page.dart'; // Importa kPrimary, kPanel, kField, kHint e kFont

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

  @override
  void dispose() {
    _userController.dispose();
    _emailController.dispose();
    _rmController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _cadastrar() {
    // TODO: integrar com o auth_repository.dart
    debugPrint('Usuário: ${_userController.text}');
    debugPrint('Email: ${_emailController.text}');
    debugPrint('RM: ${_rmController.text}');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimary,
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          // Área Superior / Logo
          SafeArea(
            bottom: false,
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.2,
              child: const Center(child: _Logo()),
            ),
          ),
          
          // Painel principal do cadastro (fundo kPanel com borda arredondada no topo)
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                color: kPanel,
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(28),
                ),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
                child: Column(
                  children: [
                    const Text(
                      'Cadastrar',
                      style: TextStyle(
                        fontFamily: kFont,
                        color: kPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 24),
                    
                    // 1. Nome de Usuário
                    _InputField(
                      controller: _userController,
                      hint: 'Nome de Usuário',
                      icon: Icons.person,
                    ),
                    const SizedBox(height: 12),
                    
                    // 2. Email Educacional
                    _InputField(
                      controller: _emailController,
                      hint: 'Email Educacional',
                      icon: Icons.mail_outline,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 12),
                    
                    // 3. RM (Registro de Matrícula)
                    _InputField(
                      controller: _rmController,
                      hint: 'RM (Registro de Matrícula)',
                      icon: Icons.badge_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    
                    // 4. Senha
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
                    const SizedBox(height: 22),
                    
                    // Botão Cadastrar (200px de largura, estilo arredondado)
                    SizedBox(
                      width: 200,
                      height: 44,
                      child: ElevatedButton(
                        onPressed: _cadastrar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kPrimary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
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
                    
                    // Link de navegação para Voltar / Login
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
        hintStyle: const TextStyle(
          fontFamily: kFont,
          color: kHint,
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, color: kPrimary, size: 22),
        suffixIcon: suffix,
        contentPadding: const EdgeInsets.symmetric(vertical: 16),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none, // Sem borda externa
        ),
      ),
    );
  }
}