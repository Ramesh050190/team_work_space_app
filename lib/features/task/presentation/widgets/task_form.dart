import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_bloc.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_event.dart';
import 'package:team_workspace/features/task/presentation/bloc/task_form/task_form_state.dart';
import 'package:team_workspace/features/task/presentation/widgets/date_picker_field.dart';
import 'package:team_workspace/features/task/presentation/widgets/primary_action_button.dart';
import 'package:team_workspace/features/task/presentation/widgets/priority_dropdown.dart';
import 'package:team_workspace/features/task/presentation/widgets/status_dropdown.dart';
import 'package:team_workspace/features/task/presentation/widgets/task_text_field.dart';
import 'package:team_workspace/features/task/presentation/widgets/validation_message.dart';

/// Shared create/edit form. All business logic lives in [TaskFormBloc].
class TaskForm extends StatelessWidget {
  const TaskForm({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TaskFormBloc, TaskFormState>(
      builder: (context, state) {
        final form = switch (state) {
          TaskFormEditing() => state,
          TaskFormSubmitting(:final form) => form,
          TaskFormFailure(:final form) => form,
          TaskFormValidationError(:final form) => form,
          _ => null,
        };

        if (form == null) {
          return const Center(child: CircularProgressIndicator());
        }

        final isSubmitting = state is TaskFormSubmitting;
        final isEdit = form.isEditMode;
        final strings = AppStrings.of(context);

        return AbsorbPointer(
          absorbing: isSubmitting,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (form.submitError != null) ...[
                ValidationMessage(
                  message: strings.resolveMessage(form.submitError),
                ),
                const SizedBox(height: 16),
              ],
              TaskTextField(
                label: strings.title,
                initialValue: form.title,
                errorText: form.titleError == null
                    ? null
                    : strings.resolveMessage(form.titleError),
                enabled: !isSubmitting,
                maxLength: 100,
                textInputAction: TextInputAction.next,
                onChanged: (value) {
                  context.read<TaskFormBloc>().add(TitleChanged(value));
                },
              ),
              const SizedBox(height: 16),
              TaskTextField(
                label: strings.description,
                initialValue: form.description,
                errorText: form.descriptionError == null
                    ? null
                    : strings.resolveMessage(form.descriptionError),
                enabled: !isSubmitting,
                maxLines: 4,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                onChanged: (value) {
                  context.read<TaskFormBloc>().add(DescriptionChanged(value));
                },
              ),
              const SizedBox(height: 16),
              PriorityDropdown(
                value: form.priority,
                errorText: form.priorityError == null
                    ? null
                    : strings.resolveMessage(form.priorityError),
                enabled: !isSubmitting,
                onChanged: (priority) {
                  if (priority != null) {
                    context.read<TaskFormBloc>().add(PriorityChanged(priority));
                  }
                },
              ),
              if (isEdit) ...[
                const SizedBox(height: 16),
                StatusDropdown(
                  value: form.status,
                  enabled: !isSubmitting,
                  onChanged: (status) {
                    if (status != null) {
                      context.read<TaskFormBloc>().add(StatusChanged(status));
                    }
                  },
                ),
              ],
              const SizedBox(height: 16),
              DatePickerField(
                value: form.dueDate,
                errorText: form.dueDateError == null
                    ? null
                    : strings.resolveMessage(form.dueDateError),
                enabled: !isSubmitting,
                onChanged: (date) {
                  context.read<TaskFormBloc>().add(DueDateChanged(date));
                },
              ),
              const SizedBox(height: 32),
              PrimaryActionButton(
                label: isEdit ? strings.updateTask : strings.createTask,
                isLoading: isSubmitting,
                onPressed: () {
                  final bloc = context.read<TaskFormBloc>();
                  if (isEdit) {
                    bloc.add(const SubmitUpdateTask());
                  } else {
                    bloc.add(const SubmitCreateTask());
                  }
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
