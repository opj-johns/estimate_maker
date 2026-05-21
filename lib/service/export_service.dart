import 'dart:io';
import 'package:docx_creator/docx_creator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../model/estimate_entry.dart';

class ExportService {
  // ── Brand constants ──────────────────────────────────────────────
  static const String _companyName = 'Maa Tee Ent';
  static const String _description = 'Building and Materials Store';

  // Company colors as hex strings (no # prefix — docx_creator convention)
  static const String _colorYellow   = 'F5C518'; // Brand yellow
  static const String _colorRed      = '006994'; // Brand Sea blue
  static const String _colorWhite    = 'FFFFFF';
  static const String _colorDarkText = '1A1A1A';
  static const String _colorRowAlt   = 'FFF8E1'; // Light yellow for alt rows

  /// Builds and shares the estimate as a .docx file.
  /// Returns true on success, false on any failure.
  static Future<bool> exportEstimate({
    required List<EstimateEntry> entries,
    required double grossTotal,
  }) async {
    try {
      final doc = _buildDocument(entries, grossTotal);
      final bytes = DocxExporter().exportToBytes(doc);

      // Write to a temp file
      final dir  = await getTemporaryDirectory();
      final path = '${dir.path}/tile_estimate_${_timestamp()}.docx';
      await File(path).writeAsBytes(await bytes);

      // Trigger native share sheet
      await SharePlus.instance.share(
        ShareParams(
          files: [XFile(path, mimeType: 'application/vnd.openxmlformats-officedocument.wordprocessingml.document')],
          subject: 'Tile Estimate — $_companyName',
          text: 'Please find the tile estimate attached.',
        ),
      );

      return true;
    } catch (_) {
      return false;
    }
  }

  // ── Document builder ─────────────────────────────────────────────

  static DocxBuiltDocument _buildDocument(
    List<EstimateEntry> entries,
    double grossTotal,
  ) {
    final builder = DocxDocumentBuilder();

    builder.section(
      pageSize: DocxPageSize.a4,
      orientation: DocxPageOrientation.portrait,
    );

    _addHeader(builder);
    _addMetaInfo(builder);
    _addEntriesTable(builder, entries);
    _addGrossTotal(builder, grossTotal);
    _addFooter(builder);

    return builder.build();
  }

  // ── Header block ─────────────────────────────────────────────────

  static void _addHeader(DocxDocumentBuilder builder) {
    // Coloured banner paragraph acting as a header bar
    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            _companyName,
            fontSize: 18,
            fontWeight: DocxFontWeight.bold,
            color: DocxColor(_colorWhite),
          ),
          DocxText(
            _description,
            fontSize: 14,
            color: DocxColor(_colorWhite),
          ),
        ],
        align: DocxAlign.center,
        shadingFill: _colorRed,
        spacingBefore: 80,
        spacingAfter: 0,
      ),
    );

    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            'TILE ESTIMATE',
            fontSize: 13,
            fontWeight: DocxFontWeight.bold,
            color: DocxColor(_colorDarkText),
          ),
        ],
        align: DocxAlign.center,
        shadingFill: _colorYellow,
        spacingBefore: 0,
        spacingAfter: 200,
      ),
    );
  }

  // ── Date + entry count meta info ─────────────────────────────────

  static void _addMetaInfo(DocxDocumentBuilder builder) {
    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            'Date: ',
            fontWeight: DocxFontWeight.bold,
            fontSize: 11,
          ),
          DocxText(
            _formattedDate(),
            fontSize: 11,
          ),
        ],
        spacingAfter: 60,
      ),
    );
  }

  // ── Entries table ─────────────────────────────────────────────────

  static void _addEntriesTable(
    DocxDocumentBuilder builder,
    List<EstimateEntry> entries,
  ) {
    final rows = <DocxTableRow>[];

    // Header row
    rows.add(_headerRow());

    // Data rows — alternate background for readability
    for (int i = 0; i < entries.length; i++) {
      rows.add(_dataRow(entries[i], isAlt: i.isOdd));
    }

    builder.add(
      DocxTable(
        rows: rows,
        width: 9026, // A4 content width in DXA (1440 DXA = 1 inch)
      ),
    );
  }

  static DocxTableRow _headerRow() {
    final headers = ['Tile', 'Finish', 'Area (m²)', 'Boxes', 'Unit Price', 'Total'];
    return DocxTableRow(
      cells: headers.map((label) {
        return DocxTableCell(
          shadingFill: _colorRed,
          children: [
            DocxParagraph(
              children: [
                DocxText(
                  label,
                  fontWeight: DocxFontWeight.bold,
                  color: DocxColor(_colorWhite),
                  fontSize: 10,
                ),
              ],
              align: DocxAlign.center,
            ),
          ],
        );
      }).toList(),
    );
  }

  static DocxTableRow _dataRow(EstimateEntry entry, {required bool isAlt}) {
    final fill = isAlt ? _colorRowAlt : _colorWhite;

    final cells = [
      entry.tile.name,
      entry.tile.finish,
      entry.roomArea.toStringAsFixed(2),
      '${entry.boxesNeeded}',
      'GH₵ ${entry.tile.price!.toStringAsFixed(2)}',
      'GH₵ ${entry.entryTotal.toStringAsFixed(2)}',
    ];

    return DocxTableRow(
      cells: cells.map((value) {
        return DocxTableCell(
          shadingFill: fill,
          children: [
            DocxParagraph(
              children: [
                DocxText(value, fontSize: 10),
              ],
              align: DocxAlign.center,
            ),
          ],
        );
      }).toList(),
    );
  }

  // ── Gross total ───────────────────────────────────────────────────

  static void _addGrossTotal(
    DocxDocumentBuilder builder,
    double grossTotal,
  ) {
    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            'GROSS TOTAL:  GH₵ ${grossTotal.toStringAsFixed(2)}',
            fontWeight: DocxFontWeight.bold,
            fontSize: 13,
            color: DocxColor(_colorWhite),
          ),
        ],
        align: DocxAlign.right,
        shadingFill: _colorRed,
        spacingBefore: 160,
        spacingAfter: 160,
      ),
    );
  }

  // ── Footer ────────────────────────────────────────────────────────

  static void _addFooter(DocxDocumentBuilder builder) {
    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            'Thank you for your business.',
            fontSize: 10,
            fontStyle: DocxFontStyle.italic,
            color: DocxColor('888888'),
          ),
        ],
        align: DocxAlign.center,
        spacingBefore: 300,
      ),
    );
  }

  // ── Utilities ─────────────────────────────────────────────────────

  static String _formattedDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  static String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month}${now.day}_${now.hour}${now.minute}';
  }
}