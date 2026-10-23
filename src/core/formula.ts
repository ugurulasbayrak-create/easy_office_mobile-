// A small but real spreadsheet formula engine.
//
// Supported: numbers, "strings", TRUE/FALSE, cell references (A1, $A$1),
// ranges (A1:B9), + - * / ^ & % unary +/-, comparisons (= <> < > <= >=),
// parentheses, and the functions listed in SUPPORTED_FUNCTIONS.
// Both "," and ";" are accepted as argument separators.
//
// Errors follow spreadsheet conventions: #DIV/0!, #VALUE!, #NAME?, #REF!,
// #NUM!, #CYCLE! (circular reference) and #ERROR! (syntax error).

import type { Grid } from './types.ts';
import { colIndex, colName, formatNumber, parseNumber, parseRef, refOf } from './sheet.ts';

export interface CellErr {
  err: string;
}
export type Value = number | string | boolean | null | CellErr;

export function isErr(v: unknown): v is CellErr {
  return typeof v === 'object' && v !== null && 'err' in (v as object);
}
const E = (err: string): CellErr => ({ err });

// ---------------------------------------------------------------- tokenizer

type Tok =
  | { t: 'num'; v: number }
  | { t: 'str'; v: string }
  | { t: 'id'; v: string; call: boolean }
  | { t: 'ref'; col: number; row: number }
  | { t: 'op'; v: string }
  | { t: '(' }
  | { t: ')' }
  | { t: ',' }
  | { t: '%' }
  | { t: 'bad'; v: string };

const REF_FULL = /^\$?([A-Za-z]{1,3})\$?([0-9]+)$/;
const NUM_RE = /(?:\d+\.?\d*|\.\d+)(?:[eE][+-]?\d+)?/y;

function tokenize(src: string): Tok[] {
  const toks: Tok[] = [];
  let i = 0;
  const n = src.length;
  while (i < n) {
    const c = src[i];
    if (c === ' ' || c === '\t' || c === '\n' || c === '\r') {
      i++;
      continue;
    }
    if ((c >= '0' && c <= '9') || (c === '.' && src[i + 1] >= '0' && src[i + 1] <= '9')) {
      NUM_RE.lastIndex = i;
      const m = NUM_RE.exec(src);
      if (m) {
        toks.push({ t: 'num', v: Number(m[0]) });
        i += m[0].length;
        continue;
      }
    }
    if (c === '"') {
      let s = '';
      i++;
      let closed = false;
      while (i < n) {
        if (src[i] === '"') {
          if (src[i + 1] === '"') {
            s += '"';
            i += 2;
            continue;
          }
          closed = true;
          i++;
          break;
        }
        s += src[i++];
      }
      toks.push(closed ? { t: 'str', v: s } : { t: 'bad', v: '"' });
      continue;
    }
    if (c === '$' || c === '_' || (c >= 'A' && c <= 'Z') || (c >= 'a' && c <= 'z')) {
      let j = i;
      while (j < n && /[A-Za-z0-9_.$]/.test(src[j])) j++;
      const span = src.slice(i, j);
      let k = j;
      while (k < n && src[k] === ' ') k++;
      const next = src[k];
      i = j;
      if (next === '(') {
        toks.push({ t: 'id', v: span.toUpperCase(), call: true });
      } else if (next === '!') {
        toks.push({ t: 'bad', v: span + '!' }); // cross-sheet references are not supported
        i = k + 1;
      } else {
        const m = REF_FULL.exec(span);
        if (m) {
          const row = parseInt(m[2], 10) - 1;
          if (row < 0) toks.push({ t: 'bad', v: span });
          else toks.push({ t: 'ref', col: colIndex(m[1]), row });
        } else {
          toks.push({ t: 'id', v: span.toUpperCase(), call: false });
        }
      }
      continue;
    }
    const two = src.slice(i, i + 2);
    if (two === '<=' || two === '>=' || two === '<>') {
      toks.push({ t: 'op', v: two });
      i += 2;
      continue;
    }
    if ('+-*/^&=<>:'.includes(c)) {
      toks.push({ t: 'op', v: c });
      i++;
      continue;
    }
    if (c === '(') toks.push({ t: '(' });
    else if (c === ')') toks.push({ t: ')' });
    else if (c === ',' || c === ';') toks.push({ t: ',' });
    else if (c === '%') toks.push({ t: '%' });
    else toks.push({ t: 'bad', v: c });
    i++;
  }
  return toks;
}

