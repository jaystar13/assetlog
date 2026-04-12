/// DateTime → 'YYYY-MM' 형식 문자열
String toMonthKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}';

/// DateTime → 'YYYY-MM-DD' 형식 문자열
String toDateKey(DateTime date) =>
    '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
