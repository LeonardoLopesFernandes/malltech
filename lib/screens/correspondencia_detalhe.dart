import 'package:flutter/material.dart';
import 'package:malltech_flutter/core/datas.dart';
import 'package:malltech_flutter/core/models.dart';
import 'package:malltech_flutter/core/repos.dart';

class CorrespondenciaDetalhePage extends StatelessWidget {
  final Correspondencia c;
  const CorrespondenciaDetalhePage({super.key, required this.c});

  Future<void> _acao(
    BuildContext context,
    Future<void> Function() fn,
    String ok,
  ) async {
    try {
      await fn();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correspondência'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Devolver',
            onPressed: () =>
                _acao(context, () => CorrespondenciaRepo.devolver(c.cId), 'Devolvido'),
          ),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'comunicado') {
                _acao(context, () => CorrespondenciaRepo.gerarComunicado(c.cId),
                    'Comunicado gerado');
              } else if (v == 'excluir') {
                _acao(context, () => CorrespondenciaRepo.excluir(c.cId), 'Excluído');
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'comunicado', child: Text('Gerar comunicado')),
              PopupMenuItem(value: 'excluir', child: Text('Excluir')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Cabeçalho
          Card(
            color: Theme.of(context).primaryColor,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.nome,
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 18)),
                  const SizedBox(height: 6),
                  Text(c.tipo,
                      style: const TextStyle(color: Colors.white, fontSize: 14)),
                  if (c.codigo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Código: ${c.codigo}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Informações
          const Text('Informações',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _linha(context, 'Status', c.status),
                  _linha(context, 'Tipo', c.tipo),
                  _linha(context, 'Código', c.codigo),
                  _linha(context, 'Entrada', formatarData(c.entradaFormatada)),
                  _linha(context, 'Saída', formatarData(c.saidaFormatada)),
                  _linha(context, 'Postagem', formatarData(c.postagem)),
                  _linha(context, 'Cadastro', formatarData(c.cadFormatada)),
                  _linha(context, 'CDD', c.cdd),
                ],
              ),
            ),
          ),

          // Retirado por
          if (c.retiradoNome.isNotEmpty || c.retiradoCpf.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Retirado por',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _linha(context, 'Nome', c.retiradoNome),
                    _linha(context, 'CPF', c.retiradoCpf),
                  ],
                ),
              ),
            ),
          ],

          // Descrição
          if (c.descricao.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Descrição',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(c.descricao),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _linha(BuildContext context, String rotulo, String valor) {
    if (valor.isEmpty) return const SizedBox.shrink();
    final onSurface = Theme.of(context).colorScheme.onSurface;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: TextStyle(color: onSurface, fontSize: 13),
          children: [
            TextSpan(
              text: '$rotulo: ',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }
}
