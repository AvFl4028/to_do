/// Formatea un tamaño en bytes de forma legible (`840 B`, `12,4 KB`, ...).
String formatFileSize(int bytes) {
  if (bytes <= 0) {
    return '0 B';
  }
  const int kb = 1024;
  const int mb = kb * 1024;
  const int gb = mb * 1024;

  String format(double value, String unit) {
    final rounded = value >= 10
        ? value.round().toString()
        : value.toStringAsFixed(1);
    return '${rounded.replaceAll('.', ',')} $unit';
  }

  if (bytes >= gb) {
    return format(bytes / gb, 'GB');
  }
  if (bytes >= mb) {
    return format(bytes / mb, 'MB');
  }
  if (bytes >= kb) {
    return format(bytes / kb, 'KB');
  }
  return '$bytes B';
}
