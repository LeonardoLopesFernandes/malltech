import 'dart:convert';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html_parser;
import 'api.dart';

class PedidoColuna {
  final String nome;
  final List<PedidoCard> cards;
  PedidoColuna(this.nome, this.cards);
}

class PedidoCard {
  final int id;
  final String tipo;
  final String titulo;
  final String? subtipo;
  final String? dataExecutar;
  final String status;
  PedidoCard({
    required this.id,
    required this.tipo,
    required this.titulo,
    this.subtipo,
    this.dataExecutar,
    required this.status,
  });
}

class PessoaDetalhe {
  final String nome;
  final String cpf;
  final String cargo;
  PessoaDetalhe(this.nome, this.cpf, this.cargo);
}

class MensagemPedido {
  final bool self;
  final String dataFormatada;
  final String usuario;
  final String mensagem;
  MensagemPedido(this.self, this.dataFormatada, this.usuario, this.mensagem);
}

class DetalhePedido {
  final String protocolo;
  final String titulo;
  final String solicitante;
  final String descricao;
  final String data;
  final String cpf;
  final String telefone;
  final String contratante;
  final String empresa;
  final String empresaTelefone;
  final String responsavel;
  final List<PessoaDetalhe> pessoas;
  final List<MensagemPedido> mensagens;
  DetalhePedido({
    required this.protocolo,
    required this.titulo,
    required this.solicitante,
    required this.descricao,
    required this.data,
    required this.cpf,
    required this.telefone,
    required this.contratante,
    required this.empresa,
    required this.empresaTelefone,
    required this.responsavel,
    required this.pessoas,
    required this.mensagens,
  });
}

class TipoPedido {
  final int id;
  final String nome;
  final int departamentoId;
  final String? grupo;
  TipoPedido(this.id, this.nome, this.departamentoId, this.grupo);
}

class Departamento {
  final int id;
  final String nome;
  Departamento(this.id, this.nome);
}

class PedidoRepo {
  static Future<List<PedidoColuna>> kanban() async {
    await Api.ensurePortalSession();
    final page = await Api.get('/sistemas/pedido/');
    return parseKanban(page);
  }

  static Future<DetalhePedido> detalhe(int id) async {
    await Api.ensurePortalSession();
    final raw = await Api.get(
      '/sistemas/pedido/',
      {'p': 'detalhe', 'id': id.toString()},
    );
    final d = parseDetalhePedido(id, raw);
    if (d == null) throw ApiException('Detalhe indisponível');
    return d;
  }

