import 'package:flutter/material.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';

class PriorityDropdown extends StatelessWidget {
  const PriorityDropdown({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
  });

  final TaskPriority? value;
  final ValueChanged<TaskPriority?> onChanged;
  final String? errorText;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return Semantics(
      label: strings.priority,
      child: DropdownButtonFormField<TaskPriority>(
        key: ValueKey(value),
        initialValue: value,
        decoration: InputDecoration(
          labelText: strings.priority,
          errorText: errorText,
          border: const OutlineInputBorder(),
        ),
        items: TaskPriority.values
            .map(
              (priority) => DropdownMenuItem(
                value: priority,
                child: Text(strings.priorityLabel(priority)),
              ),
            )
            .toList(),
        onChanged: enabled ? onChanged : null,
      ),
    );
  }
}
