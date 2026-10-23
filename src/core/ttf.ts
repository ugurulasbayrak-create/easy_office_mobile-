// Minimal TrueType (glyf-flavoured) font reader and subsetter.
// Used to embed a Unicode font in generated PDFs so Turkish (and any other
// script the font covers) renders correctly. Glyph ids are kept stable when
// subsetting, which lets the PDF use an Identity CIDToGIDMap.

export interface TtfFont {
  data: Uint8Array;
  unitsPerEm: number;
  ascent: number;
  descent: number;
  bbox: [number, number, number, number];
  numGlyphs: number;
  numHMetrics: number;
  locaFormat: number;
  tables: Record<string, { offset: number; length: number }>;
  advance(gid: number): number;
  glyphForCodePoint(cp: number): number;
}

function u16(d: DataView, o: number): number {
  return d.getUint16(o, false);
}
function i16(d: DataView, o: number): number {
  return d.getInt16(o, false);
}
function u32(d: DataView, o: number): number {
  return d.getUint32(o, false);
}

export function parseTtf(data: Uint8Array): TtfFont {
  const dv = new DataView(data.buffer, data.byteOffset, data.byteLength);
  const sfnt = u32(dv, 0);
  if (sfnt !== 0x00010000 && sfnt !== 0x74727565 /* 'true' */) throw new Error('unsupported_font');
  const numTables = u16(dv, 4);
  const tables: Record<string, { offset: number; length: number }> = {};
  for (let i = 0; i < numTables; i++) {
    const rec = 12 + i * 16;
    const tag = String.fromCharCode(data[rec], data[rec + 1], data[rec + 2], data[rec + 3]);
    tables[tag] = { offset: u32(dv, rec + 8), length: u32(dv, rec + 12) };
  }
  for (const need of ['head', 'hhea', 'hmtx', 'maxp', 'cmap', 'loca', 'glyf']) {
    if (!tables[need]) throw new Error('unsupported_font');
  }
  const head = tables.head.offset;
  const hhea = tables.hhea.offset;
  const unitsPerEm = u16(dv, head + 18);
  const bbox: [number, number, number, number] = [i16(dv, head + 36), i16(dv, head + 38), i16(dv, head + 40), i16(dv, head + 42)];
  const locaFormat = i16(dv, head + 50);
  const ascent = i16(dv, hhea + 4);
  const descent = i16(dv, hhea + 6);
  const numHMetrics = u16(dv, hhea + 34);
  const numGlyphs = u16(dv, tables.maxp.offset + 4);
  const hmtx = tables.hmtx.offset;

  // pick the best Unicode cmap subtable
  const cmapOff = tables.cmap.offset;
  const nSub = u16(dv, cmapOff + 2);
  let best = -1;
  let bestScore = -1;
  for (let i = 0; i < nSub; i++) {
    const platform = u16(dv, cmapOff + 4 + i * 8);
    const enc = u16(dv, cmapOff + 6 + i * 8);
    const off = cmapOff + u32(dv, cmapOff + 8 + i * 8);
    const fmt = u16(dv, off);
    let score = -1;
    if (platform === 3 && enc === 10 && fmt === 12) score = 4;
    else if (platform === 0 && fmt === 12) score = 3;
    else if (platform === 3 && enc === 1 && fmt === 4) score = 2;
    else if (platform === 0 && fmt === 4) score = 1;
    if (score > bestScore) {
      bestScore = score;
      best = off;
    }
  }
  if (best < 0) throw new Error('unsupported_font');
  const cmapFmt = u16(dv, best);
  const cache = new Map<number, number>();

  const lookup4 = (cp: number): number => {
    if (cp > 0xffff) return 0;
    const segX2 = u16(dv, best + 6);
    const segs = segX2 / 2;
    const endBase = best + 14;
    const startBase = endBase + segX2 + 2;
    const deltaBase = startBase + segX2;
    const rangeBase = deltaBase + segX2;
    let lo = 0;
    let hi = segs - 1;
    while (lo <= hi) {
      const mid = (lo + hi) >> 1;
      const end = u16(dv, endBase + mid * 2);
      if (cp > end) lo = mid + 1;
      else {
        const start = u16(dv, startBase + mid * 2);
        if (cp < start) hi = mid - 1;
        else {
          const delta = u16(dv, deltaBase + mid * 2);
          const rangeOffset = u16(dv, rangeBase + mid * 2);
          if (rangeOffset === 0) return (cp + delta) & 0xffff;
          const g = u16(dv, rangeBase + mid * 2 + rangeOffset + (cp - start) * 2);
          return g === 0 ? 0 : (g + delta) & 0xffff;
        }
      }
    }
    return 0;
  };
  const lookup12 = (cp: number): number => {
    const nGroups = u32(dv, best + 12);
    let lo = 0;
    let hi = nGroups - 1;
    while (lo <= hi) {
      const mid = (lo + hi) >> 1;
      const g = best + 16 + mid * 12;
      const start = u32(dv, g);
      const end = u32(dv, g + 4);
      if (cp < start) hi = mid - 1;
      else if (cp > end) lo = mid + 1;
      else return u32(dv, g + 8) + (cp - start);
    }
    return 0;
  };

  return {
    data,
    unitsPerEm,
    ascent,
    descent,
    bbox,
    numGlyphs,
    numHMetrics,
    locaFormat,
    tables,
    advance(gid: number): number {
      const g = gid < numHMetrics ? gid : numHMetrics - 1;
      return u16(dv, hmtx + g * 4);
    },
    glyphForCodePoint(cp: number): number {
      const hit = cache.get(cp);
      if (hit !== undefined) return hit;
      const gid = cmapFmt === 12 ? lookup12(cp) : lookup4(cp);
      cache.set(cp, gid);
      return gid;
    },
  };
}