  static Future<List<MensagemPedido>> mensagens(int id) async {
    final raw = await Api.get(
      '/systems/pedidos/api/pedido.php?do=mensagem',
      {'id': id.toString()},
    );
    try {
      final arr = jsonDecode(raw) as List<dynamic>;
      return arr.map((e) {
        final o = e as Map<String, dynamic>;
        return MensagemPedido(
          o['self'] == true,
          (o['data_formatada'] ?? '').toString(),
          (o['usuario'] ?? '').toString(),
          (o['mensagem'] ?? '').toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<void> enviarMensagem(int id, String mensagem) => Api.post(
        '/sistemas/pedido/ajax/mensagem.php',
        fields: {
          'id': id.toString(),
          'mensagem': mensagem,
          'integrated': 'true'
        },
      );

  static Future<void> aprovar(int id, String mensagem) => Api.post(
        '/sistemas/pedido/ajax/aprovar.php',
        fields: {
          'id': id.toString(),
          'mensagem': mensagem,
          'integrated': 'true'
        },
      );

  static Future<void> reprovar(int id, String mensagem) => Api.post(
        '/sistemas/pedido/ajax/reprovar.php',
        fields: {
          'id': id.toString(),
          'mensagem': mensagem,
          'integrated': 'true'
        },
      );

  static Future<void> cancelar(int id, String mensagem) => Api.post(
        '/sistemas/pedido/ajax/cancelar.php',
        fields: {
          'id': id.toString(),
          'mensagem': mensagem,
          'integrated': 'true'
        },
      );

  static Future<void> confirmar(int id) => Api.post(
        '/sistemas/pedido/ajax/confirmar.php',
        fields: {'id': id.toString(), 'integrated': 'true'},
      );

  static Future<void> executar(int id) => Api.post(
        '/sistemas/pedido/ajax/executar.php',
        fields: {'id': id.toString(), 'integrated': 'true'},
      );

  static Future<void> executarData(int id, String data) => Api.post(
        '/sistemas/pedido/ajax/executar_data.php',
        fields: {
          'id': id.toString(),
          'executar_data': data,
          'integrated': 'true'
        },
      );

  static Future<void> reabrir(int id) => Api.post(
        '/sistemas/pedido/ajax/reabrir.php',
        fields: {'id': id.toString(), 'integrated': 'true'},
      );

  static Future<void> redirecionarDepartamento(
          int id, int departamentoId, String nome) =>
      Api.post(
        '/sistemas/pedido/ajax/redirecionar_departamento.php',
        fields: {
          'id': id.toString(),
          'redirecionar_departamento': departamentoId.toString(),
          'departamento_nome': nome,
          'integrated': 'true'
        },
      );

  static Future<List<Departamento>> departamentos() async {
    final raw = await Api.getBackend('/api/v1/utilities/filters/departamentos');
    try {
      final obj = jsonDecode(raw) as Map<String, dynamic>;
      List<dynamic>? arr = obj['data'] as List<dynamic>?;
      arr ??= obj['departamentos'] as List<dynamic>?;
      if (arr == null) return [];
      return arr.map((e) {
        final o = e as Map<String, dynamic>;
        return Departamento(
          int.tryParse(o['id']?.toString() ?? '') ?? 0,
          (o['nome'] ?? o['value'] ?? '').toString(),
        );
      }).toList();
    } catch (_) {
      return [];
    }
  }

  static Future<List<TipoPedido>> tipos() async {
    await Api.ensurePortalSession();
    final page = await Api.get(
      '/sistemas/pedido/',
      {'p': 'novo', 'integrated': 'true'},
    );
    return parseTipos(page);
  }

  static Future<void> enviarNovo({
    required TipoPedido tipo,
    required Map<String, String> campos,
    required List<List<String>> pessoas,
    List<String> arquivos = const [],
  }) async {
    await Api.ensurePortalSession();
    final fields = <String, String>{};
    fields['id_sistema'] = '33';
    fields['tipo_id'] = tipo.id.toString();
    fields['departamento_id'] = tipo.departamentoId.toString();
    campos.forEach((k, v) {
      if (v.isNotEmpty) fields[k] = v;
    });
    final nomes = [
      'pessoa_cpf[]',
      'pessoa_rg[]',
      'pessoa_nome[]',
      'pessoa_cargo[]',
      'pessoa_veiculo[]',
      'pessoa_placa[]'
    ];
    final repeated = <List<String>>[];
    for (final linha in pessoas) {
      if (linha.any((e) => e.isNotEmpty)) {
        for (var i = 0; i < nomes.length; i++) {
          repeated.add([nomes[i], linha.length > i ? linha[i] : '']);
        }
      }
    }
    for (final id in arquivos) {
      repeated.add(['arquivos[]', id]);
    }
    await Api.postForm(
      '/sistemas/pedido/actions/novo.php',
      fields: fields,
      repeated: repeated,
    );
  }

  // ---------- Parsers (HTML) ----------

  static List<PedidoColuna> parseKanban(String html) {
    final doc = html_parser.parse(html);
    final colunas = <PedidoColuna>[];

    final meus = doc.querySelector('[data-meuspedidos]');
    if (meus != null) {
      final cards = meus
          .querySelectorAll('ul > li.tiles-content')
          .map(parseCard)
          .whereType<PedidoCard>()
          .toList();
      colunas.add(PedidoColuna('Meus Pedidos', cards));
    }

    final agendados = doc.querySelectorAll('.pedidos_lista [agendado]');
    if (agendados.isNotEmpty) {
      colunas.add(PedidoColuna(
        'Pedidos Agendados',
        agendados.map(parseCard).whereType<PedidoCard>().toList(),
      ));
    }

    final finalizados = doc
        .querySelectorAll('.pedidos_lista h2.small-title, .pedidos_lista .small-title')
        .where((e) =>
            e.text.contains('Aprovados') || e.text.contains('Reprovados'))
        .toList();
    if (finalizados.isNotEmpty) {
      final cards = <PedidoCard>[];
      for (final title in finalizados) {
        var sibling = title.nextElementSibling;
        while (sibling != null) {
          final lis = sibling.querySelectorAll('li');
          if (lis.isNotEmpty) {
            for (final li in lis) {
              final c = parseCard(li);
              if (c != null) cards.add(c);
            }
            break;
          }
          sibling = sibling.nextElementSibling;
        }
      }
      colunas.add(PedidoColuna('Aprovados/Reprovados', cards));
    }

    return colunas;
  }

  static PedidoCard? parseCard(Element li) {
    int? id;
    int? parseId(String? v) => int.tryParse(v ?? '');
    id ??= parseId(li.querySelector('input[name=id]')?.attributes['value']);
    id ??= parseId(li.querySelector('[name=id]')?.attributes['value']);
    id ??= parseId(
        li.querySelector('input[type=hidden]')?.attributes['value']);
    id ??= parseId(li.querySelector('.tiles')?.attributes['alt']);
    final infoText = li.querySelector('.pedido_info li')?.text ?? '';
    if (id == null) {
      final hash = infoText.indexOf('#');
      if (hash >= 0) {
        final after = infoText.substring(hash + 1).trim();
        final sp = after.indexOf(' ');
        id = parseId(sp > 0 ? after.substring(0, sp) : after);
      }
    }
    if (id == null) return null;

    final titulo = li.querySelector('.note-description')?.text ??
        li.querySelector('.tiles-title')?.text ??
        li.querySelector('.subtipo')?.text ??
        li.text;
    final subtipo = li.querySelector('.subtipo')?.text;
    final data = li.querySelector('[name=data_execucao]')?.attributes['value'];
    final agendado = _attr(li, 'agendado');
    final status = _attr(li, 'data-status') ??
        _attr(li, 'data-status-analise') ??
        (agendado != null ? 'Agendado' : '');
    return PedidoCard(
      id: id,
      tipo: status,
      titulo: titulo.trim(),
      subtipo: subtipo,
      dataExecutar: data ?? agendado?.split(' ').first,
      status: status,
    );
  }

  static DetalhePedido? parseDetalhePedido(int id, String html) {
    final doc = html_parser.parse(html);
    final note = doc.querySelector('#note$id');
    if (note == null) return null;

    final info = <String, String>{};
    for (final li in note.querySelectorAll('.pedido_info li')) {
      final t = _liText(li).trim();
      for (final line in t.split('\n')) {
        final tt = line.trim();
        if (tt.contains(':')) {
          info[tt.substringBefore(':').trim()] = tt.substringAfter(':').trim();
        }
      }
    }
    final pMap = <String, String>{};
    for (final p in note.querySelectorAll('p')) {
      final t = _liText(p).trim();
      if (t.contains(':')) {
        pMap[t.substringBefore(':').trim()] = t.substringAfter(':').trim();
      }
    }

    final pessoas = <PessoaDetalhe>[];
    final full = _liText(note);
    final pIdx = full.indexOf('Pessoas');
    if (pIdx >= 0) {
      final bloco = full.substring(pIdx);
      var nome = '', cpf = '', cargo = '';
      for (final linhaRaw in bloco.split('\n')) {
        final l = linhaRaw.trim();
        if (l.startsWith('Nome:')) {
          final resto = l.substring(5).trim();
          if (resto.contains(' | ')) {
            nome = resto.substringBefore(' | ').trim();
            cpf = resto
                .substringAfter(' | ')
                .replaceFirst(RegExp(r'^CPF:\s*', caseSensitive: false), '')
                .trim();
          } else {
            nome = resto;
          }
        } else if (l.startsWith('CPF:')) {
          cpf = l.substring(4).trim();
        } else if (l.startsWith('Cargo:')) {
          cargo = l.substring(6).trim();
        }
        if (nome.isNotEmpty && cpf.isNotEmpty && cargo.isNotEmpty) {
          pessoas.add(PessoaDetalhe(nome, cpf, cargo));
          nome = '';
          cpf = '';
          cargo = '';
        }
      }
    }

    final mensagens = <MensagemPedido>[];
    for (final li in note.querySelectorAll('.mensagens li')) {
      final spans = li.querySelectorAll('span');
      if (spans.length < 2) continue;
      final meta = spans[0].text;
      final texto = spans.last.text;
      final sep = meta.lastIndexOf(' - ');
      if (sep <= 0) continue;
      final usuario = meta.substring(sep + 3).trim();
      mensagens.add(MensagemPedido(
        false,
        meta.substring(0, sep).trim(),
        usuario.endsWith(':') ? usuario.substring(0, usuario.length - 1) : usuario,
        texto,
      ));
    }

    return DetalhePedido(
      protocolo: info['Protocolo'] ?? '#$id',
      titulo: info['Título'] ?? '',
      solicitante: info['Solicitante'] ?? '',
      descricao: info['Descrição'] ?? '',
      data: info['Data'] ?? '',
      cpf: info['CPF'] ?? '',
      telefone: info['Telefone'] ?? '',
      contratante: pMap['Contratante'] ?? '',
      empresa: pMap['Empresa'] ?? '',
      empresaTelefone: pMap['Telefone'] ?? '',
      responsavel: pMap['Responsável'] ?? '',
      pessoas: pessoas,
      mensagens: mensagens,
    );
  }

  static List<TipoPedido> parseTipos(String html) {
    final byId = <int, TipoPedido>{};
    final subExpr = RegExp(r'<li\s+class="subitens">');
    final subStarts =
        subExpr.allMatches(html).map((m) => m.start).toList();
    final leaf = RegExp(r'<span\s+data-tipo="(\d+)"[^>]*>([^<]+)</span>');
    final groupLabel =
        RegExp(r'</ul>\s*<span\s*>([^<]{1,120})</span>');

    for (var i = 0; i < subStarts.length; i++) {
      final start = subStarts[i];
      final end = i + 1 < subStarts.length ? subStarts[i + 1] : html.length;
      final seg = html.substring(start, end);
      final labelMatch = groupLabel.firstMatch(seg);
      if (labelMatch == null) continue;
      final grupo = labelMatch.group(1)!.trim();
      final zone = seg.substring(0, labelMatch.start);
      for (final m in leaf.allMatches(zone)) {
        final id = int.parse(m.group(1)!);
        byId.putIfAbsent(
            id, () => TipoPedido(id, m.group(2)!.trim(), 0, grupo));
      }
    }
    for (final m in leaf.allMatches(html)) {
      final id = int.parse(m.group(1)!);
      byId.putIfAbsent(id, () => TipoPedido(id, m.group(2)!.trim(), 0, null));
    }
    final list = byId.values.toList();
    list.sort((a, b) => a.nome.toLowerCase().compareTo(b.nome.toLowerCase()));
    return list;
  }

  static String? _attr(Element e, String name) {
    final v = e.attributes[name];
    if (v == null || v.isEmpty) return null;
    return v;
  }

  /// Texto do elemento preservando quebras de linha dos <br> (fiel ao
  /// wholeText() do Jsoup, que insere \n em <br>).
  static String _liText(Element el) {
    final sb = StringBuffer();
    void walk(Node n) {
      if (n is Text) {
        sb.write(n.text);
      } else if (n is Element) {
        if (n.localName == 'br') {
          sb.write('\n');
        } else {
          for (final c in n.nodes) walk(c);
        }
      }
    }
    for (final n in el.nodes) walk(n);
    return sb.toString();
  }
}

extension _StringExt on String {
  String substringBefore(String sep) {
    final i = indexOf(sep);
    return i < 0 ? this : substring(0, i);
  }

  String substringAfter(String sep) {
    final i = indexOf(sep);
    return i < 0 ? '' : substring(i + sep.length);
  }
}
