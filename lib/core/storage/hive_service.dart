import 'package:hive_flutter/hive_flutter.dart';
import 'package:team_workspace/core/constants/hive_constants.dart';
import 'package:team_workspace/core/exceptions/cache_exception.dart';
import 'package:team_workspace/core/logger/app_logger.dart';
import 'package:team_workspace/features/authentication/data/models/app_user_adapter.dart';
import 'package:team_workspace/features/authentication/data/models/user_model.dart';
import 'package:team_workspace/features/task/data/models/pending_sync_model.dart';
import 'package:team_workspace/features/task/data/models/task_model.dart';
import 'package:team_workspace/features/task/data/models/task_model_adapter.dart';

/// Opens Hive boxes and registers type adapters used by offline persistence.
class HiveService {
  HiveService({AppLogger? logger}) : _logger = logger;

  final AppLogger? _logger;
  bool _adaptersRegistered = false;

  Future<void> init() async {
    await Hive.initFlutter();
    _registerAdapters();

    await Future.wait([
      Hive.openBox(HiveConstants.appBox),
      _openTypedBox<UserModel>(HiveConstants.userBox),
      Hive.openBox(HiveConstants.settingsBox),
      Hive.openBox<String>(HiveConstants.taskDetailsBox),
      _openLazyTypedBox<String>(HiveConstants.taskListBox),
      _openTypedBox<PendingSyncModel>(HiveConstants.pendingOperationsBox),
      _openLazyTypedBox<TaskModel>(HiveConstants.tasksBox),
    ]);
  }

  Future<void> _openTypedBox<T>(String name) async {
    try {
      await Hive.openBox<T>(name);
    } catch (error) {
      _logger?.warning(
        'Recreating Hive box "$name" after type mismatch',
        error,
      );
      await Hive.deleteBoxFromDisk(name);
      await Hive.openBox<T>(name);
    }
  }

  Future<void> _openLazyTypedBox<T>(String name) async {
    try {
      await Hive.openLazyBox<T>(name);
    } catch (error) {
      _logger?.warning(
        'Recreating lazy Hive box "$name" after type mismatch',
        error,
      );
      await Hive.deleteBoxFromDisk(name);
      await Hive.openLazyBox<T>(name);
    }
  }

  void _registerAdapters() {
    if (_adaptersRegistered) return;
    try {
      if (!Hive.isAdapterRegistered(0)) {
        Hive.registerAdapter(AppUserAdapter());
      }
      if (!Hive.isAdapterRegistered(1)) {
        Hive.registerAdapter(TaskModelAdapter());
      }
      if (!Hive.isAdapterRegistered(2)) {
        Hive.registerAdapter(PendingSyncModelAdapter());
      }
      _adaptersRegistered = true;
    } catch (error, stackTrace) {
      _logger?.error('Failed to register Hive adapters', error, stackTrace);
      throw CacheException(message: 'Hive adapter registration failed: $error');
    }
  }

  Box get appBox => _boxOrThrow(HiveConstants.appBox);

  Box<UserModel> get userBox => _typedBoxOrThrow(HiveConstants.userBox);

  Box get settingsBox => _boxOrThrow(HiveConstants.settingsBox);

  Box<String> get taskDetailsBox =>
      _typedBoxOrThrow(HiveConstants.taskDetailsBox);

  LazyBox<String> get taskListBox =>
      _lazyTypedBoxOrThrow(HiveConstants.taskListBox);

  Box<PendingSyncModel> get pendingOperationsBox =>
      _typedBoxOrThrow(HiveConstants.pendingOperationsBox);

  LazyBox<TaskModel> get tasksBox =>
      _lazyTypedBoxOrThrow(HiveConstants.tasksBox);

  Box _boxOrThrow(String name) {
    if (!Hive.isBoxOpen(name)) {
      throw CacheException(message: 'Hive box "$name" is not open.');
    }
    return Hive.box(name);
  }

  Box<T> _typedBoxOrThrow<T>(String name) {
    if (!Hive.isBoxOpen(name)) {
      throw CacheException(message: 'Hive box "$name" is not open.');
    }
    return Hive.box<T>(name);
  }

  LazyBox<T> _lazyTypedBoxOrThrow<T>(String name) {
    if (!Hive.isBoxOpen(name)) {
      throw CacheException(message: 'Hive box "$name" is not open.');
    }
    return Hive.lazyBox<T>(name);
  }
}
