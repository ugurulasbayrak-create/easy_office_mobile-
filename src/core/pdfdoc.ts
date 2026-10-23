// PDF generation from scratch: text layout with an embedded, subsetted Unicode
// TrueType font (so Turkish ğ ş ı İ Ğ Ş Ç Ö Ü render and stay searchable),
// tables, lists, headings, sheets and slides.

import pako from 'pako';
import type { Block, Inline, PdfFonts, Slide } from './types.ts';
import { parseTtf, subsetTtf } from './ttf.ts';
import type { TtfFont } from './ttf.ts';
import { SLIDE_THEMES } from './themes.ts';
import { parseNumber } from './sheet.ts';

// ---------------------------------------------------------------- low level

export interface PageSize {
  width: number;
  height: number;
}
export const A4: PageSize = { width: 595.28, height: 841.89 };
export const A4_LANDSCAPE: PageSize = { width: 841.89, height: 595.28 };
export const SLIDE_PAGE: PageSize = { width: 960, height: 540 };

const num = (n: number): string => String(Math.round(n * 100) / 100);

function rgb(hex: string): string {
  const h = hex.replace('#', '');
  const f = (i: number): number => Math.round((parseInt(h.slice(i, i + 2), 16) / 255) * 1000) / 1000;
  return `${f(0)} ${f(2)} ${f(4)}`;
}

function ascii(s: string): Uint8Array {
  const out = new Uint8Array(s.length);
  for (let i = 0; i < s.length; i++) out[i] = s.charCodeAt(i) & 255;
  return out;
}

function concat(parts: Uint8Array[]): Uint8Array {
  let len = 0;
  for (const p of parts) len += p.length;
  const out = new Uint8Array(len);
  let o = 0;
  for (const p of parts) {
    out.set(p, o);
    o += p.length;
  }
  return out;
}

function hex4(n: number): string {
  return n.toString(16).toUpperCase().padStart(4, '0');
}

function utf16Hex(s: string): string {
  let out = 'FEFF';
  for (let i = 0; i < s.length; i++) out += hex4(s.charCodeAt(i));
  return out;
}

interface FontUse {
  font: TtfFont;
  usage: Map<number, number>; // code point -> glyph id
  tag: string;
  baseName: string;
}

const SKIP = new Set([0x00ad, 0x200b, 0x200c, 0x200d, 0x2060, 0xfeff]);

export class PdfBuilder {
  readonly size: PageSize;
  private title: string;
  private regular: FontUse;
  private bold: FontUse;
  private pages: string[][] = [];
  private cur: string[] | null = null;

  constructor(fonts: PdfFonts, size: PageSize, title = '') {
    this.size = size;
    this.title = title;
    this.regular = { font: parseTtf(fonts.regular), usage: new Map(), tag: 'EOAAAA', baseName: 'EasyOfficeSans' };
    this.bold = { font: parseTtf(fonts.bold), usage: new Map(), tag: 'EOBBBB', baseName: 'EasyOfficeSans-Bold' };
  }

  get pageCount(): number {
    return this.pages.length + (this.cur ? 1 : 0);
  }

  newPage(background?: string): void {
    if (this.cur) this.pages.push(this.cur);
    this.cur = [];
    if (background) this.fillRect(0, 0, this.size.width, this.size.height, background);
  }

  private ops(): string[] {
    if (!this.cur) this.newPage();
    return this.cur!;
  }

  private font(bold: boolean): FontUse {
    return bold ? this.bold : this.regular;
  }

  private glyphFor(f: FontUse, cp: number): number {
    if (cp === 0xa0) cp = 0x20;
    let g = f.font.glyphForCodePoint(cp);
    if (g === 0) g = f.font.glyphForCodePoint(0x3f); // '?'
    return g;
  }

  /** Width of `text` in points. Does not record glyph usage. */
  measure(text: string, size: number, bold = false): number {
    const f = this.font(bold);
    let w = 0;
    for (const ch of text) {
      const cp = ch.codePointAt(0)!;
      if (cp < 0x20 || SKIP.has(cp)) continue;
      w += f.font.advance(this.glyphFor(f, cp));
    }
    return (w * size) / f.font.unitsPerEm;
  }

