import 'dart:io';

import 'package:docx_creator/docx_creator.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../model/estimate_entry.dart';

class ExportService {
  // ───────────────────────────────────────────────────────────
  // Company Details
  // ───────────────────────────────────────────────────────────

  static const String _companyName = 'Maa Tee Ent.';
  static const String _description = 'Building Materials Store';
  static const String _address = 'Q386+G36, Dawhenya, Ghana';
  static const String _phone = '+233248431409';

  // ───────────────────────────────────────────────────────────
  // Colors
  // ───────────────────────────────────────────────────────────

  static const String _primaryColor = '1F2937';
  static const String _lightGray = 'F3F4F6';
  static const String _white = 'FFFFFF';
  static const String _darkText = '111827';
  static const String _mutedText = '6B7280';

  // ───────────────────────────────────────────────────────────
  // Public Export Method
  // ───────────────────────────────────────────────────────────

  static Future<bool> exportEstimate({
    required List<EstimateEntry> entries,
    required double grossTotal,
    required String customerName,
    String? customerPhone,
    String? projectLocation,
  }) async {
    try {
      final doc = _buildDocument(
        entries: entries,
        grossTotal: grossTotal,
        customerName: customerName,
        customerPhone: customerPhone,
        projectLocation: projectLocation,
      );

      final bytes = DocxExporter().exportToBytes(doc);

      final dir = await getTemporaryDirectory();

      final path =
          '${dir.path}/estimate_${_timestamp()}.docx';

      await File(path).writeAsBytes(await bytes);

      await SharePlus.instance.share(
        ShareParams(
          files: [
            XFile(
              path,
              mimeType:
                  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            ),
          ],
          subject: 'Estimate from $_companyName',
          text: 'Please find your estimate attached.',
        ),
      );
      
      return true;
    } catch (e) {
      return false;
    }
  }

  // ───────────────────────────────────────────────────────────
  // Document Builder
  // ───────────────────────────────────────────────────────────

  static DocxBuiltDocument _buildDocument({
    required List<EstimateEntry> entries,
    required double grossTotal,
    required String customerName,
    String? customerPhone,
    String? projectLocation,
  }) {
    final builder = DocxDocumentBuilder();

    builder.section(
      pageSize: DocxPageSize.a4,
      orientation: DocxPageOrientation.portrait,
    );

    _addHeader(builder);

    _addSpacing(builder, 120);

    _addCustomerSection(
      builder,
      customerName,
      customerPhone,
      projectLocation,
    );

    _addSpacing(builder, 180);

    _addEstimateTable(builder, entries);

    _addSpacing(builder, 180);

    _addTotals(builder, grossTotal);

    _addSpacing(builder, 220);

    _addNotes(builder);

    _addSpacing(builder, 300);

    _addFooter(builder);

    return builder.build();
  }

  // ───────────────────────────────────────────────────────────
  // Header
  // ───────────────────────────────────────────────────────────

