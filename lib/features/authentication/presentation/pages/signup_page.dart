import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/core/constants/route_constants.dart';
import 'package:team_workspace/core/widgets/language_switcher_button.dart';
import 'package:team_workspace/core/widgets/primary_button.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_event.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_state.dart';
import 'package:team_workspace/features/authentication/presentation/widgets/auth_scaffold.dart';
import 'package:team_workspace/features/authentication/presentation/widgets/email_text_field.dart';
import 'package:team_workspace/features/authentication/presentation/widgets/password_text_field.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;

    context.read<AuthBloc>().add(
      AuthSignupRequested(
        email: _emailController.text.trim().toLowerCase(),
        password: _passwordController.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listenWhen: (previous, current) => current is AuthFailure,
      listener: (context, state) {
        if (state is AuthFailure) {
          ScaffoldMessenger.of(context)
            ..hideCurrentSnackBar()
            ..showSnackBar(SnackBar(content: Text(state.message)));
          context.read<AuthBloc>().add(const AuthErrorReset());
        }
      },
      builder: (context, state) {
        final isLoading = state is AuthLoading;
        final strings = AppStrings.of(context);

        return AuthenticationWidget(
          title: strings.createAccount,
          actions: const [LanguageSwitcherButton()],
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                EmailTextField(controller: _emailController),
                const SizedBox(height: 16),
                PasswordTextField(controller: _passwordController),
                const SizedBox(height: 16),
                PasswordTextField(
                  controller: _confirmPasswordController,
                  label: strings.confirmPassword,
                  validator: (value) => strings.validateConfirmPassword(
                    value,
                    _passwordController.text,
                  ),
                ),
                const SizedBox(height: 24),
                PrimaryButton(
                  label: strings.createAccount,
                  isLoading: isLoading,
                  onPressed: isLoading ? null : _submit,
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: isLoading
                      ? null
                      : () => context.go(RouteConstants.login),
                  child: Text(strings.alreadyHaveAccountLogin),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
