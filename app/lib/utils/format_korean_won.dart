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

/// Overview 차트용 (백만 단위 데이터)
String formatChartWon(num amount) {
  if (amount >= 100) {
    return '${(amount / 100).toStringAsFixed(1)}억';
  }
  return '$amount백만';
}

/// 월 포맷 (2026-03 → 03월)
String formatMonth(String monthStr) {
  final parts = monthStr.split('-');
  if (parts.length == 2) {
    return '${parts[1]}월';
  }
  return monthStr;
}
