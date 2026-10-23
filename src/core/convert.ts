// Conversion orchestrator. Pure: bytes in, files + notices out.
// Everything the engine cannot preserve is reported as a Notice code,
// never silently dropped and never invented.

import type { Block, Notice, OutputFile, PdfFonts, Slide } from './types.ts';
import { MIME } from './types.ts';
import { baseName, decodeText, extOf, utf8Encode } from './text.ts';
import { parseCsv, toCsv } from './csv.ts';
import { blocksToMarkdown, blocksToPlainText, parseMarkdown, plainTextToBlocks } from './markdown.ts';
import { displayGrid, readXlsx, writeXlsx } from './xlsx.ts';
import { readDocx, writeDocx } from './docx.ts';
import { readPptx, writePptx } from './pptx.ts';
import { gridToMatrix, matrixToGrid } from './sheet.ts';
import { renderBlocksToPdf, renderSheetsToPdf, renderSlidesToPdf } from './pdfdoc.ts';
import { extractPdf, hasText, pdfToBlocks, pdfToRows } from './pdftext.ts';
import { imagesToPdf } from './pdftools.ts';
import { themeByIndex } from './themes.ts';

export type Target = 'pdf' | 'docx' | 'xlsx' | 'pptx' | 'csv' | 'txt' | 'md';

export class ConvertError extends Error {
  code: 'unsupported' | 'encrypted' | 'not_pdf' | 'no_text_found' | 'corrupt' | 'bad_image';
  constructor(code: ConvertError['code']) {
    super(code);
    this.code = code;
  }
}

export interface ConvertResult {
  files: OutputFile[];
  notices: Notice[];
}

export interface Input {
  name: string;
  bytes: Uint8Array;
}

const IMAGE_EXT = ['png', 'jpg', 'jpeg'];

/** Which targets make sense for an input extension. */
export function targetsFor(ext: string): Target[] {
  switch (ext.toLowerCase()) {
    case 'docx': return ['pdf', 'txt', 'md'];
    case 'md': return ['docx', 'pdf', 'txt'];
    case 'txt': return ['docx', 'pdf', 'md'];
    case 'xlsx': return ['pdf', 'csv'];
    case 'csv': return ['xlsx', 'pdf'];
    case 'pptx': return ['pdf'];
    case 'pdf': return ['docx', 'txt', 'md', 'xlsx', 'pptx'];
    case 'png': case 'jpg': case 'jpeg': return ['pdf'];
    default: return [];
  }
}

function out(name: string, target: Target, bytes: Uint8Array): OutputFile {
  return { name: baseName(name) + '.' + target, mime: MIME[target], bytes };
}

function dedupe(n: Notice[]): Notice[] {
  const seen = new Set<string>();
  return n.filter((x) => {
    const k = x.code + ':' + (x.n ?? '');
    if (seen.has(k)) return false;
    seen.add(k);
    return true;
  });
}

function slidesFromBlocks(blocks: Block[]): Slide[] {
  const slides: Slide[] = [];
  let cur: Slide | null = null;
  const text = (runs: { text: string }[]) => runs.map((r) => r.text).join('');
  for (const b of blocks) {
    if (b.type === 'heading') {
      cur = { title: text(b.runs), subtitle: '', bullets: [], theme: themeByIndex(slides.length) };
      slides.push(cur);
      continue;
    }
    if (!cur) {
      cur = { title: '', subtitle: '', bullets: [], theme: themeByIndex(0) };
      slides.push(cur);
    }
    if (b.type === 'paragraph') cur.bullets.push(text(b.runs));
    else if (b.type === 'list') for (const it of b.items) cur.bullets.push(text(it));
    else if (b.type === 'code') cur.bullets.push(b.text);
  }
  return slides;
}

