import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:market_list/ui/listas/listas_screen.dart';
import 'package:market_list/ui/login/login_screen.dart';
import 'package:market_list/ui/productos/productos_screen.dart';
import 'package:sqflite/sqflite.dart';

import '../helpers/widget_test_helpers.dart';

void main() {
  late Database db;

  setUp(() async {
    db = await openInMemoryDatabaseForWidgets();
  });

  tearDown(() async {
    await db.close();
  });

  Future<void> ingresar(
    WidgetTester tester,
    String usuario,
    String password,
  ) async {
    await tester.enterText(find.byKey(const Key('campo-usuario')), usuario);
    await tester.enterText(find.byKey(const Key('campo-password')), password);
    await tester.tap(find.text('Ingresar'));
    await tester.pumpAndSettle();
  }

  group('pantalla de login', () {
    testWidgets('arranca en /login sin sesión previa', (tester) async {
      await pumpAppWithDb(tester, db, autenticado: false);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ProductosScreen), findsNothing);
      expect(find.byType(ListasScreen), findsNothing);
    });

    testWidgets('credenciales válidas activan la sesión y navegan a Listas',
        (tester) async {
      await pumpAppWithDb(tester, db, autenticado: false);

      await ingresar(tester, 'Carlos', '123456789');

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(ListasScreen), findsOneWidget);
    });

    testWidgets('credenciales inválidas muestran modal de error y quedan en /login',
        (tester) async {
      await pumpAppWithDb(tester, db, autenticado: false);

      await ingresar(tester, 'Carlos', 'incorrecta');

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Credenciales incorrectas'), findsOneWidget);
      expect(
        find.text('Usuario o contraseña incorrectos. Intentá de nuevo.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Intentar de nuevo'));
      await tester.pumpAndSettle();
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('ambos campos vacíos muestran ambos mensajes sin SnackBar',
        (tester) async {
      await pumpAppWithDb(tester, db, autenticado: false);

      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresá tu usuario'), findsOneWidget);
      expect(find.text('Ingresá tu contraseña'), findsOneWidget);
      expect(find.text('Usuario o contraseña incorrectos. Intentá de nuevo.'),
          findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('usuario vacío muestra mensaje en su campo sin SnackBar',
        (tester) async {
      await pumpAppWithDb(tester, db, autenticado: false);

      await tester.enterText(
        find.byKey(const Key('campo-password')),
        '123456789',
      );
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresá tu usuario'), findsOneWidget);
      expect(find.text('Ingresá tu contraseña'), findsNothing);
      expect(find.text('Usuario o contraseña incorrectos. Intentá de nuevo.'),
          findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('contraseña vacía muestra mensaje en su campo sin SnackBar',
        (tester) async {
      await pumpAppWithDb(tester, db, autenticado: false);

      await tester.enterText(find.byKey(const Key('campo-usuario')), 'Carlos');
      await tester.tap(find.text('Ingresar'));
      await tester.pumpAndSettle();

      expect(find.text('Ingresá tu contraseña'), findsOneWidget);
      expect(find.text('Ingresá tu usuario'), findsNothing);
      expect(find.text('Usuario o contraseña incorrectos. Intentá de nuevo.'),
          findsNothing);
      expect(find.byType(AlertDialog), findsNothing);
    });

    testWidgets('el toggle alterna la visibilidad de la contraseña',
        (tester) async {
      await pumpAppWithDb(tester, db, autenticado: false);

      bool esOculta() => tester
          .widget<TextField>(find.descendant(
            of: find.byKey(const Key('campo-password')),
            matching: find.byType(TextField),
          ))
          .obscureText;

      expect(esOculta(), isTrue);

      await tester.tap(find.byTooltip('Mostrar contraseña'));
      await tester.pump();
      expect(esOculta(), isFalse);

      await tester.tap(find.byTooltip('Ocultar contraseña'));
      await tester.pump();
      expect(esOculta(), isTrue);
    });
  });

  group('protección de rutas', () {
    testWidgets('ruta interna sin sesión deriva a /login', (tester) async {
      await pumpAppWithDb(tester, db, autenticado: false);

      var contexto = tester.element(find.byType(LoginScreen));
      GoRouter.of(contexto).go('/productos');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);

      contexto = tester.element(find.byType(LoginScreen));
      GoRouter.of(contexto).go('/listas');
      await tester.pumpAndSettle();
      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('con sesión activa /login deriva a /listas', (tester) async {
      await pumpAppWithDb(tester, db);
      final contexto = tester.element(find.byType(NavigationBar));
      GoRouter.of(contexto).go('/productos');
      await tester.pumpAndSettle();
      expect(find.byType(ProductosScreen), findsOneWidget);

      GoRouter.of(contexto).go('/login');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsNothing);
      expect(find.byType(ListasScreen), findsOneWidget);
    });
  });

  group('cierre de sesión', () {
    testWidgets('cerrar sesión desde Productos vuelve a /login y bloquea rutas',
        (tester) async {
      await pumpAppWithDb(tester, db);
      final contexto = tester.element(find.byType(NavigationBar));
      GoRouter.of(contexto).go('/productos');
      await tester.pumpAndSettle();
      expect(find.byType(ProductosScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);

      final loginCtx = tester.element(find.byType(LoginScreen));
      GoRouter.of(loginCtx).go('/productos');
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(find.byType(ProductosScreen), findsNothing);
    });

    testWidgets('cerrar sesión desde Listas vuelve a /login', (tester) async {
      await pumpAppWithDb(tester, db);
      final contexto = tester.element(find.byType(NavigationBar));
      GoRouter.of(contexto).go('/listas');
      await tester.pumpAndSettle();
      expect(find.byType(ListasScreen), findsOneWidget);

      await tester.tap(find.byTooltip('Cerrar sesión'));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });
  });
}