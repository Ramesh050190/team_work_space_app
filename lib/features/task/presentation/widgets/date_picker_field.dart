import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:team_workspace/core/constants/app_strings.dart';

class DatePickerField extends StatelessWidget {
  const DatePickerField({
    super.key,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.enabled = true,
    this.label,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final String? errorText;
  final bool enabled;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final resolvedLabel = label ?? strings.dueDate;
    final formatter = DateFormat.yMMMd();
    final display = value == null
        ? strings.selectDate
        : formatter.format(value!);

    return Semantics(
      button: true,
      label: '$resolvedLabel $display',
      child: InkWell(
        onTap: enabled ? () => _pickDate(context) : null,
        borderRadius: BorderRadius.circular(4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: resolvedLabel,
            errorText: errorText,
            border: const OutlineInputBorder(),
            suffixIcon: const Icon(Icons.calendar_today_outlined),
          ),
          child: Text(
            display,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: value == null ? Theme.of(context).hintColor : null,
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickDate(BuildContext context) async {
    final now = DateTime.now();
    final initial = value ?? now.add(const Duration(days: 1));
    final picked = await showDatePicker(
      context: context,
      initialDate: initial.isBefore(now) ? now : initial,
      firstDate: DateTime(now.year, now.month, now.day),
      lastDate: DateTime(now.year + 5),
    );
    if (picked != null) {
      onChanged(picked);
    }
  }
}
