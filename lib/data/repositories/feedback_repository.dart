import 'dart:io';
import 'dart:typed_data';

import '../datasources/database_service.dart';
import '../models/feedback_entry.dart';
import '../services/csv_export_service.dart';
import '../services/device_info_service.dart';
import '../services/media_storage_service.dart';
import '../services/pdf_export_service.dart';

/// Coordinates the data services to fulfil higher-level feedback use cases.
class FeedbackRepository {
  final DatabaseService _db;
  final MediaStorageService _media;
  final DeviceInfoService _deviceInfo;
  final CsvExportService _csv;
  final PdfExportService _pdf;

  FeedbackRepository({
    required DatabaseService database,
    required MediaStorageService mediaStorage,
    required DeviceInfoService deviceInfo,
    required CsvExportService csv,
    required PdfExportService pdf,
  })  : _db = database,
        _media = mediaStorage,
        _deviceInfo = deviceInfo,
        _csv = csv,
        _pdf = pdf;

  Future<void> submit(FeedbackEntry draft) async {
    final savedMedia = <String>[];
    for (final path in draft.mediaPaths) {
      final file = File(path);
      if (await file.exists()) {
        final savedName = await _media.saveMedia(file);
        savedMedia.add(savedName ?? path);
      }
    }

    final deviceDescription = draft.deviceInfo.isNotEmpty
        ? draft.deviceInfo
        : await _deviceInfo.describe();

    final entry = draft.copyWith(
      mediaPaths: savedMedia.isEmpty ? draft.mediaPaths : savedMedia,
      deviceInfo: deviceDescription,
      createdAt: DateTime.now(),
    );

    await _db.insertFeedback(entry);
  }

  Future<List<FeedbackEntry>> getAll() => _db.getAllFeedback();

  Future<int> count() => _db.count();

  /// Builds the CSV and writes it to scoped storage.
  Future<String?> exportToCsv() async {
    final entries = await _db.getAllFeedback();
    final csv = _csv.buildCsv(entries);
    return _media.saveCsv(csv);
  }

  /// Builds the PDF, saves it, and returns the path plus bytes (for preview).
  Future<({String? path, Uint8List bytes})> exportToPdf() async {
    final entries = await _db.getAllFeedback();
    final bytes = await _pdf.buildPdf(entries);
    final name = 'feedback_export_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final String? path = await _media.saveBytes(bytes, name);
    return (path: path, bytes: bytes);
  }
}