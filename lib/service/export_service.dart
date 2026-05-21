import 'dart:io';
import 'package:estimate_maker/model/estimate_entry.dart';
import 'package:flutter/services.dart';
import 'package:docx_template/docx_template.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';


class ExportService {
  /// Last error message captured during an export attempt (for debugging).
  static String? lastError;
  /// Generates a .docx estimate and triggers the native share sheet.
  /// Returns true on success, false on failure.
  static Future<bool> exportEstimate({
    required List<EstimateEntry> entries,
    required double grossTotal,
  }) async {
    lastError = null;
    try {
      // ── 1. Load the template from assets ──────────────────────────
      final templateBytes = await rootBundle.load(
        'assets/estimate_template.docx',
      );
      final bytes = templateBytes.buffer.asUint8List();

      // Quick validation: a .docx file is a ZIP archive and must start with PK\x03\x04
      if (bytes.length < 4 || bytes[0] != 0x50 || bytes[1] != 0x4B) {
        final msg = 'Template file is not a valid .docx (missing ZIP header).'
            ' Size=${bytes.length}';
        print(msg);
        lastError = msg;
        return false;
      }

      final template = await DocxTemplate.fromBytes(bytes);

      // ── 2. Build the content map ───────────────────────────────────
      // Each key matches a {placeholder} in the template exactly.
      final content = Content()
        ..add(TableContent('entries', [
          for (final entry in entries)
            RowContent()
              ..add(TextContent('tile_name', entry.tile.name))
              ..add(TextContent('finish', entry.tile.finish))
              ..add(TextContent(
                'room_area',
                entry.roomArea.toStringAsFixed(2),
              ))
              ..add(TextContent('boxes', '${entry.boxesNeeded}'))
              ..add(TextContent(
                'entry_total',
                entry.entryTotal.toStringAsFixed(2),
              )),
        ]))
        ..add(TextContent('date', _formattedDate()))
        ..add(TextContent(
          'gross_total',
          grossTotal.toStringAsFixed(2),
        ));

      // ── 3. Generate the document ───────────────────────────────────
      final generated = await template.generate(content);
      if (generated == null) return false;

      // ── 4. Write to a temp file ────────────────────────────────────
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/tile_estimate_${_timestamp()}.docx');
      await file.writeAsBytes(generated);

      // ── 5. Trigger native share sheet ─────────────────────────────
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Tile Estimate',
        text: 'Please find the tile estimate attached.',
      );

      return true;
    } catch (e, st) {
      // Log the error and stacktrace to help debugging when export fails
      // (previously swallowed silently).
      // Use print so the message appears in debug console / adb logs.
      final msg = 'ExportService.exportEstimate failed: $e';
      print(msg);
      print(st);
      lastError = '$msg\n$st';
      return false;
    }
  }

  static String _formattedDate() {
    final now = DateTime.now();
    return '${now.day.toString().padLeft(2, '0')}/'
        '${now.month.toString().padLeft(2, '0')}/'
        '${now.year}';
  }

  static String _timestamp() {
    final now = DateTime.now();
    return '${now.year}${now.month}${now.day}_'
        '${now.hour}${now.minute}';
  }
}