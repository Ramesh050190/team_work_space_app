import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/constants/app_strings.dart';
import 'package:team_workspace/core/localization/locale_cubit.dart';

/// Popup menu to switch between English and Hindi.
class LanguageSwitcherButton extends StatelessWidget {
  const LanguageSwitcherButton({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final current = context.watch<LocaleCubit>().state;

    return PopupMenuButton<Locale>(
      tooltip: strings.language,
      icon: const Icon(Icons.language),
      initialValue: current,
      onSelected: (locale) => context.read<LocaleCubit>().setLocale(locale),
      itemBuilder: (context) => [
        PopupMenuItem(value: AppLocales.english, child: Text(strings.english)),
        PopupMenuItem(value: AppLocales.hindi, child: Text(strings.hindi)),
      ],
    );
  }
}
