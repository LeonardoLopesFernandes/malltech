import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:malltech_flutter/core/api.dart';
import 'package:malltech_flutter/core/session.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _user = TextEditingController();
  final _pass = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;
  String _status = '';
  bool _lembrar = false;

  @override
  void initState() {
    super.initState();
    _user.text = Session.ultimoLogin();
    _lembrar = Session.deveSalvarSenha();
    if (_lembrar) {
      _pass.text = Session.ultimaSenha();
    }
  }

  Future<void> _submit() async {
    if (_loading) return;
    final usuario = _user.text.trim();
    final senha = _pass.text;
    if (usuario.isEmpty || senha.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _status = 'Autenticando...';
    });
    try {
      debugPrint('LOGIN: submit usuario="$usuario"');
      final token = await Api.login(usuario, senha);
      debugPrint('LOGIN: token recebido length=${token.length}');
      if (token.isEmpty) throw ApiException('Falha na autenticação');
      Api.setCredenciais(usuario, senha);
      Session.token.value = token;
      if (_lembrar) {
        Session.salvarSenha(senha);
      } else {
        Session.salvarSenha('');
      }
      Session.salvarOpcaoLembrar(_lembrar);
      Session.token.value = token;
      _status = 'Carregando seus dados...';
      Usuario decoded;
      try {
        final raw = await Api.getBackend('/api/auth/user');
        decoded = _decodeUser(raw);
        debugPrint('LOGIN: usuario decodificado nome="${decoded.nome}" login="${decoded.login}"');
      } catch (e) {
        debugPrint('LOGIN: falha ao buscar usuario (nao fatal): $e');
        // Mesmo se falhar a busca do usuário, entra com dados mínimos.
        decoded = Usuario(
          id: 0,
          lojaId: 0,
          empreendimentoId: 0,
          login: usuario,
          nome: usuario,
          lojaNome: '',
          empreendimentoNome: '',
          isAdmin: false,
          acessos: [],
        );
      }
      Session.save(token, decoded);
      debugPrint('LOGIN: Session.save ok -> token=${Session.token.value != null} usuario=${Session.usuario.value != null}');
      Session.salvarUltimoLogin(usuario);
      try {
        final ok = await Api.portalLogin(usuario, senha);
        debugPrint('LOGIN: portalLogin ok=$ok');
      } catch (_) {}
      debugPrint('LOGIN: fluxo concluido (AuthGate deve mostrar Home)');
    } catch (e) {
      debugPrint('LOGIN: ERRO $e');
      Session.clear();
      setState(() {
        _error = e is ApiException
            ? e.message
            : 'Sem conexão com o servidor. Verifique internet/Wi-Fi. (${e.runtimeType})';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _status = '';
        });
      }
    }
  }

  Usuario _decodeUser(String raw) {
    final json = _safeDecode(raw);
    final data = json['data'] is Map ? json['data'] as Map : json;
    return Session.parseUsuario(data.cast<String, dynamic>());
  }

  Map<String, dynamic> _safeDecode(String raw) {
    try {
      return Map<String, dynamic>.from(jsonDecode(raw) as Map);
    } catch (_) {
      return {};
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/logo_malltech.png',
                width: 200,
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 8),
              Text(
                'Acesso ao Malltech',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Informe suas credenciais para continuar',
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 14),
              ),
              const SizedBox(height: 28),
              TextField(
                controller: _user,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Usuário',
                  labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                ),
                enabled: !_loading,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 15),
              TextField(
                controller: _pass,
                obscureText: _obscure,
                style: TextStyle(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontSize: 16),
                decoration: InputDecoration(
                  labelText: 'Senha',
                  labelStyle: TextStyle(
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: Theme.of(context).primaryColor),
                  ),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscure ? Icons.visibility : Icons.visibility_off,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
                enabled: !_loading,
                onSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Entre em contato com a administração do shopping',
                              ),
                            ),
                          ),
                  child: Text(
                    'Esqueci minha senha.',
                    style: TextStyle(
                      color: Theme.of(context).primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Checkbox(
                    value: _lembrar,
                    onChanged: _loading
                        ? null
                        : (v) => setState(() => _lembrar = v ?? false),
                    activeColor: Theme.of(context).primaryColor,
                  ),
                  Text(
                    'Lembrar senha',
                    style: TextStyle(
                        color:
                            Theme.of(context).colorScheme.onSurface,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                _error ?? _status,
                style: TextStyle(
                  color: _error != null ? Colors.red : Colors.grey,
                  fontWeight:
                      _error != null ? FontWeight.w500 : FontWeight.normal,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _loading
                      ? const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Carregando'),
                            SizedBox(width: 10),
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          'Entrar',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
