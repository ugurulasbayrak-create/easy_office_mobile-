// A compact Markdown dialect <-> Block model.
// Supported: # headings, paragraphs, - / * / 1. lists (nesting is flattened),
// | tables |, fenced code, --- rules, **bold**, *italic*, `code`, [links](url).
// This is the storage format of Easy Docs and the bridge to DOCX/PDF.

import type { Block, Inline } from './types.ts';

// ------------------------------------------------------------------ inline

export function parseInline(src: string): Inline[] {
  const out: Inline[] = [];
  let bold = false;
  let italic = false;
  let buf = '';
  const flush = () => {
    if (buf === '') return;
    const last = out[out.length - 1];
    if (last && !!last.bold === bold && !!last.italic === italic && !last.code) last.text += buf;
    else out.push({ text: buf, ...(bold ? { bold: true } : {}), ...(italic ? { italic: true } : {}) });
    buf = '';
  };
  let i = 0;
  const n = src.length;
  while (i < n) {
    const c = src[i];
    if (c === '\\' && i + 1 < n && '\\`*_[]()#>-|!'.includes(src[i + 1])) {
      buf += src[i + 1];
      i += 2;
      continue;
    }
    if (c === '`') {
      const end = src.indexOf('`', i + 1);
      if (end > i) {
        flush();
        out.push({ text: src.slice(i + 1, end), code: true });
        i = end + 1;
        continue;
      }
    }
    if (c === '[') {
      const m = /^\[([^\]]*)\]\(([^)]*)\)/.exec(src.slice(i));
      if (m) {
        const inner = parseInline(m[1]);
        flush();
        for (const r of inner) out.push({ ...r, ...(bold ? { bold: true } : {}), ...(italic ? { italic: true } : {}) });
        i += m[0].length;
        continue;
      }
    }
    if ((c === '*' || c === '_') && src[i + 1] === c) {
      // ** or __ : bold toggle. '__' inside words is left alone.
      const prev = i > 0 ? src[i - 1] : ' ';
      const next = src[i + 2] ?? ' ';
      const canOpen = !bold && next !== ' ' && (c === '*' || !/\w/.test(prev));
      const canClose = bold && prev !== ' ' && (c === '*' || !/\w/.test(next));
      if (canOpen || canClose) {
        flush();
        bold = !bold;
        i += 2;
        continue;
      }
    }
    if (c === '*' || c === '_') {
      const prev = i > 0 ? src[i - 1] : ' ';
      const next = src[i + 1] ?? ' ';
      const canOpen = !italic && next !== ' ' && (c === '*' || !/\w/.test(prev));
      const canClose = italic && prev !== ' ' && (c === '*' || !/\w/.test(next));
      if (canOpen || canClose) {
        // only open when a matching closer exists later on
        if (canClose || src.indexOf(c, i + 1) > i) {
          flush();
          italic = !italic;
          i += 1;
          continue;
        }
      }
    }
    buf += c;
    i++;
  }
  flush();
  return out;
}

export function inlineToPlain(runs: Inline[]): string {
  return runs.map((r) => r.text).join('');
}

