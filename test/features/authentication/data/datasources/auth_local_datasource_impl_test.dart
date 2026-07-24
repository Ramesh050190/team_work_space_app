import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/constants/hive_constants.dart';
import 'package:team_workspace/core/exceptions/cache_exception.dart';
import 'package:team_workspace/core/storage/hive_service.dart';
import 'package:team_workspace/features/authentication/data/datasources/auth_local_datasource_impl.dart';
import 'package:team_workspace/features/authentication/data/models/app_user_adapter.dart';
import 'package:team_workspace/features/authentication/data/models/user_model.dart';

class MockHiveService extends Mock implements HiveService {}

void main() {
  late Directory tempDir;
  late Box appBox;
  late Box<UserModel> userBox;
  late MockHiveService hiveService;
  late AuthLocalDataSourceImpl dataSource;

  const user = UserModel(
    uid: 'uid-1',
    email: 'test@example.com',
    displayName: 'Test',
  );

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('auth_local_');
    Hive.init(tempDir.path);
    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(AppUserAdapter());
    }
    appBox = await Hive.openBox(HiveConstants.appBox);
    userBox = await Hive.openBox<UserModel>(HiveConstants.userBox);

    hiveService = MockHiveService();
    when(() => hiveService.appBox).thenReturn(appBox);
    when(() => hiveService.userBox).thenReturn(userBox);
    dataSource = AuthLocalDataSourceImpl(hiveService: hiveService);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  group('AuthLocalDataSourceImpl', () {
    test('cacheUser stores user and last session uid', () async {
      await dataSource.cacheUser(user);

      expect(userBox.get(HiveConstants.cachedUserKey), user);
      expect(appBox.get(HiveConstants.lastSessionUidKey), 'uid-1');
    });

    test('getCachedUser / clearCachedUser', () async {
      await dataSource.cacheUser(user);
      expect(await dataSource.getCachedUser(), user);

      await dataSource.clearCachedUser();
      expect(await dataSource.getCachedUser(), isNull);
    });

    test('getLastSessionUid handles empty and non-string', () async {
      expect(await dataSource.getLastSessionUid(), isNull);

      await appBox.put(HiveConstants.lastSessionUidKey, '');
      expect(await dataSource.getLastSessionUid(), isNull);

      await appBox.put(HiveConstants.lastSessionUidKey, 123);
      expect(await dataSource.getLastSessionUid(), isNull);

      await dataSource.saveLastSessionUid('uid-9');
      expect(await dataSource.getLastSessionUid(), 'uid-9');
    });

    test('wraps Hive failures as CacheException', () async {
      when(() => hiveService.userBox).thenThrow(Exception('closed'));

      expect(
        () => dataSource.getCachedUser(),
        throwsA(isA<CacheException>()),
      );
    });
  });
}
