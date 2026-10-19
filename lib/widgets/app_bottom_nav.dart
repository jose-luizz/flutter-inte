import 'package:flutter/material.dart';

import '../pages/buscar_page.dart';
import '../pages/chat_page.dart';

/// Barra de navegação inferior: 0 = Home, 1 = Buscar, 2 = Chat, 3 = Perfil.
/// Ela mesma cuida da navegação: basta informar em qual aba a tela está.
class AppBottomNav extends StatelessWidget {
  final int currentIndex;

  const AppBottomNav({super.key, required this.currentIndex});

  void _ir(BuildContext context, int destino) {
    if (destino == currentIndex) return;

    // Home é a primeira rota da pilha: volta até ela
    if (destino == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    final Widget? pagina = destino == 1
        ? const BuscarPage()
        : destino == 2
            ? const ChatPage()
            : null; // TODO: 3 = Perfil (perfil_page)
    if (pagina == null) return;

    final rota = MaterialPageRoute(builder: (_) => pagina);
    if (currentIndex == 0) {
      Navigator.of(context).push(rota);
    } else {
      Navigator.of(context).pushReplacement(rota);
    }
  }

  @override
  Widget build(BuildContext context) {
    const icons = [
      Icons.home_filled,
      Icons.search,
      Icons.sms_outlined,
      Icons.person,
    ];

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: List.generate(icons.length, (i) {
          return IconButton(
            onPressed: () => _ir(context, i),
            icon: Icon(
              icons[i],
              size: 28,
              color: i == currentIndex ? Colors.black : Colors.black54,
            ),
          );
        }),
      ),
    );
  }
}
