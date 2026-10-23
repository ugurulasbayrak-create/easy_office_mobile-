import type { Grid, Slide } from './core/types.ts';

// Neutral starter content. Every name, amount and date is a placeholder.
export const DOC_TEMPLATES: Array<{ id: string; tr: string; en: string; md: string }> = [
  { id: 'letter', tr: 'Mektup', en: 'Letter', md: '# Konu\n\nSayın [Alıcı],\n\n[Metin]\n\nSaygılarımla,\n\n[Ad Soyad]' },
  { id: 'meeting', tr: 'Toplantı notları', en: 'Meeting notes', md: '# Toplantı notları\n\n**Tarih:** [gg.aa.yyyy]\n\n## Katılımcılar\n\n- [Ad]\n\n## Kararlar\n\n1. [Karar]\n\n## Yapılacaklar\n\n- [Görev] — [Sorumlu]' },
];

const g = (rows: string[][]): Grid => {
  const out: Grid = {};
  rows.forEach((r, i) => r.forEach((v, j) => { if (v) out[String.fromCharCode(65 + j) + (i + 1)] = v; }));
  return out;
};

export const SHEET_TEMPLATES: Array<{ id: string; tr: string; en: string; grid: Grid }> = [
  { id: 'budget', tr: 'Bütçe', en: 'Budget', grid: g([['Kalem', 'Tutar'], ['[Kalem 1]', '0'], ['[Kalem 2]', '0'], ['Toplam', '=SUM(B2:B3)']]) },
  { id: 'items', tr: 'Kalem listesi', en: 'Item list', grid: g([['Ad', 'Adet', 'Birim fiyat', 'Tutar'], ['[Ad]', '1', '0', '=B2*C2'], ['Toplam', '', '', '=SUM(D2:D2)']]) },
];

export const DECK_TEMPLATES: Array<{ id: string; tr: string; en: string; slides: Slide[] }> = [
  { id: 'pitch', tr: 'Tanıtım', en: 'Pitch', slides: [
    { title: '[Proje adı]', subtitle: '[Kısa açıklama]', bullets: [], theme: 'dark' },
    { title: 'Sorun', subtitle: '', bullets: ['[Madde]', '[Madde]'], theme: 'navy' },
    { title: 'Çözüm', subtitle: '', bullets: ['[Madde]', '[Madde]'], theme: 'emerald' },
  ] },
];