function inlineToMarkdown(runs: Inline[]): string {
  return runs
    .map((r) => {
      let t = r.text.replace(/([\\`*_[\]])/g, '\\$1');
      if (r.code) return '`' + r.text + '`';
      if (t.trim() === '') return t;
      const lead = /^\s*/.exec(t)![0];
      const trail = /\s*$/.exec(t)![0];
      let core = t.slice(lead.length, t.length - trail.length);
      if (r.bold && r.italic) core = '***' + core + '***';
      else if (r.bold) core = '**' + core + '**';
      else if (r.italic) core = '*' + core + '*';
      t = lead + core + trail;
      return t;
    })
    .join('');
}

// ------------------------------------------------------------------- blocks

const HEADING = /^(#{1,6})\s+(.*?)\s*#*\s*$/;
const HR = /^\s{0,3}([-*_])(\s*\1){2,}\s*$/;
const LIST_ITEM = /^(\s*)([-*+•]|\d+[.)])\s+(.*)$/;
const TABLE_SEP = /^\s*\|?\s*:?-{2,}:?\s*(\|\s*:?-{2,}:?\s*)*\|?\s*$/;

function splitRow(line: string): string[] {
  let s = line.trim();
  if (s.startsWith('|')) s = s.slice(1);
  if (s.endsWith('|') && !s.endsWith('\\|')) s = s.slice(0, -1);
  const cells: string[] = [];
  let cur = '';
  for (let i = 0; i < s.length; i++) {
    if (s[i] === '\\' && s[i + 1] === '|') {
      cur += '|';
      i++;
    } else if (s[i] === '|') {
      cells.push(cur.trim());
      cur = '';
    } else cur += s[i];
  }
  cells.push(cur.trim());
  return cells;
}

export function parseMarkdown(md: string): Block[] {
  const lines = md.replace(/\r\n?/g, '\n').split('\n');
  const blocks: Block[] = [];
  let para: string[] = [];
  const flushPara = () => {
    if (para.length) {
      blocks.push({ type: 'paragraph', runs: parseInline(para.join(' ')) });
      para = [];
    }
  };

  let i = 0;
  while (i < lines.length) {
    const line = lines[i];
    if (line.trim() === '') {
      flushPara();
      i++;
      continue;
    }
    if (/^\s*```/.test(line)) {
      flushPara();
      const code: string[] = [];
      i++;
      while (i < lines.length && !/^\s*```/.test(lines[i])) code.push(lines[i++]);
      i++; // closing fence
      blocks.push({ type: 'code', text: code.join('\n') });
      continue;
    }
    const h = HEADING.exec(line);
    if (h) {
      flushPara();
      blocks.push({ type: 'heading', level: h[1].length as 1 | 2 | 3 | 4 | 5 | 6, runs: parseInline(h[2]) });
      i++;
      continue;
    }
    if (HR.test(line) && !LIST_ITEM.test(line)) {
      flushPara();
      blocks.push({ type: 'hr' });
      i++;
      continue;
    }
    if (line.includes('|') && i + 1 < lines.length && TABLE_SEP.test(lines[i + 1]) && lines[i + 1].includes('-')) {
      flushPara();
      const rows: Inline[][][] = [splitRow(line).map(parseInline)];
      i += 2;
      while (i < lines.length && lines[i].trim() !== '' && lines[i].includes('|')) {
        rows.push(splitRow(lines[i]).map(parseInline));
        i++;
      }
      const width = Math.max(...rows.map((r) => r.length));
      for (const r of rows) while (r.length < width) r.push([]);
      blocks.push({ type: 'table', rows, header: true });
      continue;
    }
    const li = LIST_ITEM.exec(line);
    if (li) {
      flushPara();
      const ordered = /\d/.test(li[2]);
      const items: Inline[][] = [];
      while (i < lines.length) {
        const m = LIST_ITEM.exec(lines[i]);
        if (!m || /\d/.test(m[2]) !== ordered) break;
        let text = m[3];
        i++;
        // continuation lines (indented, not a new item)
        while (i < lines.length && lines[i].trim() !== '' && /^\s{2,}\S/.test(lines[i]) && !LIST_ITEM.test(lines[i])) {
          text += ' ' + lines[i].trim();
          i++;
        }
        items.push(parseInline(text));
      }
      blocks.push({ type: 'list', ordered, items });
      continue;
    }
    // blockquote: keep as paragraph text without the marker
    para.push(line.replace(/^\s*>\s?/, '').trim());
    i++;
  }
  flushPara();
  return blocks;
}

export function blocksToMarkdown(blocks: Block[]): string {
  const parts: string[] = [];
  for (const b of blocks) {
    switch (b.type) {
      case 'heading':
        parts.push('#'.repeat(b.level) + ' ' + inlineToMarkdown(b.runs));
        break;
      case 'paragraph':
        parts.push(inlineToMarkdown(b.runs));
        break;
      case 'list':
        parts.push(b.items.map((it, idx) => (b.ordered ? `${idx + 1}. ` : '- ') + inlineToMarkdown(it)).join('\n'));
        break;
      case 'table': {
        const esc = (cell: Inline[]) => inlineToMarkdown(cell).replace(/\|/g, '\\|').replace(/\n/g, ' ');
        const rows = b.rows.map((r) => '| ' + r.map(esc).join(' | ') + ' |');
        const width = b.rows[0]?.length ?? 1;
        const sep = '| ' + Array.from({ length: width }, () => '---').join(' | ') + ' |';
        parts.push([rows[0], sep, ...rows.slice(1)].join('\n'));
        break;
      }
      case 'code':
        parts.push('```\n' + b.text + '\n```');
        break;
      case 'hr':
        parts.push('---');
        break;
    }
  }
  return parts.join('\n\n') + (parts.length ? '\n' : '');
}

export function blocksToPlainText(blocks: Block[]): string {
  const parts: string[] = [];
  for (const b of blocks) {
    switch (b.type) {
      case 'heading':
      case 'paragraph':
        parts.push(inlineToPlain(b.runs));
        break;
      case 'list':
        parts.push(b.items.map((it, idx) => (b.ordered ? `${idx + 1}. ` : '- ') + inlineToPlain(it)).join('\n'));
        break;
      case 'table':
        parts.push(b.rows.map((r) => r.map(inlineToPlain).join('\t')).join('\n'));
        break;
      case 'code':
        parts.push(b.text);
        break;
      case 'hr':
        parts.push('----------');
        break;
    }
  }
  return parts.join('\n\n') + (parts.length ? '\n' : '');
}

/** Plain text (as produced by .txt files / PDF extraction) -> blocks. Blank line = new paragraph. */
export function plainTextToBlocks(text: string): Block[] {
  const blocks: Block[] = [];
  const chunks = text.replace(/\r\n?/g, '\n').split(/\n{2,}/);
  for (const chunk of chunks) {
    const t = chunk.trim();
    if (t === '') continue;
    const lines = t.split('\n').map((l) => l.trim());
    blocks.push({ type: 'paragraph', runs: [{ text: lines.join(' ') }] });
  }
  return blocks;
}

export function countWords(md: string): number {
  const m = md.match(/[\p{L}\p{N}][\p{L}\p{N}'’-]*/gu);
  return m ? m.length : 0;
}
