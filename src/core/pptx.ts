// Real PPTX writing and reading on top of JSZip.

import JSZip from 'jszip';
import type { Notice, Slide } from './types.ts';
import { SLIDE_THEMES } from './themes.ts';
import { attr, child, descendants, elements, escapeXml, parseXml, textContent } from './xml.ts';
import type { XmlNode } from './xml.ts';

// ------------------------------------------------------------------- write

const NS =
  'xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" ' +
  'xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships" ' +
  'xmlns:p="http://schemas.openxmlformats.org/presentationml/2006/main"';
const REL_NS = 'http://schemas.openxmlformats.org/package/2006/relationships';
const REL = 'http://schemas.openxmlformats.org/officeDocument/2006/relationships';
const EMU_W = 12192000;
const EMU_H = 6858000;
const MARGIN = 640080;

const GROUP_PROPS =
  '<p:nvGrpSpPr><p:cNvPr id="1" name=""/><p:cNvGrpSpPr/><p:nvPr/></p:nvGrpSpPr>' +
  '<p:grpSpPr><a:xfrm><a:off x="0" y="0"/><a:ext cx="0" cy="0"/><a:chOff x="0" y="0"/><a:chExt cx="0" cy="0"/></a:xfrm></p:grpSpPr>';

function textBox(id: number, name: string, x: number, y: number, w: number, h: number, anchor: string, paras: string): string {
  return (
    `<p:sp><p:nvSpPr><p:cNvPr id="${id}" name="${name}"/><p:cNvSpPr txBox="1"/><p:nvPr/></p:nvSpPr>` +
    `<p:spPr><a:xfrm><a:off x="${x}" y="${y}"/><a:ext cx="${w}" cy="${h}"/></a:xfrm><a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:noFill/></p:spPr>` +
    `<p:txBody><a:bodyPr wrap="square" lIns="0" tIns="0" rIns="0" bIns="0" anchor="${anchor}"><a:normAutofit/></a:bodyPr><a:lstStyle/>${paras}</p:txBody></p:sp>`
  );
}

function run(text: string, size: number, color: string, bold: boolean): string {
  return (
    `<a:r><a:rPr lang="tr-TR" sz="${size}"${bold ? ' b="1"' : ''} dirty="0"><a:solidFill><a:srgbClr val="${color}"/></a:solidFill>` +
    `<a:latin typeface="Calibri"/><a:cs typeface="Calibri"/></a:rPr><a:t>${escapeXml(text)}</a:t></a:r>`
  );
}

function slideXml(s: Slide): string {
  const c = SLIDE_THEMES[s.theme] ?? SLIDE_THEMES.dark;
  const w = EMU_W - 2 * MARGIN;
  const hasBody = s.bullets.length > 0;
  const shapes: string[] = [];
  let id = 2;

  const titleSize = s.title.length > 60 ? 3000 : s.title.length > 40 ? 3600 : hasBody ? 4000 : 5400;
  if (hasBody) {
    shapes.push(textBox(id++, 'Title', MARGIN, 420000, w, 1000000, 'b', `<a:p>${run(s.title, titleSize, c.title, true)}</a:p>`));
    shapes.push(
      `<p:sp><p:nvSpPr><p:cNvPr id="${id++}" name="Accent"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr><p:spPr><a:xfrm><a:off x="${MARGIN}" y="1500000"/><a:ext cx="1100000" cy="54000"/></a:xfrm>` +
        `<a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:solidFill><a:srgbClr val="${c.subtitle}"/></a:solidFill><a:ln><a:noFill/></a:ln></p:spPr></p:sp>`,
    );
    let y = 1680000;
    if (s.subtitle.trim() !== '') {
      shapes.push(textBox(id++, 'Subtitle', MARGIN, y, w, 520000, 't', `<a:p>${run(s.subtitle, 2200, c.subtitle, false)}</a:p>`));
      y += 640000;
    }
    const total = s.bullets.join('').length;
    const size = s.bullets.length > 9 || total > 700 ? 1800 : s.bullets.length > 6 || total > 450 ? 2000 : 2400;
    const paras = s.bullets
      .map(
        (b) =>
          `<a:p><a:pPr marL="342900" indent="-342900"><a:spcBef><a:spcPts val="900"/></a:spcBef><a:buClr><a:srgbClr val="${c.subtitle}"/></a:buClr><a:buFont typeface="Arial"/><a:buChar char="•"/></a:pPr>${run(b, size, c.body, false)}</a:p>`,
      )
      .join('');
    shapes.push(textBox(id++, 'Content', MARGIN, y, w, EMU_H - y - 500000, 't', paras));
  } else {
    shapes.push(textBox(id++, 'Title', MARGIN, 2000000, w, 1500000, 'b', `<a:p>${run(s.title, titleSize, c.title, true)}</a:p>`));
    shapes.push(
      `<p:sp><p:nvSpPr><p:cNvPr id="${id++}" name="Accent"/><p:cNvSpPr/><p:nvPr/></p:nvSpPr><p:spPr><a:xfrm><a:off x="${MARGIN}" y="3640000"/><a:ext cx="1100000" cy="54000"/></a:xfrm>` +
        `<a:prstGeom prst="rect"><a:avLst/></a:prstGeom><a:solidFill><a:srgbClr val="${c.subtitle}"/></a:solidFill><a:ln><a:noFill/></a:ln></p:spPr></p:sp>`,
    );
    if (s.subtitle.trim() !== '') {
      shapes.push(textBox(id++, 'Subtitle', MARGIN, 3820000, w, 900000, 't', `<a:p>${run(s.subtitle, 2600, c.subtitle, false)}</a:p>`));
    }
  }

  return (
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    `<p:sld ${NS}><p:cSld><p:bg><p:bgPr><a:solidFill><a:srgbClr val="${c.bg}"/></a:solidFill><a:effectLst/></p:bgPr></p:bg>` +
    `<p:spTree>${GROUP_PROPS}${shapes.join('')}</p:spTree></p:cSld><p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sld>`
  );
}

