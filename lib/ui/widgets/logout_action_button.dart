import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../state/providers/auth_provider.dart';

class LogoutActionButton extends ConsumerWidget {
  const LogoutActionButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return IconButton(
      tooltip: 'Cerrar sesión',
      icon: const Icon(Icons.logout),
      onPressed: () {
        ref.read(authProvider.notifier).logout();
        context.go('/login');
      },
    );
  }
}