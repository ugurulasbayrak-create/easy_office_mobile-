// Text extraction from PDFs (via pdf.js) with line, paragraph, heading and
// table-ish structure recovery. Scanned PDFs (images only) yield no text.

import type { Block, Inline } from './types.ts';

export interface PdfCell {
  x: number;
  w: number;
  text: string;
}
export interface PdfLine {
  y: number;
  size: number;
  cells: PdfCell[];
}
export interface PdfPageText {
  lines: PdfLine[];
}
export interface PdfExtract {
  pages: PdfPageText[];
}

interface Item {
  str: string;
  x: number;
  y: number;
  w: number;
  size: number;
}

export async function extractPdf(bytes: Uint8Array): Promise<PdfExtract> {
  // The legacy build runs on Hermes/Node without a DOM; loaded lazily because it is large.
  const pdfjs: any = await import('pdfjs-dist/legacy/build/pdf.mjs');
  let doc: any;
  try {
    doc = await pdfjs.getDocument({
      data: new Uint8Array(bytes),
      useSystemFonts: false,
      disableFontFace: true,
      isEvalSupported: false,
      verbosity: 0,
    }).promise;
  } catch (e: any) {
    if (e && (e.name === 'PasswordException' || /password/i.test(String(e.message)))) throw new Error('encrypted');
    throw new Error('not_pdf');
  }
  const pages: PdfPageText[] = [];
  try {
    for (let p = 1; p <= doc.numPages; p++) {
      const page = await doc.getPage(p);
      const content = await page.getTextContent();
      const items: Item[] = [];
      for (const it of content.items as any[]) {
        if (typeof it.str !== 'string' || !it.transform) continue;
        const size = Math.hypot(it.transform[0], it.transform[1]) || it.height || 10;
        items.push({ str: it.str, x: it.transform[4], y: it.transform[5], w: it.width ?? 0, size });
      }
      pages.push({ lines: buildLines(items) });
      page.cleanup?.();
    }
  } finally {
    await doc.destroy?.();
  }
  return { pages };
}

export function buildLines(items: Item[]): PdfLine[] {
  const live = items.filter((i) => i.str !== '' && Number.isFinite(i.x) && Number.isFinite(i.y));
  live.sort((a, b) => b.y - a.y || a.x - b.x);
  const rows: Item[][] = [];
  for (const it of live) {
    const row = rows[rows.length - 1];
    if (row && Math.abs(row[0].y - it.y) <= Math.max(2, 0.45 * Math.min(row[0].size, it.size))) row.push(it);
    else rows.push([it]);
  }
  const lines: PdfLine[] = [];
  for (const row of rows) {
    row.sort((a, b) => a.x - b.x);
    const cells: PdfCell[] = [];
    let cur: PdfCell | null = null;
    let prevEnd = 0;
    for (const it of row) {
      if (it.str.trim() === '') continue; // spacing items: the gap to the next word decides
      const gap = it.x - prevEnd;
      if (!cur || gap > Math.max(it.size * 0.6, 4)) {
        cur = { x: it.x, w: it.w, text: it.str };
        cells.push(cur);
      } else {
        if (gap > it.size * 0.12 && !cur.text.endsWith(' ') && !it.str.startsWith(' ')) cur.text += ' ';
        cur.text += it.str;
        cur.w = it.x + it.w - cur.x;
      }
      prevEnd = it.x + it.w;
    }
    for (const c of cells) c.text = c.text.replace(/\s+/g, ' ').trim();
    const kept = cells.filter((c) => c.text !== '');
    if (kept.length) lines.push({ y: row[0].y, size: Math.max(...row.map((r) => r.size)), cells: kept });
  }
  return lines;
}

export function lineText(line: PdfLine): string {
  return line.cells.map((c) => c.text).join(' ');
}

export function hasText(ex: PdfExtract): boolean {
  return ex.pages.some((p) => p.lines.length > 0);
}

function median(nums: number[]): number {
  if (!nums.length) return 0;
  const s = [...nums].sort((a, b) => a - b);
  return s[Math.floor(s.length / 2)];
}

const BULLET = /^([•▪●◦‣·\-–—*]|\d{1,2}[.)])\s+/;

