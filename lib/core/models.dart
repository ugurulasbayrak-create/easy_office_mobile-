import 'package:flutter/material.dart';
import 'theme.dart';

enum DocumentType { doc, sheet, slide, pdf }

class OfficeDocument {
  final String id;
  String title;
  final DocumentType type;
  DateTime lastModified;
  String previewContent;
  dynamic data;
  bool isFavorite;
  String tag;
  int fileSizeKb;

  OfficeDocument({
    required this.id,
    required this.title,
    required this.type,
    required this.lastModified,
    required this.previewContent,
    this.data,
    this.isFavorite = false,
    this.tag = 'General',
    this.fileSizeKb = 142,
  });

  Color get brandColor {
    switch (type) {
      case DocumentType.doc:
        return OfficeTheme.docColor;
      case DocumentType.sheet:
        return OfficeTheme.sheetColor;
      case DocumentType.slide:
        return OfficeTheme.slideColor;
      case DocumentType.pdf:
        return OfficeTheme.pdfColor;
    }
  }

  Color get brandLight {
    switch (type) {
      case DocumentType.doc:
        return OfficeTheme.docLight;
      case DocumentType.sheet:
        return OfficeTheme.sheetLight;
      case DocumentType.slide:
        return OfficeTheme.slideLight;
      case DocumentType.pdf:
        return OfficeTheme.pdfLight;
    }
  }

  IconData get icon {
    switch (type) {
      case DocumentType.doc:
        return Icons.article_rounded;
      case DocumentType.sheet:
        return Icons.grid_on_rounded;
      case DocumentType.slide:
        return Icons.co_present_rounded;
      case DocumentType.pdf:
        return Icons.picture_as_pdf_rounded;
    }
  }

  String get typeLabel {
    switch (type) {
      case DocumentType.doc:
        return 'DOCX';
      case DocumentType.sheet:
        return 'XLSX';
      case DocumentType.slide:
        return 'PPTX';
      case DocumentType.pdf:
        return 'PDF';
    }
  }
}

class SlideModel {
  String title;
  String subtitle;
  String body;
  String themeName; // 'Modern Dark', 'Emerald Luxury', 'Corporate Navy', 'Sunset'

  SlideModel({
    required this.title,
    required this.subtitle,
    required this.body,
    this.themeName = 'Modern Dark',
  });
}
