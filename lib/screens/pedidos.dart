import 'package:flutter/material.dart';
import 'package:malltech_flutter/core/datas.dart';
import 'package:malltech_flutter/core/pedido_repo.dart';
import 'package:malltech_flutter/core/session.dart';

String _fmtData(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

class PedidosScreen extends StatefulWidget {
  const PedidosScreen({super.key});

  @override
  State<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends State<PedidosScreen> {
  late Future<List<PedidoColuna>> _future;
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _menuAberto = false;
  String? _filtroStatus;

  static const _filtros = [
    ['novo', 'Novo', Icons.description_outlined],
    ['andamento', 'Em andamento', Icons.list_alt],
    ['aprovado', 'Aprovados', Icons.check],
    ['reprovado', 'Reprovados', Icons.close],
    ['cancelado', 'Cancelados', Icons.block],
  ];

  @override
  void initState() {
    super.initState();
    _future = PedidoRepo.kanban();
  }

  Future<void> _refresh() async {
    setState(() {
      _future = PedidoRepo.kanban();
    });
  }

  Future<void> _novoPedido() async {
    await Navigator.pushNamed(context, '/pedidos/novo');
    _refresh();
  }

  void _alternarMenu() {
    if (_menuAberto) {
      Navigator.pop(context);
    } else {
      _scaffoldKey.currentState?.openDrawer();
    }
  }

  List<PedidoColuna> _colunasFiltradas(List<PedidoColuna> cols) {
    if (_filtroStatus == null) return cols;
    final chave = _filtroStatus!;
    // Palavras-chave por status (ignorando acentos e maiúsculas).
    bool coincide(PedidoCard c) {
      final status = c.status.toLowerCase();
      switch (chave) {
        case 'novo':
          return status.isEmpty ||
              status.contains('novo') ||
              status.contains('pendente') ||
              status.contains('aguardando');
        case 'andamento':
          return status.contains('andamento') ||
              status.contains('executando') ||
              status.contains('analise') ||
              status.contains('análise') ||
              status.contains('em execução') ||
              status.contains('agendado');
        case 'aprovado':
          return status.contains('aprovado');
        case 'reprovado':
          return status.contains('reprovado') ||
              status.contains('recusado');
        case 'cancelado':
          return status.contains('cancelado') ||
              status.contains('cancelada');
        default:
          return status.contains(chave);
      }
    }

    return [
      for (final col in cols)
        PedidoColuna(
          col.nome,
          col.cards.where(coincide).toList(),
        ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Atualizar',
            onPressed: _refresh,
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: Theme.of(context).primaryColor,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.only(top: 20),
            children: [
              for (final f in _filtros)
                ListTile(
                  leading: Icon(f[2] as IconData, color: Colors.white),
                  title: Text(f[1] as String,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500)),
                  selected: _filtroStatus == f[0],
                  selectedTileColor: Colors.white.withOpacity(0.15),
                  onTap: () {
                    setState(() => _filtroStatus =
                        _filtroStatus == f[0] ? null : f[0] as String);
                    Navigator.pop(context);
                  },
                ),
            ],
          ),
        ),
      ),
      onDrawerChanged: (aberto) =>
          setState(() => _menuAberto = aberto),
      floatingActionButton: FloatingActionButton(
        onPressed: _alternarMenu,
        backgroundColor: const Color(0xFF00A091),
        foregroundColor: Colors.white,
        child: Icon(
            _menuAberto ? Icons.chevron_left : Icons.chevron_right),
      ),
      floatingActionButtonLocation:
          FloatingActionButtonLocation.startFloat,
      body: FutureBuilder<List<PedidoColuna>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Erro: ${snap.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: _refresh,
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          final cols = _colunasFiltradas(snap.data ?? []);
          final total =
              cols.fold<int>(0, (s, c) => s + c.cards.length);
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 20, 16, 90),
            children: [
              // Label "Pedidos" já está no toolbar; aqui só mostra "Nenhum
              // Pedido" quando a lista está vazia.
              if (total == 0) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Nenhum Pedido',
                      style: TextStyle(
                        fontSize: 22,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    Icon(Icons.list_alt,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              // Card "+ Pedido" só aparece quando não há pedidos.
              if (total == 0)
                GestureDetector(
                  onTap: _novoPedido,
                  child: Container(
                    height: 130,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add,
                              size: 32,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onSurfaceVariant),
                          const SizedBox(width: 8),
                          Text('Pedido',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              )),
                        ],
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              for (final col in cols)
                if (col.cards.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      col.nome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  ...col.cards.map((c) => _PedidoCardItem(
                        card: c,
                        onChanged: _refresh,
                      )),
                ],
            ],
          );
        },
      ),
    );
  }
}

