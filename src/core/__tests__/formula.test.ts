import test from 'node:test';
import assert from 'node:assert/strict';
import { evaluateGrid, displayValue, shiftFormula, normalizeFormula, formulaIsSupported, Evaluator } from '../formula.ts';
import { parseNumber, colName, colIndex, parseRef, gridBounds } from '../sheet.ts';

function calc(formula: string, extra: Record<string, string> = {}): string {
  const grid = { A1: '=' + formula, ...extra };
  return displayValue(evaluateGrid(grid).A1);
}

test('arithmetic and precedence', () => {
  assert.equal(calc('1+2*3'), '7');
  assert.equal(calc('(1+2)*3'), '9');
  assert.equal(calc('2^3^2'), '64'); // left associative like Excel
  assert.equal(calc('-2^2'), '4'); // unary minus binds tighter, like Excel
  assert.equal(calc('10/4'), '2.5');
  assert.equal(calc('50%'), '0.5');
  assert.equal(calc('0.1+0.2'), '0.3');
  assert.equal(calc('1/0'), '#DIV/0!');
});

test('cell references, ranges and aggregates', () => {
  const g = { B1: '10', B2: '20', B3: '30', B4: 'text', B5: '' };
  assert.equal(calc('SUM(B1:B5)', g), '60');
  assert.equal(calc('AVERAGE(B1:B3)', g), '20');
  assert.equal(calc('MIN(B1:B4)', g), '10');
  assert.equal(calc('MAX(B1:B4)', g), '30');
  assert.equal(calc('COUNT(B1:B5)', g), '3');
  assert.equal(calc('COUNTA(B1:B5)', g), '4');
  assert.equal(calc('SUM(B1,B2;B3)', g), '60');
  assert.equal(calc('B1+B2', g), '30');
  assert.equal(calc('MEDIAN(B1:B3)', g), '20');
  assert.equal(calc('PRODUCT(B1:B2)', g), '200');
  assert.equal(calc('AVERAGE(C1:C3)'), '#DIV/0!');
});

test('logic and text functions', () => {
  assert.equal(calc('IF(1>2,"yes","no")'), 'no');
  assert.equal(calc('IF(B1>5,"big","small")', { B1: '9' }), 'big');
  assert.equal(calc('IF(1=1,5)'), '5');
  assert.equal(calc('IF(1=2,5)'), 'FALSE');
  assert.equal(calc('IFERROR(1/0,"oops")'), 'oops');
  assert.equal(calc('AND(1<2,2<3)'), 'TRUE');
  assert.equal(calc('OR(1>2,2>3)'), 'FALSE');
  assert.equal(calc('NOT(FALSE)'), 'TRUE');
  assert.equal(calc('"a"&"b"&1'), 'ab1');
  assert.equal(calc('CONCAT("ğ","Ş")'), 'ğŞ');
  assert.equal(calc('LEN("merhaba")'), '7');
  assert.equal(calc('UPPER("abc")'), 'ABC');
  assert.equal(calc('LEFT("abcdef",2)&RIGHT("abcdef",2)'), 'abef');
  assert.equal(calc('MID("abcdef",2,3)'), 'bcd');
  assert.equal(calc('TRIM("  a   b ")'), 'a b');
  assert.equal(calc('VALUE("12,5")'), '12.5');
});

test('rounding and math', () => {
  assert.equal(calc('ROUND(2.5,0)'), '3');
  assert.equal(calc('ROUND(-2.5,0)'), '-3');
  assert.equal(calc('ROUND(1.005,2)'), '1.01');
  assert.equal(calc('ROUND(1234.5678,-2)'), '1200');
  assert.equal(calc('ROUNDUP(2.1,0)'), '3');
  assert.equal(calc('ROUNDDOWN(2.9,0)'), '2');
  assert.equal(calc('ABS(-4)'), '4');
  assert.equal(calc('INT(-1.5)'), '-2');
  assert.equal(calc('MOD(-3,2)'), '1');
  assert.equal(calc('MOD(5,0)'), '#DIV/0!');
  assert.equal(calc('POWER(2,10)'), '1024');
  assert.equal(calc('SQRT(16)'), '4');
  assert.equal(calc('SQRT(-1)'), '#NUM!');
});

test('SUMIF and COUNTIF', () => {
  const g = { A2: 'elma', A3: 'armut', A4: 'elma', B2: '1', B3: '2', B4: '3', C2: '5', C3: '15', C4: '25' };
  assert.equal(calc('SUMIF(A2:A4,"elma",B2:B4)', g), '4');
  assert.equal(calc('COUNTIF(A2:A4,"elma")', g), '2');
  assert.equal(calc('COUNTIF(C2:C4,">10")', g), '2');
  assert.equal(calc('SUMIF(C2:C4,">=15")', g), '40');
  assert.equal(calc('COUNTIF(A2:A4,"e*")', g), '2');
  assert.equal(calc('COUNTIF(A2:A4,"<>elma")', g), '1');
});

