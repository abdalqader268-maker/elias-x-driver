import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../orders/available_orders_screen.dart';
import '../orders/active_order_screen.dart';
import '../history/history_screen.dart';
import '../profile/profile_screen.dart';

final tabProvider = StateProvider<int>((_) => 0);

class ShellScreen extends ConsumerWidget {
  final Widget child;
  const ShellScreen({super.key, required this.child});

  static const _screens = [
    AvailableOrdersScreen(),
    ActiveOrderScreen(),
    HistoryScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tab = ref.watch(tabProvider);
    return Scaffold(
      body: _screens[tab],
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: kBorder, width: .8))),
        child: BottomNavigationBar(
          currentIndex: tab,
          onTap: (i) => ref.read(tabProvider.notifier).state = i,
          backgroundColor: kNav,
          selectedItemColor: kPrimary,
          unselectedItemColor: kMuted,
          type: BottomNavigationBarType.fixed,
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.list_alt_rounded),      label: 'الطلبات'),
            BottomNavigationBarItem(icon: Icon(Icons.delivery_dining_rounded),label: 'نشط الآن'),
            BottomNavigationBarItem(icon: Icon(Icons.history_rounded),       label: 'السجل'),
            BottomNavigationBarItem(icon: Icon(Icons.person_rounded),        label: 'حسابي'),
          ],
        ),
      ),
    );
  }
}
