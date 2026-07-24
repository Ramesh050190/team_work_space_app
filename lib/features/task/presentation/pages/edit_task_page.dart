import 'package:flutter/material.dart';
import 'package:team_workspace/features/task/presentation/pages/task_form_page.dart';

class EditTaskPage extends StatelessWidget {
  const EditTaskPage({super.key, required this.taskId});

  final int taskId;

  @override
  Widget build(BuildContext context) {
    return TaskFormPage.edit(taskId: taskId);
  }
}