const THEME_XML =
  '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
  '<a:theme xmlns:a="http://schemas.openxmlformats.org/drawingml/2006/main" name="Easy Office"><a:themeElements>' +
  '<a:clrScheme name="Easy Office"><a:dk1><a:srgbClr val="000000"/></a:dk1><a:lt1><a:srgbClr val="FFFFFF"/></a:lt1>' +
  '<a:dk2><a:srgbClr val="1F2937"/></a:dk2><a:lt2><a:srgbClr val="F3F4F6"/></a:lt2>' +
  '<a:accent1><a:srgbClr val="0284C7"/></a:accent1><a:accent2><a:srgbClr val="06B6D4"/></a:accent2>' +
  '<a:accent3><a:srgbClr val="10B981"/></a:accent3><a:accent4><a:srgbClr val="F59E0B"/></a:accent4>' +
  '<a:accent5><a:srgbClr val="EF4444"/></a:accent5><a:accent6><a:srgbClr val="8B5CF6"/></a:accent6>' +
  '<a:hlink><a:srgbClr val="0563C1"/></a:hlink><a:folHlink><a:srgbClr val="954F72"/></a:folHlink></a:clrScheme>' +
  '<a:fontScheme name="Easy Office"><a:majorFont><a:latin typeface="Calibri"/><a:ea typeface=""/><a:cs typeface=""/></a:majorFont>' +
  '<a:minorFont><a:latin typeface="Calibri"/><a:ea typeface=""/><a:cs typeface=""/></a:minorFont></a:fontScheme>' +
  '<a:fmtScheme name="Easy Office"><a:fillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:fillStyleLst>' +
  '<a:lnStyleLst><a:ln w="9525"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln><a:ln w="19050"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln><a:ln w="28575"><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:ln></a:lnStyleLst>' +
  '<a:effectStyleLst><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle><a:effectStyle><a:effectLst/></a:effectStyle></a:effectStyleLst>' +
  '<a:bgFillStyleLst><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill><a:solidFill><a:schemeClr val="phClr"/></a:solidFill></a:bgFillStyleLst></a:fmtScheme>' +
  '</a:themeElements></a:theme>';

const MASTER_XML =
  '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
  `<p:sldMaster ${NS}><p:cSld><p:bg><p:bgRef idx="1001"><a:schemeClr val="bg1"/></p:bgRef></p:bg><p:spTree>${GROUP_PROPS}</p:spTree></p:cSld>` +
  '<p:clrMap bg1="lt1" tx1="dk1" bg2="lt2" tx2="dk2" accent1="accent1" accent2="accent2" accent3="accent3" accent4="accent4" accent5="accent5" accent6="accent6" hlink="hlink" folHlink="folHlink"/>' +
  '<p:sldLayoutIdLst><p:sldLayoutId id="2147483649" r:id="rId1"/></p:sldLayoutIdLst>' +
  '<p:txStyles><p:titleStyle><a:lvl1pPr algn="l"><a:defRPr sz="4000"/></a:lvl1pPr></p:titleStyle>' +
  '<p:bodyStyle><a:lvl1pPr marL="342900" indent="-342900"><a:defRPr sz="2400"/></a:lvl1pPr></p:bodyStyle>' +
  '<p:otherStyle><a:lvl1pPr><a:defRPr sz="1800"/></a:lvl1pPr></p:otherStyle></p:txStyles></p:sldMaster>';

