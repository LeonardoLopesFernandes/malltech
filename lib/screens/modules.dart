import 'package:flutter/material.dart';
import 'package:html/parser.dart' as html_parser;
import 'package:malltech_flutter/core/api.dart';
import 'package:malltech_flutter/core/datas.dart';
import 'package:malltech_flutter/core/session.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:malltech_flutter/core/repos.dart' show ComunicadoRepo,
    ArquivosRepo, FaleConoscoRepo, BoletosRepo, GuiaRepo, CorrespondenciaRepo;
import 'package:malltech_flutter/core/models.dart';
import 'package:malltech_flutter/widgets/list_screen.dart';
import 'package:malltech_flutter/widgets/pdf_viewer_screen.dart';
import 'package:malltech_flutter/screens/correspondencia_detalhe.dart';
import 'package:malltech_flutter/screens/novo_produto_screen.dart';

String _textoLimpo(String html) {
  String texto;
  try {
    texto = html_parser.parse(html).body?.text ?? html;
  } catch (_) {
    texto = html.replaceAll(RegExp(r'<[^>]*>'), '');
  }
  final linhas = texto.split('\n').map((l) => l.trim()).where((l) {
    if (l.isEmpty) return false;
    // Descarta linhas só com números/pontuação (ex: "17:3", "26.", "09:4")
    if (RegExp(r'^[\d\s.:,;/\-]+$').hasMatch(l)) return false;
    return true;
  }).toList();
  var junto = linhas.join('\n');
  // Remove marcadores inline tipo "17:3" (minuto de 1 dígito = sujeira, não horário)
  junto = junto.replaceAll(RegExp(r'\b\d+:\d\b'), '');
  junto = junto.replaceAll(RegExp(r'[ \t]{2,}'), ' ');
  junto = junto.replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
  return junto.isEmpty
      ? html.replaceAll(RegExp(r'<[^>]*>'), '')
      : junto;
}

class ComunicadosScreen extends StatefulWidget {
  const ComunicadosScreen({super.key});

  @override
  State<ComunicadosScreen> createState() => _ComunicadosScreenState();
}

class _ComunicadosScreenState extends State<ComunicadosScreen> {
  static const _kLidos = 'comunicados_lidos';
  final _lidos = <int>{};

  @override
  void initState() {
    super.initState();
    _carregarLidos();
  }

  Future<void> _carregarLidos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lista = prefs.getStringList(_kLidos) ?? [];
      _lidos
        ..clear()
        ..addAll(lista.map(int.parse).toList());
    } catch (_) {}
    if (mounted) setState(() {});
  }

  Future<void> _salvarLidos() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList(
          _kLidos, _lidos.map((e) => e.toString()).toList());
    } catch (_) {}
  }

  void _marcarLido(int id) {
    _lidos.add(id);
    _salvarLidos();
  }

  Future<void> _abrirDetalhe(BuildContext context, Comunicado c) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
    try {
      final d = await ComunicadoRepo.detalhe(c.id);
      if (!context.mounted) return;
      Navigator.pop(context);
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(d.nome.isNotEmpty ? d.nome : c.nome),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_textoLimpo(d.texto)),
                if (d.anexos.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  const Text('Anexos:',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  ...d.anexos.map((a) => ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.attach_file),
                        title: Text(a.nome),
                        onTap: () {
                          Navigator.push(
                            ctx,
                            MaterialPageRoute(
                              builder: (_) => PdfViewerScreen(
                                title: a.nome,
                                url: a.url,
                              ),
                            ),
                          );
                        },
                      )),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar'),
            ),
            ElevatedButton(
              onPressed: () async {
                try {
                  await ComunicadoRepo.confirmar(c.id);
                  if (ctx.mounted) {
                    setState(() => _marcarLido(c.id));
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Leitura confirmada')),
                    );
                  }
                } catch (e) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(content: Text('Erro: $e')),
                    );
                  }
                }
              },
              child: const Text('Confirmar leitura'),
            ),
          ],
        ),
      );
    } catch (e) {
      if (!context.mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Falha ao carregar detalhe: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListScreen(
      title: 'Comunicados',
      loader: ComunicadoRepo.listar,
      emptyText: 'Nenhum comunicado.',
      itemBuilder: (ctx, item, _) {
        final c = item as Comunicado;
        final lido = _lidos.contains(c.id);
        return ListTile(
          title: Text(c.nome.isNotEmpty ? c.nome : c.pessoa),
          subtitle: Text(
            [c.empreendimento, formatarData(c.data)]
                .where((e) => e.isNotEmpty)
                .join(' • '),
          ),
          trailing: lido
              ? const Icon(Icons.check_circle,
                  color: Colors.green, size: 28)
              : IconButton(
                  icon: const Icon(Icons.check_circle_outline),
                  tooltip: 'Confirmar',
                  onPressed: () async {
                    try {
                      await ComunicadoRepo.confirmar(c.id);
                      if (ctx.mounted) {
setState(() => _marcarLido(c.id));
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(
                              content: Text('Comunicado confirmado')),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          SnackBar(content: Text('Erro: $e')),
                        );
                      }
                    }
                  },
                ),
          onTap: () => _abrirDetalhe(ctx, c),
        );
      },
    );
  }
}