  text(x: number, y: number, str: string, o: { size: number; bold?: boolean; italic?: boolean; color?: string }): void {
    const f = this.font(!!o.bold);
    let hex = '';
    for (const ch of str) {
      const cp = ch.codePointAt(0)!;
      if (cp < 0x20 || SKIP.has(cp)) continue;
      const g = this.glyphFor(f, cp);
      hex += hex4(g);
      const key = cp === 0xa0 ? 0x20 : cp;
      if (!f.usage.has(key)) f.usage.set(key, g);
    }
    if (hex === '') return;
    const skew = o.italic ? 0.21 : 0;
    this.ops().push(
      `BT ${rgb(o.color ?? '000000')} rg /${o.bold ? 'F2' : 'F1'} ${num(o.size)} Tf 1 0 ${skew} 1 ${num(x)} ${num(y)} Tm <${hex}> Tj ET`,
    );
  }

  fillRect(x: number, y: number, w: number, h: number, color: string): void {
    this.ops().push(`${rgb(color)} rg ${num(x)} ${num(y)} ${num(w)} ${num(h)} re f`);
  }

  strokeRect(x: number, y: number, w: number, h: number, color: string, lineWidth = 0.5): void {
    this.ops().push(`${rgb(color)} RG ${num(lineWidth)} w ${num(x)} ${num(y)} ${num(w)} ${num(h)} re S`);
  }

  line(x1: number, y1: number, x2: number, y2: number, color: string, lineWidth = 0.75): void {
    this.ops().push(`${rgb(color)} RG ${num(lineWidth)} w ${num(x1)} ${num(y1)} m ${num(x2)} ${num(y2)} l S`);
  }

