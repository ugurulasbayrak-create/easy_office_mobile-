import test from 'node:test';
import assert from 'node:assert/strict';
import JSZip from 'jszip';
import { writePptx, readPptx } from '../pptx.ts';
import type { Slide } from '../types.ts';

const SLIDES: Slide[] = [
  { title: 'Easy Office', subtitle: 'Yeni nesil ofis', bullets: [], theme: 'dark' },
  { title: 'Sorun & Fırsat <1>', subtitle: 'Pazar', bullets: ['Birinci madde ğüşıİöç', 'İkinci "madde"', '500M+ kullanıcı'], theme: 'emerald' },
  { title: 'Çözüm', subtitle: '', bullets: ['Tek uygulama'], theme: 'sunset' },
];

test('pptx round trip', async () => {
  const bytes = await writePptx(SLIDES);
  const back = await readPptx(bytes);
  assert.deepEqual(back.notices, []);
  assert.equal(back.slides.length, 3);
  assert.deepEqual(back.slides.map((s) => s.title), ['Easy Office', 'Sorun & Fırsat <1>', 'Çözüm']);
  assert.deepEqual(back.slides.map((s) => s.subtitle), ['Yeni nesil ofis', 'Pazar', '']);
  assert.deepEqual(back.slides[1].bullets, ['Birinci madde ğüşıİöç', 'İkinci "madde"', '500M+ kullanıcı']);
  assert.deepEqual(back.slides[0].bullets, []);
});

test('pptx package structure', async () => {
  const zip = await JSZip.loadAsync(await writePptx(SLIDES));
  for (const n of ['[Content_Types].xml', 'ppt/presentation.xml', 'ppt/slideMasters/slideMaster1.xml', 'ppt/slideLayouts/slideLayout1.xml', 'ppt/theme/theme1.xml', 'ppt/slides/slide3.xml', 'ppt/slides/_rels/slide3.xml.rels']) {
    assert.ok(zip.file(n), n);
  }
  const empty = await readPptx(await writePptx([]));
  assert.equal(empty.slides.length, 1);
});

test('pptx: reads placeholders, tables, groups, order from presentation.xml, ignores footers', async () => {
  const A = 'xmlns:a="a" xmlns:r="r" xmlns:p="p"';
  const z = new JSZip();
  z.file('ppt/presentation.xml', `<p:presentation ${A}><p:sldIdLst><p:sldId id="1" r:id="rB"/><p:sldId id="2" r:id="rA"/></p:sldIdLst></p:presentation>`);
  z.file(
    'ppt/_rels/presentation.xml.rels',
    '<Relationships><Relationship Id="rA" Target="slides/slide1.xml"/><Relationship Id="rB" Target="slides/slide2.xml"/></Relationships>',
  );
  const sp = (ph: string, text: string) =>
    `<p:sp><p:nvSpPr><p:cNvPr id="1" name="x"/><p:cNvSpPr/><p:nvPr>${ph}</p:nvPr></p:nvSpPr><p:txBody><a:p><a:r><a:t>${text}</a:t></a:r></a:p></p:txBody></p:sp>`;
  z.file(
    'ppt/slides/slide1.xml',
    `<p:sld ${A}><p:cSld><p:spTree>${sp('<p:ph type="ctrTitle"/>', 'Birinci')}${sp('<p:ph type="subTitle"/>', 'Alt')}${sp('<p:ph type="ftr"/>', 'altbilgi')}` +
      `<p:grpSp>${sp('', 'grup metni')}</p:grpSp><p:pic/>` +
      '<p:graphicFrame><a:tbl><a:tr><a:tc><a:txBody><a:p><a:r><a:t>H1</a:t></a:r></a:p></a:txBody></a:tc><a:tc><a:txBody><a:p><a:r><a:t>H2</a:t></a:r></a:p></a:txBody></a:tc></a:tr></a:tbl></p:graphicFrame>' +
      '</p:spTree></p:cSld></p:sld>',
  );
  z.file('ppt/slides/slide2.xml', `<p:sld ${A}><p:cSld><p:spTree>${sp('', 'Başlıksız slayt')}</p:spTree></p:cSld></p:sld>`);
  const r = await readPptx(await z.generateAsync({ type: 'uint8array' }));
  assert.equal(r.slides.length, 2);
  assert.equal(r.slides[0].title, 'Başlıksız slayt'); // order follows sldIdLst (rB -> slide2 first)
  assert.equal(r.slides[1].title, 'Birinci');
  assert.equal(r.slides[1].subtitle, 'Alt');
  assert.deepEqual(r.slides[1].bullets, ['grup metni', 'H1 | H2']);
  assert.deepEqual(r.notices, [{ code: 'images_skipped', n: 1 }]);
});

test('pptx: rejects non-pptx input', async () => {
  const z = new JSZip();
  z.file('a.txt', 'a');
  await assert.rejects(readPptx(await z.generateAsync({ type: 'uint8array' })), /not_pptx/);
});
