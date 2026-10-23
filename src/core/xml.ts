// Minimal, forgiving XML reader for OOXML parts (docx/xlsx/pptx).
// Not a validating parser: it handles elements, attributes, text, CDATA,
// comments, processing instructions and the five predefined entities plus
// numeric character references.

export interface XmlNode {
  name: string; // qualified name, e.g. "w:p"; "#text" for text nodes; "#root" for the document
  attrs: Record<string, string>;
  children: XmlNode[];
  text: string; // only set for "#text" nodes
}

const ENTITIES: Record<string, string> = { amp: '&', lt: '<', gt: '>', quot: '"', apos: "'" };

export function decodeEntities(s: string): string {
  if (s.indexOf('&') === -1) return s;
  return s.replace(/&(#x[0-9a-fA-F]+|#[0-9]+|[a-zA-Z]+);/g, (m, g: string) => {
    if (g[0] === '#') {
      const cp = g[1] === 'x' || g[1] === 'X' ? parseInt(g.slice(2), 16) : parseInt(g.slice(1), 10);
      if (!Number.isFinite(cp) || cp < 0 || cp > 0x10ffff) return m;
      return cp > 0xffff
        ? String.fromCharCode(0xd800 + ((cp - 0x10000) >> 10), 0xdc00 + ((cp - 0x10000) & 0x3ff))
        : String.fromCharCode(cp);
    }
    return ENTITIES[g] ?? m;
  });
}

export function escapeXml(s: string): string {
  // Strip characters that are illegal in XML 1.0, then escape markup.
  // eslint-disable-next-line no-control-regex
  return s
    .replace(/[\u0000-\u0008\u000b\u000c\u000e-\u001f￾￿]/g, '')
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

const ATTR_RE = /([^\s=/>]+)\s*=\s*(?:"([^"]*)"|'([^']*)')/g;

export function parseXml(src: string): XmlNode {
  const root: XmlNode = { name: '#root', attrs: {}, children: [], text: '' };
  const stack: XmlNode[] = [root];
  const n = src.length;
  let i = 0;

  const top = () => stack[stack.length - 1];
  const pushText = (raw: string, decode: boolean) => {
    if (raw.length === 0) return;
    top().children.push({ name: '#text', attrs: {}, children: [], text: decode ? decodeEntities(raw) : raw });
  };

  while (i < n) {
    const lt = src.indexOf('<', i);
    if (lt === -1) {
      pushText(src.slice(i), true);
      break;
    }
    if (lt > i) pushText(src.slice(i, lt), true);

    if (src.startsWith('<!--', lt)) {
      const e = src.indexOf('-->', lt + 4);
      i = e === -1 ? n : e + 3;
      continue;
    }
    if (src.startsWith('<![CDATA[', lt)) {
      const e = src.indexOf(']]>', lt + 9);
      pushText(src.slice(lt + 9, e === -1 ? n : e), false);
      i = e === -1 ? n : e + 3;
      continue;
    }
    const next = src[lt + 1];
    if (next === '?') {
      const e = src.indexOf('?>', lt + 2);
      i = e === -1 ? n : e + 2;
      continue;
    }
    if (next === '!') {
      const e = src.indexOf('>', lt + 2);
      i = e === -1 ? n : e + 1;
      continue;
    }
    if (next === '/') {
      const e = src.indexOf('>', lt + 2);
      if (stack.length > 1) stack.pop();
      i = e === -1 ? n : e + 1;
      continue;
    }

    // start tag: find the closing '>' while respecting quoted attribute values
    let j = lt + 1;
    let quote = '';
    while (j < n) {
      const c = src[j];
      if (quote) {
        if (c === quote) quote = '';
      } else if (c === '"' || c === "'") quote = c;
      else if (c === '>') break;
      j++;
    }
    let inner = src.slice(lt + 1, j);
    const selfClose = inner.endsWith('/');
    if (selfClose) inner = inner.slice(0, -1);
    const nameMatch = /^[^\s/>]+/.exec(inner);
    const name = nameMatch ? nameMatch[0] : '';
    const attrs: Record<string, string> = {};
    ATTR_RE.lastIndex = 0;
    const rest = inner.slice(name.length);
    let m: RegExpExecArray | null;
    while ((m = ATTR_RE.exec(rest))) attrs[m[1]] = decodeEntities(m[2] ?? m[3] ?? '');
    const node: XmlNode = { name, attrs, children: [], text: '' };
    top().children.push(node);
    if (!selfClose) stack.push(node);
    i = j + 1;
  }
  return root;
}

/** Element children only (drops text nodes). */
export function elements(node: XmlNode): XmlNode[] {
  return node.children.filter((c) => c.name !== '#text');
}

/** First direct child with this qualified name. */
export function child(node: XmlNode, name: string): XmlNode | undefined {
  for (const c of node.children) if (c.name === name) return c;
  return undefined;
}

/** All direct children with this qualified name. */
export function childrenNamed(node: XmlNode, name: string): XmlNode[] {
  return node.children.filter((c) => c.name === name);
}

/** All descendants (depth-first, document order) with this qualified name. */
export function descendants(node: XmlNode, name: string, out: XmlNode[] = []): XmlNode[] {
  for (const c of node.children) {
    if (c.name === name) out.push(c);
    if (c.children.length) descendants(c, name, out);
  }
  return out;
}

/** Concatenated text of a node and all of its descendants. */
export function textContent(node: XmlNode): string {
  if (node.name === '#text') return node.text;
  let s = '';
  for (const c of node.children) s += textContent(c);
  return s;
}

/** Attribute lookup that tolerates a missing prefix, e.g. attr(n, 'w:val'). */
export function attr(node: XmlNode | undefined, name: string): string | undefined {
  if (!node) return undefined;
  if (name in node.attrs) return node.attrs[name];
  const local = name.includes(':') ? name.split(':')[1] : name;
  for (const k of Object.keys(node.attrs)) {
    if (k === local || k.endsWith(':' + local)) return node.attrs[k];
  }
  return undefined;
}
