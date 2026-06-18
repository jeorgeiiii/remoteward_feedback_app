import 'package:equatable/equatable.dart';

/// A single feedback record. This is both the draft (built up across the three
/// collection screens) and the persisted entity (stored in SQLite).
///
/// Media paths are stored in the DB as a single pipe-delimited string and
/// exposed here as a `List<String>` for convenience.
class FeedbackEntry extends Equatable {
  final int? id;

  // Device owner (the authenticated Google account using the app).
  final String ownerName;
  final String ownerEmail;

  // Details of the user submitting feedback.
  final String userName;
  final String userEmail;
  final String userContact;

  // The bug / issue.
  final String issueTitle;
  final String description;

  // The user's device info (model + OS).
  final String deviceInfo;

  // Local file paths / URIs to attached media.
  final List<String> mediaPaths;

  final DateTime createdAt;

  const FeedbackEntry({
    this.id,
    this.ownerName = '',
    this.ownerEmail = '',
    this.userName = '',
    this.userEmail = '',
    this.userContact = '',
    this.issueTitle = '',
    this.description = '',
    this.deviceInfo = '',
    this.mediaPaths = const [],
    required this.createdAt,
  });

  factory FeedbackEntry.empty() =>
      FeedbackEntry(createdAt: DateTime.now());

  FeedbackEntry copyWith({
    int? id,
    String? ownerName,
    String? ownerEmail,
    String? userName,
    String? userEmail,
    String? userContact,
    String? issueTitle,
    String? description,
    String? deviceInfo,
    List<String>? mediaPaths,
    DateTime? createdAt,
  }) {
    return FeedbackEntry(
      id: id ?? this.id,
      ownerName: ownerName ?? this.ownerName,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userContact: userContact ?? this.userContact,
      issueTitle: issueTitle ?? this.issueTitle,
      description: description ?? this.description,
      deviceInfo: deviceInfo ?? this.deviceInfo,
      mediaPaths: mediaPaths ?? this.mediaPaths,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'owner_name': ownerName,
      'owner_email': ownerEmail,
      'user_name': userName,
      'user_email': userEmail,
      'user_contact': userContact,
      'issue_title': issueTitle,
      'description': description,
      'device_info': deviceInfo,
      'media_paths': mediaPaths.join('|'),
      'created_at': createdAt.toIso8601String(),
    };
  }

  factory FeedbackEntry.fromMap(Map<String, dynamic> map) {
    final raw = (map['media_paths'] as String?) ?? '';
    return FeedbackEntry(
      id: map['id'] as int?,
      ownerName: map['owner_name'] as String? ?? '',
      ownerEmail: map['owner_email'] as String? ?? '',
      userName: map['user_name'] as String? ?? '',
      userEmail: map['user_email'] as String? ?? '',
      userContact: map['user_contact'] as String? ?? '',
      issueTitle: map['issue_title'] as String? ?? '',
      description: map['description'] as String? ?? '',
      deviceInfo: map['device_info'] as String? ?? '',
      mediaPaths:
          raw.isEmpty ? const [] : raw.split('|').where((e) => e.isNotEmpty).toList(),
      createdAt:
          DateTime.tryParse(map['created_at'] as String? ?? '') ?? DateTime.now(),
    );
  }

  @override
  List<Object?> get props => [
        id,
        ownerName,
        ownerEmail,
        userName,
        userEmail,
        userContact,
        issueTitle,
        description,
        deviceInfo,
        mediaPaths,
        createdAt,
      ];
}
