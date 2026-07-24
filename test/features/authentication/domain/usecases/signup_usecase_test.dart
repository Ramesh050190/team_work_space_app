import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/authentication_failure.dart';
import 'package:team_workspace/features/authentication/domain/usecases/signup_usecase.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late SignupUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = SignupUseCase(repository);
  });

  group('SignupUseCase', () {
    test('returns AppUser when repository signup succeeds', () async {
      when(
        () => repository.signup(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(FakeData.user));

      final result = await useCase(
        email: 'new@example.com',
        password: 'password123',
      );

      expect(result, const Right(FakeData.user));
      verify(
        () => repository.signup(
          email: 'new@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('returns Failure when repository signup fails', () async {
      when(
        () => repository.signup(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Left(AuthenticationFailure(message: 'Email in use')),
      );

      final result = await useCase(
        email: 'taken@example.com',
        password: 'password123',
      );

      expect(
        result,
        const Left(AuthenticationFailure(message: 'Email in use')),
      );
    });
  });
}