// ------------------------------------------------------------------- parser

type Node =
  | { k: 'num'; v: number }
  | { k: 'str'; v: string }
  | { k: 'bool'; v: boolean }
  | { k: 'ref'; col: number; row: number }
  | { k: 'range'; c1: number; r1: number; c2: number; r2: number }
  | { k: 'un'; op: string; a: Node }
  | { k: 'pct'; a: Node }
  | { k: 'bin'; op: string; a: Node; b: Node }
  | { k: 'call'; name: string; args: Node[] }
  | { k: 'name'; v: string }
  | { k: 'err'; e: string };

class SyntaxErr extends Error {}

class Parser {
  toks: Tok[];
  p = 0;
  constructor(toks: Tok[]) {
    this.toks = toks;
  }
  peek(): Tok | undefined {
    return this.toks[this.p];
  }
  isOp(v: string): boolean {
    const t = this.peek();
    return !!t && t.t === 'op' && t.v === v;
  }

  parseAll(): Node {
    const node = this.comparison();
    if (this.p < this.toks.length) throw new SyntaxErr('trailing tokens');
    return node;
  }

  comparison(): Node {
    let left = this.concat();
    for (;;) {
      const t = this.peek();
      if (t && t.t === 'op' && ['=', '<>', '<', '>', '<=', '>='].includes(t.v)) {
        this.p++;
        left = { k: 'bin', op: t.v, a: left, b: this.concat() };
      } else return left;
    }
  }
  concat(): Node {
    let left = this.additive();
    while (this.isOp('&')) {
      this.p++;
      left = { k: 'bin', op: '&', a: left, b: this.additive() };
    }
    return left;
  }
  additive(): Node {
    let left = this.term();
    for (;;) {
      const t = this.peek();
      if (t && t.t === 'op' && (t.v === '+' || t.v === '-')) {
        this.p++;
        left = { k: 'bin', op: t.v, a: left, b: this.term() };
      } else return left;
    }
  }
  term(): Node {
    let left = this.power();
    for (;;) {
      const t = this.peek();
      if (t && t.t === 'op' && (t.v === '*' || t.v === '/')) {
        this.p++;
        left = { k: 'bin', op: t.v, a: left, b: this.power() };
      } else return left;
    }
  }
  power(): Node {
    // Like Excel: ^ is left-associative and binds weaker than unary minus.
    let left = this.unary();
    while (this.isOp('^')) {
      this.p++;
      left = { k: 'bin', op: '^', a: left, b: this.unary() };
    }
    return left;
  }
  unary(): Node {
    const t = this.peek();
    if (t && t.t === 'op' && (t.v === '-' || t.v === '+')) {
      this.p++;
      return { k: 'un', op: t.v, a: this.unary() };
    }
    return this.postfix();
  }
  postfix(): Node {
    let node = this.primary();
    while (this.peek()?.t === '%') {
      this.p++;
      node = { k: 'pct', a: node };
    }
    return node;
  }
  primary(): Node {
    const t = this.peek();
    if (!t) throw new SyntaxErr('unexpected end');
    this.p++;
    switch (t.t) {
      case 'num':
        return { k: 'num', v: t.v };
      case 'str':
        return { k: 'str', v: t.v };
      case 'ref': {
        if (this.isOp(':')) {
          const save = this.p;
          this.p++;
          const t2 = this.peek();
          if (t2 && t2.t === 'ref') {
            this.p++;
            return {
              k: 'range',
              c1: Math.min(t.col, t2.col),
              r1: Math.min(t.row, t2.row),
              c2: Math.max(t.col, t2.col),
              r2: Math.max(t.row, t2.row),
            };
          }
          this.p = save;
          throw new SyntaxErr('bad range');
        }
        return { k: 'ref', col: t.col, row: t.row };
      }
      case 'id': {
        if (t.call) {
          if (this.peek()?.t !== '(') throw new SyntaxErr('expected (');
          this.p++;
          const args: Node[] = [];
          if (this.peek()?.t === ')') {
            this.p++;
            return { k: 'call', name: t.v, args };
          }
          for (;;) {
            // allow empty arguments such as IF(A1,,2)
            if (this.peek()?.t === ',' || this.peek()?.t === ')') args.push({ k: 'err', e: '' });
            else args.push(this.comparison());
            const sep = this.peek();
            if (sep?.t === ',') {
              this.p++;
              continue;
            }
            if (sep?.t === ')') {
              this.p++;
              break;
            }
            throw new SyntaxErr('expected , or )');
          }
          return { k: 'call', name: t.v, args };
        }
        if (t.v === 'TRUE') return { k: 'bool', v: true };
        if (t.v === 'FALSE') return { k: 'bool', v: false };
        return { k: 'name', v: t.v };
      }
      case '(': {
        const inner = this.comparison();
        if (this.peek()?.t !== ')') throw new SyntaxErr('expected )');
        this.p++;
        return inner;
      }
      case 'bad':
        if (t.v.endsWith('!')) {
          // Cross-sheet reference: swallow the reference (or range) that follows.
          if (this.peek()?.t === 'ref') {
            this.p++;
            if (this.isOp(':') && this.toks[this.p + 1]?.t === 'ref') this.p += 2;
          }
          return { k: 'err', e: '#REF!' };
        }
        throw new SyntaxErr('bad token');
      default:
        throw new SyntaxErr('unexpected token');
    }
  }
}

