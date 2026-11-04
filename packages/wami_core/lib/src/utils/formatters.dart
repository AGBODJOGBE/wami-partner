/// Formatage des montants, durées et heures, à la française.
abstract final class Fmt {
  static const _nbsp = ' ';

  /// 12500 → « 12 500 F ».
  static String fcfa(int amount, {bool withUnit = true, bool signed = false}) {
    final negative = amount < 0;
    final digits = amount.abs().toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write(_nbsp);
      buffer.write(digits[i]);
    }
    final sign = negative ? '−$_nbsp' : (signed ? '+$_nbsp' : '');
    return '$sign$buffer${withUnit ? '${_nbsp}F' : ''}';
  }

  /// 390 → « 6 h 30 ».
  static String duration(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    if (h == 0) return '$m${_nbsp}min';
    return '$h${_nbsp}h$_nbsp${m.toString().padLeft(2, '0')}';
  }

  /// 125 → « 2:05 ».
  static String clock(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '$m:${s.toString().padLeft(2, '0')}';
  }

  /// Heure « 08:42 ».
  static String hhmm(DateTime t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  static const _days = ['Lun.', 'Mar.', 'Mer.', 'Jeu.', 'Ven.', 'Sam.', 'Dim.'];
  static const _months = [
    'janv.', 'févr.', 'mars', 'avr.', 'mai', 'juin',
    'juil.', 'août', 'sept.', 'oct.', 'nov.', 'déc.',
  ];

  /// « Sam. 26 oct. ».
  static String dayMonth(DateTime d) => '${_days[d.weekday - 1]} ${d.day} ${_months[d.month - 1]}';

  /// « Aujourd'hui », « Demain » ou « Sam. 26 ».
  static String relativeDay(DateTime d, {DateTime? now}) {
    final today = _dateOnly(now ?? DateTime.now());
    final diff = _dateOnly(d).difference(today).inDays;
    if (diff == 0) return 'Aujourd’hui';
    if (diff == 1) return 'Demain';
    if (diff == -1) return 'Hier';
    return '${_days[d.weekday - 1]} ${d.day}';
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  /// « Gilexe AGBODJOGBE » → « GA ».
  static String initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    final first = parts.first[0];
    final last = parts.length > 1 ? parts.last[0] : '';
    return (first + last).toUpperCase();
  }
}
