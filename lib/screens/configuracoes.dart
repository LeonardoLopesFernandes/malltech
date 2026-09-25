import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:malltech_flutter/core/api.dart';
import 'package:malltech_flutter/core/repos.dart';
import 'package:malltech_flutter/core/session.dart';
import 'package:malltech_flutter/core/tema.dart';
import 'package:image_picker/image_picker.dart';

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  final _novaSenha = TextEditingController();
  final _repeteSenha = TextEditingController();
  bool _salvandoSenha = false;
  bool _enviandoFoto = false;

  @override
  void dispose() {
    _novaSenha.dispose();
    _repeteSenha.dispose();
    super.dispose();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg)));
  }

  Future<void> _trocarFoto() async {
    try {
      final img = await ImagePicker()
          .pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (img == null) return;
      setState(() => _enviandoFoto = true);
      final bytes = await img.readAsBytes();
      final nome =
          'perfil_${DateTime.now().millisecondsSinceEpoch}.png';
      final payload = await ConfigRepo.uploadFoto(bytes, nome);
      final url = Api.urlDoUpload(payload);
      if (url == null) throw ApiException('Falha ao processar o upload');
      await ConfigRepo.definirImagem(url);
      Session.atualizarImagem(url);
      if (mounted) setState(() {});
      _toast('Foto atualizada');
    } catch (e) {
      _toast('Falha ao atualizar foto: $e');
    } finally {
      if (mounted) setState(() => _enviandoFoto = false);
    }
  }

  Future<void> _removerFoto() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remover foto de perfil?'),
        content: const Text('A foto será removida do seu perfil.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Remover'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await ConfigRepo.removerImagem();
      _toast('Foto removida');
    } catch (e) {
      _toast('Falha ao remover foto: $e');
    }
  }

  Future<void> _atualizarSenha() async {
    final nova = _novaSenha.text;
    final repete = _repeteSenha.text;
    if (nova.isEmpty || repete.isEmpty) {
      _toast('Preencha a nova senha nos dois campos.');
      return;
    }
    if (nova != repete) {
      _toast('As senhas não coincidem.');
      return;
    }
    setState(() => _salvandoSenha = true);
    try {
      await ConfigRepo.trocarSenha(nova, repete);
      _novaSenha.clear();
      _repeteSenha.clear();
      _toast('Senha atualizada com sucesso');
    } catch (e) {
      _toast('Falha ao atualizar senha: $e');
    } finally {
      if (mounted) setState(() => _salvandoSenha = false);
    }
  }

  Future<void> _adiar() async {
    try {
      await ConfigRepo.adiarSenha();
      _toast('Adiado. Você será lembrado depois.');
    } catch (e) {
      _toast('Falha ao adiar: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Session.usuario.value;
    final tema = context.watch<TemaApp>();
    return Scaffold(
      appBar: AppBar(title: const Text('Configurações')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _titulo('Aparência'),
          const SizedBox(height: 8),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              for (int i = 0; i < TemaApp.opcoes.length; i++)
                GestureDetector(
                  onTap: () => tema.definirCor(i),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: TemaApp.opcoes[i]['cor'] as Color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: tema.indice == i
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                            width: tema.indice == i ? 3 : 1,
                          ),
                        ),
                        child: tema.indice == i
                            ? const Icon(Icons.check,
                                color: Colors.white)
                            : null,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        TemaApp.opcoes[i]['nome'] as String,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
            ],
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Modo escuro'),
            secondary: const Icon(Icons.dark_mode),
            value: tema.escuro,
            onChanged: (v) => tema.definirEscuro(v),
          ),
          const SizedBox(height: 12),
          _titulo('Foto de perfil'),
          const SizedBox(height: 8),
          Row(
            children: [
              CircleAvatar(
                radius: 32,
                backgroundImage: user?.imagem.isNotEmpty == true
                    ? NetworkImage(user!.imagem)
                    : null,
                child: user?.imagem.isNotEmpty == true
                    ? null
                    : const Icon(Icons.person, size: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(user?.nome ?? '',
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                    Text(user?.imagem.isNotEmpty == true
                        ? 'Foto definida'
                        : 'Nenhuma foto'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _enviandoFoto ? null : _trocarFoto,
                  icon: const Icon(Icons.photo_library),
                  label: Text(
                      _enviandoFoto ? 'Enviando...' : 'Alterar foto'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _removerFoto,
                  icon: const Icon(Icons.delete_outline),
                  label: const Text('Remover'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _titulo('Senha'),
          const SizedBox(height: 8),
          TextField(
            controller: _novaSenha,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Nova senha',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: _repeteSenha,
            obscureText: true,
            decoration: const InputDecoration(
              labelText: 'Repita a senha',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _salvandoSenha ? null : _atualizarSenha,
                  child: Text(_salvandoSenha
                      ? 'Atualizando...'
                      : 'Atualizar senha'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton(
                  onPressed: _adiar,
                  child: const Text('Adiar atualização'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _titulo(String texto) {
    return Text(
      texto.toUpperCase(),
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        letterSpacing: 1.2,
        color: Theme.of(context).primaryColor,
      ),
    );
  }
}
