import 'package:flutter/material.dart';
import 'package:malltech_flutter/core/repos.dart';

/// Tela nativa para criar um novo produto na vitrine.
class NovoProdutoScreen extends StatefulWidget {
  const NovoProdutoScreen({super.key});

  @override
  State<NovoProdutoScreen> createState() => _NovoProdutoScreenState();
}

class _NovoProdutoScreenState extends State<NovoProdutoScreen> {
  final _nome = TextEditingController();
  final _descricao = TextEditingController();
  final _valorDe = TextEditingController();
  final _valorPor = TextEditingController();
  final _desconto = TextEditingController();
  final _whatsapp = TextEditingController();
  final _telefone = TextEditingController();
  final _email = TextEditingController();
  final _ecom = TextEditingController();
  final _dataEntrada = TextEditingController();
  final _dataSaida = TextEditingController();
  final _sku = TextEditingController();
  final _ifood = TextEditingController();
  final _uberEats = TextEditingController();
  final _rappi = TextEditingController();
  final _posicao = TextEditingController();
  final _instagram = TextEditingController();
  String _categoria = '';
  bool _enviando = false;

  static const _categorias = [
    'Alimentação',
    'Bebidas',
    'Utensílios Domésticos',
    'Eletrônicos',
    'Roupas',
    'Acessórios',
    'Outros',
  ];

  @override
  void dispose() {
    _nome.dispose();
    _descricao.dispose();
    _valorDe.dispose();
    _valorPor.dispose();
    _desconto.dispose();
    _whatsapp.dispose();
    _telefone.dispose();
    _email.dispose();
    _ecom.dispose();
    _dataEntrada.dispose();
    _dataSaida.dispose();
    _sku.dispose();
    _ifood.dispose();
    _uberEats.dispose();
    _rappi.dispose();
    _posicao.dispose();
    _instagram.dispose();
    super.dispose();
  }

  Future<void> _enviar() async {
    final nome = _nome.text.trim();
    if (nome.isEmpty) {
      _toast('Informe o nome do produto');
      return;
    }
    setState(() => _enviando = true);
    try {
      await GuiaRepo.inserir(
        nome: nome,
        descricao: _descricao.text.trim(),
        valorDe: _valorDe.text.trim(),
        valorPor: _valorPor.text.trim(),
        desconto: _desconto.text.trim(),
        whatsapp: _whatsapp.text.trim(),
        telefone: _telefone.text.trim(),
        email: _email.text.trim(),
        ecom: _ecom.text.trim(),
        dataEntrada: _dataEntrada.text.trim(),
        dataSaida: _dataSaida.text.trim(),
        sku: _sku.text.trim(),
        ifood: _ifood.text.trim(),
        uberEats: _uberEats.text.trim(),
        rappi: _rappi.text.trim(),
        posicao: _posicao.text.trim(),
        instagram: _instagram.text.trim(),
        categoria: _categoria,
      );
      if (mounted) {
        _toast('Produto enviado');
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) _toast('Falha ao enviar: $e');
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Widget _campo(String label, TextEditingController ctrl,
      {bool multilinha = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: ctrl,
        minLines: multilinha ? 3 : 1,
        maxLines: multilinha ? 5 : 1,
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo produto')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _campo('Nome do produto *', _nome),
          _campo('Descrição', _descricao, multilinha: true),
          Row(
            children: [
              Expanded(child: _campo('Valor inicial (de)', _valorDe)),
              const SizedBox(width: 8),
              Expanded(child: _campo('Valor final (por)', _valorPor)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _campo('Desconto (%)', _desconto)),
              const SizedBox(width: 8),
              Expanded(child: _campo('Posição', _posicao)),
            ],
          ),
          _campo('Whatsapp', _whatsapp),
          _campo('Telefone', _telefone),
          _campo('E-mail', _email),
          Row(
            children: [
              Expanded(child: _campo('Data de entrada *', _dataEntrada)),
              const SizedBox(width: 8),
              Expanded(child: _campo('Data de saída *', _dataSaida)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _campo('SKU', _sku)),
              const SizedBox(width: 8),
              Expanded(child: _campo('E-com', _ecom)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _campo('iFood', _ifood)),
              const SizedBox(width: 8),
              Expanded(child: _campo('Uber Eats', _uberEats)),
            ],
          ),
          Row(
            children: [
              Expanded(child: _campo('Rappi', _rappi)),
              const SizedBox(width: 8),
              Expanded(child: _campo('Instagram', _instagram)),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: DropdownButtonFormField<String>(
              value: _categoria.isEmpty ? null : _categoria,
              items: _categorias
                  .map((c) =>
                      DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _categoria = v ?? ''),
              decoration: const InputDecoration(
                labelText: 'Categoria',
                border: OutlineInputBorder(),
              ),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: _enviando ? null : _enviar,
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              child: _enviando
                  ? const CircularProgressIndicator(color: Colors.white)
                  : const Text('Enviar produto',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}