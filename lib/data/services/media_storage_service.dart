import 'dart:io';
import 'dart:typed_data';

import 'package:media_store_plus/media_store_plus.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../core/constants/app_constants.dart';

/// Handles writing files to the device's public **Downloads** folder using
/// Android's scoped-storage MediaStore API (via media_store_plus).
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

  /// Saves a picked media file two ways:
  ///  1. A copy into public Downloads (scoped-storage requirement).
  ///  2. A persistent copy inside the app's own documents dir, whose absolute
  ///     path is returned — so it can be embedded later (e.g. in the PDF).
  Future<String?> saveMedia(File file) async {
    // 1. Public Downloads copy.
    await _mediaStore.saveFile(
      tempFilePath: file.path,
      dirType: DirType.download,
      dirName: DirName.download,
    );

    // 2. Persistent in-app copy (the picker's cache file can be cleared).
    final docsDir = await getApplicationDocumentsDirectory();
    final mediaDir = Directory(p.join(docsDir.path, 'media'));
    if (!await mediaDir.exists()) await mediaDir.create(recursive: true);

    final dest = p.join(
      mediaDir.path,
      '${DateTime.now().millisecondsSinceEpoch}_${p.basename(file.path)}',
    );
    final saved = await file.copy(dest);
    return saved.path; // absolute, readable path
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