  static void _addHeader(DocxDocumentBuilder builder) {
    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            _companyName,
            fontSize: 22,
            fontWeight: DocxFontWeight.bold,
            color: DocxColor(_darkText),
          ),
        ],
      ),
    );

    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            _description,
            fontSize: 11,
            color: DocxColor(_mutedText),
          ),
        ],
        spacingAfter: 20,
      ),
    );

    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            _address,
            fontSize: 10,
            color: DocxColor(_mutedText),
          ),
        ],
      ),
    );

    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            _phone,
            fontSize: 10,
            color: DocxColor(_mutedText),
          ),
        ],
        spacingAfter: 180,
      ),
    );

    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            'ESTIMATE',
            fontSize: 24,
            fontWeight: DocxFontWeight.bold,
            color: DocxColor(_primaryColor),
          ),
        ],
        align: DocxAlign.right,
      ),
    );

    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            'Estimate #: ${_estimateNumber()}',
            fontSize: 10,
            color: DocxColor(_darkText),
          ),
        ],
        align: DocxAlign.right,
      ),
    );

    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            'Date: ${_formattedDate()}',
            fontSize: 10,
            color: DocxColor(_darkText),
          ),
        ],
        align: DocxAlign.right,
      ),
    );

    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            'Validity: 14 Days',
            fontSize: 10,
            color: DocxColor(_darkText),
          ),
        ],
        align: DocxAlign.right,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // Customer Section
  // ───────────────────────────────────────────────────────────

  static void _addCustomerSection(
    DocxDocumentBuilder builder,
    String customerName,
    String? customerPhone,
    String? projectLocation,
  ) {
    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            'Prepared For',
            fontSize: 13,
            fontWeight: DocxFontWeight.bold,
            color: DocxColor(_primaryColor),
          ),
        ],
        spacingAfter: 60,
      ),
    );

    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            'Customer Name: ',
            fontWeight: DocxFontWeight.bold,
            fontSize: 10,
          ),
          DocxText(
            customerName,
            fontSize: 10,
          ),
        ],
      ),
    );

    if (customerPhone != null && customerPhone.isNotEmpty) {
      builder.add(
        DocxParagraph(
          children: [
            DocxText(
              'Phone Number: ',
              fontWeight: DocxFontWeight.bold,
              fontSize: 10,
            ),
            DocxText(
              customerPhone,
              fontSize: 10,
            ),
          ],
        ),
      );
    }

    if (projectLocation != null && projectLocation.isNotEmpty) {
      builder.add(
        DocxParagraph(
          children: [
            DocxText(
              'Project Location: ',
              fontWeight: DocxFontWeight.bold,
              fontSize: 10,
            ),
            DocxText(
              projectLocation,
              fontSize: 10,
            ),
          ],
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────
  // Estimate Table
  // ───────────────────────────────────────────────────────────

  static void _addEstimateTable(
    DocxDocumentBuilder builder,
    List<EstimateEntry> entries,
  ) {
    final rows = <DocxTableRow>[];

    rows.add(_tableHeader());

    for (int i = 0; i < entries.length; i++) {
      rows.add(
        _tableRow(
          index: i + 1,
          entry: entries[i],
          isAlt: i.isOdd,
        ),
      );
    }

    builder.add(
      DocxTable(
        rows: rows,
        width: 9026,
      ),
    );
  }

  static DocxTableRow _tableHeader() {
    final headers = [
      'Item',
      'Tile',
      'Finish',
      'Area (m²)',
      'Boxes',
      'Total',
    ];

    return DocxTableRow(
      cells: headers.map((header) {
        return DocxTableCell(
          shadingFill: _primaryColor,
          children: [
            DocxParagraph(
              children: [
                DocxText(
                  header,
                  fontWeight: DocxFontWeight.bold,
                  fontSize: 10,
                  color: DocxColor(_white),
                ),
              ],
              align: DocxAlign.center,
            ),
          ],
        );
      }).toList(),
    );
  }

  static DocxTableRow _tableRow({
    required int index,
    required EstimateEntry entry,
    required bool isAlt,
  }) {
    final fill = isAlt ? _lightGray : _white;

    final values = [
      '$index',
      entry.tile.name,
      entry.tile.finish,
      entry.roomArea.toStringAsFixed(2),
      '${entry.boxesNeeded}',
      'GH₵ ${entry.entryTotal.toStringAsFixed(2)}',
    ];

    return DocxTableRow(
      cells: values.map((value) {
        return DocxTableCell(
          shadingFill: fill,
          children: [
            DocxParagraph(
              children: [
                DocxText(
                  value,
                  fontSize: 10,
                  color: DocxColor(_darkText),
                ),
              ],
              align: DocxAlign.center,
            ),
          ],
        );
      }).toList(),
    );
  }

  // ───────────────────────────────────────────────────────────
  // Totals
  // ───────────────────────────────────────────────────────────

  static void _addTotals(
    DocxDocumentBuilder builder,
    double grossTotal,
  ) {
    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            'Subtotal: ',
            fontWeight: DocxFontWeight.bold,
            fontSize: 11,
          ),
          DocxText(
            'GH₵ ${grossTotal.toStringAsFixed(2)}',
            fontSize: 11,
          ),
        ],
        align: DocxAlign.right,
        spacingAfter: 40,
      ),
    );

    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            'Grand Total: GH₵ ${grossTotal.toStringAsFixed(2)}',
            fontWeight: DocxFontWeight.bold,
            fontSize: 15,
            color: DocxColor(_primaryColor),
          ),
        ],
        align: DocxAlign.right,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // Notes
  // ───────────────────────────────────────────────────────────

  static void _addNotes(DocxDocumentBuilder builder) {
    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            'Notes',
            fontWeight: DocxFontWeight.bold,
            fontSize: 12,
            color: DocxColor(_primaryColor),
          ),
        ],
        spacingAfter: 40,
      ),
    );

    final notes = [
      'Installation not included.',
      'Estimate valid for 14 days.',
      'Tiles subject to stock availability.',
    ];

    for (final note in notes) {
      builder.add(
        DocxParagraph(
          children: [
            DocxText(
              '• $note',
              fontSize: 10,
              color: DocxColor(_darkText),
            ),
          ],
          spacingAfter: 20,
        ),
      );
    }
  }

  // ───────────────────────────────────────────────────────────
  // Footer
  // ───────────────────────────────────────────────────────────

  static void _addFooter(DocxDocumentBuilder builder) {
    builder.add(
      DocxParagraph(
        children: [
          DocxText(
            'Thank you for choosing Maa Tee Ent.',
            fontStyle: DocxFontStyle.italic,
            fontSize: 9,
            color: DocxColor(_mutedText),
          ),
        ],
        align: DocxAlign.center,
      ),
    );
  }

  // ───────────────────────────────────────────────────────────
  // Utilities
  // ───────────────────────────────────────────────────────────

  static void _addSpacing(
    DocxDocumentBuilder builder,
    int size,
  ) {
    builder.add(
      DocxParagraph(
        children: [
          DocxText(''),
        ],
        spacingAfter: size,
      ),
    );
  }

  static String _formattedDate() {
    final now = DateTime.now();

    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  static String _estimateNumber() {
    final now = DateTime.now();

    return 'EST-${now.year}-${now.millisecondsSinceEpoch.toString().substring(8)}';
  }

  static String _timestamp() {
    final now = DateTime.now();

    return '${now.year}'
        '${now.month.toString().padLeft(2, '0')}'
        '${now.day.toString().padLeft(2, '0')}_'
        '${now.hour.toString().padLeft(2, '0')}'
        '${now.minute.toString().padLeft(2, '0')}';
  }
}
