# 📱 Easy Office Mobile

<div align="center">
  <img src="assets/icons/app_icon.png" width="128" height="128" alt="Easy Office Logo" style="border-radius: 24px; box-shadow: 0 10px 30px rgba(2,132,199,0.3);" />
  <h3>Yeni Nesil Mobil & Web Ofis Paketi (All-in-One Office Suite)</h3>
  <p>Word, Excel, PowerPoint, PDF Düzenleyici, OCR Tarayıcı, Bağımsız Dosya Dönüştürücü ve Easy AI Asistanı</p>
</div>

---

## 🌟 Özellikler

- 📝 **Easy Docs:** Zengin metin düzenleme, başlıklar, listeler, PDF ve DOCX dışa aktarma.
- 📊 **Easy Sheets:** Formüllü hücre hesaplamaları (`SUM`, `AVERAGE`), tablo yönetimi ve XLSX dışa aktarma.
- 📽️ **Easy Slides:** Modern sunum şablonları, şık temalar ve tam ekran slayt gösterisi.
- 🔄 **Bağımsız Format Dönüştürücü:** PDF ➔ Excel, Word ➔ PDF, Excel ➔ PDF, Görsel ➔ PDF modlarında bağımsız dosya işleme motoru.
- ✍️ **PDF & Dijital İmza:** PDF görüntüleyici, sözleşme damgalama ve el yazısı dijital imzalama.
- 🔍 **Kamera & Galeri OCR:** Fotoğraflardan ve belgelerden anında metin çıkarma.
- 🤖 **Easy AI Asistanı:** Sözleşme taslakları, Excel formül önerileri, sunum özetleri ve tek dokunuşla belgeye aktarma.
- 💎 **3D Glassmorphism Arayüz:** Derin gece mavisi zemin üzerinde neon camgöbeği ışıltılı buzlu cam kartlar.

---

## 🚀 Kurulum ve Çalıştırma

### Gereksinimler
- [Flutter SDK](https://flutter.dev) (v3.19+)
- Dart SDK

```bash
# Bağımlılıkları yükleyin
flutter pub get

# Web üzerinde çalıştırma
flutter run -d chrome

# Android APK derleme
flutter build apk --debug
```

---

## 📂 Proje Yapısı

```
easy_office_mobile/
├── android/            # Android yerel yapılandırması & launcher ikonları
├── assets/icons/       # 3D Glassmorphic uygulama ikonu
├── lib/
│   ├── core/           # Tema, model, yerel veritabanı ve dönüştürme motoru
│   ├── screens/        # Ana sayfa, editörler, dönüştürücü, PDF araçları, AI ekranı
│   ├── widgets/        # GlassCard, GlassBackground, imza ve OCR bileşenleri
│   └── main.dart       # Uygulama giriş noktası ve cam alt gezinme çubuğu
└── pubspec.yaml        # Paket bağımlılıkları ve varlık ayarları
```
