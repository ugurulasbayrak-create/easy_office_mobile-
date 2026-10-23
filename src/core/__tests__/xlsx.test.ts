import test from 'node:test';
import assert from 'node:assert/strict';
import JSZip from 'jszip';
import { writeXlsx, readXlsx, displayGrid } from '../xlsx.ts';
import { evaluateGrid, displayValue } from '../formula.ts';

test('xlsx round trip keeps text, numbers, booleans and formulas', async () => {
  const grid = {
    A1: 'Ürün', B1: 'Satış (₺)', C1: 'Not',
    A2: 'Çay & Şeker <özel>', B2: '1500', C2: 'satır1\nsatır2',
    A3: 'Kahve', B3: '2500,5', C3: '007',
    A4: 'Toplam', B4: '=SUM(B2:B3)', C4: '=IF(B4>3000,"yüksek","düşük")',
    A5: 'Açık', B5: 'TRUE', C5: '=B2/0',
  };
  const bytes = await writeXlsx([{ name: 'Rapor: 2026/Q1?', grid }]);
  const back = await readXlsx(bytes);
  assert.equal(back.sheets.length, 1);
  const s = back.sheets[0];
  assert.equal(s.name, 'Rapor  2026 Q1');
  assert.equal(s.grid.A1, 'Ürün');
  assert.equal(s.grid.A2, 'Çay & Şeker <özel>');
  assert.equal(s.grid.B2, '1500');
  assert.equal(s.grid.B3, '2500.5'); // stored as a real number, locale comma normalised
  assert.equal(s.grid.C2, 'satır1\nsatır2');
  assert.equal(s.grid.C3, '007'); // leading zeros stay text
  assert.equal(s.grid.B4, '=SUM(B2:B3)');
  assert.equal(s.grid.C4, '=IF(B4>3000,"yüksek","düşük")');
  assert.equal(s.grid.B5, 'TRUE');
  assert.equal(s.cached.B4, '4000.5');
  assert.equal(s.cached.C4, 'yüksek');
  assert.equal(s.cached.C5, '#DIV/0!');
  const ev = evaluateGrid(s.grid);
  assert.equal(displayValue(ev.B4), '4000.5');
  assert.equal(displayGrid(s).C5, '#DIV/0!');
});

test('xlsx: multiple sheets, name de-duplication, empty workbook', async () => {
  const bytes = await writeXlsx([
    { name: 'Veri', grid: { A1: 'x' } },
    { name: 'veri', grid: { A1: 'y' } },
    { name: '', grid: {} },
  ]);
  const r = await readXlsx(bytes);
  assert.deepEqual(r.sheets.map((s) => s.name), ['Veri', 'veri (2)', 'Sheet3']);
  assert.equal(r.sheets[1].grid.A1, 'y');
  const empty = await readXlsx(await writeXlsx([]));
  assert.equal(empty.sheets.length, 1);
  assert.deepEqual(empty.sheets[0].grid, {});
});

test('xlsx: header row is styled bold and frozen only when it is text', async () => {
  const withHeader = await JSZip.loadAsync(await writeXlsx([{ name: 'S', grid: { A1: 'Ad', B1: 'Tutar', A2: 'x', B2: '5' } }]));
  const xml1 = await withHeader.file('xl/worksheets/sheet1.xml')!.async('string');
  assert.ok(xml1.includes('s="1"'));
  assert.ok(xml1.includes('state="frozen"'));
  const numeric = await JSZip.loadAsync(await writeXlsx([{ name: 'S', grid: { A1: '1', B1: '2' } }]));
  const xml2 = await numeric.file('xl/worksheets/sheet1.xml')!.async('string');
  assert.ok(!xml2.includes('s="1"'));
});

async function handmade(files: Record<string, string>): Promise<Uint8Array> {
  const z = new JSZip();
  for (const [k, v] of Object.entries(files)) z.file(k, v);
  return z.generateAsync({ type: 'uint8array' });
}

const NS = 'xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main" xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships"';

test('xlsx: reads files produced by Excel (shared formulas, inline strings, dates, hidden sheets)', async () => {
  const bytes = await handmade({
    'xl/workbook.xml': `<workbook ${NS}><sheets><sheet name="Veri" sheetId="1" r:id="rId1"/><sheet name="Gizli" sheetId="2" state="hidden" r:id="rId2"/></sheets></workbook>`,
    'xl/_rels/workbook.xml.rels':
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
      '<Relationship Id="rId1" Type="x" Target="worksheets/sheet1.xml"/><Relationship Id="rId2" Type="x" Target="/xl/worksheets/sheet2.xml"/></Relationships>',
    'xl/sharedStrings.xml': `<sst ${NS}><si><t>Ad</t></si><si><r><t>Rich </t></r><r><rPr><b/></rPr><t>text</t></r></si></sst>`,
    'xl/styles.xml':
      `<styleSheet ${NS}><numFmts count="1"><numFmt numFmtId="164" formatCode="dd/mm/yyyy"/></numFmts>` +
      '<cellXfs count="3"><xf numFmtId="0"/><xf numFmtId="14"/><xf numFmtId="164"/></cellXfs></styleSheet>',
    'xl/worksheets/sheet1.xml':
      `<worksheet ${NS}><sheetData>` +
      '<row r="1"><c r="A1" t="s"><v>0</v></c><c r="B1" t="s"><v>1</v></c><c r="C1" t="inlineStr"><is><t>inline</t></is></c></row>' +
      '<row r="2"><c r="A2"><v>10</v></c><c r="B2"><f t="shared" ref="B2:B4" si="0">A2*2</f><v>20</v></c><c r="C2" s="1"><v>45292</v></c><c r="D2" s="2"><v>45292.5</v></c></row>' +
      '<row r="3"><c r="A3"><v>0.30000000000000004</v></c><c r="B3"><f t="shared" si="0"/><v>0.6</v></c></row>' +
      '<row r="4"><c r="A4"><v>5</v></c><c r="B4"><f t="shared" si="0"/><v>10</v></c><c r="C4"><f>VLOOKUP(A4,A2:B4,2,0)</f><v>10</v></c></row>' +
      '</sheetData></worksheet>',
    'xl/worksheets/sheet2.xml': `<worksheet ${NS}><sheetData><row r="1"><c r="A1"><v>1</v></c></row></sheetData></worksheet>`,
  });
  const r = await readXlsx(bytes);
  assert.equal(r.sheets.length, 1); // hidden sheet skipped
  const g = r.sheets[0].grid;
  assert.equal(g.A1, 'Ad');
  assert.equal(g.B1, 'Rich text');
  assert.equal(g.C1, 'inline');
  assert.equal(g.B2, '=A2*2');
  assert.equal(g.B3, '=A3*2'); // shared formula follower translated
  assert.equal(g.B4, '=A4*2');
  assert.equal(g.C2, '2024-01-01');
  assert.equal(g.D2, '2024-01-01 12:00');
  assert.equal(g.A3, '0.3');
  assert.equal(g.C4, '10'); // VLOOKUP unsupported -> cached value
  assert.deepEqual(r.notices, [{ code: 'formulas_as_values', n: 1 }]);
});

test('xlsx: rejects non-xlsx input', async () => {
  const z = new JSZip();
  z.file('hello.txt', 'hi');
  await assert.rejects(readXlsx(await z.generateAsync({ type: 'uint8array' })), /not_xlsx/);
});
