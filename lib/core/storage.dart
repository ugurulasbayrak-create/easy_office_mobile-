import 'package:flutter/foundation.dart';
import 'models.dart';

class OfficeStorage extends ChangeNotifier {
  static final OfficeStorage _instance = OfficeStorage._internal();
  factory OfficeStorage() => _instance;

  OfficeStorage._internal() {
    _loadInitialSampleDocs();
  }

  final List<OfficeDocument> _documents = [];

  List<OfficeDocument> get documents => List.unmodifiable(_documents);

  void _loadInitialSampleDocs() {
    _documents.addAll([
      OfficeDocument(
        id: 'doc-fatura',
        title: 'MİRDAŞ MADENCİLİK e-FATURA.docx',
        type: DocumentType.doc,
        lastModified: DateTime.now(),
        previewContent: 'MİRDAŞ MADENCİLİK LİMİTED ŞİRKETİ • e-FATURA (MIR2026000000056) • 2.720,00 USD',
        isFavorite: true,
        tag: 'Fatura',
        fileSizeKb: 145,
        data: '''# MİRDAŞ MADENCİLİK LİMİTED ŞİRKETİ
**e-FATURA (Ticari Fatura / İhraç Kayıtlı)**

**Adres:** ÇUKUR MAHALLESİ KATİP MEHMET CADDESİ NO:36/4 No: 21600 Çermik / Diyarbakır
**Tel:** 5327420584 | **Fax:** -
**E-Posta:** recepgundem@hotmail.com
**Vergi Dairesi:** ÇERMİK MAL MÜDÜRLÜĞÜ | **VKN:** 6211156954
**ETTN:** a20c626e-1c1a-48e3-b65e-e7cdb90e90d9

---

### ALICI BİLGİLERİ (SAYIN)
**EKOMAR MADENCİLİK SAN TİC LTD ŞTİ**
ÜÇEVLER MAH. AHISKA CAD. ÇETİNKAYA A BLOK No:73 A 00000 Nilüfer / Bursa
**Vergi Dairesi:** ÇEKİRGE VERGİ DAİRESİ | **VKN:** 3300481589

**Fatura No:** MIR2026000000056 | **Özelleştirme No:** TR1.2
**Fatura Tarihi:** 14-08-2026 | **Düzenleme Tarihi:** 14-08-2026
**Senaryo:** TİCARİ FATURA | **Fatura Tipi:** İHRAÇ KAYITLI
**İrsaliye No:** MDS2026000000056 | **İrsaliye Tarihi:** 11-08-2026

---

### MAL / HİZMET DETAYLARI
| Sıra | Mal / Hizmet | Miktar | Birim Fiyat | İskonto | KDV Oranı | KDV Tutarı | Toplam Tutar |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| 1 | 310X180X180 Ebatlarında Mermer Blok | 27,2 ton | 100 USD | %0 | %20,00 | 544,00 USD | 2.720,00 USD |

---

### VERGİ VE TUTAR ÖZETİ
• **Mal Hizmet Toplam Tutarı:** 2.720,00 USD
• **Toplam İskonto:** 0,00 USD
• **KDV Matrahı:** 2.720,00 USD
• **Hesaplanan KDV (%20):** 544,00 USD
• **Vergiler Dahil Toplam Tutar:** 3.264,00 USD
• **ÖDENECEK TOPLAM TUTAR:** 2.720,00 USD

• **Hesaplanan KDV (%20) (TL):** 25.987,80 TL
• **Mal Hizmet Toplam Tutarı (TL):** 129.939,02 TL
• **Vergiler Dahil Toplam Tutar (TL):** 155.926,83 TL
• **ÖDENECEK TOPLAM TUTAR (TL):** 129.939,02 TL

---

**Vergi İstisna Muafiyet Sebebi:** 701-3065 s. KDV Kanununun 11/1-c md. Kapsamındaki İhraç Kayıtlı Satış
*(3065 sayılı KDV Kanununun 11/1-c maddesi hükümlerine göre ihraç edilmek şartıyla teslim edildiğinden KDV tahsil edilmemiştir.)*

**Yazı İle Tutar:** Yalnız İKİBİNYEDİYÜZYİRMİ Dolar'dır (Yalnız YÜZYİRMİDOKUZBİNDOKUZYÜZOTUZDOKUZ TL İKİ Kr'dir)
**Döviz Kuru:** 47.7717 TL

---

### BANKA VE ÖDEME BİLGİLERİ
• **IBAN:** TR500001200126900010100254
• **Para Birimi:** TRY
• **Banka Şubesi:** HALK BANKASI / ÇERMİK ŞUBESİ (Şube Kodu: 1269)''',
      ),
      OfficeDocument(
        id: 'doc-1',
        title: 'Project Architecture & Proposal.docx',
        type: DocumentType.doc,
        lastModified: DateTime.now().subtract(const Duration(minutes: 15)),
        previewContent:
            'Executive Summary: Easy Office platform integration with AI Copilot, document OCR, and sheet formulas.',
        isFavorite: true,
        tag: 'Business',
        fileSizeKb: 284,
        data:
            '# Project Architecture Proposal\n\n## 1. Executive Summary\nEasy Office is a high-performance productivity suite combining Word, Excel, PowerPoint, and PDF tools.\n\n## 2. Key Modules\n- Easy Docs rich text editor with live word counters\n- Easy Sheets formula engine with dynamic charts\n- Easy Slides presentation deck with presenter mode\n- AI Assistant & Real-time OCR Camera Scanner\n\n## 3. Deployment & Cloud Security\nAll documents are encrypted and cached locally for offline-first performance with zero cloud latency.',
      ),
      OfficeDocument(
        id: 'sheet-1',
        title: 'Q3 Financials & Revenue.xlsx',
        type: DocumentType.sheet,
        lastModified: DateTime.now().subtract(const Duration(hours: 1)),
        previewContent:
            'Total Q3 Net Income: \$42,500 | Costs: \$18,200 | Net Margin: 57.2%',
        isFavorite: true,
        tag: 'Finance',
        fileSizeKb: 196,
        data: <String, String>{
          'A1': 'Product',
          'B1': 'Sales (\$)',
          'C1': 'Costs (\$)',
          'D1': 'Profit (\$)',
          'A2': 'Easy Docs Pro',
          'B2': '15000',
          'C2': '4000',
          'D2': '=B2-C2',
          'A3': 'Easy Sheets Pro',
          'B3': '22000',
          'C3': '6000',
          'D3': '=B3-C3',
          'A4': 'Easy Slides Studio',
          'B4': '12000',
          'C4': '3500',
          'D4': '=B4-C4',
          'A5': 'Total Revenue',
          'B5': '=SUM(B2:B4)',
          'C5': '=SUM(C2:C4)',
          'D5': '=SUM(D2:D4)',
        },
      ),
      OfficeDocument(
        id: 'slide-1',
        title: 'Startup Investor Pitch.pptx',
        type: DocumentType.slide,
        lastModified: DateTime.now().subtract(const Duration(hours: 4)),
        previewContent:
            'Slide 1: Vision Statement | Slide 2: Market Size (\$48B) | Slide 3: Solution Matrix',
        isFavorite: false,
        tag: 'Pitch',
        fileSizeKb: 512,
        data: [
          SlideModel(
            title: 'EASY OFFICE MOBILE',
            subtitle: 'Next-Gen Mobile Document & AI Suite',
            body: 'Presented by Founding Team | Google Play 2026',
            themeName: 'Modern Dark',
          ),
          SlideModel(
            title: 'Problem & Opportunity',
            subtitle: '500M+ Mobile Users Need Lightweight Tools',
            body:
                '• Traditional desktop office suites are heavy and bloated\n• Users need instant offline document creation and OCR on the go\n• Fragmentation between Word and PDF tools causes friction',
            themeName: 'Emerald Luxury',
          ),
          SlideModel(
            title: 'Our Solution',
            subtitle: 'All-in-One Office + AI Intelligence',
            body:
                '• Docs, Sheets, Slides, and PDF in a single fast app\n• Finger digital signatures and instant AI summaries\n• 11-in-1 format converter hub',
            themeName: 'Corporate Navy',
          ),
        ],
      ),
      OfficeDocument(
        id: 'pdf-1',
        title: 'Non-Disclosure Agreement (NDA).pdf',
        type: DocumentType.pdf,
        lastModified: DateTime.now().subtract(const Duration(days: 2)),
        previewContent:
            'Mutual NDA between Easy Office Technologies and Client. Signed and sealed.',
        isFavorite: true,
        tag: 'Legal',
        fileSizeKb: 340,
      ),
    ]);
  }

  void toggleFavorite(String id) {
    final doc = _documents.firstWhere((d) => d.id == id, orElse: () => _documents.first);
    doc.isFavorite = !doc.isFavorite;
    notifyListeners();
  }

  void addDocument(OfficeDocument doc) {
    _documents.insert(0, doc);
    notifyListeners();
  }

  void updateDocument(String id, {String? title, dynamic data, String? preview}) {
    final index = _documents.indexWhere((d) => d.id == id);
    if (index != -1) {
      if (title != null) _documents[index].title = title;
      if (data != null) _documents[index].data = data;
      if (preview != null) _documents[index].previewContent = preview;
      _documents[index].lastModified = DateTime.now();
      notifyListeners();
    }
  }

  void deleteDocument(String id) {
    _documents.removeWhere((d) => d.id == id);
    notifyListeners();
  }
}
