// KB국민카드 이용대금명세서 파서
// 파일 형식: 실제 xlsx (binary)
// 컬럼 구조 (0-indexed, xlsx 라이브러리 기준):
//   [0] 이용일자 (YY.MM.DD)
//   [3] 이용하신 가맹점
//   [5] 이용금액 (number, 음수 = 할인/취소)

import * as XLSX from 'xlsx';
import type { ParsedTransaction } from './shinhan.parser';

// YY.MM.DD 패턴
const DATE_PATTERN = /^\d{2}\.\d{2}\.\d{2}$/;

function normalizeText(value: unknown): string {
  return String(value ?? '')
    .replace(/\xa0/g, ' ') // non-breaking space 치환
    .trim();
}

export function parseKbXlsx(fileBuffer: Buffer): ParsedTransaction[] {
  const workbook = XLSX.read(fileBuffer, { type: 'buffer' });
  const sheetName = workbook.SheetNames[0];
  if (!sheetName) {
    throw new Error('파일 형식이 올바르지 않습니다. KB국민카드 이용대금명세서 파일인지 확인해주세요.');
  }

  const sheet = workbook.Sheets[sheetName];
  const rows: unknown[][] = XLSX.utils.sheet_to_json(sheet, { header: 1, defval: null });

  const results: ParsedTransaction[] = [];

  for (const row of rows) {
    const dateRaw = normalizeText(row[0]);

    // 날짜 형식(YY.MM.DD)이 아닌 행 스킵 (헤더, 소계, 합계 등)
    if (!DATE_PATTERN.test(dateRaw)) continue;

    const amountVal = row[5];
    // 숫자가 아니거나 0 이하인 행 스킵 (할인/취소)
    if (typeof amountVal !== 'number' || amountVal <= 0) continue;

    const name = normalizeText(row[3]);
    if (!name) continue;

    // YY.MM.DD → YYYY-MM-DD
    const [yy, mm, dd] = dateRaw.split('.');
    const date = `20${yy}-${mm}-${dd}`;

    results.push({ date, name, amount: amountVal });
  }

  if (results.length === 0 && rows.length > 3) {
    throw new Error('파일 형식이 올바르지 않습니다. KB국민카드 이용대금명세서 파일인지 확인해주세요.');
  }

  return results;
}
