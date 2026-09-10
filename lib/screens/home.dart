import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:malltech_flutter/core/session.dart';

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
        title: const Text('Malltech'),
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
      _Module('Pedidos', Icons.assignment, () =>
          Navigator.pushNamed(context, '/pedidos')),
      _Module('Cursos', Icons.school, () =>
          Navigator.pushNamed(context, '/cursos')),
      _Module('Trabalhe Conosco', Icons.work, () =>
          Navigator.pushNamed(context, '/trabalhe')),
      _Module('Arquivos', Icons.folder_open, () =>
          Navigator.pushNamed(context, '/arquivos')),
      _Module('Comunicados', Icons.campaign, () =>
          Navigator.pushNamed(context, '/comunicados')),
      _Module('Fale Conosco', Icons.chat, () =>
          Navigator.pushNamed(context, '/fale')),
      _Module('Boletos', Icons.receipt_long, () =>
          Navigator.pushNamed(context, '/boletos')),
      _Module('Guia', Icons.store, () =>
          Navigator.pushNamed(context, '/guia')),
      _Module('Correspondência', Icons.mail, () =>
          Navigator.pushNamed(context, '/correspondencia')),
      _Module('Configurações', Icons.settings, () =>
          Navigator.pushNamed(context, '/configuracoes')),
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
          ],
        ),
      ),
    );
  }
}

class _Module {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  _Module(this.label, this.icon, this.onTap);
}
