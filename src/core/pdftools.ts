// PDF manipulation on top of pdf-lib: merge, split, rotate, optimize,
// images → PDF and vector signature stamping.

import { PDFDocument, degrees, rgb } from 'pdf-lib';
import type { Notice } from './types.ts';

export class PdfToolError extends Error {
  code: 'encrypted' | 'not_pdf' | 'bad_range' | 'bad_image' | 'empty';
  constructor(code: PdfToolError['code']) {
    super(code);
    this.code = code;
  }
}

async function load(bytes: Uint8Array): Promise<PDFDocument> {
  try {
    return await PDFDocument.load(bytes, { ignoreEncryption: false, updateMetadata: false });
  } catch (e: any) {
    if (/encrypt/i.test(String(e?.message))) throw new PdfToolError('encrypted');
    throw new PdfToolError('not_pdf');
  }
}

export async function pageCount(bytes: Uint8Array): Promise<number> {
  return (await load(bytes)).getPageCount();
}

/** "1-3, 5, 8-" → zero-based page indexes. 1-based in text. Throws bad_range. */
export function parseRanges(spec: string, total: number): number[] {
  const out: number[] = [];
  const parts = spec.split(/[,;\s]+/).filter(Boolean);
  if (!parts.length) throw new PdfToolError('bad_range');
  for (const part of parts) {
    const m = /^(\d*)(?:-(\d*))?$/.exec(part);
    if (!m || (m[1] === '' && (m[2] === undefined || m[2] === ''))) throw new PdfToolError('bad_range');
    const hasDash = part.includes('-');
    const a = m[1] === '' ? 1 : parseInt(m[1], 10);
    const b = hasDash ? (m[2] === '' || m[2] === undefined ? total : parseInt(m[2], 10)) : a;
    if (a < 1 || b < a || b > total) throw new PdfToolError('bad_range');
    for (let i = a; i <= b; i++) out.push(i - 1);
  }
  return out;
}

export async function mergePdfs(inputs: Uint8Array[]): Promise<Uint8Array> {
  if (!inputs.length) throw new PdfToolError('empty');
  const out = await PDFDocument.create();
  for (const bytes of inputs) {
    const src = await load(bytes);
    const pages = await out.copyPages(src, src.getPageIndices());
    pages.forEach((p) => out.addPage(p));
  }
  return out.save();
}

export async function extractPages(bytes: Uint8Array, spec: string): Promise<Uint8Array> {
  const src = await load(bytes);
  const idx = parseRanges(spec, src.getPageCount());
  const out = await PDFDocument.create();
  const pages = await out.copyPages(src, idx);
  pages.forEach((p) => out.addPage(p));
  return out.save();
}

/** One PDF per page. */
export async function splitPages(bytes: Uint8Array): Promise<Uint8Array[]> {
  const src = await load(bytes);
  const res: Uint8Array[] = [];
  for (let i = 0; i < src.getPageCount(); i++) {
    const out = await PDFDocument.create();
    const [p] = await out.copyPages(src, [i]);
    out.addPage(p);
    res.push(await out.save());
  }
  return res;
}

/** Rotate by a multiple of 90 degrees; spec = pages to rotate (empty = all). */
export async function rotatePages(bytes: Uint8Array, angle: number, spec = ''): Promise<Uint8Array> {
  const src = await load(bytes);
  const idx = spec.trim() ? parseRanges(spec, src.getPageCount()) : src.getPageIndices();
  const a = (((Math.round(angle / 90) * 90) % 360) + 360) % 360;
  for (const i of idx) {
    const page = src.getPage(i);
    page.setRotation(degrees((page.getRotation().angle + a) % 360));
  }
  return src.save();
}

export interface OptimizeResult {
  bytes: Uint8Array;
  before: number;
  after: number;
  notices: Notice[];
}

/**
 * Re-saves the file with object streams (drops unreferenced objects and
 * compresses structure). Image data is not recompressed, so gains are
 * honest and sometimes zero: when output is not smaller the original is
 * returned unchanged with a `no_size_gain` notice.
 */
export async function optimizePdf(bytes: Uint8Array): Promise<OptimizeResult> {
  const src = await load(bytes);
  // Copy pages into a fresh document so unreferenced objects are dropped.
  const out = await PDFDocument.create();
  const pages = await out.copyPages(src, src.getPageIndices());
  pages.forEach((p) => out.addPage(p));
  const saved = await out.save({ useObjectStreams: true });
  if (saved.length >= bytes.length) {
    return { bytes, before: bytes.length, after: bytes.length, notices: [{ code: 'no_size_gain' }] };
  }
  return { bytes: saved, before: bytes.length, after: saved.length, notices: [] };
}

function sniffImage(b: Uint8Array): 'png' | 'jpg' | null {
  if (b.length > 8 && b[0] === 0x89 && b[1] === 0x50 && b[2] === 0x4e && b[3] === 0x47) return 'png';
  if (b.length > 3 && b[0] === 0xff && b[1] === 0xd8) return 'jpg';
  return null;
}

/** PNG/JPEG images → one page each, page sized to the image fitted in A4 bounds. */
export async function imagesToPdf(images: Uint8Array[]): Promise<Uint8Array> {
  if (!images.length) throw new PdfToolError('empty');
  const out = await PDFDocument.create();
  for (const img of images) {
    const kind = sniffImage(img);
    if (!kind) throw new PdfToolError('bad_image');
    let emb;
    try {
      emb = kind === 'png' ? await out.embedPng(img) : await out.embedJpg(img);
    } catch {
      throw new PdfToolError('bad_image');
    }
    const maxW = 595.28;
    const maxH = 841.89;
    const scale = Math.min(maxW / emb.width, maxH / emb.height, 1);
    const w = emb.width * scale;
    const h = emb.height * scale;
    const page = out.addPage([Math.max(w, 1), Math.max(h, 1)]);
    page.drawImage(emb, { x: 0, y: 0, width: w, height: h });
  }
  return out.save();
}

export interface SignaturePlacement {
  page: number; // zero-based
  /** Box in page fractions, origin top-left: 0..1 */
  x: number;
  y: number;
  w: number;
  h: number;
}

/** strokes: polylines in a unit box (0..1 both axes, origin top-left). */
export async function stampSignature(
  bytes: Uint8Array,
  strokes: Array<Array<{ x: number; y: number }>>,
  place: SignaturePlacement,
  color = { r: 0.05, g: 0.1, b: 0.45 },
): Promise<Uint8Array> {
  const doc = await load(bytes);
  if (place.page < 0 || place.page >= doc.getPageCount()) throw new PdfToolError('bad_range');
  const page = doc.getPage(place.page);
  const { width, height } = page.getSize();
  const bx = place.x * width;
  const bw = place.w * width;
  const bh = place.h * height;
  const by = height - place.y * height - bh;
  const col = rgb(color.r, color.g, color.b);
  const thickness = Math.max(0.8, Math.min(bw, bh) * 0.02);
  for (const s of strokes) {
    if (s.length === 1) {
      page.drawCircle({ x: bx + s[0].x * bw, y: by + (1 - s[0].y) * bh, size: thickness / 2, color: col });
      continue;
    }
    for (let i = 1; i < s.length; i++) {
      page.drawLine({
        start: { x: bx + s[i - 1].x * bw, y: by + (1 - s[i - 1].y) * bh },
        end: { x: bx + s[i].x * bw, y: by + (1 - s[i].y) * bh },
        thickness,
        color: col,
      });
    }
  }
  return doc.save();
}
