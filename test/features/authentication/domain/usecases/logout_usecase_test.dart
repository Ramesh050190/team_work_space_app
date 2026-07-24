import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/authentication_failure.dart';
import 'package:team_workspace/features/authentication/domain/usecases/logout_usecase.dart';

import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late LogoutUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LogoutUseCase(repository);
  });

  group('LogoutUseCase', () {
    test('returns Right(null) when repository logout succeeds', () async {
      when(
        () => repository.logout(),
      ).thenAnswer((_) async => const Right(null));

      final result = await useCase();

      expect(result, const Right(null));
      verify(() => repository.logout()).called(1);
    });

    test('returns Failure when repository logout fails', () async {
      when(() => repository.logout()).thenAnswer(
        (_) async =>
            const Left(AuthenticationFailure(message: 'Logout failed')),
      );

      final result = await useCase();

      expect(
        result,
        const Left(AuthenticationFailure(message: 'Logout failed')),
      );
    });
  });
}
