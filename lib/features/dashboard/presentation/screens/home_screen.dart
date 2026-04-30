import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../shared/widgets/custom_app_bar.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../../../budgets/presentation/screens/budgets_screen.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../financial_health/presentation/providers/financial_health_provider.dart';
import '../../../financial_health/presentation/screens/financial_health_screen.dart';
import '../../../financial_products/presentation/providers/financial_products_provider.dart';
import '../../../profile/presentation/screens/profile_screen.dart';
import '../../../reports/presentation/providers/reports_provider.dart';
import '../../../reports/presentation/screens/reports_screen.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../transactions/presentation/screens/transactions_screen.dart';
import 'dashboard_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

  static const _titles = [
    'Dashboard',
    'Movimientos',
    'Presupuesto',
    'Reportes',
    'Perfil',
  ];

  final _screens = const [
    DashboardScreen(),
    TransactionsScreen(),
    BudgetsScreen(),
    ReportsScreen(),
    ProfileScreen(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().loadDashboard();
      context.read<TransactionsProvider>().loadTransactions();
      context.read<FinancialProductsProvider>().loadProducts();
      context.read<BudgetsProvider>().loadBudgets();
      context.read<ReportsProvider>().loadReports();
      context.read<FinancialHealthProvider>().loadHealth();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: _titles[_currentIndex],
        actions: _currentIndex == 0
            ? [
                IconButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const FinancialHealthScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.monitor_heart_outlined),
                ),
              ]
            : null,
      ),
      body: SafeArea(
        child: IndexedStack(index: _currentIndex, children: _screens),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        height: 72,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          if (index == 0) {
            context.read<DashboardProvider>().refreshDashboard();
          }
          if (index == 2) {
            context.read<BudgetsProvider>().refreshBudgets();
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long_rounded),
            label: 'Movs.',
          ),
          NavigationDestination(
            icon: Icon(Icons.savings_outlined),
            selectedIcon: Icon(Icons.savings_rounded),
            label: 'Presup.',
          ),
          NavigationDestination(
            icon: Icon(Icons.summarize_outlined),
            selectedIcon: Icon(Icons.summarize_rounded),
            label: 'Reportes',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline_rounded),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
