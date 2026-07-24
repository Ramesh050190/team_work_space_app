import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/storage/hive_service.dart';

/// Supported app locales.
class AppLocales {
  AppLocales._();

  static const Locale english = Locale('en');
  static const Locale hindi = Locale('hi');

  static const List<Locale> supported = [english, hindi];

  static const String settingsKey = 'app_locale';
}

/// Persists and emits the active [Locale] (English / Hindi).
class LocaleCubit extends Cubit<Locale> {
  LocaleCubit({required HiveService hiveService})
    : _hiveService = hiveService,
      super(AppLocales.english) {
    _restore();
  }

  final HiveService _hiveService;

  void _restore() {
    try {
      final code =
          _hiveService.settingsBox.get(AppLocales.settingsKey) as String?;
      if (code == 'hi') {
        emit(AppLocales.hindi);
      } else {
        emit(AppLocales.english);
      }
    } catch (_) {
      emit(AppLocales.english);
    }
  }

  Future<void> setLocale(Locale locale) async {
    final normalized = locale.languageCode == 'hi'
        ? AppLocales.hindi
        : AppLocales.english;
    try {
      await _hiveService.settingsBox.put(
        AppLocales.settingsKey,
        normalized.languageCode,
      );
    } catch (_) {
      // Still update UI even if persistence fails.
    }
    emit(normalized);
  }

  Future<void> toggle() {
    final next = state.languageCode == 'hi'
        ? AppLocales.english
        : AppLocales.hindi;
    return setLocale(next);
  }
}
