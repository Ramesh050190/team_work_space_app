import 'package:equatable/equatable.dart';

class AssignedUser extends Equatable {
  const AssignedUser({
    required this.id,
    required this.name,
    required this.email,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String? avatarUrl;

  @override
  List<Object?> get props => [id, name, email, avatarUrl];
}
