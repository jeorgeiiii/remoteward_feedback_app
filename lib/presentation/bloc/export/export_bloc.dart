import 'dart:typed_data';

import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../../data/repositories/feedback_repository.dart';
import '../../../data/services/biometric_service.dart';

part 'export_event.dart';
part 'export_state.dart';

/// Handles the secure export flow: device-credential auth first, then
/// CSV or PDF generation and scoped-storage write.
class ExportBloc extends Bloc<ExportEvent, ExportState> {
  final FeedbackRepository _repository;
  final BiometricService _biometric;

  ExportBloc({
    required FeedbackRepository repository,
    required BiometricService biometric,
  })  : _repository = repository,
        _biometric = biometric,
        super(const ExportState()) {
    on<ExportRequested>(_onRequested);
    on<ExportCountRefreshed>(_onCountRefreshed);
  }

  Future<void> _onCountRefreshed(
    ExportCountRefreshed event,
    Emitter<ExportState> emit,
  ) async {
    final count = await _repository.count();
    emit(state.copyWith(entryCount: count, status: ExportStatus.idle));
  }

  Future<void> _onRequested(
    ExportRequested event,
    Emitter<ExportState> emit,
  ) async {
    final count = await _repository.count();
    if (count == 0) {
      emit(state.copyWith(
        status: ExportStatus.failure,
        error: 'There is no feedback to export yet.',
      ));
      return;
    }

    // 1. Device-credential gate (fingerprint / PIN / pattern / password).
    emit(state.copyWith(status: ExportStatus.authenticating, error: null));
    final outcome = await _biometric.authenticate();
    if (outcome == AuthOutcome.lockNotSet) {
      emit(state.copyWith(
        status: ExportStatus.lockNotSet,
        error: 'No screen lock found. Set up a PIN, pattern, or password in '
            'your device settings, then try exporting again.',
      ));
      return;
    }
    if (outcome != AuthOutcome.success) {
      emit(state.copyWith(status: ExportStatus.authFailed));
      return;
    }

    // 2. Export in the requested format.
    emit(state.copyWith(status: ExportStatus.exporting));
    try {
      if (event.format == ExportFormat.pdf) {
        final res = await _repository.exportToPdf();
        emit(state.copyWith(
          status: ExportStatus.success,
          savedPath: res.path,
          pdfBytes: res.bytes,
        ));
      } else {
        final path = await _repository.exportToCsv();
        emit(state.copyWith(status: ExportStatus.success, savedPath: path));
      }
    } catch (e) {
      emit(state.copyWith(
        status: ExportStatus.failure,
        error: 'Export failed. Check storage permissions and try again.',
      ));
    }
  }
}