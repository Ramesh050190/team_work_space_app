import 'package:flutter/material.dart';
import 'package:team_workspace/features/task/domain/entities/assigned_user.dart';

class AssignedUserTile extends StatelessWidget {
  const AssignedUserTile({super.key, required this.user});

  final AssignedUser user;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Assigned to ${user.name}',
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: Text(
            _initials(user.name),
            style: TextStyle(
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
          ),
        ),
        title: Text(user.name),
        subtitle: Text(user.email),
      ),
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, 1).toUpperCase();
    }
    return '${parts.first.substring(0, 1)}${parts.last.substring(0, 1)}'
        .toUpperCase();
  }
}