// ---------------------------------------------------------------- evaluator

type Matrix = Value[][];
const MAX_RANGE_CELLS = 250_000;

export function isFormula(raw: string): boolean {
  return raw.length > 1 && raw[0] === '=';
}

function literal(raw: string): Value {
  if (raw === '') return null;
  if (raw[0] === "'") return raw.slice(1);
  const n = parseNumber(raw);
  if (n !== null) return n;
  const up = raw.toUpperCase();
  if (up === 'TRUE') return true;
  if (up === 'FALSE') return false;
  return raw;
}

function toNum(v: Value): number | CellErr {
  if (isErr(v)) return v;
  if (v === null) return 0;
  if (typeof v === 'boolean') return v ? 1 : 0;
  if (typeof v === 'number') return v;
  const n = parseNumber(v);
  return n === null ? E('#VALUE!') : n;
}

function toStr(v: Value): string | CellErr {
  if (isErr(v)) return v;
  if (v === null) return '';
  if (typeof v === 'boolean') return v ? 'TRUE' : 'FALSE';
  if (typeof v === 'number') return formatNumber(v);
  return v;
}

function toBool(v: Value): boolean | CellErr {
  if (isErr(v)) return v;
  if (v === null) return false;
  if (typeof v === 'boolean') return v;
  if (typeof v === 'number') return v !== 0;
  const up = v.toUpperCase();
  if (up === 'TRUE') return true;
  if (up === 'FALSE') return false;
  return E('#VALUE!');
}

function rank(v: Value): number {
  if (typeof v === 'number') return 1;
  if (typeof v === 'string') return 2;
  return 3;
}

function compareValues(a: Value, b: Value): number {
  let x = a;
  let y = b;
  if (x === null) x = typeof y === 'string' ? '' : typeof y === 'boolean' ? false : 0;
  if (y === null) y = typeof x === 'string' ? '' : typeof x === 'boolean' ? false : 0;
  const ra = rank(x);
  const rb = rank(y);
  if (ra !== rb) return ra < rb ? -1 : 1;
  if (typeof x === 'string' && typeof y === 'string') {
    const lx = x.toLowerCase();
    const ly = y.toLowerCase();
    return lx < ly ? -1 : lx > ly ? 1 : 0;
  }
  const nx = Number(x);
  const ny = Number(y);
  return nx < ny ? -1 : nx > ny ? 1 : 0;
}

function roundTo(x: number, digits: number, mode: 'half' | 'up' | 'down'): number {
  const f = Math.pow(10, digits);
  const abs = Math.abs(x);
  // shift via string exponent to dodge binary floating-point artefacts (1.005 -> 1.01)
  const shifted = Number(abs + 'e' + digits);
  const scaled = Number.isFinite(shifted) && !/e/i.test(String(abs)) ? shifted : abs * f;
  let r: number;
  if (mode === 'half') r = Math.round(scaled);
  else if (mode === 'up') r = Math.ceil(scaled - 1e-9);
  else r = Math.floor(scaled + 1e-9);
  const back = !/e/i.test(String(r)) ? Number(r + 'e' + -digits) : r / f;
  return Math.sign(x) * back;
}