class ArquivosScreen extends StatelessWidget {
  const ArquivosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListScreen(
      title: 'Arquivos',
      loader: ArquivosRepo.listar,
      emptyText: 'Nenhum documento.',
      itemBuilder: (ctx, item, _) {
        final d = item as Documento;
        return ListTile(
          leading: Icon(
            d.foiLido ? Icons.description : Icons.mark_as_unread,
            color: d.foiLido
                ? Colors.grey
                : Theme.of(ctx).primaryColor,
          ),
          title: Text(d.titulo),
          subtitle: Text(
            [d.tipo, formatarData(d.vigencia)]
                .where((e) => e.isNotEmpty)
                .join(' • '),
          ),
          onTap: () async {
            try {
              await ArquivosRepo.marcarLido(d.id);
            } catch (_) {}
            if (d.arquivo != null && d.arquivo!.isNotEmpty && ctx.mounted) {
              final base = d.arquivo!.startsWith('http')
                  ? d.arquivo!
                  : '${ApiConfig.v3}${d.arquivo!}';
              final sep = base.contains('?') ? '&' : '?';
              final token = Session.token.value;
              final url = token != null && token.isNotEmpty
                  ? '$base${sep}token=$token&integrated=true'
                  : base;
              final cookies = Api.phpsessid.isNotEmpty
                  ? 'PHPSESSID=${Api.phpsessid}'
                  : null;
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => PdfViewerScreen(
                    title: d.titulo,
                    url: url,
                    cookie: cookies,
                  ),
                ),
              );
            }
          },
        );
      },
    );
  }
}

class FaleConoscoScreen extends StatefulWidget {
  const FaleConoscoScreen({super.key});

  @override
  State<FaleConoscoScreen> createState() => _FaleConoscoScreenState();
}

class _FaleConoscoScreenState extends State<FaleConoscoScreen> {
  String _filtro = '';
  late Future<List<FaleConosco>> _future;

  static const _filtros = [
    ['', 'Todos'],
    ['pendente', 'Pendentes'],
    ['respondido', 'Respondidos'],
    ['finalizado', 'Finalizados'],
  ];

  @override
  void initState() {
    super.initState();
    _future = FaleConoscoRepo.listar(_filtro);
  }

  void _recarregar() {
    setState(() => _future = FaleConoscoRepo.listar(_filtro));
  }

