import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:market_list/state/providers/auth_provider.dart';

void main() {
  test('el estado inicial es no autenticado', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(authProvider), isFalse);
  });

  test('login con credenciales correctas activa la sesión', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final resultado = container.read(authProvider.notifier).login(
          'Carlos',
          '123456789',
        );

    expect(resultado, isTrue);
    expect(container.read(authProvider), isTrue);
  });

  test('login con el usuario en minúsculas es rechazado (case sensible)',
      () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final resultado = container.read(authProvider.notifier).login(
          'carlos',
          '123456789',
        );

    expect(resultado, isFalse);
    expect(container.read(authProvider), isFalse);
  });

  test('login con contraseña incorrecta es rechazado', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final resultado = container
        .read(authProvider.notifier)
        .login('Carlos', '123456');

    expect(resultado, isFalse);
    expect(container.read(authProvider), isFalse);
  });

  test('logout desactiva la sesión', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(authProvider.notifier);

    notifier.login('Carlos', '123456789');
    notifier.logout();

    expect(container.read(authProvider), isFalse);
  });

  test('con sesión inicial activa no se requiere login', () {
    final container = ProviderContainer(
      overrides: [
        authProvider.overrideWith(() => AuthNotifier(sesionInicial: true)),
      ],
    );
    addTearDown(container.dispose);

    expect(container.read(authProvider), isTrue);
  });
}