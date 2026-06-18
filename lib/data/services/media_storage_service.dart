import 'dart:io';
import 'dart:typed_data';

import 'package:media_store_plus/media_store_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';

/// Handles persistent media storage. Picked files are copied into the app's
/// own documents directory (a stable, permanent location) AND mirrored into
/// the public Downloads folder via MediaStore for the assignment requirement.
class MediaStorageService {
  final MediaStore _mediaStore = MediaStore();

  Future<void> initialize() async {
    await MediaStore.ensureInitialized();
    MediaStore.appFolder = AppConstants.exportFolder;
  }

  Future<bool> ensurePermission() async {
    if (!Platform.isAndroid) return true;
    final status = await Permission.storage.request();
    return status.isGranted || status.isLimited || status.isPermanentlyDenied;
  }

  /// Copies a picked file into the app's documents dir under /feedback_media,
  /// returning the **permanent path**. This is what we store in the DB so the
  /// file is still readable at export time. Also mirrors to public Downloads.
  Future<String?> saveMedia(File file) async {
    final docs = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(docs.path, 'feedback_media'));
    if (!await mediaDir.exists()) {
      await mediaDir.create(recursive: true);
    }

    // Unique, stable filename inside app storage.
    final stamped =
        '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}';
    final permanentPath = p.join(mediaDir.path, stamped);
    await file.copy(permanentPath);

    // Also drop a copy into public Downloads (best-effort; ignore failure).
    try {
      await _mediaStore.saveFile(
        tempFilePath: file.path,
        dirType: DirType.download,
        dirName: DirName.download,
      );
    } catch (_) {}

    return permanentPath;
  }

  /// Writes CSV text to Downloads/FeedbackCollector.
  Future<String?> saveCsv(String csvContent, {String? fileName}) async {
    final name = fileName ??
        'feedback_export_${DateTime.now().millisecondsSinceEpoch}.csv';

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, name));
    await tempFile.writeAsString(csvContent);

    final info = await _mediaStore.saveFile(
      tempFilePath: tempFile.path,
      dirType: DirType.download,
      dirName: DirName.download,
    );

    if (await tempFile.exists()) await tempFile.delete();
    return info?.name ?? 'Downloads/${AppConstants.exportFolder}/$name';
  }

  /// Writes raw bytes (e.g. a PDF) to Downloads/FeedbackCollector.
  Future<String?> saveBytes(Uint8List bytes, String fileName) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File(p.join(tempDir.path, fileName));
    await tempFile.writeAsBytes(bytes);

    await _mediaStore.saveFile(
      tempFilePath: tempFile.path,
      dirType: DirType.download,
      dirName: DirName.download,
    );

    if (await tempFile.exists()) await tempFile.delete();
    return 'Downloads/${AppConstants.exportFolder}/$fileName';
  }
}