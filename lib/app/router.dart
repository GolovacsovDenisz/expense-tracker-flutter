import 'dart:async';

import 'package:expense_tracker_fresh/features/dashboard/presentation/dashboard_screen.dart';
import 'package:expense_tracker_fresh/features/expenses/domain/expense.dart';
import 'package:expense_tracker_fresh/features/expenses/presentation/add_expense_screen.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/application/auth_providers.dart';
import '../features/auth/presentation/login_screen.dart';
import '../features/auth/presentation/register_screen.dart';
import '../features/home/presentation/home_screen.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(Stream<dynamic> stream) {
    _sub = stream.asBroadcastStream().listen((_) => notifyListeners());
  }
  late final StreamSubscription<dynamic> _sub;

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final authStream = ref.read(authRepositoryProvider).authStateChanges();
  return GoRouter(
    initialLocation: '/dashboard',

    refreshListenable: GoRouterRefreshStream(authStream),

    redirect: (context, state) {
      final loggedIn = ref.read(firebaseAuthProvider).currentUser != null;

      final goingToAuth =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/register';

      if (!loggedIn && !goingToAuth) return '/login';
      if (loggedIn && goingToAuth) return '/home';
      debugPrint('REDIRECT? from=${state.matchedLocation}  loggedIn=$loggedIn');
      return null;
    },

    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) {
          final extra = state.extra;
          String? categoryId;
          if (extra is Map) {
            final v = extra['categoryId'];
            if (v is String) categoryId = v;
          }
          return HomeScreen(initialCategoryId: categoryId);
        },
      ),
      GoRoute(
        path: '/expenses/add',
        builder: (context, state) {
          final expense = state.extra as Expense?;
          return AddExpenseScreen(initial: expense);
        },
      ),
      GoRoute(
        path: '/dashboard',
        builder: (context, state) => DashboardScreen(),
      ),
    ],
  );
});
