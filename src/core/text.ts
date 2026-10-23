// Text/bytes helpers that do not depend on TextEncoder/TextDecoder
// (older Hermes builds do not ship TextDecoder).

export function utf8Encode(str: string): Uint8Array {
  const out: number[] = [];
  for (let i = 0; i < str.length; i++) {
    let cp = str.charCodeAt(i);
    if (cp >= 0xd800 && cp <= 0xdbff && i + 1 < str.length) {
      const lo = str.charCodeAt(i + 1);
      if (lo >= 0xdc00 && lo <= 0xdfff) {
        cp = 0x10000 + ((cp - 0xd800) << 10) + (lo - 0xdc00);
        i++;
      }
    }
    if (cp < 0x80) out.push(cp);
    else if (cp < 0x800) out.push(0xc0 | (cp >> 6), 0x80 | (cp & 63));
    else if (cp < 0x10000) out.push(0xe0 | (cp >> 12), 0x80 | ((cp >> 6) & 63), 0x80 | (cp & 63));
    else out.push(0xf0 | (cp >> 18), 0x80 | ((cp >> 12) & 63), 0x80 | ((cp >> 6) & 63), 0x80 | (cp & 63));
  }
  return Uint8Array.from(out);
}

/** Strict UTF-8 decode. Returns null when the bytes are not valid UTF-8. */
export function utf8DecodeStrict(bytes: Uint8Array): string | null {
  let out = '';
  let i = 0;
  const n = bytes.length;
  while (i < n) {
    const b = bytes[i];
    let cp: number;
    let extra: number;
    if (b < 0x80) { cp = b; extra = 0; }
    else if (b >= 0xc2 && b <= 0xdf) { cp = b & 0x1f; extra = 1; }
    else if (b >= 0xe0 && b <= 0xef) { cp = b & 0x0f; extra = 2; }
    else if (b >= 0xf0 && b <= 0xf4) { cp = b & 0x07; extra = 3; }
    else return null;
    if (i + extra >= n && extra > 0) return null;
    for (let k = 1; k <= extra; k++) {
      const c = bytes[i + k];
      if (c === undefined || (c & 0xc0) !== 0x80) return null;
      cp = (cp << 6) | (c & 63);
    }
    if (extra === 2 && (cp < 0x800 || (cp >= 0xd800 && cp <= 0xdfff))) return null;
    if (extra === 3 && (cp < 0x10000 || cp > 0x10ffff)) return null;
    out += cp > 0xffff
      ? String.fromCharCode(0xd800 + ((cp - 0x10000) >> 10), 0xdc00 + ((cp - 0x10000) & 0x3ff))
      : String.fromCharCode(cp);
    i += extra + 1;
  }
  return out;
}

// Windows-1254 (Turkish ANSI) differs from Latin-1 in these positions.
const CP1254: Record<number, number> = {
  0x80: 0x20ac, 0x82: 0x201a, 0x83: 0x0192, 0x84: 0x201e, 0x85: 0x2026, 0x86: 0x2020,
  0x87: 0x2021, 0x88: 0x02c6, 0x89: 0x2030, 0x8a: 0x0160, 0x8b: 0x2039, 0x8c: 0x0152,
  0x91: 0x2018, 0x92: 0x2019, 0x93: 0x201c, 0x94: 0x201d, 0x95: 0x2022, 0x96: 0x2013,
  0x97: 0x2014, 0x98: 0x02dc, 0x99: 0x2122, 0x9a: 0x0161, 0x9b: 0x203a, 0x9c: 0x0153,
  0x9f: 0x0178, 0xd0: 0x011e, 0xdd: 0x0130, 0xde: 0x015e, 0xf0: 0x011f, 0xfd: 0x0131,
  0xfe: 0x015f,
};

export function cp1254Decode(bytes: Uint8Array): string {
  let out = '';
  for (let i = 0; i < bytes.length; i++) {
    const b = bytes[i];
    out += String.fromCharCode(CP1254[b] ?? b);
  }
  return out;
}

function utf16Decode(bytes: Uint8Array, littleEndian: boolean): string {
  let out = '';
  for (let i = 0; i + 1 < bytes.length; i += 2) {
    out += String.fromCharCode(littleEndian ? bytes[i] | (bytes[i + 1] << 8) : (bytes[i] << 8) | bytes[i + 1]);
  }
  return out;
}

/**
 * Decode a text file of unknown encoding: BOMs first, then strict UTF-8,
 * then Windows-1254 (the usual encoding of Turkish legacy files).
 */
export function decodeText(bytes: Uint8Array): string {
  if (bytes.length >= 3 && bytes[0] === 0xef && bytes[1] === 0xbb && bytes[2] === 0xbf) {
    return utf8DecodeStrict(bytes.subarray(3)) ?? cp1254Decode(bytes.subarray(3));
  }
  if (bytes.length >= 2 && bytes[0] === 0xff && bytes[1] === 0xfe) return utf16Decode(bytes.subarray(2), true);
  if (bytes.length >= 2 && bytes[0] === 0xfe && bytes[1] === 0xff) return utf16Decode(bytes.subarray(2), false);
  return utf8DecodeStrict(bytes) ?? cp1254Decode(bytes);
}

/** File name helpers */
export function baseName(fileName: string): string {
  const last = fileName.split(/[\\/]/).pop() ?? fileName;
  const dot = last.lastIndexOf('.');
  return dot > 0 ? last.slice(0, dot) : last;
}

export function extOf(fileName: string): string {
  const last = fileName.split(/[\\/]/).pop() ?? fileName;
  const dot = last.lastIndexOf('.');
  return dot > 0 ? last.slice(dot + 1).toLowerCase() : '';
}
