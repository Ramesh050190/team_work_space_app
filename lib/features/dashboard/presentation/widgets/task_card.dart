import 'package:flutter/material.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/core/utils/date_formatter.dart';
import 'package:team_workspace/features/dashboard/domain/entities/task_entity.dart';
import 'package:team_workspace/features/task/domain/entities/task_priority.dart';
import 'package:team_workspace/features/task/presentation/widgets/priority_badge.dart';

/// Card widget displaying a single dashboard task.
class TaskCard extends StatelessWidget {
  const TaskCard({
    super.key,
    required this.task,
    this.onTap,
    this.isPendingSync = false,
  });

  final TaskEntity task;
  final VoidCallback? onTap;

  /// Shows an optimistic-UI badge while a local change awaits sync.
  final bool isPendingSync;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = AppStrings.of(context);
    final TaskPriority priority = TaskPriority.fromString(task.priority);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  _StatusBadge(status: task.status),
                ],
              ),
              if (task.description.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  task.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
              const SizedBox(height: 12),
              PriorityBadge(priority: priority),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      DateFormatter.format(task.createdAt),
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  if (isPendingSync)
                    Semantics(
                      label: strings.waitingForSync,
                      child: Chip(
                        visualDensity: VisualDensity.compact,
                        avatar: Icon(
                          Icons.cloud_upload_outlined,
                          size: 16,
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        label: Text(strings.waitingForSync),
                        labelStyle: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSecondaryContainer,
                        ),
                        backgroundColor: theme.colorScheme.secondaryContainer,
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final normalized = status.toLowerCase().replaceAll('_', ' ');
    final (bg, fg) = _colorsFor(theme, normalized);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _label(normalized),
        style: theme.textTheme.labelSmall?.copyWith(
          color: fg,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  String _label(String normalized) {
    if (normalized.isEmpty) return 'Pending';
    return normalized
        .split(' ')
        .map(
          (part) => part.isEmpty
              ? part
              : '${part[0].toUpperCase()}${part.substring(1)}',
        )
        .join(' ');
  }

  (Color, Color) _colorsFor(ThemeData theme, String normalized) {
    final scheme = theme.colorScheme;
    switch (normalized) {
      case 'completed':
        return (scheme.primaryContainer, scheme.onPrimaryContainer);
      case 'in progress':
      case 'inprogress':
        return (scheme.tertiaryContainer, scheme.onTertiaryContainer);
      case 'pending':
      default:
        return (scheme.secondaryContainer, scheme.onSecondaryContainer);
    }
  }
}
