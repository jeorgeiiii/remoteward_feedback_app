part of 'export_bloc.dart';

sealed class ExportEvent extends Equatable {
  const ExportEvent();
  @override
  List<Object?> get props => [];
}

/// The two output formats the owner can export.
enum ExportFormat { csv, pdf }

/// Triggers biometric auth and, on success, the export in the chosen format.
class ExportRequested extends ExportEvent {
  final ExportFormat format;
  const ExportRequested(this.format);
  @override
  List<Object?> get props => [format];
}

/// Refresh the count of stored entries shown on the export screen.
class ExportCountRefreshed extends ExportEvent {
  const ExportCountRefreshed();
}