function criteriaMatcher(crit: Value): (v: Value) => boolean {
  if (typeof crit === 'string') {
    const m = /^(>=|<=|<>|>|<|=)?(.*)$/s.exec(crit);
    const op = m?.[1] ?? '=';
    const rhsRaw = m?.[2] ?? '';
    const rhsNum = parseNumber(rhsRaw);
    return (v) => {
      if (isErr(v)) return false;
      if (rhsNum !== null) {
        if (typeof v !== 'number') {
          if (op === '<>') return true;
          return false;
        }
        switch (op) {
          case '=': return v === rhsNum;
          case '<>': return v !== rhsNum;
          case '>': return v > rhsNum;
          case '<': return v < rhsNum;
          case '>=': return v >= rhsNum;
          default: return v <= rhsNum;
        }
      }
      const text = v === null ? '' : String(toStr(v)).toLowerCase();
      const rhs = rhsRaw.toLowerCase();
      if (op === '=' || op === '<>') {
        let eq: boolean;
        if (rhs.includes('*') || rhs.includes('?')) {
          const re = new RegExp('^' + rhs.replace(/[.+^${}()|[\]\\]/g, '\\$&').replace(/\*/g, '.*').replace(/\?/g, '.') + '$', 's');
          eq = re.test(text);
        } else eq = text === rhs;
        return op === '=' ? eq : !eq;
      }
      if (typeof v !== 'string') return false;
      switch (op) {
        case '>': return text > rhs;
        case '<': return text < rhs;
        case '>=': return text >= rhs;
        default: return text <= rhs;
      }
    };
  }
  return (v) => !isErr(v) && v !== null && compareValues(v, crit) === 0;
}

type FnImpl = (args: Node[], ev: Evaluator) => Value;

function numArgs(args: Node[], ev: Evaluator): number[] | CellErr {
  const out: number[] = [];
  for (const a of args) {
    if (a.k === 'range' || a.k === 'ref') {
      const m = ev.matrix(a);
      if (isErr(m)) return m;
      for (const row of m) {
        for (const v of row) {
          if (isErr(v)) return v;
          if (typeof v === 'number') out.push(v);
        }
      }
    } else if (a.k === 'err' && a.e === '') {
      continue;
    } else {
      const v = ev.scalar(a);
      if (isErr(v)) return v;
      if (v === null) continue;
      const n = toNum(v);
      if (isErr(n)) return n;
      out.push(n);
    }
  }
  return out;
}

function allValues(args: Node[], ev: Evaluator): Value[] {
  const out: Value[] = [];
  for (const a of args) {
    if (a.k === 'range' || a.k === 'ref') {
      const m = ev.matrix(a);
      if (isErr(m)) {
        out.push(m);
        continue;
      }
      for (const row of m) for (const v of row) out.push(v);
    } else out.push(ev.scalar(a));
  }
  return out;
}

function need(args: Node[], min: number, max: number): boolean {
  return args.length >= min && args.length <= max;
}

function one(args: Node[], ev: Evaluator, fn: (n: number) => number | CellErr): Value {
  if (!need(args, 1, 1)) return E('#VALUE!');
  const n = toNum(ev.scalar(args[0]));
  if (isErr(n)) return n;
  const r = fn(n);
  if (typeof r === 'number' && !Number.isFinite(r)) return E('#NUM!');
  return r;
}

