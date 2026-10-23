import test from 'node:test';
import assert from 'node:assert/strict';
import JSZip from 'jszip';
import { writeDocx, readDocx } from '../docx.ts';
import { parseMarkdown, blocksToMarkdown } from '../markdown.ts';
import type { Block } from '../types.ts';

const MD = [
  '# Başlık: Çalışma Planı',
  '',
  'Bu bir **kalın**, *eğik* ve `kod` içeren paragraftır. Özel karakterler: & < > "tırnak" ğüşıİöç.',
  '',
  '## Liste',
  '',
  '- birinci madde',
  '- ikinci **önemli** madde',
  '',
  '1. adım bir',
  '2. adım iki',
  '',
  '1. yeni liste',
  '',
  '| Ad | Tutar |',
  '| --- | --- |',
  '| Çay | 15 |',
  '| Kahve | 25 |',
  '',
  '---',
  '',
  '```',
  'kod satırı 1',
  'kod satırı 2',
  '```',
].join('\n');

test('docx round trip preserves structure and formatting', async () => {
  const blocks = parseMarkdown(MD);
  const bytes = await writeDocx(blocks, { title: 'Deneme' });
  const back = await readDocx(bytes);
  assert.deepEqual(back.notices, []);
  const b = back.blocks;
  assert.equal(b[0].type, 'heading');
  assert.equal((b[0] as Extract<Block, { type: 'heading' }>).level, 1);
  const para = b[1] as Extract<Block, { type: 'paragraph' }>;
  assert.equal(para.type, 'paragraph');
  assert.ok(para.runs.some((r) => r.bold && r.text === 'kalın'));
  assert.ok(para.runs.some((r) => r.italic && r.text === 'eğik'));
  assert.ok(para.runs.map((r) => r.text).join('').includes('& < > "tırnak" ğüşıİöç'));
  const lists = b.filter((x) => x.type === 'list') as Extract<Block, { type: 'list' }>[];
  assert.equal(lists.length, 3);
  assert.equal(lists[0].ordered, false);
  assert.equal(lists[0].items.length, 2);
  assert.equal(lists[1].ordered, true);
  assert.equal(lists[1].items.length, 2);
  assert.equal(lists[2].ordered, true); // separate numbering instance
  const table = b.find((x) => x.type === 'table') as Extract<Block, { type: 'table' }>;
  assert.equal(table.rows.length, 3);
  assert.equal(table.rows[2][0].map((r) => r.text).join(''), 'Kahve');
  // markdown survives the trip
  const md = blocksToMarkdown(b.filter((x) => x.type !== 'code' && x.type !== 'hr'));
  assert.ok(md.includes('| Çay | 15 |'));
  assert.ok(md.includes('# Başlık: Çalışma Planı'));
});

test('docx package has the parts Word expects', async () => {
  const zip = await JSZip.loadAsync(await writeDocx(parseMarkdown('# A\n\n1. x\n\n1. y')));
  for (const name of ['[Content_Types].xml', '_rels/.rels', 'word/document.xml', 'word/styles.xml', 'word/numbering.xml', 'word/_rels/document.xml.rels']) {
    assert.ok(zip.file(name), name);
  }
  const numbering = await zip.file('word/numbering.xml')!.async('string');
  assert.ok(numbering.includes('w:numId="2"') && numbering.includes('w:numId="3"'));
});

test('docx: empty document and non-docx input', async () => {
  const back = await readDocx(await writeDocx([]));
  assert.deepEqual(back.blocks, []);
  assert.deepEqual(back.notices, [{ code: 'no_text_found' }]);
  const z = new JSZip();
  z.file('x.txt', 'x');
  await assert.rejects(readDocx(await z.generateAsync({ type: 'uint8array' })), /not_docx/);
});

test('docx: reads localized heading styles via style names, outline levels, images, tabs and breaks', async () => {
  const W = 'xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main" xmlns:mc="x"';
  const z = new JSZip();
  z.file(
    'word/styles.xml',
    `<w:styles ${W}><w:style w:type="paragraph" w:styleId="Balk1"><w:name w:val="heading 1"/></w:style>` +
      '<w:style w:type="paragraph" w:styleId="Ozel"><w:name w:val="Custom"/><w:pPr><w:outlineLvl w:val="1"/></w:pPr></w:style></w:styles>',
  );
  z.file(
    'word/numbering.xml',
    `<w:numbering ${W}><w:abstractNum w:abstractNumId="5"><w:lvl w:ilvl="0"><w:numFmt w:val="decimal"/></w:lvl></w:abstractNum><w:num w:numId="9"><w:abstractNumId w:val="5"/></w:num></w:numbering>`,
  );
  z.file(
    'word/document.xml',
    `<w:document ${W}><w:body>` +
      '<w:p><w:pPr><w:pStyle w:val="Balk1"/></w:pPr><w:r><w:t>Giriş</w:t></w:r></w:p>' +
      '<w:p><w:pPr><w:pStyle w:val="Ozel"/></w:pPr><w:r><w:t>Alt başlık</w:t></w:r></w:p>' +
      '<w:p><w:r><w:t>Bir</w:t><w:tab/><w:t>iki</w:t><w:br/><w:t>üç</w:t></w:r><w:r><w:drawing/></w:r></w:p>' +
      '<w:p><w:pPr><w:numPr><w:ilvl w:val="0"/><w:numId w:val="9"/></w:numPr></w:pPr><w:hyperlink><w:r><w:rPr><w:b w:val="0"/></w:rPr><w:t>madde</w:t></w:r></w:hyperlink></w:p>' +
      '<w:p/>' +
      '<w:sdt><w:sdtContent><w:p><w:r><w:t>içerik denetimi</w:t></w:r></w:p></w:sdtContent></w:sdt>' +
      '</w:body></w:document>',
  );
  const r = await readDocx(await z.generateAsync({ type: 'uint8array' }));
  assert.equal(r.blocks[0].type, 'heading');
  assert.equal((r.blocks[0] as Extract<Block, { type: 'heading' }>).level, 1);
  assert.equal((r.blocks[1] as Extract<Block, { type: 'heading' }>).level, 2);
  const p = r.blocks[2] as Extract<Block, { type: 'paragraph' }>;
  assert.equal(p.runs.map((x) => x.text).join(''), 'Bir iki üç');
  const list = r.blocks[3] as Extract<Block, { type: 'list' }>;
  assert.equal(list.ordered, true);
  assert.equal(list.items[0][0].bold, undefined);
  assert.equal((r.blocks[4] as Extract<Block, { type: 'paragraph' }>).runs[0].text, 'içerik denetimi');
  assert.deepEqual(r.notices, [{ code: 'images_skipped', n: 1 }]);
});
