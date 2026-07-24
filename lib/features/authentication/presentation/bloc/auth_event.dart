import 'package:equatable/equatable.dart';
import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

final class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

final class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthSignupRequested extends AuthEvent {
  const AuthSignupRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

final class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}

final class AuthStateChanged extends AuthEvent {
  const AuthStateChanged(this.user);

  final AppUser? user;

  @override
  List<Object?> get props => [user];
}

final class AuthErrorReset extends AuthEvent {
  const AuthErrorReset();
}
