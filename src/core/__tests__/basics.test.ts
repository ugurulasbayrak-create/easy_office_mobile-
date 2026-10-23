import test from 'node:test';
import assert from 'node:assert/strict';
import { parseCsv, toCsv, detectDelimiter } from '../csv.ts';
import { parseXml, descendants, textContent, escapeXml, decodeEntities, attr } from '../xml.ts';
import { utf8Encode, utf8DecodeStrict, decodeText, cp1254Decode, baseName, extOf } from '../text.ts';
import { toBase64, fromBase64 } from '../base64.ts';

test('csv: quotes, delimiters, newlines in fields, BOM', () => {
  assert.deepEqual(parseCsv('a,b,c\n1,2,3\n'), [['a', 'b', 'c'], ['1', '2', '3']]);
  assert.deepEqual(parseCsv('a;b\n1,5;2'), [['a', 'b'], ['1,5', '2']]);
  assert.deepEqual(parseCsv('"x, y","he said ""hi""",z'), [['x, y', 'he said "hi"', 'z']]);
  assert.deepEqual(parseCsv('"line1\nline2",b\r\nc,d'), [['line1\nline2', 'b'], ['c', 'd']]);
  assert.deepEqual(parseCsv('﻿a,b\n1,2'), [['a', 'b'], ['1', '2']]);
  assert.deepEqual(parseCsv('a\tb\n1\t2'), [['a', 'b'], ['1', '2']]);
  assert.deepEqual(parseCsv('a,,c\n,,\n'), [['a', '', 'c']]);
  assert.deepEqual(parseCsv(''), []);
  assert.equal(detectDelimiter('a;b;c\n1;2;3'), ';');
  assert.equal(detectDelimiter('"a;b",c\n"d;e",f'), ',');
});

test('csv: round trip with awkward values', () => {
  const rows = [['ad', 'not'], ['Ayşe "A"', 'a,b'], ['satır\nsonu', ' boşluk ']];
  const back = parseCsv(toCsv(rows));
  assert.deepEqual(back, rows);
  assert.equal(toCsv([['a', 'b']], ';'), 'a;b\r\n');
});

test('xml: elements, attributes, entities, CDATA, self closing', () => {
  const doc = parseXml('<?xml version="1.0"?><r a="1 &amp; 2"><!-- c --><x/><y k=\'v\'>t&lt;1 &#65;&#x42;<![CDATA[<raw>]]></y><y>2</y></r>');
  const r = doc.children[0];
  assert.equal(r.name, 'r');
  assert.equal(attr(r, 'a'), '1 & 2');
  const ys = descendants(doc, 'y');
  assert.equal(ys.length, 2);
  assert.equal(textContent(ys[0]), 't<1 AB<raw>');
  assert.equal(attr(ys[0], 'k'), 'v');
  assert.equal(attr(parseXml('<a w:val="x"/>').children[0], 'val'), 'x');
});

test('xml: escaping', () => {
  assert.equal(escapeXml('a<b>&"c"\u0001'), 'a&lt;b&gt;&amp;&quot;c&quot;');
  assert.equal(decodeEntities('&lt;&amp;&gt;&quot;&apos;&#350;'), '<&>"\'Ş');
});

test('text: utf8 round trip and decoding of legacy Turkish files', () => {
  const s = 'Çalışkan öğrenci İstanbul ğüşıö 😀 €';
  assert.equal(utf8DecodeStrict(utf8Encode(s)), s);
  assert.equal(utf8DecodeStrict(Uint8Array.from([0xc3])), null);
  assert.equal(utf8DecodeStrict(Uint8Array.from([0xff, 0x41])), null);
  // "ğüşıİ" in windows-1254
  const ansi = Uint8Array.from([0xf0, 0xfc, 0xfe, 0xfd, 0xdd]);
  assert.equal(cp1254Decode(ansi), 'ğüşıİ');
  assert.equal(decodeText(ansi), 'ğüşıİ');
  assert.equal(decodeText(utf8Encode('﻿merhaba')), 'merhaba');
  assert.equal(decodeText(Uint8Array.from([0xff, 0xfe, 0x41, 0x00, 0x42, 0x00])), 'AB');
  assert.equal(baseName('/a/b/rapor.final.docx'), 'rapor.final');
  assert.equal(extOf('X.PDF'), 'pdf');
  assert.equal(extOf('noext'), '');
});

test('base64 matches Buffer for all tail lengths', () => {
  for (let len = 0; len < 40; len++) {
    const bytes = Uint8Array.from({ length: len }, (_, i) => (i * 37 + 11) & 255);
    const expected = Buffer.from(bytes).toString('base64');
    assert.equal(toBase64(bytes), expected, 'encode ' + len);
    assert.deepEqual(Array.from(fromBase64(expected)), Array.from(bytes), 'decode ' + len);
  }
  const big = Uint8Array.from({ length: 100000 }, (_, i) => i & 255);
  assert.equal(toBase64(big), Buffer.from(big).toString('base64'));
});