const LAYOUT_XML =
  '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
  `<p:sldLayout ${NS} type="blank" preserve="1"><p:cSld name="Blank"><p:spTree>${GROUP_PROPS}</p:spTree></p:cSld>` +
  '<p:clrMapOvr><a:masterClrMapping/></p:clrMapOvr></p:sldLayout>';

function rels(items: { id: string; type: string; target: string }[]): string {
  return (
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
    `<Relationships xmlns="${REL_NS}">` +
    items.map((r) => `<Relationship Id="${r.id}" Type="${REL}/${r.type}" Target="${r.target}"/>`).join('') +
    '</Relationships>'
  );
}

export async function writePptx(slides: Slide[], opts: { title?: string } = {}): Promise<Uint8Array> {
  const list: Slide[] = slides.length ? slides : [{ title: opts.title ?? '', subtitle: '', bullets: [], theme: 'dark' }];
  const zip = new JSZip();
  zip.file(
    '[Content_Types].xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      '<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">' +
      '<Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>' +
      '<Default Extension="xml" ContentType="application/xml"/>' +
      '<Override PartName="/ppt/presentation.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.presentation.main+xml"/>' +
      '<Override PartName="/ppt/slideMasters/slideMaster1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideMaster+xml"/>' +
      '<Override PartName="/ppt/slideLayouts/slideLayout1.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slideLayout+xml"/>' +
      '<Override PartName="/ppt/theme/theme1.xml" ContentType="application/vnd.openxmlformats-officedocument.theme+xml"/>' +
      list.map((_, i) => `<Override PartName="/ppt/slides/slide${i + 1}.xml" ContentType="application/vnd.openxmlformats-officedocument.presentationml.slide+xml"/>`).join('') +
      '</Types>',
  );
  zip.file('_rels/.rels', rels([{ id: 'rId1', type: 'officeDocument', target: 'ppt/presentation.xml' }]));
  zip.file(
    'ppt/presentation.xml',
    '<?xml version="1.0" encoding="UTF-8" standalone="yes"?>' +
      `<p:presentation ${NS} saveSubsetFonts="1"><p:sldMasterIdLst><p:sldMasterId id="2147483648" r:id="rId1"/></p:sldMasterIdLst>` +
      `<p:sldIdLst>${list.map((_, i) => `<p:sldId id="${256 + i}" r:id="rId${i + 2}"/>`).join('')}</p:sldIdLst>` +
      `<p:sldSz cx="${EMU_W}" cy="${EMU_H}"/><p:notesSz cx="6858000" cy="9144000"/></p:presentation>`,
  );
  zip.file(
    'ppt/_rels/presentation.xml.rels',
    rels([
      { id: 'rId1', type: 'slideMaster', target: 'slideMasters/slideMaster1.xml' },
      ...list.map((_, i) => ({ id: `rId${i + 2}`, type: 'slide', target: `slides/slide${i + 1}.xml` })),
      { id: `rId${list.length + 2}`, type: 'theme', target: 'theme/theme1.xml' },
    ]),
  );
  zip.file('ppt/slideMasters/slideMaster1.xml', MASTER_XML);
  zip.file(
    'ppt/slideMasters/_rels/slideMaster1.xml.rels',
    rels([
      { id: 'rId1', type: 'slideLayout', target: '../slideLayouts/slideLayout1.xml' },
      { id: 'rId2', type: 'theme', target: '../theme/theme1.xml' },
    ]),
  );
  zip.file('ppt/slideLayouts/slideLayout1.xml', LAYOUT_XML);
  zip.file('ppt/slideLayouts/_rels/slideLayout1.xml.rels', rels([{ id: 'rId1', type: 'slideMaster', target: '../slideMasters/slideMaster1.xml' }]));
  zip.file('ppt/theme/theme1.xml', THEME_XML);
  list.forEach((s, i) => {
    zip.file(`ppt/slides/slide${i + 1}.xml`, slideXml(s));
    zip.file(`ppt/slides/_rels/slide${i + 1}.xml.rels`, rels([{ id: 'rId1', type: 'slideLayout', target: '../slideLayouts/slideLayout1.xml' }]));
  });
  return zip.generateAsync({ type: 'uint8array', compression: 'DEFLATE' });
}

// -------------------------------------------------------------------- read

interface ShapeText {
  role: 'title' | 'subtitle' | 'other';
  paras: string[];
}