export async function convert(input: Input, target: Target, fonts: PdfFonts): Promise<ConvertResult> {
  const ext = extOf(input.name).toLowerCase();
  if (!targetsFor(ext).includes(target)) throw new ConvertError('unsupported');
  const title = baseName(input.name);
  const notices: Notice[] = [];

  try {
    // ------------------------------------------------ text-like sources
    if (ext === 'md' || ext === 'txt') {
      const src = decodeText(input.bytes);
      const blocks = ext === 'md' ? parseMarkdown(src) : plainTextToBlocks(src);
      if (target === 'docx') return { files: [out(input.name, 'docx', await writeDocx(blocks, { title }))], notices };
      if (target === 'pdf') return { files: [out(input.name, 'pdf', renderBlocksToPdf(blocks, fonts, { title }))], notices };
      if (target === 'txt') return { files: [out(input.name, 'txt', utf8Encode(blocksToPlainText(blocks)))], notices };
      return { files: [out(input.name, 'md', utf8Encode(blocksToMarkdown(blocks)))], notices };
    }

    if (ext === 'docx') {
      const r = await readDocx(input.bytes);
      notices.push(...r.notices);
      if (target === 'pdf') return { files: [out(input.name, 'pdf', renderBlocksToPdf(r.blocks, fonts, { title }))], notices: dedupe(notices) };
      if (target === 'txt') return { files: [out(input.name, 'txt', utf8Encode(blocksToPlainText(r.blocks)))], notices: dedupe(notices) };
      return { files: [out(input.name, 'md', utf8Encode(blocksToMarkdown(r.blocks)))], notices: dedupe(notices) };
    }

    // ------------------------------------------------ spreadsheets
    if (ext === 'csv') {
      const rows = parseCsv(decodeText(input.bytes));
      if (target === 'xlsx') {
        const bytes = await writeXlsx([{ name: title || 'Sheet1', grid: matrixToGrid(rows) }], { headerBold: true });
        return { files: [out(input.name, 'xlsx', bytes)], notices };
      }
      return { files: [out(input.name, 'pdf', renderSheetsToPdf([{ name: title, rows }], fonts, { title }))], notices };
    }

    if (ext === 'xlsx') {
      const r = await readXlsx(input.bytes);
      notices.push(...r.notices);
      if (!r.sheets.length) throw new ConvertError('corrupt');
      const mats = r.sheets.map((s) => ({ name: s.name, rows: gridToMatrix(displayGrid(s)) }));
      if (r.sheets.some((s) => Object.values(s.grid).some((v) => v.startsWith('=')))) notices.push({ code: 'formulas_as_values' });
      if (target === 'csv') {
        if (mats.length > 1) notices.push({ code: 'only_first_sheet', n: mats.length });
        return { files: [out(input.name, 'csv', utf8Encode(toCsv(mats[0].rows)))], notices: dedupe(notices) };
      }
      return { files: [out(input.name, 'pdf', renderSheetsToPdf(mats, fonts, { title }))], notices: dedupe(notices) };
    }

    // ------------------------------------------------ slides
    if (ext === 'pptx') {
      const r = await readPptx(input.bytes);
      notices.push(...r.notices);
      return { files: [out(input.name, 'pdf', renderSlidesToPdf(r.slides, fonts, { title }))], notices: dedupe(notices) };
    }

    // ------------------------------------------------ images
    if (IMAGE_EXT.includes(ext)) {
      try {
        return { files: [out(input.name, 'pdf', await imagesToPdf([input.bytes]))], notices };
      } catch {
        throw new ConvertError('bad_image');
      }
    }

    // ------------------------------------------------ pdf sources
    if (ext === 'pdf') {
      const ex = await extractPdf(input.bytes);
      if (!hasText(ex)) throw new ConvertError('no_text_found');
      notices.push({ code: 'layout_not_preserved' });
      if (target === 'xlsx') {
        const rows = pdfToRows(ex);
        const bytes = await writeXlsx([{ name: title || 'Sheet1', grid: matrixToGrid(rows) }], { headerBold: false });
        return { files: [out(input.name, 'xlsx', bytes)], notices };
      }
      const blocks = pdfToBlocks(ex);
      if (target === 'docx') return { files: [out(input.name, 'docx', await writeDocx(blocks, { title }))], notices };
      if (target === 'txt') return { files: [out(input.name, 'txt', utf8Encode(blocksToPlainText(blocks)))], notices };
      if (target === 'md') return { files: [out(input.name, 'md', utf8Encode(blocksToMarkdown(blocks)))], notices };
      // pptx: one slide per heading; falls back to one slide per page
      let slides = slidesFromBlocks(blocks);
      if (!slides.length) slides = [{ title, subtitle: '', bullets: [], theme: 'dark' }];
      notices.push({ code: 'text_only' });
      return { files: [out(input.name, 'pptx', await writePptx(slides, { title }))], notices };
    }
  } catch (e: any) {
    if (e instanceof ConvertError) throw e;
    const m = String(e?.message ?? '');
    if (m === 'encrypted') throw new ConvertError('encrypted');
    if (m === 'not_pdf') throw new ConvertError('not_pdf');
    throw new ConvertError('corrupt');
  }
  throw new ConvertError('unsupported');
}
