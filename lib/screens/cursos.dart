import 'package:flutter/material.dart';
import 'package:html/dom.dart' hide Text;
import 'package:html/parser.dart' as html_parser;
import 'package:malltech_flutter/core/api.dart';
import 'package:malltech_flutter/core/datas.dart';
import 'package:malltech_flutter/widgets/web_view_screen.dart';

class Curso {
  final int id;
  final String data;
  final String titulo;
  final String vagas;
  Curso(this.id, this.data, this.titulo, this.vagas);
}

class CursoRepo {
  static Future<List<Curso>> listar() async {
    final html = await Api.get('/systems/curso/', {'integrated': 'true'});
    return parseCursos(html);
  }

  static List<Curso> parseCursos(String html) {
    final doc = html_parser.parse(html);
    final cursos = <Curso>[];
    final rows = doc.querySelectorAll('.content table tr');
    for (final row in rows) {
      final link = row.querySelector('a[href*="curso_id="]');
      if (link == null) continue;
      final href = link.attributes['href'] ?? '';
      final after = href.substringAfter('curso_id=');
      final id = int.tryParse(after.substringBefore('&'));
      final cells =
          row.querySelectorAll('td').map((e) => e.text.trim()).toList();
      if (id != null && cells.length >= 3) {
        cursos.add(Curso(id, cells[0], cells[1], cells[2]));
      }
    }
    final vistos = <int>{};
    return cursos.where((c) => vistos.add(c.id)).toList();
  }
}

extension _S on String {
  String substringAfter(String sep) {
    final i = indexOf(sep);
    return i < 0 ? '' : substring(i + sep.length);
  }

  String substringBefore(String sep) {
    final i = indexOf(sep);
    return i < 0 ? this : substring(0, i);
  }
}

Widget _info(BuildContext context, String rotulo, String valor) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(rotulo,
          style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
      const SizedBox(height: 2),
      Text(valor,
          style:
              const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
    ],
  );
}

class CursosScreen extends StatefulWidget {
  const CursosScreen({super.key});

  @override
  State<CursosScreen> createState() => _CursosScreenState();
}

class _CursosScreenState extends State<CursosScreen> {
  late Future<List<Curso>> _future;

  @override
  void initState() {
    super.initState();
    _future = CursoRepo.listar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Palestras e Cursos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() => _future = CursoRepo.listar()),
          ),
        ],
      ),
      body: FutureBuilder<List<Curso>>(
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
                    onPressed: () => setState(() => _future = CursoRepo.listar()),
                    child: const Text('Tentar novamente'),
                  ),
                ],
              ),
            );
          }
          final items = snap.data ?? [];
          if (items.isEmpty) {
            return const Center(child: Text('Nenhum curso ou palestra disponível'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (_, i) {
              final c = items[i];
              return ListTile(
                title: Text(c.titulo),
                subtitle: c.vagas.isNotEmpty ? Text('Vagas: ${c.vagas}') : null,
                trailing: Chip(label: Text(formatarData(c.data))),
                onTap: () => showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text(c.titulo),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _info(ctx, 'Data', formatarData(c.data)),
                        const SizedBox(height: 8),
                        _info(ctx, 'Vagas',
                            c.vagas.isNotEmpty ? c.vagas : '-'),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('Fechar'),
                      ),
                    ],
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
