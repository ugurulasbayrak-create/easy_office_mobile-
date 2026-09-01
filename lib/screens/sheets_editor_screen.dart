import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../core/localization.dart';
import '../core/models.dart';
import '../core/storage.dart';
import '../core/theme.dart';
import '../widgets/glass_background.dart';

class SheetsEditorScreen extends StatefulWidget {
  final OfficeDocument? document;

  const SheetsEditorScreen({super.key, this.document});

  @override
  State<SheetsEditorScreen> createState() => _SheetsEditorScreenState();
}

class _SheetsEditorScreenState extends State<SheetsEditorScreen> {
  late TextEditingController _titleController;
  late TextEditingController _formulaController;
  late String _sheetId;

  final int _rowCount = 35;
  final int _colCount = 8; // A to H
  final Map<String, String> _rawGrid = {};
  final Map<String, String> _computedGrid = {};

  String _selectedCell = 'A1';
  int _selectedChartType = 0; // 0: Bar, 1: Line, 2: Pie, 3: Donut

  @override
  void initState() {
    super.initState();
    _sheetId = widget.document?.id ?? 'sheet-${DateTime.now().millisecondsSinceEpoch}';
    _titleController = TextEditingController(
      text: widget.document?.title ?? 'Finansal Tablo.xlsx',
    );
    _formulaController = TextEditingController();

    if (widget.document?.data is Map) {
      final map = widget.document!.data as Map;
      map.forEach((k, v) {
        _rawGrid[k.toString()] = v.toString();
      });
    } else {
      // Default initial dataset
      _rawGrid['A1'] = 'Ürün / Hizmet';
      _rawGrid['B1'] = 'Gelir (₺)';
      _rawGrid['C1'] = 'Maliyet (₺)';
      _rawGrid['D1'] = 'Net Kâr (₺)';
      _rawGrid['A2'] = 'Yazılım Lisansı';
      _rawGrid['B2'] = '24500';
      _rawGrid['C2'] = '5200';
      _rawGrid['D2'] = '=B2-C2';
      _rawGrid['A3'] = 'Kurumsal Ofis Paketi';
      _rawGrid['B3'] = '38000';
      _rawGrid['C3'] = '7500';
      _rawGrid['D3'] = '=B3-C3';
      _rawGrid['A4'] = 'Bulut Depolama & AI';
      _rawGrid['B4'] = '19500';
      _rawGrid['C4'] = '3800';
      _rawGrid['D4'] = '=B4-C4';
      _rawGrid['A5'] = 'Mobil OCR Modülü';
      _rawGrid['B5'] = '14200';
      _rawGrid['C5'] = '2900';
      _rawGrid['D5'] = '=B5-C5';
      _rawGrid['A6'] = 'Genel Toplam';
      _rawGrid['B6'] = '=SUM(B2:B5)';
      _rawGrid['C6'] = '=SUM(C2:C5)';
      _rawGrid['D6'] = '=SUM(D2:D5)';
    }

    _recalculate();
    _selectCell('A1');
  }

  @override
  void dispose() {
    _titleController.dispose();
    _formulaController.dispose();
    super.dispose();
  }

  String _colToLetter(int idx) => String.fromCharCode(65 + idx);

  void _selectCell(String cellId) {
    setState(() {
      _selectedCell = cellId;
      _formulaController.text = _rawGrid[cellId] ?? '';
    });
  }

  void _setCellValue(String cellId, String val) {
    setState(() {
      _rawGrid[cellId] = val;
      _recalculate();
    });
  }

  void _recalculate() {
    _computedGrid.clear();
    _rawGrid.forEach((cell, raw) {
      if (raw.startsWith('=')) {
        _computedGrid[cell] = _evalFormula(raw.substring(1).toUpperCase());
      } else {
        _computedGrid[cell] = raw;
      }
    });
  }

