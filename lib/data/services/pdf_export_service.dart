import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/feedback_entry.dart';

/// Builds a human-readable PDF report, embedding attached images.
class PdfExportService {
  static const _imageExt = ['.png', '.jpg', '.jpeg', '.gif', '.bmp', '.webp'];

  Future<Uint8List> buildPdf(List<FeedbackEntry> entries) async {
    final doc = pw.Document();

    final imagesByEntry = <int, List<pw.MemoryImage>>{};
    for (var i = 0; i < entries.length; i++) {
      final imgs = <pw.MemoryImage>[];
      for (final path in entries[i].mediaPaths) {
        if (!_imageExt.contains(p.extension(path).toLowerCase())) continue;
        try {
          final file = File(path);
          if (await file.exists()) {
            imgs.add(pw.MemoryImage(await file.readAsBytes()));
          }
        } catch (_) {}
      }
      imagesByEntry[i] = imgs;
    }

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (context) => [
          pw.Text('Feedback Report',
              style: pw.TextStyle(fontSize: 22, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Total entries: ${entries.length}'),
          pw.SizedBox(height: 16),
          for (var i = 0; i < entries.length; i++)
            _entryBlock(entries[i], imagesByEntry[i] ?? const []),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _entryBlock(FeedbackEntry e, List<pw.MemoryImage> images) {
    final nonImageMedia = e.mediaPaths
        .where((m) => !_imageExt.contains(p.extension(m).toLowerCase()))
        .toList();

    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 14),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey400),
        borderRadius: pw.BorderRadius.circular(6),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(e.issueTitle.isEmpty ? '(no title)' : e.issueTitle,
              style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 6),
          _kv('Device Owner', '${e.ownerName} <${e.ownerEmail}>'),
          _kv('User Name', e.userName),
          _kv('User Email', e.userEmail),
          _kv('User Contact', e.userContact),
          _kv('User Device', e.deviceInfo),
          _kv('Description', e.description),
          if (nonImageMedia.isNotEmpty)
            _kv('Other media', nonImageMedia.map(p.basename).join(', ')),
          if (images.isNotEmpty) ...[
            pw.SizedBox(height: 8),
            pw.Text('Attachments:',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 6),
            pw.Wrap(
              spacing: 8,
              runSpacing: 8,
              children: images
                  .map((img) => pw.SizedBox(
                        width: 150,
                        height: 150,
                        child: pw.Image(img, fit: pw.BoxFit.cover),
                      ))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  pw.Widget _kv(String k, String v) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.RichText(
        text: pw.TextSpan(children: [
          pw.TextSpan(
              text: '$k: ',
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
          pw.TextSpan(text: v.isEmpty ? '-' : v),
        ]),
      ),
    );
  }
}