import type { Notice } from '../core/types.ts';
import { useApp } from '../state/store';

export type Lang = 'tr' | 'en';

const tr = {
  appName: 'Easy Office',
  home: 'Ana sayfa', docs: 'Belgeler', sheets: 'Tablolar', slides: 'Sunumlar', convert: 'Dönüştürücü',
  pdfTools: 'PDF Araçları', ocr: 'Metin Tanıma (OCR)', ai: 'Yapay Zekâ', templates: 'Şablonlar', settings: 'Ayarlar',
  save: 'Kaydet', share: 'Paylaş', open: 'Dosya aç', newItem: 'Yeni', delete: 'Sil', cancel: 'Vazgeç', ok: 'Tamam',
  edit: 'Düzenle', preview: 'Önizleme', words: 'kelime', untitled: 'Adsız',
  exportPdf: 'PDF olarak ver', exportDocx: 'DOCX olarak ver', exportMd: 'Markdown olarak ver',
  exportXlsx: 'XLSX olarak ver', exportCsv: 'CSV olarak ver', exportPptx: 'PPTX olarak ver',
  formula: 'Formül', addRow: 'Satır ekle', addCol: 'Sütun ekle',
  slideTitle: 'Başlık', slideSubtitle: 'Alt başlık', slideBullets: 'Maddeler (her satır bir madde)', addSlide: 'Slayt ekle',
  present: 'Sun', next: 'İleri', prev: 'Geri', theme: 'Tema',
  pickFile: 'Dosya seç', chooseTarget: 'Hedef biçim', run: 'Dönüştür', working: 'Çalışıyor…', done: 'Hazır',
  merge: 'Birleştir', split: 'Sayfalara böl', extract: 'Sayfa ayıkla', rotate: 'Döndür', optimize: 'Boyutu küçült',
  imagesToPdf: 'Görselden PDF', sign: 'İmzala', pagesSpec: 'Sayfalar (örn. 1-3, 5)', angle: 'Açı',
  signHere: 'Buraya imzanızı çizin', clear: 'Temizle', page: 'Sayfa',
  before: 'Önce', after: 'Sonra',
  ocrIntro: 'Cihaz üzerinde çalışır; görüntü dışarı gönderilmez.', ocrPick: 'Görsel seç', ocrResult: 'Tanınan metin', ocrCopyDoc: 'Belge olarak kaydet',
  ocrUnavailable: 'OCR modülü bu yapıda yok. Geliştirme derlemesi (dev build) gerekir.',
  aiTitle: 'Yapay zekâ asistanı henüz bağlı değil',
  aiBody: 'Gerçek bir yapay zekâ hizmetine bağlanana kadar bu ekran cevap üretmez. Uydurma cevap göstermiyoruz.',
  tplIntro: 'Başlangıç şablonları. Tüm alanlar yer tutucudur.',
  useTemplate: 'Şablonu kullan',
  language: 'Dil', themeMode: 'Görünüm', light: 'Açık', darkMode: 'Koyu', system: 'Sistem',
  empty: 'Henüz bir şey yok.',
  err_unsupported: 'Bu dönüşüm desteklenmiyor.', err_encrypted: 'Dosya parola korumalı; açılamadı.',
  err_not_pdf: 'Geçerli bir PDF değil.', err_no_text_found: 'Metin bulunamadı (taranmış olabilir). OCR deneyin.',
  err_corrupt: 'Dosya okunamadı veya bozuk.', err_bad_image: 'Görsel okunamadı (PNG/JPEG olmalı).',
  err_bad_range: 'Sayfa aralığı geçersiz.', err_empty: 'Dosya seçilmedi.', err_generic: 'Bir hata oluştu.',
  n_images_skipped: 'Görseller aktarılmadı ({n}).', n_no_text_found: 'Metin bulunamadı.',
  n_layout_not_preserved: 'Düzen (yerleşim, yazı tipleri) korunmaz; yalnızca metin ve yapı aktarılır.',
  n_sheet_truncated: 'Tablo çok büyük olduğu için kısaltıldı.',
  n_formulas_as_values: 'Formüller hesaplanmış değer olarak aktarıldı.',
  n_encrypted: 'Dosya şifreli.', n_no_size_gain: 'Boyut küçülmedi; özgün dosya korundu.',
  n_only_first_sheet: 'Yalnızca ilk sayfa aktarıldı ({n} sayfa vardı).',
  n_text_only: 'Yalnızca metin aktarıldı; görsel tasarım yeniden oluşturuldu.',
};
export type Dict = typeof tr;
const en: Dict = {
  appName: 'Easy Office',
  home: 'Home', docs: 'Documents', sheets: 'Sheets', slides: 'Slides', convert: 'Converter',
  pdfTools: 'PDF Tools', ocr: 'Text Recognition (OCR)', ai: 'AI', templates: 'Templates', settings: 'Settings',
  save: 'Save', share: 'Share', open: 'Open file', newItem: 'New', delete: 'Delete', cancel: 'Cancel', ok: 'OK',
  edit: 'Edit', preview: 'Preview', words: 'words', untitled: 'Untitled',
  exportPdf: 'Export as PDF', exportDocx: 'Export as DOCX', exportMd: 'Export as Markdown',
  exportXlsx: 'Export as XLSX', exportCsv: 'Export as CSV', exportPptx: 'Export as PPTX',
  formula: 'Formula', addRow: 'Add row', addCol: 'Add column',
  slideTitle: 'Title', slideSubtitle: 'Subtitle', slideBullets: 'Bullets (one per line)', addSlide: 'Add slide',
  present: 'Present', next: 'Next', prev: 'Back', theme: 'Theme',
  pickFile: 'Pick file', chooseTarget: 'Target format', run: 'Convert', working: 'Working…', done: 'Done',
  merge: 'Merge', split: 'Split into pages', extract: 'Extract pages', rotate: 'Rotate', optimize: 'Reduce size',
  imagesToPdf: 'Images to PDF', sign: 'Sign', pagesSpec: 'Pages (e.g. 1-3, 5)', angle: 'Angle',
  signHere: 'Draw your signature here', clear: 'Clear', page: 'Page',
  before: 'Before', after: 'After',
  ocrIntro: 'Runs on the device; the image never leaves it.', ocrPick: 'Pick image', ocrResult: 'Recognized text', ocrCopyDoc: 'Save as document',
  ocrUnavailable: 'The OCR module is not in this build. A development build is required.',
  aiTitle: 'The AI assistant is not connected yet',
  aiBody: 'Until a real AI service is connected this screen produces no replies. We do not show made-up answers.',
  tplIntro: 'Starter templates. Every field is a placeholder.',
  useTemplate: 'Use template',
  language: 'Language', themeMode: 'Appearance', light: 'Light', darkMode: 'Dark', system: 'System',
  empty: 'Nothing here yet.',
  err_unsupported: 'This conversion is not supported.', err_encrypted: 'The file is password protected and cannot be opened.',
  err_not_pdf: 'Not a valid PDF.', err_no_text_found: 'No text found (it may be scanned). Try OCR.',
  err_corrupt: 'The file could not be read or is damaged.', err_bad_image: 'Image could not be read (must be PNG/JPEG).',
  err_bad_range: 'Invalid page range.', err_empty: 'No file selected.', err_generic: 'Something went wrong.',
  n_images_skipped: 'Images were not carried over ({n}).', n_no_text_found: 'No text found.',
  n_layout_not_preserved: 'Layout (positioning, fonts) is not preserved; only text and structure carry over.',
  n_sheet_truncated: 'The sheet was too large and was truncated.',
  n_formulas_as_values: 'Formulas were exported as calculated values.',
  n_encrypted: 'The file is encrypted.', n_no_size_gain: 'No size reduction; the original was kept.',
  n_only_first_sheet: 'Only the first sheet was exported ({n} sheets).',
  n_text_only: 'Text only; the visual design was rebuilt.',
};

const dicts: Record<Lang, Dict> = { tr, en };

export function useT() {
  const lang = useApp((s) => s.lang);
  return (k: keyof Dict, n?: number): string => dicts[lang][k].replace('{n}', String(n ?? ''));
}

export function useNotice() {
  const t = useT();
  return (n: Notice): string => t(('n_' + n.code) as keyof Dict, n.n);
}

export function useErr() {
  const t = useT();
  return (e: unknown): string => {
    const code = (e as any)?.code;
    const key = ('err_' + code) as keyof Dict;
    return code && key in tr ? t(key) : t('err_generic');
  };
}