  finish(opts: { pageNumbers?: boolean } = {}): Uint8Array {
    if (this.cur) this.pages.push(this.cur);
    this.cur = null;
    if (this.pages.length === 0) this.pages.push([]);

    if (opts.pageNumbers) {
      const total = this.pages.length;
      for (let i = 0; i < total; i++) {
        this.cur = this.pages[i];
        const label = `${i + 1} / ${total}`;
        const w = this.measure(label, 9);
        this.text((this.size.width - w) / 2, 28, label, { size: 9, color: '9CA3AF' });
      }
      this.cur = null;
    }

    // ---- object table
    const bodies: Uint8Array[] = []; // index = id - 1
    const reserve = (): number => {
      bodies.push(new Uint8Array(0));
      return bodies.length;
    };
    const set = (id: number, body: Uint8Array | string): void => {
      bodies[id - 1] = typeof body === 'string' ? ascii(body) : body;
    };
    const stream = (dict: string, data: Uint8Array, compress = true): Uint8Array => {
      const payload = compress ? pako.deflate(data) : data;
      return concat([
        ascii(`<< ${dict}${compress ? ' /Filter /FlateDecode' : ''} /Length ${payload.length} >>\nstream\n`),
        payload,
        ascii('\nendstream'),
      ]);
    };

    const catalog = reserve();
    const pagesId = reserve();
    const info = reserve();

    // ---- fonts
    const fontRefs: Record<string, number> = {};
    for (const [key, f] of [['F1', this.regular], ['F2', this.bold]] as [string, FontUse][]) {
      if (f.usage.size === 0) continue;
      const subset = subsetTtf(f.font, f.usage);
      const name = `${f.tag}+${f.baseName}`;
      const fileId = reserve();
      set(fileId, stream(`/Length1 ${subset.length}`, subset));
      const descId = reserve();
      const upem = f.font.unitsPerEm;
      const sc = (v: number) => Math.round((v * 1000) / upem);
      set(
        descId,
        `<< /Type /FontDescriptor /FontName /${name} /Flags 4 /FontBBox [${f.font.bbox.map(sc).join(' ')}] /ItalicAngle 0 ` +
          `/Ascent ${sc(f.font.ascent)} /Descent ${sc(f.font.descent)} /CapHeight ${sc(f.font.ascent * 0.72)} /StemV 80 /FontFile2 ${fileId} 0 R >>`,
      );
      const gids = [...new Set(f.usage.values())].sort((a, b) => a - b);
      const w = gids.map((g) => `${g} [${sc(f.font.advance(g))}]`).join(' ');
      const cidId = reserve();
      set(
        cidId,
        `<< /Type /Font /Subtype /CIDFontType2 /BaseFont /${name} /CIDSystemInfo << /Registry (Adobe) /Ordering (Identity) /Supplement 0 >> ` +
          `/FontDescriptor ${descId} 0 R /DW 1000 /W [${w}] /CIDToGIDMap /Identity >>`,
      );
      // ToUnicode: glyph id -> first code point that used it
      const byGid = new Map<number, number>();
      for (const [cp, g] of f.usage) if (!byGid.has(g)) byGid.set(g, cp);
      const pairs = [...byGid.entries()].sort((a, b) => a[0] - b[0]);
      let cmap =
        '/CIDInit /ProcSet findresource begin\n12 dict begin\nbegincmap\n/CIDSystemInfo << /Registry (Adobe) /Ordering (UCS) /Supplement 0 >> def\n' +
        '/CMapName /Adobe-Identity-UCS def\n/CMapType 2 def\n1 begincodespacerange\n<0000> <FFFF>\nendcodespacerange\n';
      for (let i = 0; i < pairs.length; i += 100) {
        const chunk = pairs.slice(i, i + 100);
        cmap += `${chunk.length} beginbfchar\n`;
        for (const [g, cp] of chunk) {
          const u =
            cp > 0xffff
              ? hex4(0xd800 + ((cp - 0x10000) >> 10)) + hex4(0xdc00 + ((cp - 0x10000) & 0x3ff))
              : hex4(cp);
          cmap += `<${hex4(g)}> <${u}>\n`;
        }
        cmap += 'endbfchar\n';
      }
      cmap += 'endcmap\nCMapName currentdict /CMap defineresource pop\nend\nend';
      const tuId = reserve();
      set(tuId, stream('', ascii(cmap)));
      const type0 = reserve();
      set(type0, `<< /Type /Font /Subtype /Type0 /BaseFont /${name} /Encoding /Identity-H /DescendantFonts [${cidId} 0 R] /ToUnicode ${tuId} 0 R >>`);
      fontRefs[key] = type0;
    }
    const fontDict = Object.entries(fontRefs).map(([k, id]) => `/${k} ${id} 0 R`).join(' ');

    // ---- pages
    const pageIds: number[] = [];
    for (const ops of this.pages) {
      const contentId = reserve();
      set(contentId, stream('', ascii(ops.join('\n'))));
      const pageId = reserve();
      set(
        pageId,
        `<< /Type /Page /Parent ${pagesId} 0 R /MediaBox [0 0 ${num(this.size.width)} ${num(this.size.height)}] ` +
          `/Resources << /Font << ${fontDict} >> >> /Contents ${contentId} 0 R >>`,
      );
      pageIds.push(pageId);
    }
    set(pagesId, `<< /Type /Pages /Kids [${pageIds.map((i) => `${i} 0 R`).join(' ')}] /Count ${pageIds.length} >>`);
    set(catalog, `<< /Type /Catalog /Pages ${pagesId} 0 R >>`);
    const d = new Date();
    const p2 = (n: number) => String(n).padStart(2, '0');
    const stamp = `D:${d.getUTCFullYear()}${p2(d.getUTCMonth() + 1)}${p2(d.getUTCDate())}${p2(d.getUTCHours())}${p2(d.getUTCMinutes())}${p2(d.getUTCSeconds())}Z`;
    set(info, `<< /Title <${utf16Hex(this.title)}> /Producer (Easy Office) /Creator (Easy Office) /CreationDate (${stamp}) >>`);

    // ---- serialise
    const parts: Uint8Array[] = [ascii('%PDF-1.7\n%'), Uint8Array.from([0xe2, 0xe3, 0xcf, 0xd3]), ascii('\n')];
    let offset = parts[0].length + 4 + 1;
    const offsets: number[] = [];
    bodies.forEach((body, i) => {
      offsets.push(offset);
      const head = ascii(`${i + 1} 0 obj\n`);
      const tail = ascii('\nendobj\n');
      parts.push(head, body, tail);
      offset += head.length + body.length + tail.length;
    });
    let xref = `xref\n0 ${bodies.length + 1}\n0000000000 65535 f \n`;
    for (const o of offsets) xref += `${String(o).padStart(10, '0')} 00000 n \n`;
    xref += `trailer\n<< /Size ${bodies.length + 1} /Root ${catalog} 0 R /Info ${info} 0 R >>\nstartxref\n${offset}\n%%EOF\n`;
    parts.push(ascii(xref));
    return concat(parts);
  }
}

