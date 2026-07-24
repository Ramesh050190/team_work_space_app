import 'package:flutter/material.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/domain/entities/task_status.dart';

/// Bottom sheet with one status column and one priority column.
class TaskFilterBottomSheet extends StatefulWidget {
  const TaskFilterBottomSheet({
    super.key,
    this.initialStatus,
    this.initialPriority,
    required this.onApply,
  });

  final TaskStatus? initialStatus;
  final TaskPriority? initialPriority;
  final void Function({TaskStatus? status, TaskPriority? priority}) onApply;

  static Future<void> show(
    BuildContext context, {
    TaskStatus? initialStatus,
    TaskPriority? initialPriority,
    required void Function({TaskStatus? status, TaskPriority? priority})
    onApply,
  }) {
    final width = MediaQuery.sizeOf(context).width;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (context) {
        return SizedBox(
          width: width,
          child: TaskFilterBottomSheet(
            initialStatus: initialStatus,
            initialPriority: initialPriority,
            onApply: onApply,
          ),
        );
      },
    );
  }

  @override
  State<TaskFilterBottomSheet> createState() => _TaskFilterBottomSheetState();
}

class _TaskFilterBottomSheetState extends State<TaskFilterBottomSheet> {
  late TaskStatus? _status = widget.initialStatus;
  late TaskPriority? _priority = widget.initialPriority;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              strings.filters,
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 20),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _FilterColumn(
                    title: strings.status,
                    child: Column(
                      children: [
                        _FilterOption(
                          label: strings.all,
                          selected: _status == null,
                          onTap: () => setState(() => _status = null),
                        ),
                        ...TaskStatus.values.map(
                          (status) => _FilterOption(
                            label: _statusLabel(strings, status),
                            selected: _status == status,
                            onTap: () => setState(() => _status = status),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _FilterColumn(
                    title: strings.priority,
                    child: Column(
                      children: [
                        _FilterOption(
                          label: strings.all,
                          selected: _priority == null,
                          onTap: () => setState(() => _priority = null),
                        ),
                        ...TaskPriority.values.map(
                          (priority) => _FilterOption(
                            label: _priorityLabel(strings, priority),
                            selected: _priority == priority,
                            onTap: () => setState(() => _priority = priority),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      setState(() {
                        _status = null;
                        _priority = null;
                      });
                    },
                    child: Text(strings.clearAll),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: () {
                      widget.onApply(status: _status, priority: _priority);
                      Navigator.of(context).pop();
                    },
                    child: Text(strings.apply),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(AppStrings strings, TaskStatus status) {
    return switch (status) {
      TaskStatus.pending => strings.statusPending,
      TaskStatus.inProgress => strings.statusInProgress,
      TaskStatus.completed => strings.statusCompleted,
    };
  }

  String _priorityLabel(AppStrings strings, TaskPriority priority) {
    return switch (priority) {
      TaskPriority.low => strings.priorityLow,
      TaskPriority.medium => strings.priorityMedium,
      TaskPriority.high => strings.priorityHigh,
    };
  }
}

class _FilterColumn extends StatelessWidget {
  const _FilterColumn({required this.title, required this.child});

  final String title;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          title,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}

class _FilterOption extends StatelessWidget {
  const _FilterOption({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Material(
        color: selected
            ? theme.colorScheme.primaryContainer
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                      color: selected
                          ? theme.colorScheme.onPrimaryContainer
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                ),
                if (selected)
                  Icon(
                    Icons.check,
                    size: 18,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
