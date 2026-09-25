import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SistemaAcesso {
  final int id;
  final String nome;
  final String url;
  final int permissao;
  final String tipo;
  final bool loja;
  SistemaAcesso({
    required this.id,
    required this.nome,
    required this.url,
    required this.permissao,
    required this.tipo,
    required this.loja,
  });
  factory SistemaAcesso.fromJson(Map<String, dynamic> a) => SistemaAcesso(
        id: a['id'] ?? 0,
        nome: (a['nome'] ?? '').toString().trim(),
        url: a['url'] ?? '',
        permissao: a['usuario_permissao'] ?? 0,
        tipo: a['tipo'] ?? '',
        loja: a['loja'] ?? false,
      );
}

class Usuario {
  final int id;
  final int lojaId;
  final int empreendimentoId;
  final String login;
  final String nome;
  final String lojaNome;
  final String empreendimentoNome;
  final bool isAdmin;
  final List<SistemaAcesso> acessos;
  final String imagem;
  Usuario({
    required this.id,
    required this.lojaId,
    required this.empreendimentoId,
    required this.login,
    required this.nome,
    required this.lojaNome,
    required this.empreendimentoNome,
    required this.isAdmin,
    required this.acessos,
    this.imagem = '',
  });
}

class Session {
  static SharedPreferences? _prefs;

  static final ValueNotifier<String?> token = ValueNotifier<String?>(null);
  static final ValueNotifier<Usuario?> usuario = ValueNotifier<Usuario?>(null);
  static final ValueNotifier<bool> expired = ValueNotifier<bool>(false);

  static Timer? _timer;

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final t = _prefs!.getString('token');
    final userJson = _prefs!.getString('usuario');
    Usuario? u;
    if (userJson != null && userJson.isNotEmpty) {
      try {
        u = parseUsuario(jsonDecode(userJson));
      } catch (_) {
        u = null;
      }
    }
    if (t == null || t.isEmpty) {
      token.value = null;
      usuario.value = null;
    } else if (u == null || isTokenExpirado(t)) {
      _clearKeepLogin();
      token.value = null;
      usuario.value = null;
    } else {
      token.value = t;
      usuario.value = u;
    }
    _startTimer();
  }

  static void save(String t, Usuario u) {
    token.value = t;
    usuario.value = u;
    _prefs?.setString('token', t);
    _prefs?.setString('usuario', jsonEncode(_usuarioToJson(u)));
  }

  static void salvarUltimoLogin(String login) {
    if (login.isNotEmpty) _prefs?.setString('ultimo_login', login);
  }

  static String ultimoLogin() => _prefs?.getString('ultimo_login') ?? '';

  static void salvarSenha(String senha) {
    if (senha.isNotEmpty) _prefs?.setString('ultima_senha', senha);
  }

  static String ultimaSenha() => _prefs?.getString('ultima_senha') ?? '';

  static void salvarOpcaoLembrar(bool value) {
    _prefs?.setBool('lembrar_senha', value);
  }

  /// Atualiza a imagem de perfil do usuário local e persiste.
  static void atualizarImagem(String url) {
    final u = usuario.value;
    if (u == null) return;
    final novo = Usuario(
      id: u.id,
      lojaId: u.lojaId,
      empreendimentoId: u.empreendimentoId,
      login: u.login,
      nome: u.nome,
      lojaNome: u.lojaNome,
      empreendimentoNome: u.empreendimentoNome,
      isAdmin: u.isAdmin,
      acessos: u.acessos,
      imagem: url,
    );
    usuario.value = novo;
    _prefs?.setString('usuario', jsonEncode(_usuarioToJson(novo)));
  }

  static bool deveSalvarSenha() => _prefs?.getBool('lembrar_senha') ?? false;

  static void clear() {
    _clearKeepLogin();
    token.value = null;
    usuario.value = null;
    expired.value = false;
  }

  static void _clearKeepLogin() {
    final ultimo = ultimoLogin();
    final senha = ultimaSenha();
    final lembrar = deveSalvarSenha();
    _prefs?.clear();
    if (ultimo.isNotEmpty) _prefs?.setString('ultimo_login', ultimo);
    if (lembrar) {
      if (senha.isNotEmpty) _prefs?.setString('ultima_senha', senha);
      _prefs?.setBool('lembrar_senha', true);
    }
  }

  static bool isTokenExpirado([String? tk]) {
    final t = tk ?? token.value;
    if (t == null || t.isEmpty) return true;
    final parts = t.split('.');
    if (parts.length != 3) return true;
    String payload = parts[1];
    while (payload.length % 4 != 0) {
      payload += '=';
    }
    try {
      final json = utf8.decode(base64Url.decode(payload));
      final exp = (jsonDecode(json)['exp'] ?? 0) as int;
      if (exp == 0) return true;
      return exp * 1000 <= DateTime.now().millisecondsSinceEpoch;
    } catch (_) {
      return true;
    }
  }

  static void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 60), (_) {
      final t = token.value;
      if (t != null && isTokenExpirado(t)) {
        clear();
      }
    });
  }

  static Usuario parseUsuario(Map<String, dynamic> obj) {
    List<SistemaAcesso> acessos = [];
    if (obj['acessos'] is List) {
      acessos = (obj['acessos'] as List)
          .map((a) => SistemaAcesso.fromJson(a))
          .toList();
    }
    dynamic nomeDe(dynamic v, String fallback) {
      if (v == null) return fallback;
      if (v is Map) return v['nome'] ?? fallback;
      if (v is List && v.isNotEmpty) {
        final first = v[0];
        if (first is Map) return first['nome'] ?? fallback;
      }
      if (v is String) {
        final s = v.trim();
        if (s.startsWith('{')) {
          try {
            return (jsonDecode(s)['nome'] ?? fallback);
          } catch (_) {
            return fallback;
          }
        }
        return s;
      }
      return fallback;
    }

    String imagem = obj['imagem'] is String ? obj['imagem'] : '';
    if (imagem.isEmpty && obj['pessoa'] is Map) {
      final p = obj['pessoa'] as Map;
      imagem = p['imagem'] is String ? p['imagem'] : '';
    }
    return Usuario(
      id: obj['id'] ?? 0,
      lojaId: obj['loja_id'] ?? 0,
      empreendimentoId: obj['empreendimento_id'] ?? 0,
      login: obj['login'] ?? '',
      nome: nomeDe(obj['pessoa'], ''),
      lojaNome: nomeDe(obj['loja'], ''),
      empreendimentoNome: nomeDe(obj['empreendimento'], ''),
      isAdmin: obj['is_admin'] ?? false,
      acessos: acessos,
      imagem: imagem,
    );
  }

  static Map<String, dynamic> _usuarioToJson(Usuario u) => {
        'id': u.id,
        'loja_id': u.lojaId,
        'empreendimento_id': u.empreendimentoId,
        'login': u.login,
        'pessoa': {
          'nome': u.nome,
          'imagem': u.imagem,
        },
        'loja': u.lojaNome,
        'empreendimento': u.empreendimentoNome,
        'is_admin': u.isAdmin,
        'acessos': u.acessos
            .map((a) => {
                  'id': a.id,
                  'nome': a.nome,
                  'url': a.url,
                  'usuario_permissao': a.permissao,
                  'tipo': a.tipo,
                  'loja': a.loja,
                })
            .toList(),
      };
}
