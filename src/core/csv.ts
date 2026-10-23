// RFC 4180 style CSV reader/writer with delimiter detection.

export type Delimiter = ',' | ';' | '\t' | '|';
const CANDIDATES: Delimiter[] = [',', ';', '\t', '|'];

/** Guess the delimiter by counting unquoted candidates in the first lines. */
export function detectDelimiter(text: string): Delimiter {
  const sample = text.slice(0, 8000);
  const counts: Record<string, number> = { ',': 0, ';': 0, '\t': 0, '|': 0 };
  let inQuotes = false;
  let lines = 0;
  for (let i = 0; i < sample.length && lines < 12; i++) {
    const c = sample[i];
    if (c === '"') inQuotes = !inQuotes;
    else if (!inQuotes) {
      if (c === '\n') lines++;
      else if (c in counts) counts[c]++;
    }
  }
  let best: Delimiter = ',';
  let bestCount = 0;
  for (const d of CANDIDATES) {
    if (counts[d] > bestCount) {
      best = d;
      bestCount = counts[d];
    }
  }
  return best;
}

export function parseCsv(input: string, delimiter?: Delimiter): string[][] {
  const text = input.charCodeAt(0) === 0xfeff ? input.slice(1) : input;
  const d = delimiter ?? detectDelimiter(text);
  const rows: string[][] = [];
  let row: string[] = [];
  let field = '';
  let inQuotes = false;
  let fieldWasQuoted = false;
  const n = text.length;

  const endField = () => {
    row.push(field);
    field = '';
    fieldWasQuoted = false;
  };
  const endRow = () => {
    endField();
    rows.push(row);
    row = [];
  };

  for (let i = 0; i < n; i++) {
    const c = text[i];
    if (inQuotes) {
      if (c === '"') {
        if (text[i + 1] === '"') {
          field += '"';
          i++;
        } else inQuotes = false;
      } else field += c;
      continue;
    }
    if (c === '"' && field === '' && !fieldWasQuoted) {
      inQuotes = true;
      fieldWasQuoted = true;
    } else if (c === d) endField();
    else if (c === '\r') {
      if (text[i + 1] === '\n') i++;
      endRow();
    } else if (c === '\n') endRow();
    else field += c;
  }
  if (field !== '' || row.length > 0 || fieldWasQuoted) endRow();

  // drop trailing completely-empty rows
  while (rows.length && rows[rows.length - 1].every((x) => x === '')) rows.pop();
  return rows;
}

function quoteField(value: string, d: Delimiter): string {
  if (value === '') return '';
  if (value.includes('"') || value.includes(d) || value.includes('\n') || value.includes('\r') || /^\s|\s$/.test(value)) {
    return '"' + value.replace(/"/g, '""') + '"';
  }
  return value;
}

export function toCsv(rows: string[][], delimiter: Delimiter = ','): string {
  return rows.map((r) => r.map((f) => quoteField(f, delimiter)).join(delimiter)).join('\r\n') + (rows.length ? '\r\n' : '');
}
