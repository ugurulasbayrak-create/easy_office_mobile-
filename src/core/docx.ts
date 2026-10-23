// Real DOCX writing and reading on top of JSZip.

import JSZip from 'jszip';
import type { Block, Inline, Notice } from './types.ts';
import { attr, child, descendants, elements, escapeXml, parseXml, textContent } from './xml.ts';
import type { XmlNode } from './xml.ts';

// ------------------------------------------------------------------- write

const PAGE_TEXT_WIDTH = 9026; // A4 with 1" margins, in twips

function runXml(r: Inline, forceBold = false): string {
  const props: string[] = [];
  if (r.code) props.push('<w:rFonts w:ascii="Consolas" w:hAnsi="Consolas" w:cs="Consolas"/>');
  if (r.bold || forceBold) props.push('<w:b/><w:bCs/>');
  if (r.italic) props.push('<w:i/><w:iCs/>');
  if (r.code) props.push('<w:shd w:val="clear" w:color="auto" w:fill="F2F2F2"/>');
  const rPr = props.length ? `<w:rPr>${props.join('')}</w:rPr>` : '';
  // split on newlines/tabs so they become real breaks and tabs
  const pieces = r.text.split(/(\n|\t)/);
  const body = pieces
    .map((p) => (p === '\n' ? '<w:br/>' : p === '\t' ? '<w:tab/>' : p === '' ? '' : `<w:t xml:space="preserve">${escapeXml(p)}</w:t>`))
    .join('');
  return body === '' ? '' : `<w:r>${rPr}${body}</w:r>`;
}

function runsXml(runs: Inline[], forceBold = false): string {
  return runs.map((r) => runXml(r, forceBold)).join('');
}

function blocksXml(blocks: Block[], numState: { next: number; ordered: number[] }): string {
  const out: string[] = [];
  for (const b of blocks) {
    switch (b.type) {
      case 'heading':
        out.push(`<w:p><w:pPr><w:pStyle w:val="Heading${b.level}"/></w:pPr>${runsXml(b.runs)}</w:p>`);
        break;
      case 'paragraph':
        out.push(`<w:p>${runsXml(b.runs)}</w:p>`);
        break;
      case 'list': {
        let numId = 1; // shared bullet list
        if (b.ordered) {
          numId = numState.next++;
          numState.ordered.push(numId);
        }
        for (const item of b.items) {
          out.push(
            `<w:p><w:pPr><w:pStyle w:val="ListParagraph"/><w:numPr><w:ilvl w:val="0"/><w:numId w:val="${numId}"/></w:numPr></w:pPr>${runsXml(item)}</w:p>`,
          );
        }
        break;
      }
      case 'table': {
        const cols = Math.max(1, ...b.rows.map((r) => r.length));
        const w = Math.floor(PAGE_TEXT_WIDTH / cols);
        const border = (n: string) => `<w:${n} w:val="single" w:sz="4" w:space="0" w:color="A6A6A6"/>`;
        const rows = b.rows.map((row, ri) => {
          const isHead = b.header && ri === 0;
          const cells = [];
          for (let c = 0; c < cols; c++) {
            const cell = row[c] ?? [];
            const shd = isHead ? '<w:shd w:val="clear" w:color="auto" w:fill="D9E2F3"/>' : '';
            cells.push(`<w:tc><w:tcPr><w:tcW w:w="${w}" w:type="dxa"/>${shd}</w:tcPr><w:p>${runsXml(cell, isHead)}</w:p></w:tc>`);
          }
          return `<w:tr>${isHead ? '<w:trPr><w:tblHeader/></w:trPr>' : ''}${cells.join('')}</w:tr>`;
        });
        out.push(
          '<w:tbl><w:tblPr><w:tblStyle w:val="TableGrid"/><w:tblW w:w="0" w:type="auto"/>' +
            `<w:tblBorders>${['top', 'left', 'bottom', 'right', 'insideH', 'insideV'].map(border).join('')}</w:tblBorders>` +
            '<w:tblLook w:val="04A0" w:firstRow="1" w:lastRow="0" w:firstColumn="0" w:lastColumn="0" w:noHBand="0" w:noVBand="1"/></w:tblPr>' +
            `<w:tblGrid>${Array.from({ length: cols }, () => `<w:gridCol w:w="${w}"/>`).join('')}</w:tblGrid>${rows.join('')}</w:tbl><w:p/>`,
        );
        break;
      }
      case 'code':
        for (const line of b.text.split('\n')) {
          out.push(
            `<w:p><w:pPr><w:shd w:val="clear" w:color="auto" w:fill="F2F2F2"/><w:spacing w:after="0"/></w:pPr>${runXml({ text: line === '' ? ' ' : line, code: true })}</w:p>`,
          );
        }
        break;
      case 'hr':
        out.push('<w:p><w:pPr><w:pBdr><w:bottom w:val="single" w:sz="6" w:space="1" w:color="999999"/></w:pBdr></w:pPr></w:p>');
        break;
    }
  }
  return out.join('');
}

