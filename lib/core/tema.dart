import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TemaApp extends ChangeNotifier {
  static const _kCor = 'tema_cor';
  static const _kEscuro = 'tema_escuro';

  static const List<Map<String, dynamic>> opcoes = [
    {'nome': 'Malltech', 'cor': Color(0xFFFF2D55)},
    {'nome': 'Azul', 'cor': Color(0xFF2563EB)},
    {'nome': 'Verde', 'cor': Color(0xFF16A34A)},
    {'nome': 'Roxo', 'cor': Color(0xFF7C3AED)},
    {'nome': 'Laranja', 'cor': Color(0xFFEA580C)},
  ];

  int _indice = 0;
  bool _escuro = false;

  int get indice => _indice;
  bool get escuro => _escuro;
  Color get cor => (opcoes[_indice]['cor'] as Color);

  ThemeData get theme {
    final base = _escuro ? ThemeData.dark() : ThemeData.light();
    return base.copyWith(
      primaryColor: cor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: cor,
        brightness: _escuro ? Brightness.dark : Brightness.light,
      ),
      useMaterial3: true,
      // Modo escuro AMOLED: fundo preto puro.
      scaffoldBackgroundColor:
          _escuro ? const Color(0xFF000000) : base.scaffoldBackgroundColor,
    );
  }

  static Future<TemaApp> carregar() async {
    final t = TemaApp();
    final prefs = await SharedPreferences.getInstance();
    t._indice = prefs.getInt(_kCor) ?? 0;
    if (t._indice < 0 || t._indice >= opcoes.length) t._indice = 0;
    t._escuro = prefs.getBool(_kEscuro) ?? false;
    return t;
  }

  Future<void> definirCor(int i) async {
    if (i < 0 || i >= opcoes.length || i == _indice) return;
    _indice = i;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kCor, i);
    notifyListeners();
  }

  Future<void> definirEscuro(bool v) async {
    if (v == _escuro) return;
    _escuro = v;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kEscuro, v);
    notifyListeners();
  }
}
