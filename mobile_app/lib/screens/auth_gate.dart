import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'main_navigation_screen.dart';

/// AuthGate uses ref.listen to explicitly navigate when auth state changes.
/// This is more reliable than changing MaterialApp.home reactively,
/// because Flutter's Navigator stack is NOT automatically replaced when home changes.
class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    // Listen for auth changes and navigate imperatively
    ref.listen<AuthState>(authProvider, (previous, next) {
      if (previous?.isAuthenticated == false && next.isAuthenticated == true) {
        // Logged in — push main screen, remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
          (route) => false,
        );
      } else if (previous?.isAuthenticated == true && next.isAuthenticated == false) {
        // Logged out — push login screen, remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    });

    // Initial render based on current state
    if (authState.isLoading) {
      return const Scaffold(
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Connecting...', style: TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      );
    }

    if (authState.isAuthenticated) {
      return const MainNavigationScreen();
    }

    return const LoginScreen();
  }
}