function headingStyle(level: number, size: number, before: number): string {
  return (
    `<w:style w:type="paragraph" w:styleId="Heading${level}"><w:name w:val="heading ${level}"/><w:basedOn w:val="Normal"/>` +
    '<w:next w:val="Normal"/><w:uiPriority w:val="9"/><w:qFormat/>' +
    `<w:pPr><w:keepNext/><w:keepLines/><w:spacing w:before="${before}" w:after="120"/><w:outlineLvl w:val="${level - 1}"/></w:pPr>` +
    `<w:rPr><w:b/><w:bCs/><w:color w:val="1F3864"/><w:sz w:val="${size}"/><w:szCs w:val="${size}"/></w:rPr></w:style>`
  );
}

const STYLES = (() =>
  '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
  '<w:styles xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
  '<w:docDefaults><w:rPrDefault><w:rPr><w:rFonts w:ascii="Calibri" w:hAnsi="Calibri" w:eastAsia="Calibri" w:cs="Calibri"/>' +
  '<w:sz w:val="22"/><w:szCs w:val="22"/><w:lang w:val="tr-TR" w:eastAsia="en-US" w:bidi="ar-SA"/></w:rPr></w:rPrDefault>' +
  '<w:pPrDefault><w:pPr><w:spacing w:after="140" w:line="264" w:lineRule="auto"/></w:pPr></w:pPrDefault></w:docDefaults>' +
  '<w:style w:type="paragraph" w:default="1" w:styleId="Normal"><w:name w:val="Normal"/><w:qFormat/></w:style>' +
  headingStyle(1, 36, 360) + headingStyle(2, 30, 280) + headingStyle(3, 26, 240) +
  headingStyle(4, 24, 200) + headingStyle(5, 22, 200) + headingStyle(6, 22, 200) +
  '<w:style w:type="paragraph" w:styleId="ListParagraph"><w:name w:val="List Paragraph"/><w:basedOn w:val="Normal"/><w:uiPriority w:val="34"/><w:qFormat/>' +
  '<w:pPr><w:spacing w:after="60"/><w:ind w:left="720"/></w:pPr></w:style>' +
  '<w:style w:type="table" w:default="1" w:styleId="TableNormal"><w:name w:val="Normal Table"/><w:uiPriority w:val="99"/><w:semiHidden/><w:unhideWhenUsed/>' +
  '<w:tblPr><w:tblInd w:w="0" w:type="dxa"/><w:tblCellMar><w:top w:w="0" w:type="dxa"/><w:left w:w="108" w:type="dxa"/><w:bottom w:w="0" w:type="dxa"/><w:right w:w="108" w:type="dxa"/></w:tblCellMar></w:tblPr></w:style>' +
  '<w:style w:type="table" w:styleId="TableGrid"><w:name w:val="Table Grid"/><w:basedOn w:val="TableNormal"/><w:uiPriority w:val="39"/>' +
  '<w:pPr><w:spacing w:after="0" w:line="240" w:lineRule="auto"/></w:pPr>' +
  '<w:tblPr><w:tblCellMar><w:top w:w="40" w:type="dxa"/><w:left w:w="100" w:type="dxa"/><w:bottom w:w="40" w:type="dxa"/><w:right w:w="100" w:type="dxa"/></w:tblCellMar></w:tblPr></w:style>' +
  '</w:styles>')();