const FUNCS: Record<string, FnImpl> = {
  SUM(args, ev) {
    const nums = numArgs(args, ev);
    if (isErr(nums)) return nums;
    let s = 0;
    for (const n of nums) s += n;
    return s;
  },
  AVERAGE(args, ev) {
    const nums = numArgs(args, ev);
    if (isErr(nums)) return nums;
    if (nums.length === 0) return E('#DIV/0!');
    let s = 0;
    for (const n of nums) s += n;
    return s / nums.length;
  },
  MIN(args, ev) {
    const nums = numArgs(args, ev);
    if (isErr(nums)) return nums;
    return nums.length ? Math.min(...nums) : 0;
  },
  MAX(args, ev) {
    const nums = numArgs(args, ev);
    if (isErr(nums)) return nums;
    return nums.length ? Math.max(...nums) : 0;
  },
  PRODUCT(args, ev) {
    const nums = numArgs(args, ev);
    if (isErr(nums)) return nums;
    return nums.length ? nums.reduce((a, b) => a * b, 1) : 0;
  },
  MEDIAN(args, ev) {
    const nums = numArgs(args, ev);
    if (isErr(nums)) return nums;
    if (!nums.length) return E('#NUM!');
    const s = [...nums].sort((a, b) => a - b);
    const mid = Math.floor(s.length / 2);
    return s.length % 2 ? s[mid] : (s[mid - 1] + s[mid]) / 2;
  },
  COUNT(args, ev) {
    let c = 0;
    for (const v of allValues(args, ev)) if (typeof v === 'number') c++;
    return c;
  },
  COUNTA(args, ev) {
    let c = 0;
    for (const v of allValues(args, ev)) if (v !== null) c++;
    return c;
  },
  IF(args, ev) {
    if (!need(args, 2, 3)) return E('#VALUE!');
    const cond = toBool(ev.scalar(args[0]));
    if (isErr(cond)) return cond;
    if (cond) return args[1].k === 'err' && args[1].e === '' ? 0 : ev.scalar(args[1]);
    if (args.length < 3) return false;
    return args[2].k === 'err' && args[2].e === '' ? 0 : ev.scalar(args[2]);
  },
  IFERROR(args, ev) {
    if (!need(args, 2, 2)) return E('#VALUE!');
    const v = ev.scalar(args[0]);
    return isErr(v) ? ev.scalar(args[1]) : v;
  },
  AND(args, ev) {
    if (!args.length) return E('#VALUE!');
    let res = true;
    for (const v of allValues(args, ev)) {
      if (v === null) continue;
      const b = toBool(v);
      if (isErr(b)) return b;
      if (!b) res = false;
    }
    return res;
  },
  OR(args, ev) {
    if (!args.length) return E('#VALUE!');
    let res = false;
    for (const v of allValues(args, ev)) {
      if (v === null) continue;
      const b = toBool(v);
      if (isErr(b)) return b;
      if (b) res = true;
    }
    return res;
  },
  NOT(args, ev) {
    if (!need(args, 1, 1)) return E('#VALUE!');
    const b = toBool(ev.scalar(args[0]));
    return isErr(b) ? b : !b;
  },
  ROUND(args, ev) {
    return roundWith(args, ev, 'half');
  },
  ROUNDUP(args, ev) {
    return roundWith(args, ev, 'up');
  },
  ROUNDDOWN(args, ev) {
    return roundWith(args, ev, 'down');
  },
  ABS: (args, ev) => one(args, ev, Math.abs),
  INT: (args, ev) => one(args, ev, Math.floor),
  SQRT: (args, ev) => one(args, ev, (n) => (n < 0 ? E('#NUM!') : Math.sqrt(n))),
  MOD(args, ev) {
    if (!need(args, 2, 2)) return E('#VALUE!');
    const a = toNum(ev.scalar(args[0]));
    const b = toNum(ev.scalar(args[1]));
    if (isErr(a)) return a;
    if (isErr(b)) return b;
    if (b === 0) return E('#DIV/0!');
    return a - b * Math.floor(a / b);
  },
  POWER(args, ev) {
    if (!need(args, 2, 2)) return E('#VALUE!');
    const a = toNum(ev.scalar(args[0]));
    const b = toNum(ev.scalar(args[1]));
    if (isErr(a)) return a;
    if (isErr(b)) return b;
    const r = Math.pow(a, b);
    return Number.isFinite(r) ? r : E('#NUM!');
  },
  PI(args) {
    return args.length ? E('#VALUE!') : Math.PI;
  },
  CONCAT(args, ev) {
    return concatAll(args, ev);
  },
  CONCATENATE(args, ev) {
    return concatAll(args, ev);
  },
  LEN(args, ev) {
    if (!need(args, 1, 1)) return E('#VALUE!');
    const s = toStr(ev.scalar(args[0]));
    return isErr(s) ? s : s.length;
  },
  UPPER(args, ev) {
    if (!need(args, 1, 1)) return E('#VALUE!');
    const s = toStr(ev.scalar(args[0]));
    return isErr(s) ? s : s.toUpperCase();
  },
  LOWER(args, ev) {
    if (!need(args, 1, 1)) return E('#VALUE!');
    const s = toStr(ev.scalar(args[0]));
    return isErr(s) ? s : s.toLowerCase();
  },
  TRIM(args, ev) {
    if (!need(args, 1, 1)) return E('#VALUE!');
    const s = toStr(ev.scalar(args[0]));
    return isErr(s) ? s : s.replace(/\s+/g, ' ').trim();
  },
  LEFT(args, ev) {
    return sliceText(args, ev, 'left');
  },
  RIGHT(args, ev) {
    return sliceText(args, ev, 'right');
  },
  MID(args, ev) {
    if (!need(args, 3, 3)) return E('#VALUE!');
    const s = toStr(ev.scalar(args[0]));
    const start = toNum(ev.scalar(args[1]));
    const len = toNum(ev.scalar(args[2]));
    if (isErr(s)) return s;
    if (isErr(start)) return start;
    if (isErr(len)) return len;
    if (start < 1 || len < 0) return E('#VALUE!');
    return s.substr(Math.floor(start) - 1, Math.floor(len));
  },
  VALUE(args, ev) {
    if (!need(args, 1, 1)) return E('#VALUE!');
    const v = ev.scalar(args[0]);
    if (isErr(v)) return v;
    const n = toNum(v);
    return n;
  },
  SUMIF(args, ev) {
    return conditional(args, ev, true);
  },
  COUNTIF(args, ev) {
    return conditional(args, ev, false);
  },
};

