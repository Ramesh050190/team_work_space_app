import 'package:flutter/material.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/core/widgets/custom_text_field.dart';

class EmailTextField extends StatelessWidget {
  const EmailTextField({super.key, required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    return CustomTextField(
      controller: controller,
      label: strings.email,
      hint: strings.emailHint,
      keyboardType: TextInputType.emailAddress,
      validator: strings.validateEmail,
    );
  }
}
