/// App-wide constants. Kept in one place so changing a value (db name,
/// route name, CSV header) never means hunting through the codebase.
class AppConstants {
  AppConstants._();

  static const String appName = 'Feedback Collector';

  // Database
  static const String dbName = 'feedback.db';
  static const int dbVersion = 1;
  static const String feedbackTable = 'feedback';

  // Folder name used inside the public Downloads directory.
  static const String exportFolder = 'FeedbackCollector';

  // CSV header — matches the format required by the assignment.
  static const List<String> csvHeaders = [
    'Device Owner',
    'User Details',
    'Bug/Issue',
    'User Device',
    'Description and Media Links',
  ];
}

/// Named routes.
class Routes {
  Routes._();
  static const String login = '/login';
  static const String userDetails = '/user-details';
  static const String bugDescription = '/bug-description';
  static const String media = '/media';
  static const String thankYou = '/thank-you';
  static const String export = '/export';
}
