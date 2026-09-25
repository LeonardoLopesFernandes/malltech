import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:crypto/crypto.dart' as crypto;
import 'package:shared_preferences/shared_preferences.dart';
import 'session.dart';

class ApiException implements Exception {
  final String message;
  final int code;
  ApiException(this.message, [this.code = 0]);
  @override
  String toString() => message;
}

class ApiConfig {
  static const v3 = 'https://v3.madnezz.com.br';
  static const backend = 'https://backend.madnezz.com.br';
  static const spa = 'https://sistemas.madnezz.com.br';
}

class Api {
  static const _cookieKey = 'malltech_cookies';
  static SharedPreferences? _prefs;
  static final Map<String, String> _cookies = {};

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    final raw = _prefs?.getString(_cookieKey);
    if (raw != null && raw.isNotEmpty) {
      try {
        final map = jsonDecode(raw) as Map<String, dynamic>;
        _cookies.addAll(map.map((k, v) => MapEntry(k, v.toString())));
      } catch (_) {}
    }
  }

  static void _saveCookies(String? setCookie) {
    if (setCookie == null) return;
    for (final part in setCookie.split(',')) {
      final kv = part.split(';').first.trim();
      final idx = kv.indexOf('=');
      if (idx <= 0) continue;
      final name = kv.substring(0, idx);
      final value = kv.substring(idx + 1);
      _cookies[name] = value;
    }
    _prefs?.setString(_cookieKey, jsonEncode(_cookies));
  }

  static String _cookieHeader() => _cookies.entries
      .map((e) => '${e.key}=${e.value}')
      .join('; ');

  static String _v3Url(String path, Map<String, String> params) {
    final base = path.startsWith('http') ? path : '${ApiConfig.v3}$path';
    final uri = Uri.parse(base);
    final q = Map<String, String>.from(uri.queryParameters);
    if (!base.contains('token=') && Session.token.value != null) {
      q['token'] = Session.token.value!;
    }
    params.forEach((k, v) {
      if (v.isNotEmpty) q[k] = v;
    });
    return uri.replace(queryParameters: q).toString();
  }

  static Future<String> _execute(http.Request request) async {
    request.headers['Cookie'] = _cookieHeader();
    debugPrint('API: ${request.method} ${request.url}');
    final streamed = await request.send();
    final response = await http.Response.fromStream(streamed);
    _saveCookies(response.headers['set-cookie']);
    final body = response.body;
    debugPrint('API: ${request.method} ${request.url} -> ${response.statusCode}');
    if (!response.statusCode.toString().startsWith('2')) {
      if (response.statusCode == 401) Session.clear();
      String detail = '';
      try {
        detail = jsonDecode(body)['error']?.toString() ?? '';
      } catch (_) {}
      debugPrint('API: ERRO body=${body.length > 300 ? body.substring(0, 300) : body}');
      throw ApiException(
        detail.isNotEmpty ? 'HTTP ${response.statusCode}: $detail' : 'HTTP ${response.statusCode}',
        response.statusCode,
      );
    }
    return body;
  }

  static Future<String> get(String path,
      [Map<String, String> params = const {}]) async {
    final url = _v3Url(path, params);
    final req = http.Request('GET', Uri.parse(url));
    if (Session.token.value != null) {
      req.headers['Authorization'] = 'Bearer ${Session.token.value}';
    }
    return _execute(req);
  }

  static Future<String> post(String path,
      {Map<String, String> fields = const {},
      Map<String, String> params = const {}}) async {
    final url = _v3Url(path, params);
    final req = http.Request('POST', Uri.parse(url));
    req.headers['Authorization'] =
        Session.token.value != null ? 'Bearer ${Session.token.value}' : '';
    req.bodyFields = fields;
    return _execute(req);
  }

  static Map<String, String> _backendHeaders() => {
        'Authorization':
            Session.token.value != null ? 'Bearer ${Session.token.value}' : '',
        'client': 'malltech',
        'device': 'android',
        'Accept': 'application/json',
      };

  static Future<String> _executeSimple(http.BaseRequest req) async {
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    final body = response.body;
    if (!response.statusCode.toString().startsWith('2')) {
      if (response.statusCode == 401) Session.clear();
      throw ApiException('HTTP ${response.statusCode}', response.statusCode);
    }
    return body;
  }

  static Future<String> putBackendJson(
      String path, Map<String, dynamic> body) async {
    final req = http.Request(
        'PUT', Uri.parse('${ApiConfig.backend}$path'));
    req.headers.addAll(_backendHeaders());
    req.headers['Content-Type'] = 'application/json';
    req.body = jsonEncode(body);
    return _executeSimple(req);
  }

  static Future<String> postBackendEmpty(String path) async {
    final req = http.Request(
        'POST', Uri.parse('${ApiConfig.backend}$path'));
    req.headers.addAll(_backendHeaders());
    req.body = '';
    return _executeSimple(req);
  }

  static Future<String> postBackendJson(
      String path, Map<String, dynamic> body) async {
    final req = http.Request(
        'POST', Uri.parse('${ApiConfig.backend}$path'));
    req.headers.addAll(_backendHeaders());
    req.headers['Content-Type'] = 'application/json';
    req.body = jsonEncode(body);
    return _executeSimple(req);
  }

  static Future<String> deleteBackend(String path) async {
    final req = http.Request(
        'DELETE', Uri.parse('${ApiConfig.backend}$path'));
    req.headers.addAll(_backendHeaders());
    req.body = '';
    return _executeSimple(req);
  }

  static Future<Map<String, dynamic>> uploadR2(
      List<int> bytes, String fileName) async {
    final req = http.MultipartRequest(
        'POST', Uri.parse('https://upload-r2.madnezz.com.br/'));
    req.headers['Authorization'] =
        Session.token.value != null ? 'Bearer ${Session.token.value}' : '';
    req.headers['Accept'] = 'application/json';
    req.files.add(http.MultipartFile.fromBytes('files', bytes,
        filename: fileName));
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    if (!response.statusCode.toString().startsWith('2')) {
      throw ApiException('HTTP ${response.statusCode}', response.statusCode);
    }
    final data = jsonDecode(response.body);
    if (data is Map) return data.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  /// Extrai a URL pública do payload de upload R2 (`files[0].id`).
  static String? urlDoUpload(Map<String, dynamic> payload) {
    try {
      final files = payload['files'];
      if (files is List && files.isNotEmpty) {
        final primeiro = files.first;
        if (primeiro is Map) {
          final id = (primeiro['id'] ?? '').toString();
          if (id.isNotEmpty) return 'https://upload-r2.madnezz.com.br/$id';
        }
      }
    } catch (_) {}
    return null;
  }

  static Future<String> getBackend(String path) async {
    final url = '${ApiConfig.backend}$path';
    final req = http.Request('GET', Uri.parse(url));
    req.headers['Authorization'] =
        Session.token.value != null ? 'Bearer ${Session.token.value}' : '';
    req.headers['client'] = 'malltech';
    req.headers['device'] = 'android';
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    final body = response.body;
    debugPrint('API.getBackend ${path} -> ${response.statusCode}');
    if (!response.statusCode.toString().startsWith('2')) {
      if (response.statusCode == 401) Session.clear();
      debugPrint(
          'API.getBackend erro body=${body.length > 300 ? body.substring(0, 300) : body}');
      throw ApiException('HTTP ${response.statusCode}', response.statusCode);
    }
    return body;
  }

  static Future<String> login(String login, String password) async {
    final client = http.Client();
    try {
      await client.get(Uri.parse('${ApiConfig.backend}/sanctum/csrf-cookie'));
      final req = http.Request(
          'POST', Uri.parse('${ApiConfig.backend}/api/auth/login'));
      req.headers['X-Requested-With'] = 'XMLHttpRequest';
      req.headers['Origin'] = ApiConfig.spa;
      req.headers['Referer'] = '${ApiConfig.spa}/auth/login';
      req.headers['Accept'] = 'application/json, text/plain, */*';
      req.bodyFields = {
        'client': 'madnezz',
        'device': 'web',
        'login': login,
        'password': password,
      };
      final streamed = await client.send(req);
      final response = await http.Response.fromStream(streamed);
      final body = response.body;
      debugPrint('API.login status=${response.statusCode}');
      if (!response.statusCode.toString().startsWith('2')) {
        String msg = '';
        try {
          msg = jsonDecode(body)['message']?.toString() ?? '';
        } catch (_) {}
        debugPrint('API.login erro body=${body.length > 300 ? body.substring(0, 300) : body}');
        throw ApiException(msg.isNotEmpty ? msg : 'HTTP ${response.statusCode}',
            response.statusCode);
      }
      final tk = jsonDecode(body)['token']?.toString() ?? '';
      debugPrint('API.login token length=${tk.length}');
      return tk;
    } finally {
      client.close();
    }
  }

  static Future<bool> portalLogin(String login, String senha) async {
    // 1) Semeia a sessão do portal.
    try {
      final seedReq =
          http.Request('GET', Uri.parse('${ApiConfig.v3}/auth/login/'));
      final seedResp = await seedReq.send();
      _saveCookies(seedResp.headers['set-cookie']);
    } catch (_) {}

    // 2) O formulário do portal faz sha256 da senha antes de enviar.
    final senhaHash =
        crypto.sha256.convert(utf8.encode(senha)).toString();

    // 3) POST de login (não segue o redirect 302 para capturar o PHPSESSID autenticado).
    final req = http.Request(
        'POST', Uri.parse('${ApiConfig.v3}/auth/login/'));
    req.followRedirects = false;
    req.headers['Cookie'] = _cookieHeader();
    req.bodyFields = {'login': login, 'senha': senhaHash};
    final streamed = await req.send();
    final response = await http.Response.fromStream(streamed);
    _saveCookies(response.headers['set-cookie']);
    final autenticado =
        response.statusCode == 302 || response.statusCode == 200;
    if (!autenticado) return false;
    try {
      final page = await get('/sistemas/pedido/',
          {'p': 'novo', 'integrated': 'true'});
      return page.contains('data-tipo=');
    } catch (_) {
      return false;
    }
  }

  static String get phpsessid =>
      _cookies['PHPSESSID'] ?? _cookies['phpsessid'] ?? '';

  static String? _lastLogin;
  static String? _lastSenha;

  static void setCredenciais(String login, String senha) {
    _lastLogin = login;
    _lastSenha = senha;
  }

  /// Garante a sessão do portal v3 (PHPSESSID) para telas que consomem HTML.
  static Future<void> ensurePortalSession() async {
    if (_lastLogin != null && _lastSenha != null) {
      try {
        await portalLogin(_lastLogin!, _lastSenha!);
      } catch (_) {}
    }
  }

  /// POST com campos normais e campos repetidos (mesma chave várias vezes).
  static Future<String> postForm(String path,
      {Map<String, String> fields = const {},
      List<List<String>> repeated = const []}) async {
    final params = <String, String>{};
    if (Session.token.value != null) params['token'] = Session.token.value!;
    final uri = Uri.parse(_v3Url(path, {})).replace(queryParameters: params);
    final req = http.Request('POST', uri);
    if (Session.token.value != null) {
      req.headers['Authorization'] = 'Bearer ${Session.token.value}';
    }
    final parts = <String>[];
    String enc(String k, String v) =>
        '${Uri.encodeQueryComponent(k)}=${Uri.encodeQueryComponent(v)}';
    fields.forEach((k, v) => parts.add(enc(k, v)));
    for (final r in repeated) {
      if (r.length == 2) parts.add(enc(r[0], r[1]));
    }
    req.headers['Content-Type'] =
        'application/x-www-form-urlencoded; charset=utf-8';
    req.body = parts.join('&');
    return _execute(req);
  }
}