// ---------------------------------------------------------- text wrapping

interface Atom {
  text: string;
  bold: boolean;
  italic: boolean;
  code: boolean;
  width: number;
  space: boolean;
  br: boolean;
}

function atomize(b: PdfBuilder, runs: Inline[], size: number, forceBold: boolean): Atom[] {
  const atoms: Atom[] = [];
  for (const r of runs) {
    const bold = !!r.bold || forceBold;
    const text = r.text.replace(/\t/g, '    ');
    const lines = text.split(/\r?\n/);
    lines.forEach((line, li) => {
      if (li > 0) atoms.push({ text: '', bold, italic: !!r.italic, code: !!r.code, width: 0, space: false, br: true });
      for (const piece of line.split(/( +)/)) {
        if (piece === '') continue;
        atoms.push({
          text: piece,
          bold,
          italic: !!r.italic,
          code: !!r.code,
          width: b.measure(piece, size, bold),
          space: piece[0] === ' ',
          br: false,
        });
      }
    });
  }
  return atoms;
}

function splitLongAtom(b: PdfBuilder, a: Atom, size: number, maxWidth: number): Atom[] {
  const out: Atom[] = [];
  let cur = '';
  for (const ch of a.text) {
    const next = cur + ch;
    if (cur !== '' && b.measure(next, size, a.bold) > maxWidth) {
      out.push({ ...a, text: cur, width: b.measure(cur, size, a.bold) });
      cur = ch;
    } else cur = next;
  }
  if (cur !== '') out.push({ ...a, text: cur, width: b.measure(cur, size, a.bold) });
  return out;
}

function wrapAtoms(b: PdfBuilder, atoms: Atom[], maxWidth: number, size: number, keepSpaces = false): Atom[][] {
  const lines: Atom[][] = [];
  let line: Atom[] = [];
  let width = 0;
  const flush = () => {
    if (!keepSpaces) while (line.length && line[line.length - 1].space) line.pop();
    lines.push(line);
    line = [];
    width = 0;
  };
  for (const a of atoms) {
    if (a.br) {
      flush();
      continue;
    }
    if (a.space && line.length === 0 && !keepSpaces) continue;
    const pieces = a.width > maxWidth && !a.space ? splitLongAtom(b, a, size, maxWidth) : [a];
    for (const p of pieces) {
      if (width + p.width > maxWidth + 0.01 && line.length > 0) {
        if (p.space) {
          flush();
          continue;
        }
        flush();
      }
      if (p.space && line.length === 0 && !keepSpaces) continue;
      line.push(p);
      width += p.width;
    }
  }
  if (line.length || lines.length === 0) flush();
  return lines;
}

function drawAtoms(b: PdfBuilder, x: number, baseline: number, atoms: Atom[], size: number, color: string): void {
  let cx = x;
  let i = 0;
  while (i < atoms.length) {
    const first = atoms[i];
    let text = first.text;
    let w = first.width;
    let j = i + 1;
    while (j < atoms.length && atoms[j].bold === first.bold && atoms[j].italic === first.italic && atoms[j].code === first.code) {
      text += atoms[j].text;
      w += atoms[j].width;
      j++;
    }
    if (first.code && text.trim() !== '') b.fillRect(cx - 1, baseline - size * 0.25, w + 2, size * 1.15, 'EEF1F5');
    b.text(cx, baseline, text, { size, bold: first.bold, italic: first.italic, color });
    cx += w;
    i = j;
  }
}

