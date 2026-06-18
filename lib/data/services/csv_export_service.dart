import 'package:csv/csv.dart';

import '../../core/constants/app_constants.dart';
import '../models/feedback_entry.dart';

/// Converts feedback records into the CSV layout required by the assignment:
///
/// Device Owner | User Details | Bug/Issue | User Device | Description and Media Links
class CsvExportService {
  String buildCsv(List<FeedbackEntry> entries) {
    final rows = <List<String>>[
      AppConstants.csvHeaders,
      ...entries.map(_toRow),
    ];
    // Use \r\n so the file opens cleanly in Excel as well as Sheets.
    return const ListToCsvConverter(eol: '\r\n').convert(rows);
  }

  List<String> _toRow(FeedbackEntry e) {
    final owner = '${e.ownerName} <${e.ownerEmail}>';

    final userDetails = [
      'Name: ${e.userName}',
      'Email: ${e.userEmail}',
      'Contact: ${e.userContact}',
    ].join('\n');

    final descAndMedia = StringBuffer(e.description);
    if (e.mediaPaths.isNotEmpty) {
      descAndMedia.write('\n\nMedia:\n');
      descAndMedia.write(e.mediaPaths.join('\n'));
    }

    return [
      owner,
      userDetails,
      e.issueTitle,
      e.deviceInfo,
      descAndMedia.toString(),
    ];
  }
}
