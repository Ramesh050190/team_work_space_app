import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:team_workspace/core/storage/hive_service.dart';

class AppThemeCubit extends Cubit<ThemeMode> {
  AppThemeCubit({required HiveService hiveService})
    : _hiveService = hiveService,
      super(ThemeMode.system) {
    _restore();
  }

  static const String settingsKey = 'app_theme_mode';

  final HiveService _hiveService;

  void _restore() {
    try {
      final value = _hiveService.settingsBox.get(settingsKey) as String?;
      emit(_fromStorage(value));
    } catch (_) {
      emit(ThemeMode.system);
    }
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    try {
      await _hiveService.settingsBox.put(settingsKey, _toStorage(mode));
    } catch (_) {
      // Still update UI even if persistence fails.
    }
    emit(mode);
  }

  static String _toStorage(ThemeMode mode) => switch (mode) {
    ThemeMode.light => 'light',
    ThemeMode.dark => 'dark',
    ThemeMode.system => 'system',
  };

  static ThemeMode _fromStorage(String? value) => switch (value) {
    'light' => ThemeMode.light,
    'dark' => ThemeMode.dark,
    _ => ThemeMode.system,
  };
}