test('comparisons and booleans', () => {
  assert.equal(calc('1<2'), 'TRUE');
  assert.equal(calc('"a"="A"'), 'TRUE');
  assert.equal(calc('2<>2'), 'FALSE');
  assert.equal(calc('TRUE'), 'TRUE');
});

test('errors: unknown names, syntax, cycles, cross-sheet', () => {
  assert.equal(calc('FOO(1)'), '#NAME?');
  assert.equal(calc('B9'), '');
  assert.equal(calc('1+'), '#ERROR!');
  assert.equal(calc('(1+2'), '#ERROR!');
  assert.equal(calc('"a"+1'), '#VALUE!');
  assert.equal(calc('Sheet2!A1'), '#REF!');
  const cyc = evaluateGrid({ A1: '=B1', B1: '=A1' });
  assert.equal(displayValue(cyc.A1), '#CYCLE!');
  assert.equal(displayValue(cyc.B1), '#CYCLE!');
  const self = evaluateGrid({ A1: '=A1+1' });
  assert.equal(displayValue(self.A1), '#CYCLE!');
  // errors propagate through dependents
  const g = evaluateGrid({ A1: '=1/0', A2: '=A1+1', A3: '=SUM(A1:A2)' });
  assert.equal(displayValue(g.A2), '#DIV/0!');
  assert.equal(displayValue(g.A3), '#DIV/0!');
});

test('dependency chains and recalculation order', () => {
  const g = evaluateGrid({ A1: '1', A2: '=A1*2', A3: '=A2*2', A4: '=SUM(A1:A3)' });
  assert.equal(displayValue(g.A4), '7');
});

test('literals: apostrophe text, locale numbers, booleans', () => {
  const g = evaluateGrid({ A1: "'123", A2: '12,5', A3: '1.234,56', A4: '1,234', A5: 'true', A6: '=A1&"x"', A7: '=A2+A3+A4' });
  assert.equal(g.A1, '123');
  assert.equal(g.A2, 12.5);
  assert.equal(g.A3, 1234.56);
  assert.equal(g.A4, 1234);
  assert.equal(g.A5, true);
  assert.equal(g.A6, '123x');
  assert.equal(g.A7, 12.5 + 1234.56 + 1234);
});

test('number parsing', () => {
  assert.equal(parseNumber('42'), 42);
  assert.equal(parseNumber('-3.5'), -3.5);
  assert.equal(parseNumber('1e3'), 1000);
  assert.equal(parseNumber('abc'), null);
  assert.equal(parseNumber(''), null);
  assert.equal(parseNumber('12abc'), null);
  assert.equal(parseNumber('1.234.567'), 1234567);
  assert.equal(parseNumber('1,234,567.89'), 1234567.89);
});

test('column helpers', () => {
  assert.equal(colName(0), 'A');
  assert.equal(colName(25), 'Z');
  assert.equal(colName(26), 'AA');
  assert.equal(colName(701), 'ZZ');
  assert.equal(colName(702), 'AAA');
  assert.equal(colIndex('AA'), 26);
  assert.deepEqual(parseRef('C7'), { col: 2, row: 6 });
  assert.equal(parseRef('7C'), null);
  assert.deepEqual(gridBounds({ A1: 'x', C4: 'y', B9: '' }), { rows: 4, cols: 3 });
});

test('shiftFormula keeps absolute parts and strings intact', () => {
  assert.equal(shiftFormula('B2-C2', 1, 0), 'B3-C3');
  assert.equal(shiftFormula('SUM(B2:B4)', 0, 1), 'SUM(C2:C4)');
  assert.equal(shiftFormula('$B$2+B$2+$B2', 1, 1), '$B$2+C$2+$B3');
  assert.equal(shiftFormula('"A1"&A1', 1, 0), '"A1"&A2');
  assert.equal(shiftFormula('LOG10(A1)', 1, 0), 'LOG10(A2)');
  assert.equal(shiftFormula('A1', -1, 0), '#REF!');
  assert.equal(shiftFormula('1E3+A1', 0, 1), '1E3+B1');
});

test('normalizeFormula and support detection', () => {
  assert.equal(normalizeFormula('sum(a1;b2)'), 'SUM(a1,b2)');
  assert.equal(formulaIsSupported('SUM(A1:A3)*2'), true);
  assert.equal(formulaIsSupported('VLOOKUP(A1,B1:C3,2,0)'), false);
  assert.equal(formulaIsSupported("'Sheet 1'!A1"), false);
  assert.equal(formulaIsSupported('1+'), false);
});

test('Evaluator can be queried cell by cell', () => {
  const ev = new Evaluator({ A1: '2', A2: '=A1*A1' });
  assert.equal(ev.cell(0, 1), 4);
  assert.equal(ev.cell(5, 5), null);
});