/** Rebuild paragraphs, headings and lists from positioned lines. */
export function pdfToBlocks(ex: PdfExtract): Block[] {
  const blocks: Block[] = [];
  // body font size: the most common size, weighted by amount of text
  const weights = new Map<number, number>();
  for (const p of ex.pages) {
    for (const l of p.lines) {
      const k = Math.round(l.size * 2) / 2;
      weights.set(k, (weights.get(k) ?? 0) + lineText(l).length);
    }
  }
  let body = 11;
  let best = -1;
  for (const [k, w] of weights) if (w > best) { best = w; body = k; }

  for (const page of ex.pages) {
    const lines = page.lines;
    const gaps: number[] = [];
    for (let i = 1; i < lines.length; i++) {
      const g = lines[i - 1].y - lines[i].y;
      if (g > 0) gaps.push(g);
    }
    const typical = median(gaps) || body * 1.2;

    let para: string[] = [];
    let listItems: Inline[][] = [];
    let listOrdered = false;
    const flushPara = () => {
      if (!para.length) return;
      let text = '';
      for (const l of para) {
        if (!text) text = l;
        else if (/[A-Za-zÇĞİÖŞÜçğıöşü]-$/.test(text) && /^[a-zçğıöşü]/.test(l)) text = text.slice(0, -1) + l;
        else text += ' ' + l;
      }
      blocks.push({ type: 'paragraph', runs: [{ text }] });
      para = [];
    };
    const flushList = () => {
      if (listItems.length) blocks.push({ type: 'list', ordered: listOrdered, items: listItems });
      listItems = [];
    };

    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const text = lineText(line);
      const prev = lines[i - 1];
      const gap = prev ? prev.y - line.y : 0;
      const bigGap = prev ? gap > typical * 1.55 : false;

      const ratio = line.size / body;
      if (ratio >= 1.25 && text.length <= 120) {
        flushPara();
        flushList();
        const level = ratio >= 1.8 ? 1 : ratio >= 1.4 ? 2 : 3;
        const last = blocks[blocks.length - 1];
        // merge multi-line headings of equal size
        if (last && last.type === 'heading' && last.level === level && !bigGap) last.runs[0].text += ' ' + text;
        else blocks.push({ type: 'heading', level: level as 1 | 2 | 3, runs: [{ text }] });
        continue;
      }
      const m = BULLET.exec(text);
      if (m) {
        flushPara();
        const ordered = /\d/.test(m[1]);
        if (listItems.length && ordered !== listOrdered) flushList();
        listOrdered = ordered;
        listItems.push([{ text: text.slice(m[0].length) }]);
        continue;
      }
      if (listItems.length && !bigGap && line.cells[0].x > (lines[i - 1]?.cells[0].x ?? 0) - 1 && /^[a-zçğıöşü]/.test(text)) {
        // wrapped continuation of the previous list item
        const last = listItems[listItems.length - 1];
        last[0].text += ' ' + text;
        continue;
      }
      flushList();
      if (bigGap) flushPara();
      para.push(text);
    }
    flushPara();
    flushList();
  }
  return blocks;
}

/** Plain text, paragraphs separated by blank lines. */
export function pdfToPlainText(ex: PdfExtract): string {
  return pdfToBlocks(ex)
    .map((b) => {
      if (b.type === 'list') return b.items.map((it, i) => (b.ordered ? `${i + 1}. ` : '- ') + it.map((r) => r.text).join('')).join('\n');
      if (b.type === 'heading' || b.type === 'paragraph') return b.runs.map((r) => r.text).join('');
      return '';
    })
    .filter((t) => t !== '')
    .join('\n\n');
}

/**
 * Table-ish rows: cells are aligned to column positions found across lines.
 * Lines with a single cell land in the first column.
 */
export function pdfToRows(ex: PdfExtract): string[][] {
  const rows: string[][] = [];
  for (const page of ex.pages) {
    const lines = page.lines;
    if (!lines.length) continue;
    const size = median(lines.map((l) => l.size)) || 10;
    const tol = size * 0.6;

    // columns from multi-cell lines
    let cols: number[] = [];
    for (const l of lines) {
      if (l.cells.length < 2) continue;
      for (const c of l.cells) {
        const near = cols.findIndex((x) => Math.abs(x - c.x) <= tol);
        if (near < 0) cols.push(c.x);
      }
    }
    cols.sort((a, b) => a - b);
    const colOf = (x: number): number => {
      let best = 0;
      let bestD = Infinity;
      cols.forEach((cx, i) => {
        const d = Math.abs(cx - x);
        if (d < bestD) {
          bestD = d;
          best = i;
        }
      });
      return best;
    };
    // merge neighbouring columns that never share a row (right-aligned number jitter)
    let merged = true;
    while (merged && cols.length > 1) {
      merged = false;
      for (let i = 0; i < cols.length - 1; i++) {
        if (cols[i + 1] - cols[i] > size * 4) continue;
        const clash = lines.some((l) => {
          const idx = new Set(l.cells.map((c) => colOf(c.x)));
          return idx.has(i) && idx.has(i + 1);
        });
        if (!clash) {
          cols = [...cols.slice(0, i), cols[i], ...cols.slice(i + 2)];
          merged = true;
          break;
        }
      }
    }

    for (const l of lines) {
      if (l.cells.length === 1 || cols.length === 0) {
        rows.push([lineText(l)]);
        continue;
      }
      const row: string[] = Array.from({ length: cols.length }, () => '');
      for (const c of l.cells) {
        const k = colOf(c.x);
        row[k] = row[k] ? row[k] + ' ' + c.text : c.text;
      }
      while (row.length > 1 && row[row.length - 1] === '') row.pop();
      rows.push(row);
    }
  }
  return rows;
}
