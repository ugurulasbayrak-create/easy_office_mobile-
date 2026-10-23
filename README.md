# Easy Office Mobile (v2 — React Native + Expo)

Belge, tablo ve sunum düzenleyici; dönüştürücü; PDF araçları; cihaz üzerinde OCR. Flutter sürümünden
(`main` dalı) sıfırdan yeniden yazıldı.

## Yapı

- `src/core/` — saf TypeScript motoru (React Native'e bağımlı değil, Node'da test edilir):
  DOCX/XLSX/PPTX okuma-yazma, formül motoru, CSV, Markdown, sıfırdan PDF üretimi (Unicode/Türkçe gömülü yazı tipi),
  PDF metin çıkarma (pdf.js), PDF araçları (pdf-lib), dönüştürücü orkestrasyonu.
- `app/` — Expo Router ekranları. `src/platform/` — dosya/yazı tipi erişimi (tek yerde).
- `src/i18n/` — TR/EN. Motor kullanıcıya metin üretmez, kodlu uyarılar (`Notice`) döndürür.

## Kurulum

```sh
npm run bootstrap      # npm install + `npx expo install ...` (sürümleri Expo seçer)
npm test               # çekirdek motor testleri (Node 22+)
npx expo start
```

OCR yerel modül kullanır: `npx expo prebuild && npx expo run:android` (Expo Go yetmez).

## Dürüstlük notları

- **Yapay zekâ ekranı bağlı değil**: cevap üretmez, uydurma cevap göstermez.
- Dönüştürme kaybı olduğunda (PDF → DOCX düzeni, görseller, formüller) sonuç ekranında uyarı çıkar.
- Şablonlardaki tüm alanlar yer tutucudur.

## Doğrulama durumu

| Alan | Durum |
|---|---|
| Çekirdek motor (`src/core`) | 46 test geçiyor; tip kontrolü temiz; DOCX/XLSX/PPTX LibreOffice'te, PDF poppler ile doğrulandı |
| Ekranlar (`app/`, `src/ui`, `src/platform`) | **Henüz derlenmedi/çalıştırılmadı** (ağda npm kapalıydı) |
| pdf.js'nin Hermes üzerinde çalışması | Doğrulanmadı |
| ML Kit OCR | Doğrulanmadı (dev build gerekir) |
| `expo-file-system/legacy` API'si | Doğrulanmadı; değişirse yalnızca `src/platform/files.ts` etkilenir |