function roundWith(args: Node[], ev: Evaluator, mode: 'half' | 'up' | 'down'): Value {
  if (!need(args, 1, 2)) return E('#VALUE!');
  const x = toNum(ev.scalar(args[0]));
  if (isErr(x)) return x;
  let d = 0;
  if (args.length === 2) {
    const dd = toNum(ev.scalar(args[1]));
    if (isErr(dd)) return dd;
    d = Math.trunc(dd);
  }
  const r = roundTo(x, d, mode);
  return Number.isFinite(r) ? r : E('#NUM!');
}

function concatAll(args: Node[], ev: Evaluator): Value {
  let out = '';
  for (const v of allValues(args, ev)) {
    const s = toStr(v);
    if (isErr(s)) return s;
    out += s;
  }
  return out;
}

function sliceText(args: Node[], ev: Evaluator, side: 'left' | 'right'): Value {
  if (!need(args, 1, 2)) return E('#VALUE!');
  const s = toStr(ev.scalar(args[0]));
  if (isErr(s)) return s;
  let n = 1;
  if (args.length === 2) {
    const nn = toNum(ev.scalar(args[1]));
    if (isErr(nn)) return nn;
    n = Math.floor(nn);
  }
  if (n < 0) return E('#VALUE!');
  return side === 'left' ? s.slice(0, n) : n === 0 ? '' : s.slice(-n);
}

function conditional(args: Node[], ev: Evaluator, sum: boolean): Value {
  if (!need(args, sum ? 2 : 2, sum ? 3 : 2)) return E('#VALUE!');
  const range = args[0];
  if (range.k !== 'range' && range.k !== 'ref') return E('#VALUE!');
  const crit = ev.scalar(args[1]);
  if (isErr(crit)) return crit;
  const match = criteriaMatcher(crit);
  const m = ev.matrix(range);
  if (isErr(m)) return m;
  let sumM: Matrix | null = null;
  if (sum) {
    const sr = args.length === 3 ? args[2] : range;
    if (sr.k !== 'range' && sr.k !== 'ref') return E('#VALUE!');
    const sm = ev.matrix(sr, range);
    if (isErr(sm)) return sm;
    sumM = sm;
  }
  let total = 0;
  for (let r = 0; r < m.length; r++) {
    for (let c = 0; c < m[r].length; c++) {
      if (!match(m[r][c])) continue;
      if (!sum) {
        total += 1;
      } else {
        const v = sumM![r]?.[c];
        if (isErr(v)) return v;
        if (typeof v === 'number') total += v;
      }
    }
  }
  return total;
}

export const SUPPORTED_FUNCTIONS: string[] = Object.keys(FUNCS);