function numberingXml(orderedIds: number[]): string {
  const lvl = (fmt: string, text: string) =>
    `<w:lvl w:ilvl="0"><w:start w:val="1"/><w:numFmt w:val="${fmt}"/><w:lvlText w:val="${text}"/><w:lvlJc w:val="left"/>` +
    '<w:pPr><w:ind w:left="720" w:hanging="360"/></w:pPr></w:lvl>';
  return (
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    '<w:numbering xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main">' +
    `<w:abstractNum w:abstractNumId="0"><w:multiLevelType w:val="singleLevel"/>${lvl('bullet', '•')}</w:abstractNum>` +
    `<w:abstractNum w:abstractNumId="1"><w:multiLevelType w:val="singleLevel"/>${lvl('decimal', '%1.')}</w:abstractNum>` +
    '<w:num w:numId="1"><w:abstractNumId w:val="0"/></w:num>' +
    orderedIds
      .map((id) => `<w:num w:numId="${id}"><w:abstractNumId w:val="1"/><w:lvlOverride w:ilvl="0"><w:startOverride w:val="1"/></w:lvlOverride></w:num>`)
      .join('') +
    '</w:numbering>'
  );
}

export async function writeDocx(blocks: Block[], opts: { title?: string } = {}): Promise<Uint8Array> {
  const numState = { next: 2, ordered: [] as number[] };
  const body = blocksXml(blocks.length ? blocks : [{ type: 'paragraph', runs: [] }], numState);
  const zip = new JSZip();
  zip.file(
    '[Content_Types].xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
      '<Default Extension="xml" ContentType="application/xml"/>' +
      '<Override PartName="/word/document.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.document.main+xml"/>' +
      '<Override PartName="/word/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.styles+xml"/>' +
      '<Override PartName="/word/numbering.xml" ContentType="application/vnd.openxmlformats-officedocument.wordprocessingml.numbering+xml"/>' +
      '<Override PartName="/docProps/core.xml" ContentType="application/vnd.openxmlformats-package.core-properties+xml"/>' +
      '</Types>',
  );
  zip.file(
    '_rels/.rels',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="word/document.xml"/>' +
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/package/2006/relationships/metadata/core-properties" Target="docProps/core.xml"/>' +
      '</Relationships>',
  );
  zip.file(
    'word/_rels/document.xml.rels',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">' +
      '<Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>' +
      '<Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/numbering" Target="numbering.xml"/>' +
      '</Relationships>',
  );
  zip.file(
    'docProps/core.xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<cp:coreProperties xmlns:cp="http://schemas.openxmlformats.org/package/2006/metadata/core-properties" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:dcterms="http://purl.org/dc/terms/" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">' +
      `<dc:title>${escapeXml(opts.title ?? '')}</dc:title><dc:creator>Easy Office</dc:creator>` +
      `<dcterms:created xsi:type="dcterms:W3CDTF">${new Date().toISOString().replace(/\.\d+Z$/, 'Z')}</dcterms:created>` +
      '</cp:coreProperties>',
  );
  zip.file('word/styles.xml', STYLES);
  zip.file('word/numbering.xml', numberingXml(numState.ordered));
  zip.file(
    'word/document.xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<w:document xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"><w:body>' +
      body +
      '<w:sectPr><w:pgSz w:w="11906" w:h="16838"/><w:pgMar w:top="1440" w:right="1440" w:bottom="1440" w:left="1440" w:header="708" w:footer="708" w:gutter="0"/></w:sectPr>' +
      '</w:body></w:document>',
  );
  return zip.generateAsync({ type: 'uint8array', compression: 'DEFLATE' });
}

