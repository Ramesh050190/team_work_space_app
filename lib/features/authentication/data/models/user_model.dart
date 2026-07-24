import 'package:equatable/equatable.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';

class UserModel extends Equatable {
  const UserModel({required this.uid, required this.email, this.displayName});

  final String uid;
  final String email;
  final String? displayName;

  factory UserModel.fromFirebaseUser(User user) {
    return UserModel(
      uid: user.uid,
      email: user.email ?? '',
      displayName: user.displayName,
    );
  }

  AppUser toEntity() {
    return AppUser(uid: uid, email: email, displayName: displayName);
  }

  @override
  List<Object?> get props => [uid, email, displayName];
}
