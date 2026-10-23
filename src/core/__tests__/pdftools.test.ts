import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { deflateSync } from 'node:zlib';
import { renderBlocksToPdf } from '../pdfdoc.ts';
import { parseMarkdown } from '../markdown.ts';
import { extractPdf, pdfToPlainText } from '../pdftext.ts';
import { extractPages, imagesToPdf, mergePdfs, optimizePdf, pageCount, parseRanges, PdfToolError, rotatePages, splitPages, stampSignature } from '../pdftools.ts';

const fonts = {
  regular: new Uint8Array(readFileSync('assets/fonts/DejaVuSans.ttf')),
  bold: new Uint8Array(readFileSync('assets/fonts/DejaVuSans-Bold.ttf')),
};
const para = (n: number) => Array.from({ length: n }, (_, i) => `Paragraf ${i + 1} ${"söz ".repeat(120)}`).join('\n\n');
const mk = (md: string) => renderBlocksToPdf(parseMarkdown(md), fonts, { title: 't' });

function png(w: number, h: number): Uint8Array {
  const crcT = Array.from({ length: 256 }, (_, n) => { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; return c >>> 0; });
  const crc = (b: Buffer) => { let c = 0xffffffff; for (const x of b) c = crcT[(c ^ x) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; };
  const chunk = (t: string, d: Buffer) => { const l = Buffer.alloc(4); l.writeUInt32BE(d.length); const td = Buffer.concat([Buffer.from(t), d]); const c = Buffer.alloc(4); c.writeUInt32BE(crc(td)); return Buffer.concat([l, td, c]); };
  const ihdr = Buffer.alloc(13); ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 2;
  const raw = Buffer.alloc((w * 3 + 1) * h, 128);
  for (let y = 0; y < h; y++) raw[y * (w * 3 + 1)] = 0;
  return new Uint8Array(Buffer.concat([Buffer.from([0x89, 0x50, 0x4e, 0x47, 0x0d, 0x0a, 0x1a, 0x0a]), chunk('IHDR', ihdr), chunk('IDAT', deflateSync(raw)), chunk('IEND', Buffer.alloc(0))]));
}

test('parseRanges', () => {
  assert.deepEqual(parseRanges('1-3, 5', 6), [0, 1, 2, 4]);
  assert.deepEqual(parseRanges('4-', 6), [3, 4, 5]);
  for (const bad of ['', '0', '7', '3-2', 'a', '-']) assert.throws(() => parseRanges(bad, 6), (e: any) => e.code === 'bad_range', bad);
});

test('merge, extract, split, rotate', async () => {
  const a = mk(para(40));
  const b = mk('# İkinci belge\n\nçğıöşü');
  const na = await pageCount(a);
  assert.ok(na >= 2);
  const m = await mergePdfs([a, b]);
  assert.equal(await pageCount(m), na + 1);
  const last = await extractPages(m, `${na + 1}`);
  assert.match(pdfToPlainText(await extractPdf(last)), /İkinci belge/);
  assert.equal((await splitPages(m)).length, na + 1);
  const r = await rotatePages(m, 90, '1');
  const { PDFDocument } = await import('pdf-lib');
  const d = await PDFDocument.load(r);
  assert.equal(d.getPage(0).getRotation().angle, 90);
  assert.equal(d.getPage(1).getRotation().angle, 0);
});

test('not a pdf / bad range', async () => {
  await assert.rejects(() => pageCount(new Uint8Array([1, 2, 3])), (e: any) => e instanceof PdfToolError && e.code === 'not_pdf');
  await assert.rejects(() => extractPages(mk('x'), '9'), (e: any) => e.code === 'bad_range');
});

test('optimize reports honest sizes', async () => {
  const r = await optimizePdf(mk(para(4)));
  assert.ok(r.after <= r.before);
  if (r.after === r.before) assert.equal(r.notices[0].code, 'no_size_gain');
});

test('images to pdf and signature stamp', async () => {
  const pdf = await imagesToPdf([png(40, 30), png(20, 50)]);
  assert.equal(await pageCount(pdf), 2);
  await assert.rejects(() => imagesToPdf([new Uint8Array([1, 2, 3, 4, 5, 6, 7, 8, 9])]), (e: any) => e.code === 'bad_image');
  const signed = await stampSignature(mk('Sözleşme'), [[{ x: 0, y: 0.5 }, { x: 0.5, y: 1 }, { x: 1, y: 0 }], [{ x: 0.5, y: 0.5 }]], { page: 0, x: 0.1, y: 0.8, w: 0.3, h: 0.1 });
  assert.match(pdfToPlainText(await extractPdf(signed)), /Sözleşme/);
  await assert.rejects(() => stampSignature(mk('x'), [], { page: 3, x: 0, y: 0, w: 1, h: 1 }), (e: any) => e.code === 'bad_range');
});

test('encrypted pdf is reported, not crashed', async () => {
  const { execFileSync } = await import('node:child_process');
  const { writeFileSync, readFileSync: rf, mkdtempSync } = await import('node:fs');
  const { tmpdir } = await import('node:os');
  const dir = mkdtempSync(tmpdir() + '/enc-');
  writeFileSync(dir + '/a.pdf', mk('gizli'));
  try {
    execFileSync('qpdf', ['--encrypt', 'u', 'o', '256', '--', dir + '/a.pdf', dir + '/b.pdf']);
  } catch {
    return; // qpdf unavailable: skip
  }
  const enc = new Uint8Array(rf(dir + '/b.pdf'));
  await assert.rejects(() => pageCount(enc), (e: any) => e.code === 'encrypted');
  await assert.rejects(() => extractPdf(enc), /encrypted/);
});
