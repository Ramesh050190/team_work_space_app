import 'package:flutter/material.dart';
import 'package:team_workspace/features/task/presentation/pages/task_form_page.dart';

class CreateTaskPage extends StatelessWidget {
  const CreateTaskPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const TaskFormPage.create();
  }
}
