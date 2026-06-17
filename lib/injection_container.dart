import 'package:get_it/get_it.dart';

import 'data/datasources/database_service.dart';
import 'data/repositories/auth_repository.dart';
import 'data/repositories/feedback_repository.dart';
import 'data/services/biometric_service.dart';
import 'data/services/csv_export_service.dart';
import 'data/services/device_info_service.dart';
import 'data/services/media_storage_service.dart';
import 'data/services/pdf_export_service.dart';
import 'presentation/bloc/auth/auth_bloc.dart';
import 'presentation/bloc/export/export_bloc.dart';
import 'presentation/bloc/feedback/feedback_bloc.dart';

final getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt
    ..registerLazySingleton<DatabaseService>(DatabaseService.new)
    ..registerLazySingleton<MediaStorageService>(MediaStorageService.new)
    ..registerLazySingleton<DeviceInfoService>(DeviceInfoService.new)
    ..registerLazySingleton<CsvExportService>(CsvExportService.new)
    ..registerLazySingleton<PdfExportService>(PdfExportService.new)
    ..registerLazySingleton<BiometricService>(BiometricService.new)
    ..registerLazySingleton<AuthRepository>(AuthRepository.new);

  await getIt<MediaStorageService>().initialize();

  getIt.registerLazySingleton<FeedbackRepository>(
    () => FeedbackRepository(
      database: getIt(),
      mediaStorage: getIt(),
      deviceInfo: getIt(),
      csv: getIt(),
      pdf: getIt(),
    ),
  );

  getIt.registerLazySingleton<AuthBloc>(
    () => AuthBloc(authRepository: getIt())..add(const AuthStarted()),
  );

  getIt.registerFactory<FeedbackBloc>(
    () => FeedbackBloc(repository: getIt()),
  );
  getIt.registerFactory<ExportBloc>(
    () => ExportBloc(repository: getIt(), biometric: getIt()),
  );
}