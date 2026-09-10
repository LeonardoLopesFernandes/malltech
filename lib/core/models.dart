class Comunicado {
  final int id;
  final String pessoa;
  final String email;
  final String nome;
  final String empreendimento;
  final String data;
  Comunicado({
    required this.id,
    required this.pessoa,
    required this.email,
    required this.nome,
    required this.empreendimento,
    required this.data,
  });
  static List<Comunicado> parseArray(List<dynamic> arr) => arr.map((e) {
        final o = e as Map<String, dynamic>;
        return Comunicado(
          id: int.tryParse(o['id']?.toString() ?? '') ?? 0,
          pessoa: (o['pessoa'] ?? '').toString(),
          email: (o['email'] ?? '').toString(),
          nome: (o['nome'] ?? '').toString(),
          empreendimento: (o['empreendimento'] ?? '').toString(),
          data: (o['data'] ?? '').toString(),
        );
      }).toList();
}

class Documento {
  final int id;
  final String tipo;
  final String titulo;
  final String subtitulo;
  final String cadastro;
  final String vigencia;
  final String? lido;
  final String leituras;
  final String? arquivo;
  final String para;
  Documento({
    required this.id,
    required this.tipo,
    required this.titulo,
    required this.subtitulo,
    required this.cadastro,
    required this.vigencia,
    this.lido,
    required this.leituras,
    this.arquivo,
    required this.para,
  });
  bool get foiLido => lido != null && lido!.isNotEmpty;
  static List<Documento> parseArray(List<dynamic> arr) => arr.map((e) {
        final o = e as Map<String, dynamic>;
        final a = (o['arquivo'] ?? '').toString().trim();
        final l = (o['lido'] ?? '').toString().trim();
        return Documento(
          id: int.tryParse(o['id']?.toString() ?? '') ?? 0,
          tipo: (o['tipo'] ?? '').toString(),
          titulo: (o['titulo'] ?? '').toString(),
          subtitulo: (o['subtitulo'] ?? '').toString(),
          cadastro: (o['cadastro'] ?? '').toString(),
          vigencia: (o['vigencia'] ?? '').toString(),
          lido: l.isEmpty ? null : l,
          leituras: (o['leituras'] ?? '').toString(),
          arquivo: a.isEmpty ? null : a,
          para: (o['para'] ?? '').toString(),
        );
      }).toList();
}

class FaleConosco {
  final int id;
  final String cad;
  final String assunto;
  final String tipo;
  final String mensagem;
  final String empreendimento;
  final int status;
  final int finalizado;
  FaleConosco({
    required this.id,
    required this.cad,
    required this.assunto,
    required this.tipo,
    required this.mensagem,
    required this.empreendimento,
    required this.status,
    required this.finalizado,
  });
  String get statusLabel {
    if (finalizado >= 1) return 'Finalizado';
    if (status == 0) return 'Pendente';
    return 'Respondido';
  }
  static List<FaleConosco> parseArray(List<dynamic> arr) => arr.map((e) {
        final o = e as Map<String, dynamic>;
        return FaleConosco(
          id: int.tryParse(o['id']?.toString() ?? '') ?? 0,
          cad: (o['cad'] ?? '').toString(),
          assunto: (o['assunto'] ?? '').toString(),
          tipo: (o['tipo'] ?? '').toString(),
          mensagem: (o['mensagem'] ?? '').toString(),
          empreendimento: (o['empreendimento'] ?? '').toString(),
          status: int.tryParse(o['status']?.toString() ?? '0') ?? 0,
          finalizado: int.tryParse(o['finalizado']?.toString() ?? '0') ?? 0,
        );
      }).toList();
}