  String _evalFormula(String expr) {
    try {
      if (expr.startsWith('SUM(') && expr.endsWith(')')) {
        final range = expr.substring(4, expr.length - 1);
        final values = _getRangeValues(range);
        final sum = values.fold<double>(0, (prev, elem) => prev + elem);
        return _formatNum(sum);
      } else if (expr.startsWith('AVERAGE(') && expr.endsWith(')')) {
        final range = expr.substring(8, expr.length - 1);
        final values = _getRangeValues(range);
        if (values.isEmpty) return '0';
        final avg = values.fold<double>(0, (prev, elem) => prev + elem) / values.length;
        return _formatNum(avg);
      } else if (expr.startsWith('MAX(') && expr.endsWith(')')) {
        final range = expr.substring(4, expr.length - 1);
        final values = _getRangeValues(range);
        return values.isEmpty ? '0' : _formatNum(values.reduce(math.max));
      } else if (expr.startsWith('MIN(') && expr.endsWith(')')) {
        final range = expr.substring(4, expr.length - 1);
        final values = _getRangeValues(range);
        return values.isEmpty ? '0' : _formatNum(values.reduce(math.min));
      } else if (expr.startsWith('COUNT(') && expr.endsWith(')')) {
        final range = expr.substring(6, expr.length - 1);
        final values = _getRangeValues(range);
        return values.length.toString();
      }

      // Arithmetic (e.g. B2-C2 or B2*C2 or B2+C2)
      if (expr.contains('-')) {
        final parts = expr.split('-');
        if (parts.length == 2) {
          final v1 = _getCellValueAsNum(parts[0].trim());
          final v2 = _getCellValueAsNum(parts[1].trim());
          return _formatNum(v1 - v2);
        }
      }
      if (expr.contains('+')) {
        final parts = expr.split('+');
        if (parts.length == 2) {
          final v1 = _getCellValueAsNum(parts[0].trim());
          final v2 = _getCellValueAsNum(parts[1].trim());
          return _formatNum(v1 + v2);
        }
      }
      if (expr.contains('*')) {
        final parts = expr.split('*');
        if (parts.length == 2) {
          final v1 = _getCellValueAsNum(parts[0].trim());
          final v2 = _getCellValueAsNum(parts[1].trim());
          return _formatNum(v1 * v2);
        }
      }
      if (expr.contains('/')) {
        final parts = expr.split('/');
        if (parts.length == 2) {
          final v1 = _getCellValueAsNum(parts[0].trim());
          final v2 = _getCellValueAsNum(parts[1].trim());
          if (v2 == 0) return '#DIV/0!';
          return _formatNum(v1 / v2);
        }
      }
    } catch (_) {}
    return expr;
  }

  double _getCellValueAsNum(String key) {
    final raw = _computedGrid[key] ?? _rawGrid[key] ?? key;
    final clean = raw.replaceAll(RegExp(r'[^0-9\.\-]'), '');
    return double.tryParse(clean) ?? 0.0;
  }

  List<double> _getRangeValues(String range) {
    final values = <double>[];
    final parts = range.split(':');
    if (parts.length != 2) return values;

    final startCol = parts[0][0];
    final startRow = int.tryParse(parts[0].substring(1)) ?? 1;
    final endCol = parts[1][0];
    final endRow = int.tryParse(parts[1].substring(1)) ?? 1;

    final startColIdx = startCol.codeUnitAt(0) - 65;
    final endColIdx = endCol.codeUnitAt(0) - 65;

    for (int c = startColIdx; c <= endColIdx; c++) {
      for (int r = startRow; r <= endRow; r++) {
        final cellKey = '${_colToLetter(c)}$r';
        final val = _getCellValueAsNum(cellKey);
        values.add(val);
      }
    }
    return values;
  }

  String _formatNum(double val) {
    if (val % 1 == 0) {
      return val.toInt().toString();
    }
    return val.toStringAsFixed(2);
  }

