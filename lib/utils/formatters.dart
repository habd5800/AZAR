String money(Object? value) {
  final n = (value as num?)?.toInt() ?? 0;
  return '${n.toString().replaceAllMapped(RegExp(r'(?<!^)(?=(\d{3})+$)'), (m) => ',')} ریال';
}
