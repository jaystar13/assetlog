String formatKoreanWon(num amount) {
  final absAmount = amount.abs();
  final sign = amount < 0 ? '-' : '';
  if (absAmount >= 100000000) {
    return '$sign${(absAmount / 100000000).toStringAsFixed(1)}억 원';
  } else if (absAmount >= 10000) {
    return '$sign${(absAmount / 10000).round()}만 원';
  }
  return '$sign${absAmount.toStringAsFixed(0)} 원';
}

/// 차트 축 레이블용 (원 단위 → 간략 표기)
String formatChartWon(num amount) {
  final abs = amount.abs();
  final sign = amount < 0 ? '-' : '';
  if (abs >= 100000000) {
    return '$sign${(abs / 100000000).toStringAsFixed(1)}억';
  } else if (abs >= 10000) {
    return '$sign${(abs / 10000).round()}만';
  }
  return '$sign${abs.toStringAsFixed(0)}';
}

/// 월 포맷 (2026-03 → 03월)
String formatMonth(String monthStr) {
  final parts = monthStr.split('-');
  if (parts.length == 2) {
    return '${parts[1]}월';
  }
  return monthStr;
}
