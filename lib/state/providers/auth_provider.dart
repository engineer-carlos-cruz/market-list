import 'package:flutter_riverpod/flutter_riverpod.dart';

const _usuarioValido = 'Carlos';
const _passwordValida = '123456789';

final authProvider = NotifierProvider<AuthNotifier, bool>(AuthNotifier.new);

class AuthNotifier extends Notifier<bool> {
  AuthNotifier({this.sesionInicial = false});

  final bool sesionInicial;

  @override
  bool build() => sesionInicial;

  bool login(String usuario, String password) {
    final valido = usuario == _usuarioValido && password == _passwordValida;
    if (valido) state = true;
    return valido;
  }

  void logout() {
    state = false;
  }
}