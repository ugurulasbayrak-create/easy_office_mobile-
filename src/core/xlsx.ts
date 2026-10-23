// Real XLSX reading and writing on top of JSZip (no other dependencies).

import JSZip from 'jszip';
import type { Grid, Notice } from './types.ts';
import { parseRef, refOf } from './sheet.ts';
import { displayValue, evaluateGrid, formulaIsSupported, isErr, isFormula, normalizeFormula, shiftFormula } from './formula.ts';
import type { Value } from './formula.ts';
import { attr, child, childrenNamed, descendants, elements, escapeXml, parseXml, textContent } from './xml.ts';
import type { XmlNode } from './xml.ts';

const MAX_ROWS = 5000;
const MAX_COLS = 100;
const MAX_SHEET_XML = 25 * 1024 * 1024;

// ------------------------------------------------------------------- write

export interface XlsxSheetIn {
  name: string;
  grid: Grid;
}

function safeSheetName(name: string, taken: Set<string>, index: number): string {
  let n = name.replace(/[\[\]:*?/\\]/g, ' ').trim().slice(0, 31);
  if (n === '') n = 'Sheet' + (index + 1);
  let candidate = n;
  let k = 2;
  while (taken.has(candidate.toLowerCase())) {
    const suffix = ' (' + k++ + ')';
    candidate = n.slice(0, 31 - suffix.length) + suffix;
  }
  taken.add(candidate.toLowerCase());
  return candidate;
}

function sheetXml(grid: Grid, sst: Map<string, number>, sstList: string[], headerBold: boolean): string {
  const values = evaluateGrid(grid);
  const cells: { row: number; col: number; ref: string }[] = [];
  for (const key of Object.keys(grid)) {
    if (grid[key] === '' || grid[key] === undefined) continue;
    const p = parseRef(key);
    if (p) cells.push({ row: p.row, col: p.col, ref: key });
  }
  cells.sort((a, b) => a.row - b.row || a.col - b.col);

  // header detection: first row is all non-numeric text
  const firstRow = cells.filter((c) => c.row === 0);
  const boldHeader =
    headerBold &&
    firstRow.length > 0 &&
    firstRow.every((c) => {
      const v = values[c.ref];
      return typeof v === 'string' && !isFormula(grid[c.ref]);
    });

  const widths: number[] = [];
  let maxCol = -1;
  let maxRow = -1;
  const rowsXml: string[] = [];
  let i = 0;
  while (i < cells.length) {
    const row = cells[i].row;
    const cs: string[] = [];
    while (i < cells.length && cells[i].row === row) {
      const { col, ref } = cells[i];
      const raw = grid[ref];
      const v: Value = values[ref] ?? null;
      const s = boldHeader && row === 0 ? ' s="1"' : '';
      const shown = displayValue(v);
      widths[col] = Math.max(widths[col] ?? 0, Math.min(60, shown.length));
      if (col > maxCol) maxCol = col;
      if (row > maxRow) maxRow = row;
      if (isFormula(raw)) {
        const f = escapeXml(normalizeFormula(raw.slice(1)));
        if (isErr(v)) cs.push(`<c r="${ref}"${s} t="e"><f>${f}</f><v>${escapeXml(v.err)}</v></c>`);
        else if (typeof v === 'number') cs.push(`<c r="${ref}"${s}><f>${f}</f><v>${v}</v></c>`);
        else if (typeof v === 'boolean') cs.push(`<c r="${ref}"${s} t="b"><f>${f}</f><v>${v ? 1 : 0}</v></c>`);
        else if (typeof v === 'string') cs.push(`<c r="${ref}"${s} t="str"><f>${f}</f><v>${escapeXml(v)}</v></c>`);
        else cs.push(`<c r="${ref}"${s}><f>${f}</f></c>`);
      } else if (typeof v === 'number') {
        cs.push(`<c r="${ref}"${s}><v>${v}</v></c>`);
      } else if (typeof v === 'boolean') {
        cs.push(`<c r="${ref}"${s} t="b"><v>${v ? 1 : 0}</v></c>`);
      } else {
        const text = typeof v === 'string' ? v : raw;
        let idx = sst.get(text);
        if (idx === undefined) {
          idx = sstList.length;
          sstList.push(text);
          sst.set(text, idx);
        }
        cs.push(`<c r="${ref}"${s} t="s"><v>${idx}</v></c>`);
      }
      i++;
    }
    rowsXml.push(`<row r="${row + 1}">${cs.join('')}</row>`);
  }

  const dim = maxRow >= 0 ? `<dimension ref="A1:${refOf(maxCol, maxRow)}"/>` : '<dimension ref="A1"/>';
  const cols = widths.length
    ? '<cols>' +
      widths
        .map((w, c) => (w === undefined ? '' : `<col min="${c + 1}" max="${c + 1}" width="${Math.max(8, Math.round(w * 1.15 + 2))}" customWidth="1"/>`))
        .join('') +
      '</cols>'
    : '';
  const view = boldHeader
    ? '<sheetViews><sheetView workbookViewId="0"><pane ySplit="1" topLeftCell="A2" activePane="bottomLeft" state="frozen"/><selection pane="bottomLeft" activeCell="A2" sqref="A2"/></sheetView></sheetViews>'
    : '<sheetViews><sheetView workbookViewId="0"/></sheetViews>';
  return (
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
    dim + view + '<sheetFormatPr defaultRowHeight="15"/>' + cols +
    `<sheetData>${rowsXml.join('')}</sheetData></worksheet>`
  );
}

