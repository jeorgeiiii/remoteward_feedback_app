import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/feedback_entry.dart';

/// Builds a human-readable PDF report of all feedback entries.
class PdfExportService {
  Future<Uint8List> buildPdf(List<FeedbackEntry> entries) async {
    final doc = pw.Document();
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
          ...entries.map(_entryBlock),
        ],
      ),
    );
    return doc.save();
  }

  pw.Widget _entryBlock(FeedbackEntry e) {
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
          if (e.mediaPaths.isNotEmpty) _kv('Media', e.mediaPaths.join(', ')),
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