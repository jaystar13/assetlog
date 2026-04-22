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
/// [range] 가 주어지면 범위에 따라 소수점 정밀도를 조정한다.
/// - 범위가 1억 미만이면 억 단위 소수 2자리 (100만원 단위 구분)
/// - 그 외에는 억 단위 소수 1자리 (1000만원 단위 구분)
String formatChartWon(num amount, {num? range}) {
  final abs = amount.abs();
  final sign = amount < 0 ? '-' : '';
  if (abs >= 100000000) {
    final decimals = (range != null && range < 100000000) ? 2 : 1;
    return '$sign${(abs / 100000000).toStringAsFixed(decimals)}억';
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
