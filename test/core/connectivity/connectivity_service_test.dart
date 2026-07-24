import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:team_workspace/core/connectivity/connectivity_service.dart';

class _MockConnectivity extends Mock implements Connectivity {}

void main() {
  late _MockConnectivity connectivity;
  late ConnectivityService service;

  setUp(() {
    connectivity = _MockConnectivity();
    service = ConnectivityService(connectivity: connectivity);
  });

  group('ConnectivityService', () {
    test('isConnected returns true when wifi is available', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.wifi]);

      expect(await service.isConnected(), isTrue);
    });

    test('isConnected returns false when none', () async {
      when(
        () => connectivity.checkConnectivity(),
      ).thenAnswer((_) async => [ConnectivityResult.none]);

      expect(await service.isConnected(), isFalse);
    });

    test('connectionStream maps connectivity results to bool', () async {
      when(() => connectivity.onConnectivityChanged).thenAnswer(
        (_) => Stream.fromIterable([
          [ConnectivityResult.none],
          [ConnectivityResult.mobile],
        ]),
      );

      await expectLater(service.connectionStream, emitsInOrder([false, true]));
    });
  });
}