class _PedidoCardItem extends StatefulWidget {
  final PedidoCard card;
  final VoidCallback onChanged;
  const _PedidoCardItem({required this.card, required this.onChanged});

  @override
  State<_PedidoCardItem> createState() => _PedidoCardItemState();
}

class _PedidoCardItemState extends State<_PedidoCardItem> {
  bool _expanded = false;

  Future<void> _cancelar(BuildContext context) async {
    final ctrl = TextEditingController();
    final motivo = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Motivo do cancelamento'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            labelText: 'Motivo',
            border: OutlineInputBorder(),
          ),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Voltar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Cancelar pedido'),
          ),
        ],
      ),
    );
    if (motivo == null || motivo.isEmpty) return;
    try {
      await PedidoRepo.cancelar(widget.card.id, motivo);
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Pedido cancelado')));
      }
      widget.onChanged();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Erro: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.card;
    final corBadge = Theme.of(context).primaryColor;
    return Card(
      color: corBadge,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    c.titulo,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.calendar_today,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      formatarData(c.dataExecutar, separador: '-') ??
                          c.status,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              c.tipo,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              c.subtipo ?? '',
              style: const TextStyle(color: Colors.white70, fontSize: 13),
            ),
            if (_expanded) ...[
              const SizedBox(height: 12),
              const Divider(color: Colors.white30),
              _detalhe('Título', c.titulo),
              _detalhe('Tipo', c.tipo),
              _detalhe('Subtipo', c.subtipo ?? ''),
              _detalhe('Execução', formatarData(c.dataExecutar)),
              _detalhe('Status', c.status),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PedidoDetalhePage(id: c.id),
                      ),
                    ).then((_) => widget.onChanged());
                  },
                  child: const Text('Ver detalhe completo',
                      style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () => _cancelar(context),
                  icon: const Icon(Icons.block, color: Colors.white70, size: 22),
                  tooltip: 'Cancelar pedido',
                ),
                InkWell(
                  onTap: () => setState(() => _expanded = !_expanded),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      _expanded ? Icons.remove : Icons.add,
                      color: corBadge,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detalhe(String rotulo, String valor) {
    if (valor.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.white, fontSize: 13),
          children: [
            TextSpan(
              text: '$rotulo: ',
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white70),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }
}

class PedidoDetalhePage extends StatefulWidget {
  final int id;
  const PedidoDetalhePage({super.key, required this.id});

  @override
  State<PedidoDetalhePage> createState() => _PedidoDetalhePageState();
}

class _PedidoDetalhePageState extends State<PedidoDetalhePage> {
  late Future<DetalhePedido> _future;
  final _msgCtrl = TextEditingController();
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _future = PedidoRepo.detalhe(widget.id);
  }

  Future<void> _reload() async {
    setState(() {
      _future = PedidoRepo.detalhe(widget.id);
    });
  }

  Future<void> _acao(Future<void> Function() fn, String ok) async {
    setState(() => _busy = true);
    try {
      await fn();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ok)));
      await _reload();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha: $e')));
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<String?> _dialogoMensagem(String titulo, [String padrao = '']) async {
    final ctrl = TextEditingController(text: padrao);
    return showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(titulo),
        content: TextField(
          controller: ctrl,
          minLines: 3,
          maxLines: 5,
          decoration: const InputDecoration(labelText: 'Mensagem'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c),
            child: const Text('Cancelar')),
          TextButton(
            onPressed: () => Navigator.pop(c, ctrl.text.trim().isEmpty ? padrao : ctrl.text.trim()),
            child: const Text('Confirmar')),
        ],
      ),
    );
  }

  Future<void> _redirecionar() async {
    final deps = await PedidoRepo.departamentos();
    if (!mounted) return;
    if (deps.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Nenhum departamento')));
      return;
    }
    final escolha = await showDialog<Departamento>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Redirecionar para departamento'),
        content: SizedBox(
          width: double.infinity,
          child: ListView(
            shrinkWrap: true,
            children: deps
                .map((d) => ListTile(
                      title: Text(d.nome),
                      onTap: () => Navigator.pop(c, d),
                    ))
                .toList(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Fechar')),
        ],
      ),
    );
    if (escolha != null) {
      await _acao(
        () => PedidoRepo.redirecionarDepartamento(widget.id, escolha.id, escolha.nome),
        'Pedido redirecionado',
      );
    }
  }

  Future<void> _executarData() async {
    final data = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (data == null) return;
    final fmt = _fmtData(data);
    await _acao(() => PedidoRepo.executarData(widget.id, fmt), 'Execução agendada');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${widget.id}'),
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        elevation: 0.5,
      ),
      body: FutureBuilder<DetalhePedido>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Erro: ${snap.error}'),
                  const SizedBox(height: 12),
                  ElevatedButton(onPressed: _reload, child: const Text('Tentar novamente')),
                ],
              ),
            );
          }
          final d = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // 1. Card de destaque
              Card(
                color: Theme.of(context).primaryColor,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(d.solicitante,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
                      if (d.descricao.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Descrição: ${d.descricao}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13)),
                        ),
                      if (d.contratante.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text('Para: ${d.contratante}',
                              style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 2. Informações do pedido
              const Text('Informações do Pedido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Card(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _Linha('Protocolo', d.protocolo),
                      _Linha('Título', d.titulo),
                      _Linha('Data', formatarData(d.data)),
                      _Linha('CPF', d.cpf),
                      _Linha('Telefone', d.telefone),
                      _Linha('Contratante', d.contratante),
                      _Linha('Empresa', d.empresa),
                      _Linha('Responsável', d.responsavel),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // 3. Pessoas
              const Text('Pessoas', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (d.pessoas.isEmpty)
                Text('Nenhuma pessoa',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
              else
                ...d.pessoas.map((p) => _PessoaCard(p: p)),

              const SizedBox(height: 16),

              // 4. Mensagens
              const Text('Mensagens', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              if (d.mensagens.isEmpty)
                Text('Nenhuma mensagem',
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: d.mensagens.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('${m.dataFormatada} - ${m.usuario}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Theme.of(context).colorScheme.primary)),
                          const SizedBox(height: 4),
                          Text(m.mensagem),
                        ],
                      ),
                    )).toList(),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _msgCtrl,
                      decoration: const InputDecoration(labelText: 'Nova mensagem'),
                      minLines: 1,
                      maxLines: 3,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    onPressed: _busy
                        ? null
                        : () async {
                            final t = _msgCtrl.text.trim();
                            if (t.isEmpty) return;
                            _msgCtrl.clear();
                            await _acao(() => PedidoRepo.enviarMensagem(widget.id, t), 'Mensagem enviada');
                          },
                  ),
                ],
              ),
              const SizedBox(height: 12),
            ],
          );
        },
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Theme.of(context).colorScheme.surface,
        child: Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onPressed: _busy
                    ? null
                    : () => _acao(() => PedidoRepo.confirmar(widget.id), 'Confirmado'),
                icon: const Icon(Icons.check),
                label: const Text('Confirmar'),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                foregroundColor: Theme.of(context).colorScheme.onSurface,
                side: BorderSide(color: Theme.of(context).colorScheme.outline),
              ),
              onPressed: _busy
                  ? null
                  : () => _acao(() => PedidoRepo.reabrir(widget.id), 'Reaberto'),
              child: const Text('Reabrir'),
            ),
            const SizedBox(width: 4),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (v) async {
                if (v == 'aprovar') {
                  final m = await _dialogoMensagem('Aprovar pedido', 'Aprovado');
                  if (m != null) await _acao(() => PedidoRepo.aprovar(widget.id, m), 'Aprovado');
                } else if (v == 'reprovar') {
                  final m = await _dialogoMensagem('Reprovar pedido', 'Reprovado');
                  if (m != null) await _acao(() => PedidoRepo.reprovar(widget.id, m), 'Reprovado');
                } else if (v == 'cancelar') {
                  final m = await _dialogoMensagem('Cancelar pedido', 'Cancelado');
                  if (m != null) await _acao(() => PedidoRepo.cancelar(widget.id, m), 'Cancelado');
                } else if (v == 'executar') {
                  await _acao(() => PedidoRepo.executar(widget.id), 'Executado');
                } else if (v == 'redirecionar') {
                  await _redirecionar();
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(value: 'aprovar', child: Text('Aprovar')),
                PopupMenuItem(value: 'reprovar', child: Text('Reprovar')),
                PopupMenuItem(value: 'cancelar', child: Text('Cancelar')),
                PopupMenuItem(value: 'executar', child: Text('Executar')),
                PopupMenuItem(value: 'redirecionar', child: Text('Redirecionar')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Linha extends StatelessWidget {
  final String rotulo;
  final String valor;
  const _Linha(this.rotulo, this.valor);
  @override
  Widget build(BuildContext context) {
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
                    color: Theme.of(context).colorScheme.primary)),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }
}

class _PessoaCard extends StatelessWidget {
  final PessoaDetalhe p;
  const _PessoaCard({required this.p});
  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(Icons.person_outline, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nome: ${p.nome}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text('CPF: ${p.cpf}', style: const TextStyle(fontSize: 13)),
                    const SizedBox(height: 2),
                    Text('Cargo: ${p.cargo}', style: const TextStyle(fontSize: 13)),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
}

class NovoPedidoScreen extends StatefulWidget {
  const NovoPedidoScreen({super.key});

  @override
  State<NovoPedidoScreen> createState() => _NovoPedidoScreenState();
}

class _NovoPedidoScreenState extends State<NovoPedidoScreen> {
  late Future<List<TipoPedido>> _future;
  TipoPedido? _tipo;

  final _responsavel = TextEditingController();
  final _cpf = TextEditingController();
  final _telefone = TextEditingController();
  final _titulo = TextEditingController();
  final _descricao = TextEditingController();
  final _contratante = TextEditingController();
  final _empresa = TextEditingController();
  final _empresaTelefone = TextEditingController();
  final _empresaResponsavel = TextEditingController();
  final _empresaRg = TextEditingController();
  final _dataInicio = TextEditingController();
  final _dataTermino = TextEditingController();
  final _dataAgendar = TextEditingController();
  bool _pedidoAgora = true;
  bool _enviando = false;

  List<PessoaRow> _pessoas = [PessoaRow()];

  @override
  void initState() {
    super.initState();
    _responsavel.text = Session.usuario.value?.nome ?? '';
    _contratante.text = Session.usuario.value?.lojaNome ?? '';
    _empresa.text = Session.usuario.value?.lojaNome ?? '';
    _future = PedidoRepo.tipos();
  }

  Future<void> _pickData(TextEditingController ctrl, [bool comHora = false]) async {
    final d = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
    );
    if (d == null) return;
    String valor = _fmtData(d);
    if (comHora) {
      final hora = await _pickHora();
      if (hora == null) return;
      valor += ' $hora';
    }
    ctrl.text = valor;
  }

  /// Seletor de horário em intervalos de 5 minutos (00:00, 00:05, ... 23:55).
  Future<String?> _pickHora() async {
    final horarios = <String>[];
    for (var h = 0; h < 24; h++) {
      for (var m = 0; m < 60; m += 5) {
        horarios.add(
          '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}',
        );
      }
    }
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Selecione o horário'),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
            ),
            itemCount: horarios.length,
            itemBuilder: (ctx, i) => InkWell(
              onTap: () => Navigator.pop(ctx, horarios[i]),
              borderRadius: BorderRadius.circular(8),
              child: Container(
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Theme.of(ctx).primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(ctx).primaryColor.withOpacity(0.4),
                  ),
                ),
                child: Text(
                  horarios[i],
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
        ],
      ),
    );
  }

  Future<void> _enviar() async {
    if (_tipo == null) return;
    final campos = <String, String>{};
    campos['pedido'] = _pedidoAgora ? 'agora' : 'agendar';
    if (!_pedidoAgora) campos['data'] = _dataAgendar.text.trim();
    campos['responsavel'] = _responsavel.text.trim();
    campos['cpf'] = _cpf.text.trim();
    campos['telefone'] = _telefone.text.trim();
    campos['data_inicio'] = _dataInicio.text.trim();
    campos['data_termino'] = _dataTermino.text.trim();
    campos['contratante'] = _contratante.text.trim();
    campos['empresa'] = _empresa.text.trim();
    campos['empresa_telefone'] = _empresaTelefone.text.trim();
    campos['empresa_responsavel'] = _empresaResponsavel.text.trim();
    campos['empresa_rg'] = _empresaRg.text.trim();
    campos['titulo'] = _titulo.text.trim();
    campos['descricao'] = _descricao.text.trim();

    final erros = <String>[];
    if (_responsavel.text.trim().isEmpty) erros.add('Nome do solicitante');
    if (_cpf.text.trim().replaceAll(RegExp(r'\D'), '').length != 11) erros.add('CPF');
    if (_telefone.text.trim().replaceAll(RegExp(r'\D'), '').length < 10) erros.add('Telefone');
    if (_descricao.text.trim().isEmpty) erros.add('Descrição');
    if (!_pedidoAgora && _dataAgendar.text.trim().isEmpty) erros.add('Data do agendamento');
    if (_dataInicio.text.trim().isEmpty) erros.add('Data de Início');
    if (_dataTermino.text.trim().isEmpty) erros.add('Data de Término');
    if (_contratante.text.trim().isEmpty) erros.add('Contratante');
    if (_empresa.text.trim().isEmpty) erros.add('Empresa');

    if (erros.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Preencha: ${erros.join(', ')}')),
      );
      return;
    }

    final pessoas = _pessoas.map((p) => p.values).toList();

    setState(() => _enviando = true);
    try {
      await PedidoRepo.enviarNovo(
        tipo: _tipo!,
        campos: campos,
        pessoas: pessoas,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pedido enviado')));
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Falha: $e')));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo pedido')),
      body: FutureBuilder<List<TipoPedido>>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(child: Text('Erro: ${snap.error}'));
          }
          final tipos = snap.data ?? [];
          if (tipos.isEmpty) {
            return const Center(child: Text('Nenhum tipo de pedido disponível'));
          }
          if (_tipo == null) {
            // Agrupa os tipos por tópico, preservando a ordem de aparição.
            final grupos = <String, List<TipoPedido>>{};
            final ordemGrupos = <String>[];
            for (final t in tipos) {
              final chave = t.grupo == null || t.grupo!.isEmpty
                  ? 'Outros'
                  : t.grupo!;
              if (!grupos.containsKey(chave)) {
                grupos[chave] = [];
                ordemGrupos.add(chave);
              }
              grupos[chave]!.add(t);
            }
            return ListView(
              padding: const EdgeInsets.all(12),
              children: [
                for (final grupo in ordemGrupos) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 10, bottom: 4),
                    child: Text(
                      grupo,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                  for (final t in grupos[grupo]!)
                    Card(
                      child: ListTile(
                        title: Text(t.nome),
                        onTap: () => setState(() => _tipo = t),
                      ),
                    ),
                ],
              ],
            );
          }
          return _form();
        },
      ),
    );
  }

  Widget _form() {
    final templateLeve = _tipo!.id == 8416;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          color: Theme.of(context).primaryColor.withValues(alpha: 0.15),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(_tipo!.nome,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface)),
                ),
                TextButton(
                    onPressed: () => setState(() => _tipo = null),
                    child: Text(
                      'Trocar tipo',
                      style: TextStyle(
                          color: Theme.of(context).colorScheme.primary),
                    )),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Pedir agora'),
                value: true,
                groupValue: _pedidoAgora,
                onChanged: (v) => setState(() => _pedidoAgora = v ?? true),
                contentPadding: EdgeInsets.zero,
              ),
            ),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text('Agendar'),
                value: false,
                groupValue: _pedidoAgora,
                onChanged: (v) => setState(() => _pedidoAgora = v ?? false),
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ],
        ),
        if (!_pedidoAgora)
          _Campo('Agendar pedido', _dataAgendar, readOnly: true, onTap: () => _pickData(_dataAgendar)),
        _Campo('Nome do solicitante *', _responsavel),
        _Campo('CPF do solicitante *', _cpf),
        _Campo('Telefone *', _telefone),
        if (!templateLeve) ...[
          _Campo('Data de Início *', _dataInicio, readOnly: true, onTap: () => _pickData(_dataInicio, true)),
          _Campo('Data de Término *', _dataTermino, readOnly: true, onTap: () => _pickData(_dataTermino, true)),
        ],
        _Campo('Título', _titulo),
        _Campo('Descrição *', _descricao, minLines: 4),
        if (!templateLeve) ...[
          _Campo('Contratante *', _contratante),
          _Campo('Empresa *', _empresa),
          _Campo('Empresa - Telefone', _empresaTelefone),
          _Campo('Empresa - Responsável', _empresaResponsavel),
          _Campo('Empresa - RG', _empresaRg),
          const SizedBox(height: 8),
          const Text('Pessoas liberadas', style: TextStyle(fontWeight: FontWeight.bold)),
          ..._pessoas.asMap().entries.map((e) {
            final i = e.key;
            final p = e.value;
            return Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Text('Pessoa ${i + 1}', style: const TextStyle(color: Colors.grey)),
                        const Spacer(),
                        if (_pessoas.length > 1)
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.red),
                            onPressed: () => setState(() => _pessoas.removeAt(i)),
                          ),
                      ],
                    ),
                    _Campo('CPF', p.cpfCtrl),
                    _Campo('RG', p.rgCtrl),
                    _Campo('Nome', p.nomeCtrl),
                    _Campo('Cargo', p.cargoCtrl),
                    _Campo('Modelo/cor veículo', p.veiculoCtrl),
                    _Campo('Placa', p.placaCtrl),
                  ],
                ),
              ),
            );
          }),
          OutlinedButton.icon(
            onPressed: () => setState(() => _pessoas.add(PessoaRow())),
            icon: const Icon(Icons.add),
            label: const Text('Adicionar pessoa'),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton(
            onPressed: _enviando ? null : _enviar,
            style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor, foregroundColor: Colors.white),
            child: _enviando
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Enviar pedido', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ),
      ],
    );
  }
}

class PessoaRow {
  final cpfCtrl = TextEditingController();
  final rgCtrl = TextEditingController();
  final nomeCtrl = TextEditingController();
  final cargoCtrl = TextEditingController();
  final veiculoCtrl = TextEditingController();
  final placaCtrl = TextEditingController();
  List<String> get values => [cpfCtrl.text, rgCtrl.text, nomeCtrl.text, cargoCtrl.text, veiculoCtrl.text, placaCtrl.text];
}

class _Campo extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool readOnly;
  final VoidCallback? onTap;
  final int minLines;
  const _Campo(this.label, this.controller, {this.readOnly = false, this.onTap, this.minLines = 1});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: TextField(
          controller: controller,
          readOnly: readOnly,
          minLines: minLines,
          maxLines: minLines == 1 ? 1 : null,
          onTap: onTap,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: Theme.of(context).primaryColor),
            ),
          ),
        ),
      );
}
