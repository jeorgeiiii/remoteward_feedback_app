part of 'export_bloc.dart';

enum ExportStatus {
  idle,
  authenticating,
  exporting,
  success,
  failure,
  authFailed,
  lockNotSet,
}

class ExportState extends Equatable {
  final ExportStatus status;
  final int entryCount;
  final String? savedPath;
  final String? error;
  final Uint8List? pdfBytes;

  const ExportState({
    this.status = ExportStatus.idle,
    this.entryCount = 0,
    this.savedPath,
    this.error,
    this.pdfBytes,
  });

  ExportState copyWith({
    ExportStatus? status,
    int? entryCount,
    String? savedPath,
    String? error,
    Uint8List? pdfBytes,
  }) {
    return ExportState(
      status: status ?? this.status,
      entryCount: entryCount ?? this.entryCount,
      savedPath: savedPath,
      error: error,
      pdfBytes: pdfBytes,
    );
  }

  @override
  List<Object?> get props => [status, entryCount, savedPath, error];
}