export class Evaluator {
  grid: Grid;
  private cache = new Map<string, Value>();
  private visiting = new Set<string>();
  private parsed = new Map<string, Node | SyntaxErr>();

  constructor(grid: Grid) {
    this.grid = grid;
  }

  /** Value of one cell, evaluating its formula if it has one. */
  cell(col: number, row: number): Value {
    const ref = refOf(col, row);
    const hit = this.cache.get(ref);
    if (hit !== undefined) return hit;
    if (this.cache.has(ref)) return null;
    const raw = this.grid[ref];
    let result: Value;
    if (raw === undefined || raw === '') {
      result = null;
    } else if (isFormula(raw)) {
      if (this.visiting.has(ref)) return E('#CYCLE!');
      this.visiting.add(ref);
      try {
        result = this.formula(raw.slice(1));
      } finally {
        this.visiting.delete(ref);
      }
    } else {
      result = literal(raw);
    }
    this.cache.set(ref, result);
    return result;
  }

  formula(src: string): Value {
    let node = this.parsed.get(src);
    if (!node) {
      try {
        node = new Parser(tokenize(src)).parseAll();
      } catch (e) {
        node = e instanceof SyntaxErr ? e : new SyntaxErr('parse');
      }
      this.parsed.set(src, node);
    }
    if (node instanceof SyntaxErr) return E('#ERROR!');
    const v = this.scalar(node);
    if (typeof v === 'number' && !Number.isFinite(v)) return E('#NUM!');
    return v;
  }

  /** Matrix of values for a range/ref node. `like` makes the result the same size as another range. */
  matrix(node: Node, like?: Node): Matrix | CellErr {
    let c1: number, r1: number, c2: number, r2: number;
    if (node.k === 'ref') {
      c1 = c2 = node.col;
      r1 = r2 = node.row;
    } else if (node.k === 'range') {
      c1 = node.c1; r1 = node.r1; c2 = node.c2; r2 = node.r2;
    } else return E('#VALUE!');
    if (like && (like.k === 'range' || like.k === 'ref')) {
      const lc = like.k === 'ref' ? 0 : like.c2 - like.c1;
      const lr = like.k === 'ref' ? 0 : like.r2 - like.r1;
      c2 = c1 + lc;
      r2 = r1 + lr;
    }
    if ((c2 - c1 + 1) * (r2 - r1 + 1) > MAX_RANGE_CELLS) return E('#VALUE!');
    const out: Matrix = [];
    for (let r = r1; r <= r2; r++) {
      const row: Value[] = [];
      for (let c = c1; c <= c2; c++) row.push(this.cell(c, r));
      out.push(row);
    }
    return out;
  }

  scalar(node: Node): Value {
    switch (node.k) {
      case 'num': return node.v;
      case 'str': return node.v;
      case 'bool': return node.v;
      case 'err': return node.e === '' ? null : E(node.e);
      case 'name': return E('#NAME?');
      case 'ref': return this.cell(node.col, node.row);
      case 'range': return E('#VALUE!');
      case 'un': {
        const v = this.scalar(node.a);
        if (node.op === '+') return v;
        const n = toNum(v);
        return isErr(n) ? n : -n;
      }
      case 'pct': {
        const n = toNum(this.scalar(node.a));
        return isErr(n) ? n : n / 100;
      }
      case 'bin': return this.binary(node.op, this.scalar(node.a), this.scalar(node.b));
      case 'call': {
        const fn = FUNCS[node.name];
        if (!fn) return E('#NAME?');
        return fn(node.args, this);
      }
    }
  }

  private binary(op: string, a: Value, b: Value): Value {
    if (isErr(a)) return a;
    if (isErr(b)) return b;
    switch (op) {
      case '&': {
        const x = toStr(a);
        const y = toStr(b);
        return isErr(x) ? x : isErr(y) ? y : x + y;
      }
      case '=': return compareValues(a, b) === 0;
      case '<>': return compareValues(a, b) !== 0;
      case '<': return compareValues(a, b) < 0;
      case '>': return compareValues(a, b) > 0;
      case '<=': return compareValues(a, b) <= 0;
      case '>=': return compareValues(a, b) >= 0;
    }
    const x = toNum(a);
    const y = toNum(b);
    if (isErr(x)) return x;
    if (isErr(y)) return y;
    switch (op) {
      case '+': return x + y;
      case '-': return x - y;
      case '*': return x * y;
      case '/': return y === 0 ? E('#DIV/0!') : x / y;
      case '^': {
        const r = Math.pow(x, y);
        return Number.isFinite(r) ? r : E('#NUM!');
      }
    }
    return E('#ERROR!');
  }
}