const STYLES_XML =
  '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
  '<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">' +
  '<fonts count="2"><font><sz val="11"/><name val="Calibri"/><family val="2"/></font>' +
  '<font><b/><sz val="11"/><name val="Calibri"/><family val="2"/></font></fonts>' +
  '<fills count="3"><fill><patternFill patternType="none"/></fill><fill><patternFill patternType="gray125"/></fill>' +
  '<fill><patternFill patternType="solid"><fgColor rgb="FFE8EEF7"/><bgColor indexed="64"/></patternFill></fill></fills>' +
  '<borders count="1"><border><left/><right/><top/><bottom/><diagonal/></border></borders>' +
  '<cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>' +
  '<cellXfs count="2"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/>' +
  '<xf numFmtId="0" fontId="1" fillId="2" borderId="0" xfId="0" applyFont="1" applyFill="1"/></cellXfs>' +
  '<cellStyles count="1"><cellStyle name="Normal" xfId="0" builtinId="0"/></cellStyles></styleSheet>';

export async function writeXlsx(sheets: XlsxSheetIn[], opts: { headerBold?: boolean } = {}): Promise<Uint8Array> {
  const list = sheets.length ? sheets : [{ name: 'Sheet1', grid: {} }];
  const zip = new JSZip();
  const taken = new Set<string>();
  const names = list.map((s, i) => safeSheetName(s.name, taken, i));
  const sst = new Map<string, number>();
  const sstList: string[] = [];

  const sheetParts = list.map((s) => sheetXml(s.grid, sst, sstList, opts.headerBold ?? true));

  zip.file(
    '[Content_Types].xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
      '<Default Extension="xml" ContentType="application/xml"/>' +
      '<Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>' +
      list.map((_, i) => `<Override PartName="/xl/worksheets/sheet${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>`).join('') +
      '<Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>' +
      '<Override PartName="/xl/sharedStrings.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sharedStrings+xml"/>' +
      '</Types>',
  );
  zip.file(
    '_rels/.rels',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>' +
      '</Relationships>',
  );
  zip.file(
    'xl/workbook.xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">' +
      '<bookViews><workbookView/></bookViews><sheets>' +
      names.map((n, i) => `<sheet name="${escapeXml(n)}" sheetId="${i + 1}" r:id="rId${i + 1}"/>`).join('') +
      '</sheets><calcPr calcId="191029" fullCalcOnLoad="1"/></workbook>',
  );
  zip.file(
    'xl/_rels/workbook.xml.rels',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
      list.map((_, i) => `<Relationship Id="rId${i + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet${i + 1}.xml"/>`).join('') +
      `<Relationship Id="rId${list.length + 1}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>` +
      `<Relationship Id="rId${list.length + 2}" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/sharedStrings" Target="sharedStrings.xml"/>` +
      '</Relationships>',
  );
  zip.file('xl/styles.xml', STYLES_XML);
  sheetParts.forEach((xml, i) => zip.file(`xl/worksheets/sheet${i + 1}.xml`, xml));
  zip.file(
    'xl/sharedStrings.xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      `<sst xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" count="${sstList.length}" uniqueCount="${sstList.length}">` +
      sstList.map((s) => `<si><t xml:space="preserve">${escapeXml(s)}</t></si>`).join('') +
      '</sst>',
  );
  return zip.generateAsync({ type: 'uint8array', compression: 'DEFLATE' });
}

