import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/core/localization/locale_cubit.dart';
import 'package:team_workspace/core/theme/app_theme_cubit.dart';
import 'package:team_workspace/features/authentication/domain/entities/app_user.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_bloc.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_event.dart';
import 'package:team_workspace/features/authentication/presentation/bloc/auth_state.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(strings.profile)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            BlocBuilder<AuthBloc, AuthState>(
              builder: (context, state) {
                final user = state is AuthAuthenticated ? state.user : null;
                return _ProfileHeader(user: user);
              },
            ),
            const SizedBox(height: 24),
            Text(
              strings.theme,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            BlocBuilder<AppThemeCubit, ThemeMode>(
              builder: (context, mode) {
                return Card(
                  margin: EdgeInsets.zero,
                  child: RadioGroup<ThemeMode>(
                    groupValue: mode,
                    onChanged: (value) {
                      if (value != null) {
                        context.read<AppThemeCubit>().setThemeMode(value);
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<ThemeMode>(
                          title: Text(strings.themeLight),
                          secondary: const Icon(Icons.light_mode_outlined),
                          value: ThemeMode.light,
                        ),
                        RadioListTile<ThemeMode>(
                          title: Text(strings.themeDark),
                          secondary: const Icon(Icons.dark_mode_outlined),
                          value: ThemeMode.dark,
                        ),
                        RadioListTile<ThemeMode>(
                          title: Text(strings.themeSystem),
                          secondary: const Icon(Icons.brightness_auto_outlined),
                          value: ThemeMode.system,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 24),
            Text(
              strings.language,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            BlocBuilder<LocaleCubit, Locale>(
              builder: (context, locale) {
                final selected = locale.languageCode == 'hi'
                    ? AppLocales.hindi
                    : AppLocales.english;
                return Card(
                  margin: EdgeInsets.zero,
                  child: RadioGroup<Locale>(
                    groupValue: selected,
                    onChanged: (value) {
                      if (value != null) {
                        context.read<LocaleCubit>().setLocale(value);
                      }
                    },
                    child: Column(
                      children: [
                        RadioListTile<Locale>(
                          title: Text(strings.english),
                          secondary: const Icon(Icons.language),
                          value: AppLocales.english,
                        ),
                        RadioListTile<Locale>(
                          title: Text(strings.hindi),
                          secondary: const Icon(Icons.translate),
                          value: AppLocales.hindi,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 32),
            FilledButton.tonalIcon(
              onPressed: () {
                context.read<AuthBloc>().add(const AuthLogoutRequested());
              },
              icon: const Icon(Icons.logout),
              label: Text(strings.logout),
              style: FilledButton.styleFrom(
                foregroundColor: theme.colorScheme.error,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({this.user});

  final AppUser? user;

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final theme = Theme.of(context);
    final name = user?.displayName?.trim().isNotEmpty == true
        ? user!.displayName!.trim()
        : (user?.email.split('@').first ?? strings.profile);
    final email = user?.email ?? '';
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 32,
          backgroundColor: theme.colorScheme.primaryContainer,
          foregroundColor: theme.colorScheme.onPrimaryContainer,
          child: Text(
            initial,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (email.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  email,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
