// lib/features/home/presentation/home_shell.dart
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:monetiar/features/dashboard/presentation/dashboard_screen.dart';
import 'package:monetiar/features/transactions/presentation/movements_screen.dart';

class HomeShell extends StatelessWidget {
  const HomeShell({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
      tabBar: CupertinoTabBar(
        backgroundColor: Theme.of(context).cardColor,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.chart_pie),
            activeIcon: Icon(CupertinoIcons.chart_pie_fill),
            label: 'Resumen',
          ),
          BottomNavigationBarItem(
            icon: Icon(CupertinoIcons.list_bullet),
            label: 'Movimientos',
          ),
        ],
      ),
      tabBuilder: (context, index) => CupertinoTabView(
        builder: (_) => index == 0 ? const DashboardScreen() : const MovementsScreen(),
      ),
    );
  }
}