import 'package:go_router/go_router.dart';
import '../core/storage.dart';
import '../features/auth/phone_screen.dart';
import '../features/auth/otp_screen.dart';
import '../features/shell/shell_screen.dart';
import '../features/orders/available_orders_screen.dart';
import '../features/orders/active_order_screen.dart';
import '../features/history/history_screen.dart';
import '../features/profile/profile_screen.dart';

final router = GoRouter(
  initialLocation: '/',
  redirect: (context, state) async {
    final loggedIn = await hasToken();
    final onAuth   = state.matchedLocation == '/login' || state.matchedLocation == '/otp';
    if (!loggedIn && !onAuth) return '/login';
    if (loggedIn  && onAuth)  return '/orders';
    return null;
  },
  routes: [
    GoRoute(path: '/',      redirect: (_, __) => '/login'),
    GoRoute(path: '/login', builder: (_, __) => const PhoneScreen()),
    GoRoute(path: '/otp',   builder: (_, state) {
      final phone = state.extra as String? ?? '';
      return OtpScreen(phone: phone);
    }),
    ShellRoute(
      builder: (context, state, child) => ShellScreen(child: child),
      routes: [
        GoRoute(path: '/orders',  builder: (_, __) => const AvailableOrdersScreen()),
        GoRoute(path: '/active',  builder: (_, __) => const ActiveOrderScreen()),
        GoRoute(path: '/history', builder: (_, __) => const HistoryScreen()),
        GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen()),
      ],
    ),
  ],
);
