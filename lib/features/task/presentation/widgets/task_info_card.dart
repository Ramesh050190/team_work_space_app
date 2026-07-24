import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/features/task/domain/entities/task.dart';
import 'package:team_workspace/features/task/presentation/widgets/assigned_user_tile.dart';
import 'package:team_workspace/features/task/presentation/widgets/info_tile.dart';
import 'package:team_workspace/features/task/presentation/widgets/priority_badge.dart';
import 'package:team_workspace/features/task/presentation/widgets/status_chip.dart';
import 'package:team_workspace/features/task/presentation/widgets/task_section_title.dart';

class TaskInfoCard extends StatelessWidget {
  const TaskInfoCard({super.key, required this.task});

  final Task task;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat.yMMMd();
    final strings = AppStrings.of(context);

    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TaskSectionTitle(title: strings.description),
            Text(
              task.description.isEmpty
                  ? strings.noDescription
                  : task.description,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                PriorityBadge(priority: task.priority),
                StatusChip(status: task.status),
              ],
            ),
            const SizedBox(height: 20),
            InfoTile(
              icon: Icons.event_outlined,
              label: strings.dueDate,
              value: dateFormat.format(task.dueDate.toLocal()),
            ),
            const SizedBox(height: 16),
            TaskSectionTitle(title: strings.assignedUser),
            AssignedUserTile(user: task.assignedUser),
            const SizedBox(height: 12),
            InfoTile(
              icon: Icons.update_outlined,
              label: strings.lastUpdated,
              value: dateFormat.format(task.updatedAt.toLocal()),
            ),
          ],
        ),
      ),
    );
  }
}