// -------------------------------------------------------------------- read

interface StyleInfo {
  name: string;
  outline?: number;
}

function onOff(node: XmlNode | undefined): boolean {
  if (!node) return false;
  const v = attr(node, 'w:val');
  return !(v === '0' || v === 'false' || v === 'off');
}

interface ReadCtx {
  styles: Record<string, StyleInfo>;
  numbering: Record<string, boolean>; // numId -> ordered
  images: number;
}

function collectRuns(node: XmlNode, ctx: ReadCtx, out: Inline[]): void {
  for (const c of elements(node)) {
    switch (c.name) {
      case 'w:r': {
        const rPr = child(c, 'w:rPr');
        const bold = rPr ? onOff(child(rPr, 'w:b')) : false;
        const italic = rPr ? onOff(child(rPr, 'w:i')) : false;
        let text = '';
        for (const part of elements(c)) {
          if (part.name === 'w:t') text += textContent(part);
          else if (part.name === 'w:tab') text += ' ';
          else if (part.name === 'w:br') {
            if (attr(part, 'w:type') !== 'page') text += ' ';
          } else if (part.name === 'w:noBreakHyphen') text += '-';
          else if (part.name === 'w:drawing' || part.name === 'w:pict' || part.name === 'mc:AlternateContent') ctx.images++;
        }
        if (text !== '') {
          const last = out[out.length - 1];
          if (last && !!last.bold === bold && !!last.italic === italic && !last.code) last.text += text;
          else out.push({ text, ...(bold ? { bold: true } : {}), ...(italic ? { italic: true } : {}) });
        }
        break;
      }
      case 'w:hyperlink':
      case 'w:smartTag':
      case 'w:ins':
      case 'w:fldSimple':
      case 'w:sdt':
      case 'w:sdtContent':
        collectRuns(c, ctx, out);
        break;
      default:
        break;
    }
  }
}

function paragraphRuns(p: XmlNode, ctx: ReadCtx): Inline[] {
  const runs: Inline[] = [];
  collectRuns(p, ctx, runs);
  return runs;
}

function runsToText(runs: Inline[]): string {
  return runs.map((r) => r.text).join('');
}

function readTable(tbl: XmlNode, ctx: ReadCtx): Block | null {
  const rows: Inline[][][] = [];
  for (const tr of elements(tbl).filter((e) => e.name === 'w:tr')) {
    const cells: Inline[][] = [];
    for (const tc of elements(tr).filter((e) => e.name === 'w:tc')) {
      const merged: Inline[] = [];
      for (const p of elements(tc).filter((e) => e.name === 'w:p')) {
        const runs = paragraphRuns(p, ctx);
        if (runs.length === 0) continue;
        if (merged.length) merged.push({ text: ' ' });
        merged.push(...runs);
      }
      cells.push(merged);
    }
    if (cells.length) rows.push(cells);
  }
  if (!rows.length) return null;
  const width = Math.max(...rows.map((r) => r.length));
  for (const r of rows) while (r.length < width) r.push([]);
  return { type: 'table', rows, header: true };
}

