// 신한카드 이용대금명세서 파서
// 파일 형식: HTML로 저장된 .xls (UTF-8 인코딩)

export interface ParsedTransaction {
  date: string;   // YYYY-MM-DD
  name: string;   // 이용가맹점
  amount: number; // 원화 금액
}

// ──────────────────────────────────────────────────────────────────────────────
// HTML 테이블 파서 (간단한 구현)
// ──────────────────────────────────────────────────────────────────────────────

function extractTableRows(html: string): string[][] {
  const rows: string[][] = [];
  const trRegex = /<tr[^>]*>([\s\S]*?)<\/tr>/gi;
  const tdRegex = /<t[dh][^>]*>([\s\S]*?)<\/t[dh]>/gi;
  const tagRegex = /<[^>]+>/g;

  let trMatch: RegExpExecArray | null;
  while ((trMatch = trRegex.exec(html)) !== null) {
    const rowHtml = trMatch[1];
    const cells: string[] = [];
    let tdMatch: RegExpExecArray | null;
    tdRegex.lastIndex = 0;
    while ((tdMatch = tdRegex.exec(rowHtml)) !== null) {
      const cellText = tdMatch[1]
        .replace(tagRegex, '')
        .replace(/&nbsp;/g, ' ')
        .replace(/&amp;/g, '&')
        .replace(/&lt;/g, '<')
        .replace(/&gt;/g, '>')
        .replace(/\s+/g, ' ') // 개행/탭 등 내부 공백 정규화
        .trim();
      cells.push(cellText);
    }
    if (cells.some((c) => c.length > 0)) rows.push(cells);
  }
  return rows;
}

// ──────────────────────────────────────────────────────────────────────────────
// 메인 파서
// ──────────────────────────────────────────────────────────────────────────────

const DATE_PATTERN = /^\d{4}\.\d{2}\.\d{2}$/;

// 소계/합계 행 감지용 키워드
const SUMMARY_KEYWORDS = ['소계', '합계', '총합계'];

function isSummaryRow(row: string[]): boolean {
  return SUMMARY_KEYWORDS.some((kw) => row[0]?.includes(kw) || row[2]?.includes(kw));
}

function parseAmount(raw: string): number {
  return parseInt(raw.replace(/,/g, '').trim(), 10);
}

function isOverseas(amountStr: string): boolean {
  return amountStr.includes('.');
}

export function parseShinhanXls(fileBuffer: Buffer): ParsedTransaction[] {
  const rows = extractTableRows(fileBuffer.toString('utf-8'));

  // 헤더 행 탐색: '이용카드'와 '이용가맹점'이 독립 셀로 존재하는 행
  let headerIndex = -1;
  for (let i = 0; i < rows.length; i++) {
    if (rows[i].includes('이용카드') && rows[i].includes('이용가맹점')) {
      headerIndex = i;
      break;
    }
  }
  if (headerIndex === -1) {
    throw new Error('파일 형식이 올바르지 않습니다. 신한카드 이용대금명세서 파일인지 확인해주세요.');
  }

  const results: ParsedTransaction[] = [];

  // 헤더 다음 행부터 파싱 (서브헤더 행 '원금/수수료(이자)' 포함 +2)
  for (let i = headerIndex + 2; i < rows.length; i++) {
    const row = rows[i];

    // 날짜 형식이 아니면 스킵
    if (!DATE_PATTERN.test(row[0] ?? '')) continue;
    // 소계/합계 행 스킵
    if (isSummaryRow(row)) continue;

    const dateStr = row[0].replace(/\./g, '-'); // YYYY-MM-DD
    const merchant = row[2]?.trim() ?? '';
    const typeIndicator = row[8]?.trim() ?? '';

    if (!merchant) continue;
    // 취소 건 스킵
    if (typeIndicator === '취소') continue;

    // 금액 처리
    const rawAmount = row[3] ?? '';
    let amount: number;

    if (isOverseas(rawAmount)) {
      // 해외 결제: col[6]의 KRW 환산 금액 사용
      amount = parseAmount(row[6] ?? '0');
    } else {
      amount = parseAmount(rawAmount);
    }

    // 음수(취소) 또는 0 스킵
    if (isNaN(amount) || amount <= 0) continue;

    results.push({ date: dateStr, name: merchant, amount });
  }

  return results;
}
