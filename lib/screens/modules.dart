import 'package:flutter/material.dart';
import 'package:malltech_flutter/core/repos.dart' show ComunicadoRepo,
    ArquivosRepo, FaleConoscoRepo, BoletosRepo, GuiaRepo, CorrespondenciaRepo;
import 'package:malltech_flutter/core/models.dart';
import 'package:malltech_flutter/widgets/list_screen.dart';
import 'package:malltech_flutter/widgets/web_view_screen.dart';
import 'package:malltech_flutter/screens/correspondencia_detalhe.dart';

class ComunicadosScreen extends StatelessWidget {
  const ComunicadosScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListScreen(
      title: 'Comunicados',
      loader: ComunicadoRepo.listar,
      emptyText: 'Nenhum comunicado.',
      itemBuilder: (ctx, item, _) {
        final c = item as Comunicado;
        return ListTile(
          title: Text(c.nome.isNotEmpty ? c.nome : c.pessoa),
          subtitle: Text(
            [c.empreendimento, c.data].where((e) => e.isNotEmpty).join(' • '),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Confirmar',
            onPressed: () async {
              try {
                await ComunicadoRepo.confirmar(c.id);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Comunicado confirmado')),
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
            color: d.foiLido ? Colors.grey : const Color(0xFFFF2D55),
          ),
          title: Text(d.titulo),
          subtitle: Text(
            [d.tipo, d.vigencia].where((e) => e.isNotEmpty).join(' • '),
          ),
          onTap: () async {
            try {
              await ArquivosRepo.marcarLido(d.id);
            } catch (_) {}
            if (d.arquivo != null && d.arquivo!.isNotEmpty && ctx.mounted) {
              Navigator.push(
                ctx,
                MaterialPageRoute(
                  builder: (_) => WebViewScreen(
                    title: d.titulo,
                    path: d.arquivo!,
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

class FaleConoscoScreen extends StatelessWidget {
  const FaleConoscoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListScreen(
      title: 'Fale Conosco',
      loader: () => FaleConoscoRepo.listar(),
      emptyText: 'Nenhuma mensagem.',
      itemBuilder: (ctx, item, _) {
        final f = item as FaleConosco;
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
                  onPressed: () async {
                    try {
                      await FaleConoscoRepo.finalizar(f.id);
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text('Finalizado')),
                        );
                      }
                    } catch (e) {
                      if (ctx.mounted) {
                        ScaffoldMessenger.of(ctx)
                            .showSnackBar(SnackBar(content: Text('Erro: $e')));
                      }
                    }
                  },
                ),
        );
      },
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
      itemBuilder: (_, item, __) {
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
        );
      },
    );
  }
}

class GuiaScreen extends StatelessWidget {
  const GuiaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListScreen(
      title: 'Guia',
      loader: () => GuiaRepo.listar(),
      emptyText: 'Nenhum produto.',
      itemBuilder: (_, item, __) {
        final p = item as ProdutoVitrine;
        return ListTile(
          title: Text(p.nome),
          subtitle: Text(
            [p.lojaNome, p.empreendimentoNome]
                .where((e) => e.isNotEmpty)
                .join(' • '),
          ),
          trailing: Chip(label: Text(p.status)),
        );
      },
    );
  }
}

class CorrespondenciaScreen extends StatelessWidget {
  const CorrespondenciaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListScreen(
      title: 'Correspondência',
      loader: CorrespondenciaRepo.listar,
      emptyText: 'Nenhuma correspondência.',
      itemBuilder: (ctx, item, _) {
        final c = item as Correspondencia;
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
              builder: (_) => CorrespondenciaDetalhePage(c: c),
            ),
          ),
          trailing: IconButton(
            icon: const Icon(Icons.undo),
            tooltip: 'Devolver',
            onPressed: () async {
              try {
                await CorrespondenciaRepo.devolver(c.cId);
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Devolvido')),
                  );
                }
              } catch (e) {
                if (ctx.mounted) {
                  ScaffoldMessenger.of(ctx)
                      .showSnackBar(SnackBar(content: Text('Erro: $e')));
                }
              }
            },
          ),
        );
      },
    );
  }
}