/** Evaluate every non-empty cell of a grid. */
export function evaluateGrid(grid: Grid): Record<string, Value> {
  const ev = new Evaluator(grid);
  const out: Record<string, Value> = {};
  for (const key of Object.keys(grid)) {
    const raw = grid[key];
    if (raw === '' || raw === undefined) continue;
    const p = parseRef(key);
    if (!p) continue;
    out[key] = ev.cell(p.col, p.row);
  }
  return out;
}

export function displayValue(v: Value): string {
  if (v === null) return '';
  if (isErr(v)) return v.err;
  if (typeof v === 'boolean') return v ? 'TRUE' : 'FALSE';
  if (typeof v === 'number') return formatNumber(v);
  return v;
}

// ------------------------------------------------- text-level formula tools

const REF_SPAN = /^(\$?)([A-Za-z]{1,3})(\$?)([0-9]+)$/;

function mapFormulaText(
  src: string,
  onRef: (m: RegExpExecArray) => string,
  onFunc?: (name: string) => string,
): string {
  let out = '';
  let i = 0;
  const n = src.length;
  while (i < n) {
    const c = src[i];
    if (c === '"') {
      let j = i + 1;
      while (j < n) {
        if (src[j] === '"') {
          if (src[j + 1] === '"') j += 2;
          else break;
        } else j++;
      }
      out += src.slice(i, Math.min(j + 1, n));
      i = j + 1;
      continue;
    }
    if ((c >= '0' && c <= '9') || (c === '.' && src[i + 1] >= '0' && src[i + 1] <= '9')) {
      NUM_RE.lastIndex = i;
      const m = NUM_RE.exec(src);
      const len = m ? m[0].length : 1;
      out += src.slice(i, i + len);
      i += len;
      continue;
    }
    if (c === '$' || c === '_' || /[A-Za-z]/.test(c)) {
      let j = i;
      while (j < n && /[A-Za-z0-9_.$]/.test(src[j])) j++;
      const span = src.slice(i, j);
      let k = j;
      while (k < n && src[k] === ' ') k++;
      const next = src[k];
      const prev = i > 0 ? src[i - 1] : '';
      const m = REF_SPAN.exec(span);
      if (next === '(') out += onFunc ? onFunc(span) : span;
      else if (m && next !== '!' && prev !== '!') out += onRef(m);
      else out += span;
      i = j;
      continue;
    }
    if (c === ';') out += ',';
    else out += c;
    i++;
  }
  return out;
}

/**
 * Re-target the relative references of a formula (without the leading '=')
 * as if it had been copied by (dRow, dCol). Absolute ($) parts stay put.
 */
export function shiftFormula(formula: string, dRow: number, dCol: number): string {
  return mapFormulaText(formula, (m) => {
    const colAbs = m[1] === '$';
    const rowAbs = m[3] === '$';
    const col = colIndex(m[2]) + (colAbs ? 0 : dCol);
    const row = parseInt(m[4], 10) - 1 + (rowAbs ? 0 : dRow);
    if (col < 0 || row < 0) return '#REF!';
    return (colAbs ? '$' : '') + colName(col) + (rowAbs ? '$' : '') + (row + 1);
  });
}

/** Canonical storage form: upper-case function names, "," separators. */
export function normalizeFormula(formula: string): string {
  return mapFormulaText(formula, (m) => m[0], (name) => name.toUpperCase());
}

/** True when every function in the formula is implemented and no cross-sheet reference is used. */
export function formulaIsSupported(formula: string): boolean {
  const toks = tokenize(formula);
  for (const t of toks) {
    if (t.t === 'bad') return false;
    if (t.t === 'id' && t.call && !FUNCS[t.v]) return false;
    if (t.t === 'id' && !t.call && t.v !== 'TRUE' && t.v !== 'FALSE') return false;
  }
  try {
    new Parser(toks).parseAll();
  } catch {
    return false;
  }
  return true;
}
