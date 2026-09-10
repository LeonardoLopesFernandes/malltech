import 'dart:convert';
import 'api.dart';
import 'session.dart';
import 'models.dart';

class ComunicadoRepo {
  static Future<List<Comunicado>> listar() async {
    final raw = await Api.get('/systems/comunicado/api/lista.php');
    return Comunicado.parseArray(jsonDecode(raw) as List<dynamic>);
  }

  static Future<void> confirmar(int id) => Api.post(
        '/systems/comunicado/api/confirmar.php',
        fields: {'id': id.toString(), 'integrated': 'true'},
      );
}

class ArquivosRepo {
  static Future<List<Documento>> listar() async {
    final raw = await Api.get('/systems/arquivos/api/documento.php?do=get');
    return Documento.parseArray(jsonDecode(raw) as List<dynamic>);
  }

  static Future<void> marcarLido(int id) {
    final uid = Session.usuario.value?.id ?? 0;
    return Api.post(
      '/systems/arquivos/api/leitura.php',
      fields: {
        'arquivo_id': id.toString(),
        'usuario_id': uid.toString(),
        'integrated': 'true',
      },
    );
  }
}

class FaleConoscoRepo {
  static Future<List<FaleConosco>> listar([String status = '']) async {
    final raw = await Api.get(
      '/systems/fale-conosco/api/lista_ajax.php?do=get',
      {
        'loja_id': Session.usuario.value?.lojaId.toString() ?? '',
        'empreendimento':
            Session.usuario.value?.empreendimentoId.toString() ?? '',
        'status': status,
      },
    );
    return FaleConosco.parseArray(jsonDecode(raw) as List<dynamic>);
  }

  static Future<void> finalizar(int id) => Api.post(
        '/systems/fale-conosco/api/lista_ajax.php?do=finalizar',
        fields: {'id': id.toString(), 'integrated': 'true'},
      );
}

class BoletosRepo {
  static Future<List<Boleto>> listar() async {
    final raw = await Api.get(
      '/systems/boletos/api/boleto.php?do=get',
      {
        'page': '0',
        'filtro_empreendimento':
            Session.usuario.value?.empreendimentoId.toString() ?? '',
        'filtro_loja': Session.usuario.value?.lojaId.toString() ?? '',
      },
    );
    return Boleto.parseArray(jsonDecode(raw) as List<dynamic>);
  }
}

class GuiaRepo {
  static Future<List<ProdutoVitrine>> listar([String status = '-1']) async {
    final raw = await Api.get(
      '/systems/guia/api/lista.php?do=get',
      {
        'page': '0',
        'filtro_nome': '',
        'filtro_sku': '',
        'filtro_status': status,
        'filtro_loja': '',
        'filtro_empreendimento':
            Session.usuario.value?.empreendimentoId.toString() ?? '',
        'exportAjax': '0',
      },
    );
    return ProdutoVitrine.parseArray(jsonDecode(raw) as List<dynamic>);
  }
}

class CorrespondenciaRepo {
  static Future<void> _seed() =>
      Api.get('/systems/correspondencia/?integrated=true');

  static Future<List<Correspondencia>> listar() async {
    await _seed();
    final raw = await Api.get(
      '/systems/correspondencia/api/lista.php?do=get',
      {
        'page': '0',
        'filtro_status': '0',
        'filtro_loja': '',
        'filtro_codigo': '',
        'filtro_categoria': '',
      },
    );
    return Correspondencia.parseArray(jsonDecode(raw) as List<dynamic>);
  }

  static Future<void> devolver(int id) async {
    await _seed();
    await Api.post(
      '/systems/correspondencia/api/acao.php',
      fields: {
        'acao': 'devolver',
        'id': id.toString(),
        'integrated': 'true'
      },
    );
  }

  static Future<void> gerarComunicado(int id) async {
    await _seed();
    await Api.post(
      '/systems/correspondencia/api/acao.php',
      fields: {
        'acao': 'comunicado',
        'id': id.toString(),
        'integrated': 'true'
      },
    );
  }

  static Future<void> excluir(int id) async {
    await _seed();
    await Api.post(
      '/systems/correspondencia/api/excluir.php',
      fields: {'id': id.toString(), 'integrated': 'true'},
    );
  }
}

class TrabalheRepo {
  static Future<void> _seed() =>
      Api.get('/systems/trabalhe-conosco/?integrated=true');

  static Future<List<VagaTrabalhe>> listarVagas() async {
    await _seed();
    final raw = await Api.get(
      '/systems/trabalhe-conosco/api/lista.php?do=get',
      {
        'page': '0',
        'filtro_empreendimento':
            Session.usuario.value?.empreendimentoId.toString() ?? '',
        'filtro_loja': '',
      },
    );
    return VagaTrabalhe.parseArray(jsonDecode(raw) as List<dynamic>);
  }

  static Future<List<Curriculo>> listarCurriculos() async {
    await _seed();
    final raw = await Api.get(
      '/systems/trabalhe-conosco/api/curriculo_ajax.php?do=get',
      {
        'page': '0',
        'filtro_empreendimento':
            Session.usuario.value?.empreendimentoId.toString() ?? '',
        'filtro_loja': '',
      },
    );
    return Curriculo.parseArray(jsonDecode(raw) as List<dynamic>);
  }

  static Future<void> novaVaga(
    String cargo,
    String quantidade,
    String duracao,
    String descricao,
  ) async {
    await _seed();
    await Api.post(
      '/systems/trabalhe-conosco/api/novo.php',
      fields: {
        'integrated': 'true',
        'tipo': '0',
        'loja_id': Session.usuario.value?.lojaId.toString() ?? '',
        'cargo': cargo,
        'quantidade': quantidade,
        'duracao': duracao,
        'descricao': descricao,
      },
    );
  }

  static Future<void> ativar(int id) => Api.post(
        '/systems/trabalhe-conosco/api/editar.php',
        fields: {
          'acao': 'ativar',
          'id': id.toString(),
          'integrated': 'true'
        },
      );

  static Future<void> desativar(int id) => Api.post(
        '/systems/trabalhe-conosco/api/editar.php?integrated=true',
        fields: {
          'acao': 'desativar',
          'id': id.toString(),
          'integrated': 'true'
        },
      );
}

class ConfigRepo {
  static Future<void> trocarSenha(String nova, String confirma) =>
      Api.putBackendJson('/api/v1/usuarios/troca/password', {
        'password': nova,
        'password_confirmation': confirma,
      });

  static Future<void> adiarSenha() =>
      Api.postBackendEmpty('/api/v1/usuarios/troca/password/adiar');

  static Future<void> definirImagem(String url) =>
      Api.putBackendJson('/api/v1/usuarios/imagem', {'imagem': url});

  static Future<void> removerImagem() =>
      Api.postBackendEmpty('/api/v1/usuarios/imagem/remove');

  static Future<String> uploadFoto(List<int> bytes, String fileName) =>
      Api.uploadR2(bytes, fileName);
}
