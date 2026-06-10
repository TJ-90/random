import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// One label/value row inside a report section.
class ReportRow {
  const ReportRow(this.label, this.value);

  final String label;
  final String value;
}

/// A titled block of label/value rows.
class ReportSection {
  const ReportSection(this.title, this.rows);

  final String title;
  final List<ReportRow> rows;
}

/// A titled data table (used for the kill-sheet pressure schedule).
class ReportTable {
  const ReportTable({
    required this.title,
    required this.headers,
    required this.rows,
  });

  final String title;
  final List<String> headers;
  final List<List<String>> rows;
}

const String reportWatermark = 'Generated with DrillCalc';

const PdfColor _brand = PdfColor.fromInt(0xFF006C60);
const PdfColor _ink = PdfColor.fromInt(0xFF1D2522);
const PdfColor _muted = PdfColor.fromInt(0xFF5B655F);
const PdfColor _line = PdfColor.fromInt(0xFFD7DEDA);
const PdfColor _zebra = PdfColor.fromInt(0xFFF2F5F2);

/// Builds a branded DrillCalc PDF report and returns the document bytes.
///
/// Every page carries a faint diagonal "DrillCalc" stamp plus a
/// "Generated with DrillCalc" footer with the timestamp and page number.
Future<Uint8List> buildDrillCalcReport({
  required String title,
  required String category,
  String? summary,
  required List<ReportSection> sections,
  List<ReportTable> tables = const [],
  List<String> notes = const [],
}) async {
  final doc = pw.Document(
    title: '$title - DrillCalc Report',
    author: 'DrillCalc',
    creator: 'DrillCalc',
  );
  final now = DateTime.now();
  final stamp =
      '${now.year.toString().padLeft(4, '0')}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')} '
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}';

  doc.addPage(
    pw.MultiPage(
      pageTheme: pw.PageTheme(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.fromLTRB(36, 36, 36, 50),
        buildBackground: (context) => pw.FullPage(
          ignoreMargins: true,
          child: pw.Center(
            child: pw.Transform.rotateBox(
              angle: 0.55,
              child: pw.Opacity(
                opacity: 0.05,
                child: pw.Text(
                  'DrillCalc',
                  style: pw.TextStyle(
                    fontSize: 110,
                    fontWeight: pw.FontWeight.bold,
                    color: _brand,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      footer: (context) => pw.Container(
        padding: const pw.EdgeInsets.only(top: 6),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(color: _line, width: 0.5)),
        ),
        child: pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Text(
              '$reportWatermark  -  $stamp',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
            pw.Text(
              'Page ${context.pageNumber} of ${context.pagesCount}',
              style: const pw.TextStyle(fontSize: 8, color: _muted),
            ),
          ],
        ),
      ),
      build: (context) => [
        _titleBlock(title: title, category: category, summary: summary),
        pw.SizedBox(height: 14),
        for (final section in sections) ...[
          _sectionBlock(section),
          pw.SizedBox(height: 12),
        ],
        for (final table in tables) ...[
          _tableBlock(table),
          pw.SizedBox(height: 12),
        ],
        if (notes.isNotEmpty) _notesBlock(notes),
        pw.SizedBox(height: 10),
        _disclaimerBlock(),
      ],
    ),
  );

  return doc.save();
}

pw.Widget _titleBlock({
  required String title,
  required String category,
  String? summary,
}) {
  return pw.Container(
    padding: const pw.EdgeInsets.all(14),
    decoration: pw.BoxDecoration(
      color: _brand,
      borderRadius: pw.BorderRadius.circular(8),
    ),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Expanded(
              child: pw.Text(
                title,
                style: pw.TextStyle(
                  color: PdfColors.white,
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ),
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(
                horizontal: 8,
                vertical: 4,
              ),
              decoration: pw.BoxDecoration(
                color: const PdfColor.fromInt(0x33FFFFFF),
                borderRadius: pw.BorderRadius.circular(6),
              ),
              child: pw.Text(
                category,
                style: const pw.TextStyle(color: PdfColors.white, fontSize: 9),
              ),
            ),
          ],
        ),
        if (summary != null && summary.isNotEmpty) ...[
          pw.SizedBox(height: 6),
          pw.Text(
            summary,
            style: const pw.TextStyle(
              color: PdfColor.fromInt(0xFFDDEDE9),
              fontSize: 10,
            ),
          ),
        ],
      ],
    ),
  );
}

pw.Widget _sectionBlock(ReportSection section) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionTitle(section.title),
      pw.SizedBox(height: 5),
      pw.Table(
        border: pw.TableBorder.all(color: _line, width: 0.5),
        columnWidths: const {
          0: pw.FlexColumnWidth(3),
          1: pw.FlexColumnWidth(2),
        },
        children: [
          for (final (index, row) in section.rows.indexed)
            pw.TableRow(
              decoration: pw.BoxDecoration(
                color: index.isEven ? _zebra : PdfColors.white,
              ),
              children: [
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    row.label,
                    style: const pw.TextStyle(fontSize: 9, color: _muted),
                  ),
                ),
                pw.Padding(
                  padding: const pw.EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  child: pw.Text(
                    row.value,
                    textAlign: pw.TextAlign.right,
                    style: pw.TextStyle(
                      fontSize: 9,
                      color: _ink,
                      fontWeight: pw.FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

pw.Widget _tableBlock(ReportTable table) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionTitle(table.title),
      pw.SizedBox(height: 5),
      pw.TableHelper.fromTextArray(
        headers: table.headers,
        data: table.rows,
        border: pw.TableBorder.all(color: _line, width: 0.5),
        headerStyle: pw.TextStyle(
          fontSize: 9,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
        headerDecoration: const pw.BoxDecoration(color: _brand),
        cellStyle: const pw.TextStyle(fontSize: 9, color: _ink),
        cellAlignment: pw.Alignment.centerRight,
        headerAlignment: pw.Alignment.centerRight,
        cellPadding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        oddRowDecoration: const pw.BoxDecoration(color: _zebra),
      ),
    ],
  );
}

pw.Widget _sectionTitle(String title) {
  return pw.Row(
    children: [
      pw.Container(width: 4, height: 12, color: _brand),
      pw.SizedBox(width: 6),
      pw.Text(
        title.toUpperCase(),
        style: pw.TextStyle(
          fontSize: 10.5,
          fontWeight: pw.FontWeight.bold,
          color: _ink,
          letterSpacing: 0.4,
        ),
      ),
    ],
  );
}

pw.Widget _notesBlock(List<String> notes) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      _sectionTitle('Formula detail'),
      pw.SizedBox(height: 5),
      for (final note in notes)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 3),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                margin: const pw.EdgeInsets.only(top: 3.4, right: 5),
                width: 3,
                height: 3,
                decoration: const pw.BoxDecoration(
                  color: _brand,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  note,
                  style: const pw.TextStyle(fontSize: 8.5, color: _muted),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

pw.Widget _disclaimerBlock() {
  return pw.Container(
    padding: const pw.EdgeInsets.all(10),
    decoration: pw.BoxDecoration(
      color: const PdfColor.fromInt(0xFFFFF4D6),
      borderRadius: pw.BorderRadius.circular(6),
    ),
    child: pw.Text(
      'Engineering draft generated from field inputs. Verify all results '
      'against approved company procedures before operational use.',
      style: const pw.TextStyle(
        fontSize: 8.5,
        color: PdfColor.fromInt(0xFF5A4100),
      ),
    ),
  );
}