// ---------------------------------------------------------------- subsetting

function checksum(bytes: Uint8Array): number {
  let sum = 0;
  const n = bytes.length;
  for (let i = 0; i < n; i += 4) {
    const w =
      ((bytes[i] << 24) | ((bytes[i + 1] ?? 0) << 16) | ((bytes[i + 2] ?? 0) << 8) | (bytes[i + 3] ?? 0)) >>> 0;
    sum = (sum + w) >>> 0;
  }
  return sum;
}

function put16(a: Uint8Array, o: number, v: number): void {
  a[o] = (v >> 8) & 255;
  a[o + 1] = v & 255;
}
function put32(a: Uint8Array, o: number, v: number): void {
  a[o] = (v >>> 24) & 255;
  a[o + 1] = (v >>> 16) & 255;
  a[o + 2] = (v >>> 8) & 255;
  a[o + 3] = v & 255;
}

function assembleFont(tables: Record<string, Uint8Array>): Uint8Array {
  const tags = Object.keys(tables).sort();
  const n = tags.length;
  let entrySelector = 0;
  while (1 << (entrySelector + 1) <= n) entrySelector++;
  const searchRange = 16 * (1 << entrySelector);
  const headerLen = 12 + n * 16;
  let total = headerLen;
  const offsets: number[] = [];
  for (const t of tags) {
    offsets.push(total);
    total += (tables[t].length + 3) & ~3;
  }
  const out = new Uint8Array(total);
  put32(out, 0, 0x00010000);
  put16(out, 4, n);
  put16(out, 6, searchRange);
  put16(out, 8, entrySelector);
  put16(out, 10, n * 16 - searchRange);
  tags.forEach((t, i) => {
    const rec = 12 + i * 16;
    for (let k = 0; k < 4; k++) out[rec + k] = t.charCodeAt(k);
    put32(out, rec + 4, checksum(tables[t]));
    put32(out, rec + 8, offsets[i]);
    put32(out, rec + 12, tables[t].length);
    out.set(tables[t], offsets[i]);
  });
  // whole-font checksum adjustment lives in head (checksum was computed with it zeroed)
  const headIdx = tags.indexOf('head');
  if (headIdx >= 0) {
    const adj = (0xb1b0afba - checksum(out)) >>> 0;
    put32(out, offsets[headIdx] + 8, adj);
  }
  return out;
}

function glyphRange(font: TtfFont, dv: DataView, gid: number): [number, number] {
  const loca = font.tables.loca.offset;
  if (font.locaFormat === 0) return [u16(dv, loca + gid * 2) * 2, u16(dv, loca + gid * 2 + 2) * 2];
  return [u32(dv, loca + gid * 4), u32(dv, loca + gid * 4 + 4)];
}

