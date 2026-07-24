import 'package:flutter/material.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final TaskStatus status;

  ({Color background, Color foreground}) _colors(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    switch (status) {
      case TaskStatus.pending:
        return (
          background: scheme.secondaryContainer,
          foreground: scheme.onSecondaryContainer,
        );
      case TaskStatus.inProgress:
        return (
          background: scheme.primaryContainer,
          foreground: scheme.onPrimaryContainer,
        );
      case TaskStatus.completed:
        return (
          background: scheme.tertiaryContainer,
          foreground: scheme.onTertiaryContainer,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = _colors(context);
    final strings = AppStrings.of(context);
    final label = strings.statusLabel(status);

    return Semantics(
      label: '${strings.status} $label',
      child: Chip(
        label: Text(label),
        backgroundColor: colors.background,
        labelStyle: TextStyle(color: colors.foreground),
        side: BorderSide.none,
      ),
    );
  }
}
