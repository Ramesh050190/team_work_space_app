import 'package:flutter/material.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

class StatusDropdown extends StatelessWidget {
  const StatusDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.enabled = true,
  });

  final TaskStatus value;
  final ValueChanged<TaskStatus?> onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Semantics(
      label: strings.status,
      child: DropdownButtonFormField<TaskStatus>(
        key: ValueKey(value),
        initialValue: value,
        decoration: InputDecoration(
          labelText: strings.status,
          border: const OutlineInputBorder(),
        ),
        items: TaskStatus.values
            .map(
              (status) => DropdownMenuItem(
                value: status,
                child: Text(strings.statusLabel(status)),
              ),
            )
            .toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
