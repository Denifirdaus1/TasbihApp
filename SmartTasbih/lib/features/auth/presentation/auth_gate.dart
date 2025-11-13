import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers/global_providers.dart';
import '../../../core/widgets/async_value_widget.dart';
import '../../home/presentation/home_shell.dart';
import 'sign_in_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(sessionStreamProvider);
    return AsyncValueWidget(
      value: session,
      builder: (data) {
        final user = data?.user ?? ref.watch(currentUserProvider);
        if (user == null) {
          return const SignInScreen();
        }
        return const HomeShell();
      },
    );
  }
}