export async function readDocx(bytes: Uint8Array): Promise<{ blocks: Block[]; notices: Notice[] }> {
  const zip = await JSZip.loadAsync(bytes);
  const docFile = zip.file('word/document.xml');
  if (!docFile) throw new Error('not_docx');
  const doc = parseXml(await docFile.async('string'));

  const ctx: ReadCtx = { styles: {}, numbering: {}, images: 0 };

  const stylesFile = zip.file('word/styles.xml');
  if (stylesFile) {
    for (const s of descendants(parseXml(await stylesFile.async('string')), 'w:style')) {
      const id = attr(s, 'w:styleId');
      if (!id) continue;
      const name = (attr(child(s, 'w:name'), 'w:val') ?? '').toLowerCase();
      const outline = attr(child(child(s, 'w:pPr') ?? s, 'w:outlineLvl'), 'w:val');
      ctx.styles[id] = { name, outline: outline !== undefined ? Number(outline) : undefined };
    }
  }
  const numFile = zip.file('word/numbering.xml');
  if (numFile) {
    const numbering = parseXml(await numFile.async('string'));
    const abstractOrdered: Record<string, boolean> = {};
    for (const a of descendants(numbering, 'w:abstractNum')) {
      const id = attr(a, 'w:abstractNumId');
      const lvl0 = descendants(a, 'w:lvl').find((l) => attr(l, 'w:ilvl') === '0');
      const fmt = attr(child(lvl0 ?? a, 'w:numFmt'), 'w:val');
      if (id !== undefined) abstractOrdered[id] = !!fmt && fmt !== 'bullet' && fmt !== 'none';
    }
    for (const n of descendants(numbering, 'w:num')) {
      const id = attr(n, 'w:numId');
      const abs = attr(child(n, 'w:abstractNumId'), 'w:val');
      if (id !== undefined && abs !== undefined) ctx.numbering[id] = abstractOrdered[abs] ?? false;
    }
  }

  const blocks: Block[] = [];
  // Consecutive items only join one list when they share the same numbering instance,
  // so two separately numbered lists stay separate (numbering restarts at 1).
  let listKey = '';
  const pushList = (ordered: boolean, item: Inline[], key: string) => {
    const last = blocks[blocks.length - 1];
    if (last && last.type === 'list' && last.ordered === ordered && key === listKey) last.items.push(item);
    else {
      blocks.push({ type: 'list', ordered, items: [item] });
      listKey = key;
    }
  };

  const walk = (container: XmlNode) => {
    for (const el of elements(container)) {
      if (el.name === 'w:p') {
        const runs = paragraphRuns(el, ctx);
        const text = runsToText(runs);
        if (text.trim() === '') continue;
        const pPr = child(el, 'w:pPr');
        const styleId = attr(child(pPr ?? el, 'w:pStyle'), 'w:val');
        const style = styleId ? ctx.styles[styleId] : undefined;
        const styleName = style?.name ?? '';

        let level = 0;
        const hm = /^heading (\d)$/.exec(styleName);
        if (hm) level = Number(hm[1]);
        else if (styleName === 'title') level = 1;
        else if (style?.outline !== undefined && style.outline >= 0 && style.outline <= 5) level = style.outline + 1;
        else {
          const ol = attr(child(pPr ?? el, 'w:outlineLvl'), 'w:val');
          if (ol !== undefined && Number(ol) <= 5) level = Number(ol) + 1;
        }
        if (level >= 1 && level <= 6) {
          blocks.push({ type: 'heading', level: level as 1 | 2 | 3 | 4 | 5 | 6, runs: runs.map((r) => ({ text: r.text, ...(r.italic ? { italic: true } : {}) })) });
          continue;
        }

        const numPr = child(pPr ?? el, 'w:numPr');
        const numId = attr(child(numPr ?? el, 'w:numId'), 'w:val');
        if (numPr && numId && numId !== '0') {
          pushList(ctx.numbering[numId] ?? false, runs, 'num:' + numId);
          continue;
        }
        if (/^list bullet/.test(styleName)) {
          pushList(false, runs, 'style:bullet');
          continue;
        }
        if (/^list number/.test(styleName)) {
          pushList(true, runs, 'style:number');
          continue;
        }
        blocks.push({ type: 'paragraph', runs });
      } else if (el.name === 'w:tbl') {
        const t = readTable(el, ctx);
        if (t) blocks.push(t);
      } else if (el.name === 'w:sdt') {
        const content = child(el, 'w:sdtContent');
        if (content) walk(content);
      }
    }
  };
  const body = descendants(doc, 'w:body')[0];
  if (body) walk(body);

  const notices: Notice[] = [];
  if (ctx.images > 0) notices.push({ code: 'images_skipped', n: ctx.images });
  if (blocks.length === 0) notices.push({ code: 'no_text_found' });
  return { blocks, notices };
}
