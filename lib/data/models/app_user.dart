import 'package:equatable/equatable.dart';

/// Lightweight representation of the authenticated device owner.
/// Decouples the rest of the app from the Firebase `User` type.
class AppUser extends Equatable {
  final String uid;
  final String name;
  final String email;
  final String? photoUrl;

  const AppUser({
    required this.uid,
    required this.name,
    required this.email,
    this.photoUrl,
  });

  @override
  List<Object?> get props => [uid, name, email, photoUrl];
}
