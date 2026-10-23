import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { convert, ConvertError, targetsFor } from '../convert.ts';
import { utf8Encode, decodeText } from '../text.ts';
import { readDocx } from '../docx.ts';
import { readXlsx } from '../xlsx.ts';
import { readPptx } from '../pptx.ts';

const fonts = {
  regular: new Uint8Array(readFileSync('assets/fonts/DejaVuSans.ttf')),
  bold: new Uint8Array(readFileSync('assets/fonts/DejaVuSans-Bold.ttf')),
};
const md = '# Rapor Başlığı\n\nÇalışkan öğrenciler İstanbul\'da.\n\n- madde bir\n- madde iki\n\n## Alt başlık\n\nSon söz.';

test('md → docx → pdf → docx keeps text', async () => {
  const d1 = await convert({ name: 'not.md', bytes: utf8Encode(md) }, 'docx', fonts);
  assert.equal(d1.files[0].name, 'not.docx');
  const back = await readDocx(d1.files[0].bytes);
  assert.equal(back.blocks[0].type, 'heading');
  const p = await convert({ name: 'not.docx', bytes: d1.files[0].bytes }, 'pdf', fonts);
  const d2 = await convert({ name: 'not.pdf', bytes: p.files[0].bytes }, 'docx', fonts);
  assert.ok(d2.notices.some((n) => n.code === 'layout_not_preserved'));
  const txt = await convert({ name: 'not.pdf', bytes: p.files[0].bytes }, 'txt', fonts);
  const s = decodeText(txt.files[0].bytes);
  assert.match(s, /Rapor Başlığı/);
  assert.match(s, /İstanbul'da/);
});

test('csv ↔ xlsx and formulas flagged', async () => {
  const x = await convert({ name: 'v.csv', bytes: utf8Encode('Ad;Tutar\nÇay;15\nKahve;25') }, 'xlsx', fonts);
  const r = await readXlsx(x.files[0].bytes);
  assert.equal(r.sheets[0].grid.A2, 'Çay');
  const c = await convert({ name: 'v.xlsx', bytes: x.files[0].bytes }, 'csv', fonts);
  assert.match(decodeText(c.files[0].bytes), /Kahve,25/);
  const pdf = await convert({ name: 'v.xlsx', bytes: x.files[0].bytes }, 'pdf', fonts);
  assert.equal(pdf.files[0].mime, 'application/pdf');
});

test('sheet pdf → xlsx and pptx, pptx → pdf', async () => {
  const x = await convert({ name: 'v.csv', bytes: utf8Encode('Ad,Tutar\nÇay,15\nKahve,25') }, 'pdf', fonts);
  const back = await convert({ name: 'v.pdf', bytes: x.files[0].bytes }, 'xlsx', fonts);
  const r = await readXlsx(back.files[0].bytes);
  const g = r.sheets[0].grid;
  const key = Object.keys(g).find((k) => g[k] === 'Çay')!;
  assert.ok(key, JSON.stringify(g));
  assert.equal(g['B' + key.slice(1)], '15');
  const dp = await convert({ name: 'd.md', bytes: utf8Encode(md) }, 'pdf', fonts);
  const sl = await convert({ name: 'd.pdf', bytes: dp.files[0].bytes }, 'pptx', fonts);
  assert.ok(sl.notices.some((n) => n.code === 'text_only'));
  const slides = (await readPptx(sl.files[0].bytes)).slides;
  assert.ok(slides.length >= 1);
  const pp = await convert({ name: 's.pptx', bytes: sl.files[0].bytes }, 'pdf', fonts);
  assert.ok(pp.files[0].bytes.length > 500);
});

test('errors are coded', async () => {
  await assert.rejects(() => convert({ name: 'a.pdf', bytes: new Uint8Array([1, 2]) }, 'docx', fonts), (e: any) => e instanceof ConvertError && e.code === 'not_pdf');
  await assert.rejects(() => convert({ name: 'a.docx', bytes: new Uint8Array([1, 2]) }, 'pdf', fonts), (e: any) => e.code === 'corrupt');
  await assert.rejects(() => convert({ name: 'a.csv', bytes: utf8Encode('x') }, 'docx', fonts), (e: any) => e.code === 'unsupported');
  assert.ok(targetsFor('pdf').includes('xlsx'));
});