// ----------------------------------------------------------- document layout

const BODY = 11;
const LINE = 1.4;
const INK = '111827';
const HEADING_COLOR = '1E293B';
const HEADING_SIZES = [22, 18, 15, 13, 12, 11];

class DocLayout {
  b: PdfBuilder;
  size: PageSize;
  m: { l: number; r: number; t: number; bt: number };
  y = 0;

  constructor(fonts: PdfFonts, size: PageSize, margin: { l: number; r: number; t: number; b: number }, title: string) {
    this.b = new PdfBuilder(fonts, size, title);
    this.size = size;
    this.m = { l: margin.l, r: margin.r, t: margin.t, bt: margin.b };
    this.newPage();
  }
  get width(): number {
    return this.size.width - this.m.l - this.m.r;
  }
  newPage(): void {
    this.b.newPage();
    this.y = this.size.height - this.m.t;
  }
  ensure(h: number): void {
    if (this.y - h < this.m.bt) this.newPage();
  }
  atTop(): boolean {
    return this.y >= this.size.height - this.m.t - 0.5;
  }

  paragraph(runs: Inline[], size: number, o: { x?: number; width?: number; bold?: boolean; color?: string; gap?: number; keepSpaces?: boolean; background?: string } = {}): void {
    const x = o.x ?? this.m.l;
    const width = o.width ?? this.width;
    const atoms = atomize(this.b, runs, size, !!o.bold);
    const lines = wrapAtoms(this.b, atoms, width, size, o.keepSpaces);
    const lh = size * LINE;
    for (const line of lines) {
      this.ensure(lh);
      if (o.background) this.b.fillRect(this.m.l, this.y - lh, this.width, lh, o.background);
      drawAtoms(this.b, x, this.y - size * 1.0, line, size, o.color ?? INK);
      this.y -= lh;
    }
    this.y -= o.gap ?? 0;
  }

  block(blk: Block): void {
    switch (blk.type) {
      case 'heading': {
        const size = HEADING_SIZES[blk.level - 1];
        if (!this.atTop()) this.y -= size * 0.6;
        this.ensure(size * LINE * 3);
        this.paragraph(blk.runs, size, { bold: true, color: HEADING_COLOR, gap: size * 0.25 });
        break;
      }
      case 'paragraph':
        this.paragraph(blk.runs, BODY, { gap: 6 });
        break;
      case 'list': {
        const indent = 22;
        blk.items.forEach((item, i) => {
          const marker = blk.ordered ? `${i + 1}.` : '•';
          this.ensure(BODY * LINE);
          this.b.text(this.m.l + 6, this.y - BODY, marker, { size: BODY, color: INK });
          this.paragraph(item, BODY, { x: this.m.l + indent, width: this.width - indent, gap: 2 });
        });
        this.y -= 4;
        break;
      }
      case 'table':
        this.table(blk.rows, blk.header);
        this.y -= 8;
        break;
      case 'code':
        for (const line of blk.text.split('\n')) {
          this.paragraph([{ text: line === '' ? ' ' : line }], 9.5, { keepSpaces: true, background: 'F3F4F6' });
        }
        this.y -= 6;
        break;
      case 'hr':
        this.ensure(12);
        this.b.line(this.m.l, this.y - 6, this.m.l + this.width, this.y - 6, 'CBD5E1');
        this.y -= 14;
        break;
    }
  }

