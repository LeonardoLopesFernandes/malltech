import 'package:flutter/material.dart';
import 'package:malltech_flutter/core/models.dart';
import 'package:malltech_flutter/core/api.dart';
import 'package:malltech_flutter/widgets/pdf_viewer_screen.dart';

class CurriculoDetalhePage extends StatelessWidget {
  final Curriculo c;
  const CurriculoDetalhePage({super.key, required this.c});

  @override
  Widget build(BuildContext context) {
    final cv = c.cvUrl;
    final cookie = Api.phpsessid.isNotEmpty ? 'PHPSESSID=${Api.phpsessid}' : null;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currículo'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0.5,
        actions: [
          if (cv != null)
            IconButton(
              icon: const Icon(Icons.picture_as_pdf),
              tooltip: 'Visualizar CV',
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => PdfViewerScreen(
                    title: c.nome,
                    url: cv,
                    cookie: cookie,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Colors.amber[700],
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  if (c.vaga.isNotEmpty)
                    Text(c.vaga,
                        style:
                            const TextStyle(color: Colors.white, fontSize: 14)),
                  if (c.cargo.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text('Cargo: ${c.cargo}',
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Dados pessoais',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 8),
          Card(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _linha('CPF', c.cpf),
                  _linha('Nascimento', c.nascimento),
                  _linha('Sexo', c.sexo),
                  _linha('Escolaridade', c.escolaridade),
                  _linha('Cidade', c.cidade),
                  _linha('Telefone', c.telefone),
                  _linha('E-mail', c.email),
                  _linha('Enviado em', c.data),
                  _linha('Lido', c.lido ? 'Sim' : 'Não'),
                  _linha('E-mail enviado', c.emailEnviado ? 'Sim' : 'Não'),
                ],
              ),
            ),
          ),
          if (c.observacao.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Observação',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(c.observacao),
              ),
            ),
          ],
          if (c.avaliacao.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Avaliação',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 8),
            Card(
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text(c.avaliacao),
              ),
            ),
          ],
          if (cv != null) ...[
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PdfViewerScreen(
                      title: c.nome,
                      url: cv,
                      cookie: cookie,
                    ),
                  ),
                ),
                icon: const Icon(Icons.picture_as_pdf),
                label: const Text('Visualizar CV'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF2D55),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _linha(String rotulo, String valor) {
    if (valor.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(color: Colors.black87, fontSize: 13),
          children: [
            TextSpan(
              text: '$rotulo: ',
              style: const TextStyle(
                  fontWeight: FontWeight.bold, color: Color(0xFF4C505B)),
            ),
            TextSpan(text: valor),
          ],
        ),
      ),
    );
  }
}
