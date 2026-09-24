/// Formata strings de data vindas da API para o padrão brasileiro
/// (dia/mês/ano). Converte formatos como "2026/09/24", "2026-09-24",
/// "2026/09/24 10:30" em "24/09/2026" ou "24/09/2026 10:30".
String formatarData(String? entrada) {
  if (entrada == null || entrada.trim().isEmpty) return '';
  final s = entrada.trim();

  // Extrai a parte de hora, se houver.
  String? hora;
  final comHora = RegExp(r'(\d{1,2}:\d{2})').firstMatch(s);
  if (comHora != null) hora = comHora.group(1);
  final dataParte = s.split(RegExp(r'\s+T?\s*')).first.trim();

  final partes = dataParte.split(RegExp(r'[/\-.]'));
  if (partes.length != 3) return s;

  int a = int.tryParse(partes[0]) ?? 0;
  int b = int.tryParse(partes[1]) ?? 0;
  int c = int.tryParse(partes[2]) ?? 0;

  String dia, mes, ano;
  // Formato AAAA-MM-DD / AAAA/MM/DD
  if (a > 31) {
    ano = a.toString();
    mes = b.toString().padLeft(2, '0');
    dia = c.toString().padLeft(2, '0');
  } else {
    // Já em DD/MM/AAAA
    dia = a.toString().padLeft(2, '0');
    mes = b.toString().padLeft(2, '0');
    ano = c.toString();
  }
  final data = '$dia/$mes/$ano';
  return hora == null ? data : '$data $hora';
}