  Widget _linha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rotulo,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(valor,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _detalhe(BuildContext context, FaleConosco f) async {
    final resposta = TextEditingController();
    var enviando = false;
    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialog) => AlertDialog(
          title: Text(f.assunto),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _linha('Tipo', f.tipo),
                _linha('Loja', f.empreendimento),
                _linha('Data', f.cad),
                _linha('Mensagem', _textoLimpo(f.mensagem)),
                _linha('Situação', f.statusLabel),
                if (f.finalizado < 1) ...[
                  const SizedBox(height: 8),
                  const Text('Nova mensagem',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: resposta,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: 'Digite a resposta...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Fechar'),
            ),
            if (f.finalizado < 1)
              ElevatedButton(
                onPressed: enviando
                    ? null
                    : () async {
                        final texto = resposta.text.trim();
                        if (texto.isEmpty) return;
                        setDialog(() => enviando = true);
                        try {
                          await FaleConoscoRepo.responder(f.id, texto);
                          if (ctx.mounted) {
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context)
                                .showSnackBar(const SnackBar(
                                    content:
                                        Text('Resposta enviada')));
                            _recarregar();
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                                SnackBar(content: Text('Falha: $e')));
                          }
                        } finally {
                          if (ctx.mounted) {
                            setDialog(() => enviando = false);
                          }
                        }
                      },
                child: Text(enviando ? 'Enviando...' : 'Enviar resposta'),
              ),
          ],
        ),
      ),
    );
    resposta.dispose();
  }

  Future<void> _finalizar(BuildContext context, FaleConosco f) async {
    try {
      await FaleConoscoRepo.finalizar(f.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Chamado finalizado')),
        );
        _recarregar();
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
        title: const Text('Fale Conosco'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recarregar,
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final f in _filtros)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f[1]),
                      selected: _filtro == f[0],
                      onSelected: (_) {
                        setState(() => _filtro = f[0]);
                        _recarregar();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<FaleConosco>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Erro: ${snap.error}'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _recarregar,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                      child: Text('Nenhum chamado encontrado'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final f = items[i];
                    return ListTile(
                      title: Text(f.assunto),
                      subtitle: Text(
                        [f.statusLabel, f.empreendimento, f.cad]
                            .where((e) => e.isNotEmpty)
                            .join(' • '),
                      ),
                      trailing: f.finalizado >= 1
                          ? const Chip(label: Text('Finalizado'))
                          : IconButton(
                              icon: const Icon(Icons.check),
                              tooltip: 'Finalizar',
                              onPressed: () =>
                                  _finalizar(context, f),
                            ),
                      onTap: () => _detalhe(context, f),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class BoletosScreen extends StatelessWidget {
  const BoletosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListScreen(
      title: 'Boletos',
      loader: BoletosRepo.listar,
      emptyText: 'Nenhum boleto.',
      itemBuilder: (ctx, item, __) {
        final b = item as Boleto;
        return ListTile(
          title: Text(b.descricao ?? b.loja),
          subtitle: Text(
            [b.valor, b.vencimento, b.status]
                .where((e) => e.isNotEmpty)
                .join(' • '),
          ),
          trailing: b.boleto != null
              ? const Icon(Icons.receipt_long)
              : null,
          onTap: b.boleto == null || b.boleto!.isEmpty
              ? null
              : () {
                  final base = b.boleto!.startsWith('http')
                      ? b.boleto!
                      : '${ApiConfig.v3}${b.boleto!}';
                  final sep = base.contains('?') ? '&' : '?';
                  final token = Session.token.value;
                  final url = token != null && token.isNotEmpty
                      ? '$base${sep}token=$token&integrated=true'
                      : base;
                  final cookies = Api.phpsessid.isNotEmpty
                      ? 'PHPSESSID=${Api.phpsessid}'
                      : null;
                  Navigator.push(
                    ctx,
                    MaterialPageRoute(
                      builder: (_) => PdfViewerScreen(
                        title: b.descricao ?? 'Boleto',
                        url: url,
                        cookie: cookies,
                      ),
                    ),
                  );
                },
        );
      },
    );
  }
}

class GuiaScreen extends StatefulWidget {
  const GuiaScreen({super.key});

  @override
  State<GuiaScreen> createState() => _GuiaScreenState();
}

class _GuiaScreenState extends State<GuiaScreen> {
  String _filtro = '-1';
  late Future<List<ProdutoVitrine>> _future;

  static const _filtros = [
    ['-1', 'Todos'],
    ['0', 'Pendentes'],
    ['1', 'Aprovados'],
    ['2', 'Reprovados'],
    ['4', 'Excluídos'],
  ];

  @override
  void initState() {
    super.initState();
    _future = GuiaRepo.listar(_filtro);
  }

  void _recarregar() {
    setState(() => _future = GuiaRepo.listar(_filtro));
  }

  Future<void> _acao(
      BuildContext context, ProdutoVitrine p, String status, String okMsg,
      {bool excluir = false}) async {
    final confirma = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(excluir ? 'Excluir produto?' : 'Confirmar?'),
        content: Text('${p.nome} será ${status.toLowerCase()}.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );
    if (confirma != true || !context.mounted) return;
    try {
      if (excluir) {
        await GuiaRepo.excluir(p.id);
      } else {
        await GuiaRepo.definirStatus(p.id, status);
      }
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(okMsg)));
        _recarregar();
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Falha: $e')));
      }
    }
  }

  void _detalhe(BuildContext context, ProdutoVitrine p) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(p.nome),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if ((p.sku ?? '').isNotEmpty) _linha('SKU', p.sku!),
            if ((p.valor ?? '').isNotEmpty) _linha('Valor', 'R\$ ${p.valor}'),
            _linha('Loja', p.lojaNome),
            _linha('Empreendimento', p.empreendimentoNome),
            _linha('Status', p.status),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fechar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _acao(context, p, 'aprovado', 'Produto aprovado');
            },
            child: const Text('Aprovar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _acao(context, p, 'reprovado', 'Produto reprovado');
            },
            child: const Text('Reprovar'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _acao(context, p, '', 'Produto excluído', excluir: true);
            },
            child: const Text('Excluir',
                style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Widget _linha(String rotulo, String valor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(rotulo,
              style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(valor,
              style: const TextStyle(
                  fontSize: 15, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Vitrine'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Novo produto',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const NovoProdutoScreen(),
              ),
            ).then((_) => _recarregar()),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recarregar,
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final f in _filtros)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(f[1]),
                      selected: _filtro == f[0],
                      onSelected: (_) {
                        setState(() => _filtro = f[0]);
                        _recarregar();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<ProdutoVitrine>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Erro: ${snap.error}'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _recarregar,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                      child: Text('Nenhum produto encontrado'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final p = items[i];
                    return ListTile(
                      title: Text(p.nome),
                      subtitle: Text(
                        [p.lojaNome, p.empreendimentoNome]
                            .where((e) => e.isNotEmpty)
                            .join(' • '),
                      ),
                      trailing: Chip(label: Text(p.status)),
                      onTap: () => _detalhe(context, p),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class CorrespondenciaScreen extends StatefulWidget {
  const CorrespondenciaScreen({super.key});

  @override
  State<CorrespondenciaScreen> createState() => _CorrespondenciaScreenState();
}

class _CorrespondenciaScreenState extends State<CorrespondenciaScreen> {
  String _status = '0';
  late Future<List<Correspondencia>> _future;

  static const _abas = [
    ['0', 'Pendentes'],
    ['1', 'Retiradas'],
    ['2', 'Devolvidas'],
    ['3', 'Excluídas'],
  ];

  @override
  void initState() {
    super.initState();
    _future = CorrespondenciaRepo.listar(_status);
  }

  void _recarregar() {
    setState(() => _future = CorrespondenciaRepo.listar(_status));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Correspondência'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _recarregar,
          ),
        ],
      ),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final a in _abas)
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(a[1]),
                      selected: _status == a[0],
                      onSelected: (_) {
                        setState(() => _status = a[0]);
                        _recarregar();
                      },
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Correspondencia>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Center(
                      child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Erro: ${snap.error}'),
                        const SizedBox(height: 12),
                        ElevatedButton(
                          onPressed: _recarregar,
                          child: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  );
                }
                final items = snap.data ?? [];
                if (items.isEmpty) {
                  return const Center(
                      child:
                          Text('Nenhuma correspondência encontrada'));
                }
                return ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) =>
                      const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final c = items[i];
                    return ListTile(
                      title: Text(c.nome),
                      subtitle: Text(
                        [c.tipo, c.codigo, c.cadFormatada]
                            .where((e) => e.isNotEmpty)
                            .join(' • '),
                      ),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              CorrespondenciaDetalhePage(c: c),
                        ),
                      ).then((_) => _recarregar()),
                      trailing: _status == '0'
                          ? IconButton(
                              icon: const Icon(Icons.undo),
                              tooltip: 'Devolver',
                              onPressed: () async {
                                try {
                                  await CorrespondenciaRepo.devolver(
                                      c.cId);
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx)
                                        .showSnackBar(
                                      const SnackBar(
                                          content:
                                              Text('Devolvido')),
                                    );
                                    _recarregar();
                                  }
                                } catch (e) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(ctx)
                                        .showSnackBar(SnackBar(
                                            content: Text('Erro: $e')));
                                  }
                                }
                              },
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
