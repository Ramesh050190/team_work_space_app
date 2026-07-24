import 'package:flutter/material.dart';

/// Reusable Material 3 text field for the task form.
class TaskTextField extends StatelessWidget {
  const TaskTextField({
    super.key,
    required this.label,
    required this.onChanged,
    this.controller,
    this.initialValue,
    this.errorText,
    this.maxLines = 1,
    this.maxLength,
    this.enabled = true,
    this.keyboardType,
    this.textInputAction,
    this.semanticLabel,
  });

  final String label;
  final ValueChanged<String> onChanged;
  final TextEditingController? controller;
  final String? initialValue;
  final String? errorText;
  final int maxLines;
  final int? maxLength;
  final bool enabled;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? label,
      textField: true,
      child: TextFormField(
        // Keep field identity stable across Bloc rebuilds so typed text is
        // preserved while [errorText] still updates from decoration.
        key: ValueKey('task-field-$label'),
        controller: controller,
        initialValue: controller == null ? initialValue : null,
        enabled: enabled,
        maxLines: maxLines,
        maxLength: maxLength,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onChanged: onChanged,
        autovalidateMode: AutovalidateMode.disabled,
        decoration: InputDecoration(
          labelText: label,
          errorText: errorText,
          border: const OutlineInputBorder(),
          alignLabelWithHint: maxLines > 1,
        ),
      ),
    );
  }
}
