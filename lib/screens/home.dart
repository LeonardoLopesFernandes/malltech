import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:malltech_flutter/core/session.dart';

String _nomeExibicao(String nome) {
  var limpo = nome.split('@').first;
  limpo = limpo.replaceAll(RegExp(r'[^A-Za-zÀ-ÿ\s]'), ' ');
  limpo = limpo.replaceAll(RegExp(r'\s+'), ' ').trim();
  return limpo.isEmpty ? nome : limpo;
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  void _logout(BuildContext context) {
    Session.clear();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvoked: (didPop) async {
        if (didPop) return;
        final sair = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Sair do app'),
            content: const Text('Deseja realmente sair do aplicativo?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Sair'),
              ),
            ],
          ),
        );
        if (sair == true && context.mounted) {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
      appBar: AppBar(
        title: ValueListenableBuilder(
          valueListenable: Session.usuario,
          builder: (_, user, __) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _nomeExibicao(user?.nome ?? ''),
                style: const TextStyle(
                    fontSize: 17, fontWeight: FontWeight.bold),
              ),
              if ((user?.lojaNome ?? '').isNotEmpty)
                Text(
                  user!.lojaNome,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurfaceVariant),
                ),
            ],
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: GridView.count(
        padding: const EdgeInsets.all(16),
        crossAxisCount: 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        children: _modules(context),
      ),
      ),
    );
  }

  List<Widget> _modules(BuildContext context) {
    final items = [
      _Module('Boletos', '2ª via e pagamentos', Icons.receipt_long, () =>
          Navigator.pushNamed(context, '/boletos')),
      _Module('Comunicados', 'Avisos do shopping', Icons.campaign, () =>
          Navigator.pushNamed(context, '/comunicados')),
      _Module('Correspondência', 'Retirada e devolução', Icons.mail, () =>
          Navigator.pushNamed(context, '/correspondencia')),
      _Module('Arquivos', 'Arquivos e manuais', Icons.folder_open, () =>
          Navigator.pushNamed(context, '/arquivos')),
      _Module('Fale Conosco', 'Chamados e dúvidas', Icons.chat, () =>
          Navigator.pushNamed(context, '/fale')),
      _Module('Palestras e Cursos', 'Inscrições e eventos', Icons.school, () =>
          Navigator.pushNamed(context, '/cursos')),
      _Module('Pedidos', 'Acompanhar e executar', Icons.assignment, () =>
          Navigator.pushNamed(context, '/pedidos')),
      _Module('Trabalhe Conosco', 'Vagas e cadastros', Icons.work, () =>
          Navigator.pushNamed(context, '/trabalhe')),
      _Module('Configurações', 'Perfil e senha', Icons.settings, () =>
          Navigator.pushNamed(context, '/configuracoes')),
      _Module('Vitrine', 'Produtos da loja', Icons.store, () =>
          Navigator.pushNamed(context, '/guia')),
    ];
    return items
        .map((m) => _card(m, context))
        .toList();
  }

  Widget _card(_Module m, BuildContext context) {
    return InkWell(
      onTap: m.onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(m.icon, size: 40, color: const Color(0xFFFF2D55)),
            const SizedBox(height: 10),
            Text(
              m.label,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 4),
            Text(
              m.descricao,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }
}

class _Module {
  final String label;
  final String descricao;
  final IconData icon;
  final VoidCallback onTap;
  _Module(this.label, this.descricao, this.icon, this.onTap);
}
