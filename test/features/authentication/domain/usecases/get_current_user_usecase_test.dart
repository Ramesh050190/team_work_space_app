import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/cache_failure.dart';
import 'package:team_workspace/features/authentication/domain/usecases/get_current_user_usecase.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late GetCurrentUserUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = GetCurrentUserUseCase(repository);
  });

  group('GetCurrentUserUseCase', () {
    test('returns user when repository has a session', () async {
      when(
        () => repository.currentUser(),
      ).thenAnswer((_) async => const Right(FakeData.user));

      final result = await useCase();

      expect(result, const Right(FakeData.user));
      verify(() => repository.currentUser()).called(1);
    });

    test('returns null when no user is signed in', () async {
      when(
        () => repository.currentUser(),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase();

      expect(result, const Right(null));
    });

    test('returns Failure when repository fails', () async {
      when(() => repository.currentUser()).thenAnswer(
        (_) async => const Left(CacheFailure(message: 'Cache error')),
      );

      final result = await useCase();

      expect(result, const Left(CacheFailure(message: 'Cache error')));
    });

    test('watchAuthState delegates to repository stream', () async {
      when(
        () => repository.authStateChanges(),
      ).thenAnswer((_) => Stream.value(FakeData.user));

      await expectLater(useCase.watchAuthState(), emits(FakeData.user));
    });
  });
}