// -------------------------------------------------------------------- read

export interface XlsxSheetOut {
  name: string;
  /** Editable cell inputs. Supported formulas stay formulas; others become their cached value. */
  grid: Grid;
  /** Cached display values stored in the file (only for formula cells). */
  cached: Grid;
  truncated: boolean;
}

export interface XlsxReadResult {
  sheets: XlsxSheetOut[];
  notices: Notice[];
}

function siText(si: XmlNode): string {
  let out = '';
  for (const c of elements(si)) {
    if (c.name === 't') out += textContent(c);
    else if (c.name === 'r') {
      const t = child(c, 't');
      if (t) out += textContent(t);
    }
  }
  return out;
}

const BUILTIN_DATE_IDS = new Set([14, 15, 16, 17, 18, 19, 20, 21, 22, 45, 46, 47]);

function isDateFormat(code: string): boolean {
  const stripped = code.replace(/"[^"]*"/g, '').replace(/\[[^\]]*\]/g, '').replace(/\\./g, '');
  if (/general|^@$/i.test(stripped.trim())) return false;
  return /[dmyhs]/i.test(stripped) && !/^[#0.,%\s$€₺()-]*$/.test(stripped);
}

function serialToText(serial: number): string {
  const ms = Math.round(serial * 86400) * 1000;
  const d = new Date(Date.UTC(1899, 11, 30) + ms);
  const p2 = (n: number) => String(n).padStart(2, '0');
  const date = `${d.getUTCFullYear()}-${p2(d.getUTCMonth() + 1)}-${p2(d.getUTCDate())}`;
  const time = `${p2(d.getUTCHours())}:${p2(d.getUTCMinutes())}` + (d.getUTCSeconds() ? ':' + p2(d.getUTCSeconds()) : '');
  if (serial < 1) return time;
  return Number.isInteger(serial) ? date : `${date} ${time}`;
}

function cleanNumber(v: string): string {
  const n = Number(v);
  if (!Number.isFinite(n)) return v;
  return String(Number(n.toPrecision(15)));
}

async function textOf(zip: JSZip, path: string): Promise<string | null> {
  const f = zip.file(path);
  return f ? f.async('string') : null;
}

function resolveTarget(base: string, target: string): string {
  if (target.startsWith('/')) return target.slice(1);
  const parts = (base + target).split('/');
  const out: string[] = [];
  for (const p of parts) {
    if (p === '..') out.pop();
    else if (p !== '.' && p !== '') out.push(p);
  }
  return out.join('/');
}

export async function readXlsx(bytes: Uint8Array): Promise<XlsxReadResult> {
  const zip = await JSZip.loadAsync(bytes);
  const wbXml = await textOf(zip, 'xl/workbook.xml');
  if (!wbXml) throw new Error('not_xlsx');
  const wb = parseXml(wbXml);
  const relsXml = await textOf(zip, 'xl/_rels/workbook.xml.rels');
  const rels: Record<string, string> = {};
  if (relsXml) {
    for (const r of descendants(parseXml(relsXml), 'Relationship')) {
      const id = attr(r, 'Id');
      const target = attr(r, 'Target');
      if (id && target) rels[id] = resolveTarget('xl/', target);
    }
  }

  const sstXml = await textOf(zip, 'xl/sharedStrings.xml');
  const sst: string[] = sstXml ? descendants(parseXml(sstXml), 'si').map(siText) : [];

  // number formats -> which cell styles are dates
  const dateXf = new Set<number>();
  const stylesXml = await textOf(zip, 'xl/styles.xml');
  if (stylesXml) {
    const styles = parseXml(stylesXml);
    const custom: Record<string, string> = {};
    for (const nf of descendants(styles, 'numFmt')) {
      const id = attr(nf, 'numFmtId');
      const code = attr(nf, 'formatCode');
      if (id && code) custom[id] = code;
    }
    const cellXfs = descendants(styles, 'cellXfs')[0];
    if (cellXfs) {
      childrenNamed(cellXfs, 'xf').forEach((xf, idx) => {
        const id = attr(xf, 'numFmtId') ?? '0';
        if (BUILTIN_DATE_IDS.has(Number(id)) || (custom[id] && isDateFormat(custom[id]))) dateXf.add(idx);
      });
    }
  }

  const notices: Notice[] = [];
  const sheets: XlsxSheetOut[] = [];
  let formulasAsValues = 0;
  let anyTruncated = false;

  const sheetNodes = descendants(wb, 'sheet');
  const visible = sheetNodes.filter((s) => attr(s, 'state') !== 'hidden' && attr(s, 'state') !== 'veryHidden');
  for (const sn of visible.length ? visible : sheetNodes) {
    const rid = attr(sn, 'r:id');
    const path = rid ? rels[rid] : undefined;
    const name = attr(sn, 'name') ?? 'Sheet' + (sheets.length + 1);
    const xml = path ? await textOf(zip, path) : null;
    if (!xml) continue;
    if (xml.length > MAX_SHEET_XML) throw new Error('too_large');

    const root = parseXml(xml);
    const grid: Grid = {};
    const cached: Grid = {};
    const sharedMasters = new Map<string, { text: string; col: number; row: number }>();
    let truncated = false;

    for (const c of descendants(root, 'c')) {
      const ref = attr(c, 'r');
      if (!ref) continue;
      const pos = parseRef(ref);
      if (!pos) continue;
      if (pos.row >= MAX_ROWS || pos.col >= MAX_COLS) {
        truncated = true;
        continue;
      }
      const t = attr(c, 't');
      const style = Number(attr(c, 's') ?? '0');
      const vNode = child(c, 'v');
      const vText = vNode ? textContent(vNode) : '';
      let display = '';
      if (t === 's') display = sst[parseInt(vText, 10)] ?? '';
      else if (t === 'inlineStr') {
        const is = child(c, 'is');
        display = is ? siText(is) : '';
      } else if (t === 'str' || t === 'e' || t === 'd') display = vText;
      else if (t === 'b') display = vText === '1' ? 'TRUE' : 'FALSE';
      else if (vText !== '') {
        const num = Number(vText);
        display = dateXf.has(style) && Number.isFinite(num) ? serialToText(num) : cleanNumber(vText);
      }

      const fNode = child(c, 'f');
      if (fNode) {
        let ftext = textContent(fNode).trim();
        const ft = attr(fNode, 't');
        const si = attr(fNode, 'si');
        if (ft === 'shared' && si !== undefined) {
          if (ftext !== '') sharedMasters.set(si, { text: ftext, col: pos.col, row: pos.row });
          else {
            const m = sharedMasters.get(si);
            if (m) ftext = shiftFormula(m.text, pos.row - m.row, pos.col - m.col);
          }
        }
        if (ftext !== '') {
          const normalized = normalizeFormula(ftext);
          cached[ref] = display;
          if (formulaIsSupported(normalized)) grid[ref] = '=' + normalized;
          else {
            formulasAsValues++;
            if (display !== '') grid[ref] = display;
          }
          continue;
        }
      }
      if (display !== '') grid[ref] = display;
    }
    if (truncated) anyTruncated = true;
    sheets.push({ name, grid, cached, truncated });
  }
  if (formulasAsValues) notices.push({ code: 'formulas_as_values', n: formulasAsValues });
  if (anyTruncated) notices.push({ code: 'sheet_truncated' });
  return { sheets, notices };
}

/** Display text for every cell of a sheet: cached value if present, else evaluated. */
export function displayGrid(sheet: { grid: Grid; cached?: Grid }): Grid {
  const values = evaluateGrid(sheet.grid);
  const out: Grid = {};
  for (const key of Object.keys(sheet.grid)) {
    const raw = sheet.grid[key];
    if (raw === '') continue;
    if (isFormula(raw)) {
      const c = sheet.cached?.[key];
      const evaluated = displayValue(values[key] ?? null);
      // prefer our own evaluation; fall back to the file's cache when ours errors out
      out[key] = isErr(values[key]) && c !== undefined && c !== '' ? c : evaluated;
    } else {
      out[key] = raw;
    }
  }
  return out;
}

