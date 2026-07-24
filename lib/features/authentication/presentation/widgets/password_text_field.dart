import 'package:flutter/material.dart';
import 'package:team_workspace/core/constants/app_strings.dart';

class PasswordTextField extends StatelessWidget {
  const PasswordTextField({
    super.key,
    required this.controller,
    this.label,
    this.validator,
  });

  final TextEditingController controller;
  final String? label;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return _PasswordTextFieldStateful(
      controller: controller,
      label: label ?? strings.password,
      validator: validator ?? strings.validatePassword,
    );
  }
}

class _PasswordTextFieldStateful extends StatefulWidget {
  const _PasswordTextFieldStateful({
    required this.controller,
    required this.label,
    required this.validator,
  });

  final TextEditingController controller;
  final String label;
  final String? Function(String?)? validator;

  @override
  State<_PasswordTextFieldStateful> createState() =>
      _PasswordTextFieldStatefulState();
}

class _PasswordTextFieldStatefulState
    extends State<_PasswordTextFieldStateful> {
  bool _obscureText = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _obscureText,
      validator: widget.validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      autofillHints: const [AutofillHints.password],
      decoration: InputDecoration(
        labelText: widget.label,
        suffixIcon: IconButton(
          icon: Icon(_obscureText ? Icons.visibility_off : Icons.visibility),
          onPressed: () => setState(() => _obscureText = !_obscureText),
        ),
      ),
    );
  }
}