/** Add the component glyphs of composite glyphs to the set. */
function closeOverComposites(font: TtfFont, dv: DataView, gids: Set<number>): void {
  const glyf = font.tables.glyf.offset;
  const queue = [...gids];
  while (queue.length) {
    const gid = queue.pop()!;
    if (gid >= font.numGlyphs) continue;
    const [s, e] = glyphRange(font, dv, gid);
    if (e - s < 10) continue;
    if (i16(dv, glyf + s) >= 0) continue; // simple glyph
    let p = glyf + s + 10;
    for (;;) {
      const flags = u16(dv, p);
      const comp = u16(dv, p + 2);
      if (!gids.has(comp)) {
        gids.add(comp);
        queue.push(comp);
      }
      p += 4 + (flags & 0x0001 ? 4 : 2);
      if (flags & 0x0008) p += 2;
      else if (flags & 0x0040) p += 4;
      else if (flags & 0x0080) p += 8;
      if (!(flags & 0x0020)) break;
    }
  }
}

function minimalCmap(map: Map<number, number>): Uint8Array {
  const entries = [...map.entries()].filter(([cp]) => cp > 0 && cp < 0xffff).sort((a, b) => a[0] - b[0]);
  const segCount = entries.length + 1;
  const subLen = 16 + segCount * 8;
  const out = new Uint8Array(12 + subLen);
  put16(out, 0, 0);
  put16(out, 2, 1);
  put16(out, 4, 3);
  put16(out, 6, 1);
  put32(out, 8, 12);
  const s = 12;
  put16(out, s, 4);
  put16(out, s + 2, subLen);
  put16(out, s + 4, 0);
  put16(out, s + 6, segCount * 2);
  let es = 0;
  while (1 << (es + 1) <= segCount) es++;
  const sr = 2 * (1 << es);
  put16(out, s + 8, sr);
  put16(out, s + 10, es);
  put16(out, s + 12, segCount * 2 - sr);
  const endBase = s + 14;
  const startBase = endBase + segCount * 2 + 2;
  const deltaBase = startBase + segCount * 2;
  const rangeBase = deltaBase + segCount * 2;
  entries.forEach(([cp, gid], i) => {
    put16(out, endBase + i * 2, cp);
    put16(out, startBase + i * 2, cp);
    put16(out, deltaBase + i * 2, (gid - cp) & 0xffff);
    put16(out, rangeBase + i * 2, 0);
  });
  const last = entries.length;
  put16(out, endBase + last * 2, 0xffff);
  put16(out, startBase + last * 2, 0xffff);
  put16(out, deltaBase + last * 2, 1);
  put16(out, rangeBase + last * 2, 0);
  return out;
}

/**
 * Build a subset of `font` that keeps only the glyphs used by `usage`
 * (code point -> glyph id). Glyph ids are preserved.
 */
export function subsetTtf(font: TtfFont, usage: Map<number, number>): Uint8Array {
  const dv = new DataView(font.data.buffer, font.data.byteOffset, font.data.byteLength);
  const gids = new Set<number>([0]);
  for (const g of usage.values()) gids.add(g);
  closeOverComposites(font, dv, gids);

  const glyf = font.tables.glyf.offset;
  const chunks: Uint8Array[] = [];
  const newLoca = new Uint8Array((font.numGlyphs + 1) * 4);
  let pos = 0;
  for (let g = 0; g < font.numGlyphs; g++) {
    put32(newLoca, g * 4, pos);
    if (gids.has(g)) {
      const [s, e] = glyphRange(font, dv, g);
      if (e > s) {
        const len = e - s;
        const padded = (len + 3) & ~3;
        const chunk = new Uint8Array(padded);
        chunk.set(font.data.subarray(glyf + s, glyf + e));
        chunks.push(chunk);
        pos += padded;
      }
    }
  }
  put32(newLoca, font.numGlyphs * 4, pos);
  const newGlyf = new Uint8Array(pos);
  let o = 0;
  for (const c of chunks) {
    newGlyf.set(c, o);
    o += c.length;
  }

  const slice = (tag: string): Uint8Array | null => {
    const t = font.tables[tag];
    return t ? font.data.slice(t.offset, t.offset + t.length) : null;
  };
  const head = slice('head')!;
  put32(head, 8, 0); // checksum adjustment recomputed on assembly
  put16(head, 50, 1); // long loca offsets

  const post = new Uint8Array(32);
  put32(post, 0, 0x00030000);

  const tables: Record<string, Uint8Array> = {
    head,
    hhea: slice('hhea')!,
    maxp: slice('maxp')!,
    hmtx: slice('hmtx')!,
    loca: newLoca,
    glyf: newGlyf,
    cmap: minimalCmap(usage),
    post,
  };
  for (const optional of ['cvt ', 'fpgm', 'prep']) {
    const t = slice(optional);
    if (t) tables[optional] = t;
  }
  return assembleFont(tables);
}
