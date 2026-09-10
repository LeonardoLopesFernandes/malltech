import 'package:flutter/material.dart';
import 'package:malltech_flutter/core/api.dart';
import 'package:malltech_flutter/core/session.dart';
import 'package:malltech_flutter/screens/login.dart';
import 'package:malltech_flutter/screens/home.dart';
import 'package:malltech_flutter/screens/trabalhe_conosco.dart';
import 'package:malltech_flutter/screens/modules.dart';
import 'package:malltech_flutter/screens/pedidos.dart';
import 'package:malltech_flutter/screens/cursos.dart';
import 'package:malltech_flutter/screens/configuracoes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Api.init();
  await Session.init();
  runApp(const MalltechApp());
}

class MalltechApp extends StatelessWidget {
  const MalltechApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Malltech',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: const Color(0xFFFF2D55),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF2D55)),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (c) => const AuthGate(),
        '/pedidos': (c) => const PedidosScreen(),
        '/pedidos/novo': (c) => const NovoPedidoScreen(),
        '/cursos': (c) => const CursosScreen(),
        '/trabalhe': (c) => const TrabalheConoscoScreen(),
        '/arquivos': (c) => const ArquivosScreen(),
        '/comunicados': (c) => const ComunicadosScreen(),
        '/fale': (c) => const FaleConoscoScreen(),
        '/boletos': (c) => const BoletosScreen(),
        '/guia': (c) => const GuiaScreen(),
        '/correspondencia': (c) => const CorrespondenciaScreen(),
        '/configuracoes': (c) => const ConfiguracoesScreen(),
      },
    );
  }
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  @override
  void initState() {
    super.initState();
    Session.token.addListener(_onToken);
    Session.usuario.addListener(_onToken);
  }

  void _onToken() {
    final t = Session.token.value;
    final u = Session.usuario.value;
    final loggedIn = t != null && u != null;
    debugPrint(
        'AUTH: token=${t == null ? 'null' : 'set'} usuario=${u == null ? 'null' : 'set'} loggedIn=$loggedIn');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      setState(() {});
    });
  }

  @override
  void dispose() {
    Session.token.removeListener(_onToken);
    Session.usuario.removeListener(_onToken);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = Session.token.value;
    final u = Session.usuario.value;
    if (t != null && u != null) return const HomeScreen();
    return const LoginScreen();
  }
}