function paragraphText(p: XmlNode): string {
  let out = '';
  for (const c of elements(p)) {
    if (c.name === 'a:r' || c.name === 'a:fld') {
      const t = child(c, 'a:t');
      if (t) out += textContent(t);
    } else if (c.name === 'a:br') out += ' ';
  }
  return out.trim();
}

function shapeParas(txBody: XmlNode | undefined): string[] {
  if (!txBody) return [];
  return elements(txBody)
    .filter((e) => e.name === 'a:p')
    .map(paragraphText)
    .filter((t) => t !== '');
}

function collectShapes(tree: XmlNode, out: ShapeText[], counters: { images: number }): void {
  for (const el of elements(tree)) {
    if (el.name === 'p:sp') {
      const ph = descendants(child(el, 'p:nvSpPr') ?? el, 'p:ph')[0];
      const type = attr(ph, 'type');
      if (type === 'dt' || type === 'ftr' || type === 'sldNum') continue;
      const paras = shapeParas(child(el, 'p:txBody'));
      if (!paras.length) continue;
      const name = (attr(child(child(el, 'p:nvSpPr') ?? el, 'p:cNvPr'), 'name') ?? '').toLowerCase();
      let role: ShapeText['role'] = 'other';
      if (type === 'title' || type === 'ctrTitle' || name === 'title') role = 'title';
      else if (type === 'subTitle' || name === 'subtitle') role = 'subtitle';
      out.push({ role, paras });
    } else if (el.name === 'p:graphicFrame') {
      const rows = descendants(el, 'a:tr');
      if (rows.length) {
        const paras = rows
          .map((tr) =>
            descendants(tr, 'a:tc')
              .map((tc) => shapeParas(child(tc, 'a:txBody')).join(' '))
              .join(' | '),
          )
          .filter((t) => t.replace(/\|/g, '').trim() !== '');
        if (paras.length) out.push({ role: 'other', paras });
      }
    } else if (el.name === 'p:grpSp') {
      collectShapes(el, out, counters);
    } else if (el.name === 'p:pic') {
      counters.images++;
    }
  }
}

export async function readPptx(bytes: Uint8Array): Promise<{ slides: Slide[]; notices: Notice[] }> {
  const zip = await JSZip.loadAsync(bytes);
  const presFile = zip.file('ppt/presentation.xml');
  if (!presFile) throw new Error('not_pptx');
  const pres = parseXml(await presFile.async('string'));

  // slide order comes from presentation.xml, not from file names
  let paths: string[] = [];
  const relsFile = zip.file('ppt/_rels/presentation.xml.rels');
  if (relsFile) {
    const relMap: Record<string, string> = {};
    for (const r of descendants(parseXml(await relsFile.async('string')), 'Relationship')) {
      const id = attr(r, 'Id');
      const target = attr(r, 'Target');
      if (id && target) relMap[id] = target.startsWith('/') ? target.slice(1) : 'ppt/' + target.replace(/^\.\//, '');
    }
    paths = descendants(pres, 'p:sldId')
      .map((s) => relMap[attr(s, 'r:id') ?? ''])
      .filter((p): p is string => !!p);
  }
  if (!paths.length) {
    paths = Object.keys(zip.files)
      .filter((n) => /^ppt\/slides\/slide\d+\.xml$/.test(n))
      .sort((a, b) => Number(/(\d+)\.xml$/.exec(a)![1]) - Number(/(\d+)\.xml$/.exec(b)![1]));
  }

  const slides: Slide[] = [];
  const counters = { images: 0 };
  for (const path of paths) {
    const f = zip.file(path);
    if (!f) continue;
    const root = parseXml(await f.async('string'));
    const tree = descendants(root, 'p:spTree')[0];
    const shapes: ShapeText[] = [];
    if (tree) collectShapes(tree, shapes, counters);

    let title = '';
    let subtitle = '';
    const bullets: string[] = [];
    const titleShape = shapes.find((s) => s.role === 'title');
    const rest = shapes.filter((s) => s !== titleShape);
    if (titleShape) title = titleShape.paras.join(' ');
    else if (rest.length) {
      const first = rest.shift()!;
      title = first.paras[0];
      bullets.push(...first.paras.slice(1));
    }
    for (const s of rest) {
      if (s.role === 'subtitle') subtitle = subtitle ? subtitle + ' ' + s.paras.join(' ') : s.paras.join(' ');
      else bullets.push(...s.paras);
    }
    slides.push({ title, subtitle, bullets, theme: 'navy' });
  }

  const notices: Notice[] = [];
  if (counters.images > 0) notices.push({ code: 'images_skipped', n: counters.images });
  if (slides.every((s) => s.title === '' && s.bullets.length === 0)) notices.push({ code: 'no_text_found' });
  return { slides, notices };
}