  table(rows: Inline[][][], header: boolean): void {
    if (!rows.length) return;
    const cols = Math.max(...rows.map((r) => r.length));
    const size = 10;
    const pad = 4;
    // proportional column widths based on content length
    const weights = Array.from({ length: cols }, (_, c) => {
      let max = 3;
      for (const r of rows) max = Math.max(max, (r[c] ?? []).map((x) => x.text).join('').length);
      return Math.min(max, 40);
    });
    const sum = weights.reduce((a, b) => a + b, 0);
    const widths = weights.map((w) => (w / sum) * this.width);

    const drawRow = (row: Inline[][], isHead: boolean): void => {
      const cellLines = widths.map((w, c) => wrapAtoms(this.b, atomize(this.b, row[c] ?? [], size, isHead), w - 2 * pad, size));
      const lh = size * 1.3;
      const h = Math.max(...cellLines.map((l) => l.length)) * lh + 2 * pad;
      if (this.y - h < this.m.bt) {
        this.newPage();
        if (header && !isHead) drawRow(rows[0], true);
      }
      let x = this.m.l;
      cellLines.forEach((lines, c) => {
        if (isHead) this.b.fillRect(x, this.y - h, widths[c], h, 'E2E8F0');
        this.b.strokeRect(x, this.y - h, widths[c], h, 'CBD5E1');
        lines.forEach((line, li) => drawAtoms(this.b, x + pad, this.y - pad - size - li * lh + 1, line, size, INK));
        x += widths[c];
      });
      this.y -= h;
    };
    rows.forEach((row, i) => drawRow(row, header && i === 0));
  }
}

export function renderBlocksToPdf(
  blocks: Block[],
  fonts: PdfFonts,
  opts: { title?: string; size?: PageSize } = {},
): Uint8Array {
  const doc = new DocLayout(fonts, opts.size ?? A4, { l: 56, r: 56, t: 64, b: 64 }, opts.title ?? '');
  for (const blk of blocks) doc.block(blk);
  return doc.b.finish({ pageNumbers: true });
}

// ------------------------------------------------------------------- sheets

export interface PdfSheet {
  name: string;
  rows: string[][];
}

export function renderSheetsToPdf(sheets: PdfSheet[], fonts: PdfFonts, opts: { title?: string } = {}): Uint8Array {
  const doc = new DocLayout(fonts, A4_LANDSCAPE, { l: 36, r: 36, t: 44, b: 44 }, opts.title ?? '');
  const size = 9;
  const pad = 4;
  const lh = size * 1.3;
  const b = doc.b;
  let first = true;

  for (const sheet of sheets) {
    const rows = sheet.rows;
    if (!first) doc.newPage();
    first = false;
    const cols = Math.max(0, ...rows.map((r) => r.length));
    if (cols === 0) {
      doc.paragraph([{ text: sheet.name }], 14, { bold: true, color: HEADING_COLOR, gap: 8 });
      continue;
    }
    const headerIsText = rows.length > 1 && rows[0].every((c) => c === '' || parseNumber(c) === null);

    // natural column widths
    const maxCell = doc.width * 0.45;
    const widths: number[] = [];
    for (let c = 0; c < cols; c++) {
      let w = 0;
      rows.forEach((r, ri) => {
        const t = r[c] ?? '';
        if (t) w = Math.max(w, b.measure(t.length > 80 ? t.slice(0, 80) : t, size, headerIsText && ri === 0));
      });
      widths.push(Math.max(28, Math.min(maxCell, w + 2 * pad + 2)));
    }

    // greedy column chunks; the first column repeats on later chunks
    const chunks: number[][] = [];
    let cur: number[] = [];
    let used = 0;
    for (let c = 0; c < cols; c++) {
      const extra = chunks.length > 0 && cur.length === 0 ? widths[0] : 0;
      if (cur.length > 0 && used + widths[c] + extra > doc.width) {
        chunks.push(cur);
        cur = [];
        used = 0;
      }
      if (chunks.length > 0 && cur.length === 0 && c !== 0) {
        cur.push(0);
        used += widths[0];
      }
      cur.push(c);
      used += widths[c];
    }
    if (cur.length) chunks.push(cur);

    chunks.forEach((chunk, ci) => {
      if (ci > 0) doc.newPage();
      doc.paragraph([{ text: ci === 0 ? sheet.name : `${sheet.name} (${ci + 1}/${chunks.length})` }], 13, { bold: true, color: HEADING_COLOR, gap: 6 });
      const drawRow = (ri: number): void => {
        const isHead = headerIsText && ri === 0;
        const lines = chunk.map((c) => {
          const text = rows[ri][c] ?? '';
          const numeric = !isHead && text !== '' && parseNumber(text) !== null;
          return { numeric, lines: wrapAtoms(b, atomize(b, [{ text }], size, isHead), widths[c] - 2 * pad, size) };
        });
        const h = Math.max(...lines.map((l) => l.lines.length)) * lh + 2 * pad - 2;
        if (doc.y - h < doc.m.bt) {
          doc.newPage();
          if (headerIsText && ri !== 0) drawRow(0);
        }
        let x = doc.m.l;
        lines.forEach((cell, k) => {
          const w = widths[chunk[k]];
          if (isHead) b.fillRect(x, doc.y - h, w, h, 'E2E8F0');
          b.strokeRect(x, doc.y - h, w, h, 'CBD5E1');
          cell.lines.forEach((line, li) => {
            const textW = line.reduce((s, a) => s + a.width, 0);
            const tx = cell.numeric ? x + w - pad - textW : x + pad;
            drawAtoms(b, tx, doc.y - pad - size - li * lh + 1, line, size, INK);
          });
          x += w;
        });
        doc.y -= h;
      };
      for (let ri = 0; ri < rows.length; ri++) drawRow(ri);
    });
  }
  return b.finish({ pageNumbers: true });
}