class Boleto {
  final int id;
  final String? boleto;
  final String valor;
  final String vencimento;
  final String status;
  final String empreendimento;
  final String loja;
  final String? descricao;
  Boleto({
    required this.id,
    this.boleto,
    required this.valor,
    required this.vencimento,
    required this.status,
    required this.empreendimento,
    required this.loja,
    this.descricao,
  });
  static List<Boleto> parseArray(List<dynamic> arr) => arr.map((e) {
        final o = e as Map<String, dynamic>;
        final b = (o['boleto'] ?? '').toString().trim();
        final d = (o['descricao'] ?? '').toString().trim();
        return Boleto(
          id: int.tryParse(o['id']?.toString() ?? '') ?? 0,
          boleto: b.isEmpty ? null : b,
          valor: (o['valor'] ?? '').toString(),
          vencimento: (o['vencimento'] ?? '').toString(),
          status: (o['status'] ?? '').toString(),
          empreendimento: (o['empreendimento'] ?? '').toString(),
          loja: (o['loja'] ?? '').toString(),
          descricao: d.isEmpty ? null : d,
        );
      }).toList();
}

class VagaTrabalhe {
  final int id;
  final String lojaNome;
  final String cargo;
  final String cad;
  final String entrada;
  final String saida;
  final int duracaoDias;
  final bool aprovado;
  final bool reprovado;
  VagaTrabalhe({
    required this.id,
    required this.lojaNome,
    required this.cargo,
    required this.cad,
    required this.entrada,
    required this.saida,
    required this.duracaoDias,
    required this.aprovado,
    required this.reprovado,
  });
  static List<VagaTrabalhe> parseArray(List<dynamic> arr) => arr.map((e) {
        final o = e as Map<String, dynamic>;
        return VagaTrabalhe(
          id: int.tryParse(o['id']?.toString() ?? '') ?? 0,
          lojaNome: (o['loja_nome'] ?? '').toString(),
          cargo: (o['cargo'] ?? '').toString(),
          cad: (o['cad'] ?? '').toString(),
          entrada: (o['entrada'] ?? '').toString(),
          saida: (o['saida'] ?? '').toString(),
          duracaoDias: int.tryParse(o['duracao_dias']?.toString() ?? '0') ?? 0,
          aprovado: (int.tryParse(o['aprovado']?.toString() ?? '0') ?? 0) == 1,
          reprovado: (int.tryParse(o['reprovado']?.toString() ?? '0') ?? 0) == 1,
        );
      }).toList();
}

class Curriculo {
  final int id;
  final String vaga;
  final String nome;
  final String email;
  final String data;
  final String cpf;
  final String nascimento;
  final String sexo;
  final String escolaridade;
  final String cidade;
  final String telefone;
  final String cargo;
  final String observacao;
  final String avaliacao;
  final bool lido;
  final bool emailEnviado;
  final String arquivo;
  Curriculo({
    required this.id,
    required this.vaga,
    required this.nome,
    required this.email,
    required this.data,
    this.cpf = '',
    this.nascimento = '',
    this.sexo = '',
    this.escolaridade = '',
    this.cidade = '',
    this.telefone = '',
    required this.cargo,
    this.observacao = '',
    this.avaliacao = '',
    required this.lido,
    this.emailEnviado = false,
    required this.arquivo,
  });
  String? get cvUrl {
    if (arquivo.isEmpty) return null;
    if (arquivo.startsWith('http://') || arquivo.startsWith('https://')) {
      return arquivo;
    }
    return 'https://sal.madnezz.com.br/upload/cv/$arquivo';
  }
  static List<Curriculo> parseArray(List<dynamic> arr) => arr.map((e) {
        final o = e as Map<String, dynamic>;
        return Curriculo(
          id: int.tryParse(o['id']?.toString() ?? '') ?? 0,
          vaga: (o['vaga'] ?? '').toString(),
          nome: (o['nome'] ?? '').toString(),
          email: (o['email'] ?? '').toString(),
          data: (o['data'] ?? '').toString(),
          cpf: (o['cpf'] ?? '').toString(),
          nascimento: (o['nascimento'] ?? '').toString(),
          sexo: (o['sexo'] ?? '').toString(),
          escolaridade: (o['escolaridade'] ?? '').toString(),
          cidade: (o['cidade'] ?? '').toString(),
          telefone: (o['telefone1'] ?? '').toString().isNotEmpty
              ? (o['telefone1'] ?? '').toString()
              : (o['telefone'] ?? '').toString(),
          cargo: (o['cargo'] ?? '').toString(),
          observacao: (o['observacao'] ?? '').toString(),
          avaliacao: (o['avaliacao'] ?? '').toString(),
          lido: (int.tryParse(o['lido']?.toString() ?? '0') ?? 0) == 1,
          emailEnviado:
              (int.tryParse(o['email_enviado']?.toString() ?? '0') ?? 0) == 1,
          arquivo: (o['arquivo'] ?? '').toString(),
        );
      }).toList();
}

