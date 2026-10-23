// Spreadsheet addressing helpers shared by the formula engine, CSV and XLSX code.

import type { Grid } from './types.ts';

/** 0 -> "A", 25 -> "Z", 26 -> "AA" */
export function colName(index: number): string {
  let n = index;
  let s = '';
  do {
    s = String.fromCharCode(65 + (n % 26)) + s;
    n = Math.floor(n / 26) - 1;
  } while (n >= 0);
  return s;
}

/** "A" -> 0, "AA" -> 26 */
export function colIndex(name: string): number {
  let n = 0;
  const up = name.toUpperCase();
  for (let i = 0; i < up.length; i++) n = n * 26 + (up.charCodeAt(i) - 64);
  return n - 1;
}

export interface CellPos {
  col: number; // zero-based
  row: number; // zero-based
}

const REF_RE = /^\$?([A-Za-z]{1,3})\$?([0-9]+)$/;

export function parseRef(ref: string): CellPos | null {
  const m = REF_RE.exec(ref);
  if (!m) return null;
  const row = parseInt(m[2], 10) - 1;
  if (row < 0) return null;
  return { col: colIndex(m[1]), row };
}

export function refOf(col: number, row: number): string {
  return colName(col) + (row + 1);
}

/** Number of rows/columns that contain data (size of the bounding box from A1). */
export function gridBounds(grid: Grid): { rows: number; cols: number } {
  let rows = 0;
  let cols = 0;
  for (const key of Object.keys(grid)) {
    if (grid[key] === '' || grid[key] === undefined) continue;
    const p = parseRef(key);
    if (!p) continue;
    if (p.row + 1 > rows) rows = p.row + 1;
    if (p.col + 1 > cols) cols = p.col + 1;
  }
  return { rows, cols };
}

export function matrixToGrid(matrix: string[][]): Grid {
  const grid: Grid = {};
  for (let r = 0; r < matrix.length; r++) {
    const row = matrix[r];
    for (let c = 0; c < row.length; c++) {
      if (row[c] !== '' && row[c] !== undefined) grid[refOf(c, r)] = row[c];
    }
  }
  return grid;
}

export function gridToMatrix(grid: Grid, rows?: number, cols?: number): string[][] {
  const b = gridBounds(grid);
  const R = rows ?? b.rows;
  const C = cols ?? b.cols;
  const out: string[][] = [];
  for (let r = 0; r < R; r++) {
    const row: string[] = [];
    for (let c = 0; c < C; c++) row.push(grid[refOf(c, r)] ?? '');
    out.push(row);
  }
  return out;
}

/**
 * Parse a typed number. Accepted forms:
 *   12   12.5   -3   1e3   (plain, dot decimal)
 *   12,5   99,90          (comma decimal with 1-2 digits)
 *   1.234,56  1.234.567   (Turkish/German thousands with dots)
 *   1,234  1,234,567.89   (US thousands with commas)
 * Anything else returns null.
 */
export function parseNumber(raw: string): number | null {
  const s = raw.trim();
  if (s === '') return null;
  // Identifiers that merely look numeric stay text: leading zeros (007, 0532...) and
  // digit strings too long for a double to hold exactly (card numbers, long IDs).
  if (/^[+-]?0\d+$/.test(s) || /^[+-]?\d{16,}$/.test(s)) return null;
  if (/^[+-]?(\d+\.?\d*|\.\d+)([eE][+-]?\d+)?$/.test(s)) return Number(s);
  if (/^[+-]?\d+,\d{1,2}$/.test(s)) return Number(s.replace(',', '.'));
  if (/^[+-]?\d{1,3}(\.\d{3})+(,\d+)?$/.test(s)) return Number(s.replace(/\./g, '').replace(',', '.'));
  if (/^[+-]?\d{1,3}(,\d{3})+(\.\d+)?$/.test(s)) return Number(s.replace(/,/g, ''));
  return null;
}

export function formatNumber(n: number): string {
  if (Number.isInteger(n) && Math.abs(n) < 1e15) return String(n);
  const r = Number(n.toPrecision(12));
  const s = String(r);
  if (!/e/i.test(s)) return s;
  // avoid exponent notation for ordinary magnitudes
  if (Math.abs(r) >= 1e-6 && Math.abs(r) < 1e21) return r.toFixed(Math.max(0, 12 - Math.floor(Math.log10(Math.abs(r))) - 1)).replace(/\.?0+$/, '');
  return s;
}
