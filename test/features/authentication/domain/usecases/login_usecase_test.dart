import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/errors/authentication_failure.dart';
import 'package:team_workspace/features/authentication/domain/usecases/login_usecase.dart';

import '../../../../helpers/fixtures.dart';
import '../../../../helpers/mocks.dart';

void main() {
  late MockAuthRepository repository;
  late LoginUseCase useCase;

  setUp(() {
    repository = MockAuthRepository();
    useCase = LoginUseCase(repository);
  });

  group('LoginUseCase', () {
    test('returns AppUser when repository login succeeds', () async {
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => const Right(FakeData.user));

      final result = await useCase(
        email: 'test@example.com',
        password: 'password123',
      );

      expect(result, const Right(FakeData.user));
      verify(
        () => repository.login(
          email: 'test@example.com',
          password: 'password123',
        ),
      ).called(1);
    });

    test('returns Failure when repository login fails', () async {
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer(
        (_) async => const Left(AuthenticationFailure(message: 'Invalid')),
      );

      final result = await useCase(email: 'bad@example.com', password: 'wrong');

      expect(result, const Left(AuthenticationFailure(message: 'Invalid')));
    });
  });
}
