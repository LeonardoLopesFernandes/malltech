import 'package:flutter/material.dart';
import 'package:malltech_flutter/core/datas.dart';
import 'package:malltech_flutter/core/repos.dart';
import 'package:malltech_flutter/core/models.dart';
import 'package:malltech_flutter/core/api.dart';
import 'package:malltech_flutter/screens/curriculo_detalhe.dart';
import 'package:malltech_flutter/widgets/pdf_viewer_screen.dart';

class TrabalheConoscoScreen extends StatefulWidget {
  const TrabalheConoscoScreen({super.key});

  @override
  State<TrabalheConoscoScreen> createState() => _TrabalheConoscoScreenState();
}

class _TrabalheConoscoScreenState extends State<TrabalheConoscoScreen> {
  late Future<List<VagaTrabalhe>> _vagas;
  late Future<List<Curriculo>> _curriculos;

  @override
  void initState() {
    super.initState();
    _vagas = TrabalheRepo.listarVagas();
    _curriculos = TrabalheRepo.listarCurriculos();
  }

  void _refresh() {
    setState(() {
      _vagas = TrabalheRepo.listarVagas();
      _curriculos = TrabalheRepo.listarCurriculos();
    });
  }

  Future<void> _novaVaga() async {
    final cargo = TextEditingController();
    final qtd = TextEditingController();
    final dur = TextEditingController();
    final desc = TextEditingController();
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Vaga'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: cargo,
                decoration: const InputDecoration(labelText: 'Cargo'),
              ),
              TextField(
                controller: qtd,
                decoration: const InputDecoration(labelText: 'Quantidade'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: dur,
                decoration:
                    const InputDecoration(labelText: 'Duração (dias)'),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: desc,
                decoration: const InputDecoration(labelText: 'Descrição'),
                maxLines: 3,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (result == true) {
      try {
        await TrabalheRepo.novaVaga(
          cargo.text, qtd.text, dur.text, desc.text);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(const SnackBar(content: Text('Vaga criada')));
          _refresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text('Erro: $e')));
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Trabalhe Conosco'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Vagas'),
              Tab(text: 'Currículos'),
            ],
          ),
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: _novaVaga,
          backgroundColor: Theme.of(context).primaryColor,
          child: const Icon(Icons.add),
        ),
        body: TabBarView(
          children: [
            _vagasTab(),
            _curriculosTab(),
          ],
        ),
      ),
    );
  }

  Widget _vagasTab() {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: FutureBuilder<List<VagaTrabalhe>>(
        future: _vagas,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Nenhuma vaga.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) {
              final v = items[i];
              return ListTile(
                title: Text(v.cargo),
                subtitle: Text(
                  [v.lojaNome, v.cad, v.entrada, v.saida]
                      .where((e) => e.isNotEmpty)
                      .join(' • '),
                ),
                trailing: v.aprovado
                    ? const Chip(label: Text('Aprovada'))
                    : v.reprovado
                        ? const Chip(label: Text('Reprovada'))
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.check),
                                onPressed: () async {
                                  await TrabalheRepo.ativar(v.id);
                                  _refresh();
                                },
                              ),
                              IconButton(
                                icon: const Icon(Icons.close),
                                onPressed: () async {
                                  await TrabalheRepo.desativar(v.id);
                                  _refresh();
                                },
                              ),
                            ],
                          ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _curriculosTab() {
    return RefreshIndicator(
      onRefresh: () async => _refresh(),
      child: FutureBuilder<List<Curriculo>>(
        future: _curriculos,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Nenhum currículo.'));
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (ctx, i) {
              final c = items[i];
              return ListTile(
                leading: Icon(
                  c.lido ? Icons.visibility : Icons.visibility_off,
                  color: c.lido
                      ? Colors.grey
                      : Theme.of(ctx).primaryColor,
                ),
                title: Text(c.nome),
                subtitle: Text(
                  [c.vaga, c.cargo, c.email, formatarData(c.data)]
                      .where((e) => e.isNotEmpty)
                      .join(' • '),
                ),
                trailing: c.cvUrl != null
                    ? IconButton(
                        icon: Icon(Icons.picture_as_pdf,
                            color: Theme.of(ctx).primaryColor),
                        tooltip: 'Visualizar CV',
                        onPressed: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => PdfViewerScreen(
                              title: c.nome,
                              url: c.cvUrl!,
                              cookie: Api.phpsessid.isNotEmpty
                                  ? 'PHPSESSID=${Api.phpsessid}'
                                  : null,
                            ),
                          ),
                        ),
                      )
                    : null,
                onTap: () => Navigator.push(
                  ctx,
                  MaterialPageRoute(
                    builder: (_) => CurriculoDetalhePage(c: c),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