class ProdutoVitrine {
  final int id;
  final String nome;
  final String? valor;
  final String? sku;
  final String status;
  final int statusN;
  final String lojaNome;
  final String empreendimentoNome;
  ProdutoVitrine({
    required this.id,
    required this.nome,
    this.valor,
    this.sku,
    required this.status,
    required this.statusN,
    required this.lojaNome,
    required this.empreendimentoNome,
  });
  static List<ProdutoVitrine> parseArray(List<dynamic> arr) => arr.map((e) {
        final o = e as Map<String, dynamic>;
        final v = (o['valor'] ?? '').toString().trim();
        final s = (o['sku'] ?? '').toString().trim();
        final ln = (o['loja_nome'] ?? '').toString().trim();
        final en = (o['empreendimento_nome'] ?? '').toString().trim();
        return ProdutoVitrine(
          id: int.tryParse(o['id']?.toString() ?? '') ?? 0,
          nome: (o['nome'] ?? '').toString(),
          valor: v.isEmpty ? null : v,
          sku: s.isEmpty ? null : s,
          status: (o['status'] ?? '').toString(),
          statusN: int.tryParse(o['status_n']?.toString() ?? '0') ?? 0,
          lojaNome: ln.isEmpty ? '-' : ln,
          empreendimentoNome: en.isEmpty ? '-' : en,
        );
      }).toList();
}

class Correspondencia {
  final int cId;
  final String lojaId;
  final String nome;
  final String status;
  final int statusN;
  final String tipo;
  final int comunicado;
  final String entradaFormatada;
  final String saidaFormatada;
  final String postagem;
  final String cdd;
  final String retiradoNome;
  final String retiradoFoto;
  final String retiradoCpf;
  final String cadFormatada;
  final String codigo;
  final String assinatura;
  final String descricao;
  Correspondencia({
    required this.cId,
    required this.lojaId,
    required this.nome,
    required this.status,
    this.statusN = 0,
    required this.tipo,
    this.comunicado = 0,
    this.entradaFormatada = '',
    this.saidaFormatada = '',
    this.postagem = '',
    this.cdd = '',
    this.retiradoNome = '',
    this.retiradoFoto = '',
    this.retiradoCpf = '',
    required this.cadFormatada,
    required this.codigo,
    this.assinatura = '',
    required this.descricao,
  });
  static List<Correspondencia> parseArray(List<dynamic> arr) => arr.map((e) {
        final o = e as Map<String, dynamic>;
        return Correspondencia(
          cId: int.tryParse(o['c_id']?.toString() ?? '0') ?? 0,
          lojaId: (o['loja_id'] ?? '').toString(),
          nome: (o['nome'] ?? '').toString(),
          status: (o['status'] ?? '').toString(),
          statusN: int.tryParse(o['status_n']?.toString() ?? '0') ?? 0,
          tipo: (o['tipo'] ?? '').toString(),
          comunicado: int.tryParse(o['comunicado']?.toString() ?? '0') ?? 0,
          entradaFormatada: (o['entrada_formatada'] ?? '').toString(),
          saidaFormatada: (o['saida_formatada'] ?? '').toString(),
          postagem: (o['postagem'] ?? '').toString(),
          cdd: (o['cdd'] ?? '').toString(),
          retiradoNome: (o['retirado_nome'] ?? '').toString(),
          retiradoFoto: (o['retirado_foto'] ?? '').toString(),
          retiradoCpf: (o['retirado_cpf'] ?? '').toString(),
          cadFormatada: (o['cad_formatada'] ?? '').toString(),
          codigo: (o['codigo'] ?? '').toString(),
          assinatura: (o['assinatura'] ?? '').toString(),
          descricao: (o['descricao'] ?? '').toString(),
        );
      }).toList();
}