// ------------------------------------------------------------------- slides

export function renderSlidesToPdf(slides: Slide[], fonts: PdfFonts, opts: { title?: string } = {}): Uint8Array {
  const b = new PdfBuilder(fonts, SLIDE_PAGE, opts.title ?? '');
  const list: Slide[] = slides.length ? slides : [{ title: '', subtitle: '', bullets: [], theme: 'dark' }];
  const M = 52;
  const W = SLIDE_PAGE.width - 2 * M;
  const H = SLIDE_PAGE.height;

  for (const s of list) {
    const c = SLIDE_THEMES[s.theme] ?? SLIDE_THEMES.dark;
    b.newPage(c.bg);
    const hasBody = s.bullets.length > 0;
    const titleSize = hasBody ? (s.title.length > 50 ? 28 : 34) : s.title.length > 40 ? 38 : 46;
    const titleLines = wrapAtoms(b, atomize(b, [{ text: s.title }], titleSize, true), W, titleSize);
    const tlh = titleSize * 1.2;

    if (!hasBody) {
      let y = H / 2 + titleLines.length * tlh * 0.5 + 10;
      titleLines.forEach((line) => {
        drawAtoms(b, M, y - titleSize, line, titleSize, c.title);
        y -= tlh;
      });
      b.fillRect(M, y - 12, 80, 3, c.subtitle);
      y -= 8;
      if (s.subtitle.trim()) {
        const sub = wrapAtoms(b, atomize(b, [{ text: s.subtitle }], 20, false), W, 20);
        let sy = y - 30;
        sub.forEach((line) => {
          drawAtoms(b, M, sy - 16, line, 20, c.subtitle);
          sy -= 26;
        });
      }
      continue;
    }

    let y = H - 44;
    titleLines.forEach((line) => {
      drawAtoms(b, M, y - titleSize, line, titleSize, c.title);
      y -= tlh;
    });
    b.fillRect(M, y - 10, 80, 3, c.subtitle);
    y -= 28;
    if (s.subtitle.trim()) {
      const sub = wrapAtoms(b, atomize(b, [{ text: s.subtitle }], 17, false), W, 17);
      sub.forEach((line) => {
        drawAtoms(b, M, y - 14, line, 17, c.subtitle);
        y -= 22;
      });
      y -= 8;
    }
    // largest bullet size that fits the remaining height
    const avail = y - 36;
    let size = 22;
    let laid: Atom[][][] = [];
    for (; size >= 11; size -= 1) {
      laid = s.bullets.map((t) => wrapAtoms(b, atomize(b, [{ text: t }], size, false), W - 24, size));
      const h = laid.reduce((acc, ls) => acc + ls.length * size * 1.3 + size * 0.45, 0);
      if (h <= avail) break;
    }
    laid.forEach((ls) => {
      b.text(M + 4, y - size, '•', { size, color: c.subtitle });
      ls.forEach((line) => {
        drawAtoms(b, M + 24, y - size, line, size, c.body);
        y -= size * 1.3;
      });
      y -= size * 0.45;
    });
  }
  return b.finish();
}