  void _saveSheet() {
    final title = _titleController.text.trim().isEmpty
        ? 'Untitled Spreadsheet.xlsx'
        : _titleController.text.trim();

    final storage = OfficeStorage();
    if (widget.document != null) {
      storage.updateDocument(_sheetId, title: title, data: _rawGrid);
    } else {
      storage.addDocument(
        OfficeDocument(
          id: _sheetId,
          title: title,
          type: DocumentType.sheet,
          lastModified: DateTime.now(),
          previewContent: 'Formüllü hesap tablosu (${_rawGrid.length} hücre)',
          data: _rawGrid,
        ),
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(LanguageProvider.tr('save_success')),
        backgroundColor: OfficeTheme.sheetColor,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showChartModal() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            final labels = <String>[];
            final values = <double>[];
            for (int r = 2; r <= 8; r++) {
              final l = _computedGrid['A$r'] ?? '';
              final v = double.tryParse((_computedGrid['B$r'] ?? '').replaceAll(RegExp(r'[^0-9\.]'), ''));
              if (l.isNotEmpty && v != null && !l.toLowerCase().contains('toplam')) {
                labels.add(l.length > 10 ? '${l.substring(0, 10)}..' : l);
                values.add(v);
              }
            }

            final maxVal = values.isEmpty ? 100.0 : values.reduce(math.max);

            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.auto_graph_rounded, color: OfficeTheme.sheetColor),
                          SizedBox(width: 8),
                          Text('Gelişmiş Grafik Görselleştirici',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      IconButton(
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SegmentedButton<int>(
                    segments: const [
                      ButtonSegment(value: 0, label: Text('Çubuk'), icon: Icon(Icons.bar_chart_rounded, size: 16)),
                      ButtonSegment(value: 1, label: Text('Çizgi'), icon: Icon(Icons.show_chart_rounded, size: 16)),
                      ButtonSegment(value: 2, label: Text('Pasta'), icon: Icon(Icons.pie_chart_rounded, size: 16)),
                      ButtonSegment(value: 3, label: Text('Halka'), icon: Icon(Icons.donut_large_rounded, size: 16)),
                    ],
                    selected: {_selectedChartType},
                    onSelectionChanged: (val) {
                      setModalState(() {
                        _selectedChartType = val.first;
                      });
                    },
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: 190,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F1A30),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: OfficeTheme.sheetColor.withValues(alpha: 0.3)),
                    ),
                    child: _selectedChartType == 0 || _selectedChartType == 1
                        ? Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: List.generate(labels.length, (i) {
                              final heightRatio = values[i] / (maxVal == 0 ? 1 : maxVal);
                              return Column(
                                mainAxisAlignment: MainAxisAlignment.end,
                                children: [
                                  Text('${values[i].toInt()} ₺',
                                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.greenAccent)),
                                  const SizedBox(height: 4),
                                  Container(
                                    width: 38,
                                    height: (110 * heightRatio).clamp(14.0, 110.0),
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          OfficeTheme.sheetColor,
                                          OfficeTheme.sheetColor.withValues(alpha: 0.6),
                                        ],
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                      ),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(labels[i],
                                      style: const TextStyle(fontSize: 10, color: Colors.white70)),
                                ],
                              );
                            }),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.donut_small_rounded, size: 48, color: OfficeTheme.sheetColor),
                                const SizedBox(height: 8),
                                Text(
                                  'Toplam Pay: ${values.fold<double>(0, (p, e) => p + e).toInt()} ₺',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                                ),
                                const SizedBox(height: 4),
                                const Text('Veriler dilimler halinde başarıyla görselleştirildi.', style: TextStyle(fontSize: 11, color: Colors.grey)),
                              ],
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () {
            _saveSheet();
            Navigator.of(context).pop();
          },
        ),
        title: TextField(
          controller: _titleController,
          style: TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: isDark ? Colors.white : const Color(0xFF0F172A)),
          decoration: const InputDecoration(
            border: InputBorder.none,
            hintText: 'Tablo Başlığı',
          ),
          onSubmitted: (_) => _saveSheet(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.auto_graph_rounded, color: OfficeTheme.sheetColor),
            tooltip: 'Grafik Göster',
            onPressed: _showChartModal,
          ),
          IconButton(
            icon: const Icon(Icons.check_circle_rounded, color: OfficeTheme.sheetColor),
            tooltip: 'Kaydet',
            onPressed: _saveSheet,
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: GlassBackground(
        isDark: isDark,
        child: Column(
          children: [
            // Pro Formula Input Bar (fx)
            Container(
              margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF101B33).withValues(alpha: 0.85) : Colors.white.withValues(alpha: 0.9),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.cyanAccent.withValues(alpha: 0.25) : const Color(0xFFCBD5E1),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: OfficeTheme.sheetColor.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _selectedCell,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: OfficeTheme.sheetColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'fx',
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      fontWeight: FontWeight.w900,
                      fontSize: 15,
                      color: OfficeTheme.sheetColor,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _formulaController,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        hintText: 'Metin, sayı veya =SUM(B2:B5) girin',
                        isDense: true,
                      ),
                      style: TextStyle(fontSize: 13, color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      onChanged: (val) => _setCellValue(_selectedCell, val),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable 2D Table Matrix
            Expanded(
              child: Container(
                margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: isDark ? Colors.cyanAccent.withValues(alpha: 0.15) : const Color(0xFFCBD5E1),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(18),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.vertical,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Table(
                        defaultColumnWidth: const FixedColumnWidth(105),
                        border: TableBorder.all(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                        ),
                        children: [
                          // Column Letters Row
                          TableRow(
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF101B33) : const Color(0xFFF1F5F9),
                            ),
                            children: [
                              const TableCell(
                                child: SizedBox(
                                  width: 40,
                                  height: 32,
                                  child: Center(
                                    child: Icon(Icons.table_chart_rounded, size: 14, color: OfficeTheme.sheetColor),
                                  ),
                                ),
                              ),
                              for (int c = 0; c < _colCount; c++)
                                TableCell(
                                  child: Container(
                                    height: 32,
                                    alignment: Alignment.center,
                                    child: Text(
                                      _colToLetter(c),
                                      style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        fontSize: 12,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),

                          // Grid Data Rows
                          for (int r = 1; r <= _rowCount; r++)
                            TableRow(
                              children: [
                                // Row Number Header
                                TableCell(
                                  child: Container(
                                    width: 40,
                                    height: 36,
                                    color: isDark ? const Color(0xFF0C1426) : const Color(0xFFF8FAFC),
                                    alignment: Alignment.center,
                                    child: Text(
                                      '$r',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 11,
                                        color: Color(0xFF64748B),
                                      ),
                                    ),
                                  ),
                                ),

                                // Data Cells
                                for (int c = 0; c < _colCount; c++)
                                  _buildCellWidget('${_colToLetter(c)}$r', isDark),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Formula Quick Chips
            Container(
              margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0E182F).withValues(alpha: 0.95) : Colors.white.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isDark ? Colors.cyanAccent.withValues(alpha: 0.25) : const Color(0xFFCBD5E1),
                ),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ActionChip(
                      avatar: const Text('∑', style: TextStyle(fontWeight: FontWeight.bold, color: OfficeTheme.sheetColor)),
                      label: const Text('SUM Toplam'),
                      onPressed: () {
                        _setCellValue(_selectedCell, '=SUM(B2:B5)');
                        _formulaController.text = '=SUM(B2:B5)';
                      },
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      avatar: const Text('x̄', style: TextStyle(fontWeight: FontWeight.bold, color: OfficeTheme.sheetColor)),
                      label: const Text('AVG Ortalama'),
                      onPressed: () {
                        _setCellValue(_selectedCell, '=AVERAGE(B2:B5)');
                        _formulaController.text = '=AVERAGE(B2:B5)';
                      },
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      label: const Text('₺ TRY'),
                      onPressed: () {
                        final cur = _computedGrid[_selectedCell] ?? '';
                        if (cur.isNotEmpty && !cur.contains('₺')) {
                          _setCellValue(_selectedCell, '$cur ₺');
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      label: const Text('\$ USD'),
                      onPressed: () {
                        final cur = _computedGrid[_selectedCell] ?? '';
                        if (cur.isNotEmpty && !cur.startsWith('\$')) {
                          _setCellValue(_selectedCell, '\$$cur');
                        }
                      },
                    ),
                    const SizedBox(width: 6),
                    ActionChip(
                      label: const Text('Temizle'),
                      onPressed: () {
                        _setCellValue(_selectedCell, '');
                        _formulaController.clear();
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCellWidget(String cellId, bool isDark) {
    final isSelected = _selectedCell == cellId;
    final val = _computedGrid[cellId] ?? '';

    return TableCell(
      child: InkWell(
        onTap: () => _selectCell(cellId),
        child: Container(
          height: 36,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          alignment: Alignment.centerLeft,
          decoration: BoxDecoration(
            color: isSelected
                ? OfficeTheme.sheetColor.withValues(alpha: 0.22)
                : (isDark ? const Color(0xFF0A1224) : Colors.white),
            border: isSelected
                ? Border.all(color: OfficeTheme.sheetColor, width: 2)
                : null,
          ),
          child: Text(
            val,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 12,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
              fontWeight: val.contains('₺') || val.startsWith('\$') || val.toLowerCase().contains('toplam')
                  ? FontWeight.bold
                  : FontWeight.normal,
            ),
          ),
        ),
      ),
    );
  }
}
