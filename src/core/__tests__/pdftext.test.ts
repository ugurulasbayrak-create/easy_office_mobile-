import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { renderBlocksToPdf, renderSheetsToPdf } from '../pdfdoc.ts';
import { parseMarkdown } from '../markdown.ts';
import { extractPdf, hasText, pdfToBlocks, pdfToPlainText, pdfToRows } from '../pdftext.ts';

const fonts = {
  regular: new Uint8Array(readFileSync('assets/fonts/DejaVuSans.ttf')),
  bold: new Uint8Array(readFileSync('assets/fonts/DejaVuSans-Bold.ttf')),
};

test('PDF round trip keeps Turkish text, headings and lists', async () => {
  const md = '# Çalışma Planı\n\nİstanbul\'da ğüşıöç harfleri okunur.\n\n- birinci madde\n- ikinci madde\n\nSon paragraf.';
  const ex = await extractPdf(renderBlocksToPdf(parseMarkdown(md), fonts, { title: 'T' }));
  assert.ok(hasText(ex));
  const blocks = pdfToBlocks(ex);
  assert.equal(blocks[0].type, 'heading');
  const text = pdfToPlainText(ex);
  assert.match(text, /Çalışma Planı/);
  assert.match(text, /İstanbul'da ğüşıöç/);
  assert.ok(blocks.some((b) => b.type === 'list' && b.items.length === 2));
});

test('sheet PDF yields aligned rows', async () => {
  const rows = [['Ürün', 'Satış'], ['Çay', '1500'], ['Kahve', '2500']];
  const ex = await extractPdf(renderSheetsToPdf([{ name: 'R', rows }], fonts));
  const out = pdfToRows(ex);
  const found = out.filter((r) => r.length >= 2);
  assert.ok(found.some((r) => r[0] === 'Çay' && r[1] === '1500'), JSON.stringify(out));
});

test('garbage is not a pdf', async () => {
  await assert.rejects(() => extractPdf(new Uint8Array([1, 2, 3])), /not_pdf/);
});
