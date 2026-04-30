import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_converter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/widgets/summary_card.dart';
import '../../../../shared/widgets/transaction_tile.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../financial_health/presentation/screens/financial_health_screen.dart';
import '../../../financial_products/presentation/screens/financial_products_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<DashboardProvider>().loadDashboard();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();
    final summary = dashboardProvider.summary;
    final currency = summary.displayCurrency;
    final user = authProvider.currentUser;
    final greetingName = user?.name.split(' ').first ?? 'Usuario';
    final categoryEntries = summary.expensesByCategory.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return RefreshIndicator(
      onRefresh: dashboardProvider.refreshDashboard,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          if (dashboardProvider.isLoading)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: LinearProgressIndicator(),
            ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.xl),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primary, Color(0xFF294D7F)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Hola, $greetingName',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  'Balance total',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyLarge?.copyWith(color: Colors.white),
                ),
                const SizedBox(height: 8),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.format(
                      summary.totalBalance,
                      currency: currency,
                    ),
                    style: Theme.of(
                      context,
                    ).textTheme.headlineLarge?.copyWith(color: Colors.white),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Resumen actualizado al ${DateFormat('dd MMM yyyy', 'es_DO').format(DateTime.now())}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                ),
                const SizedBox(height: 8),
                Text(
                  CurrencyConverter.conversionNote(currency),
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
          if (dashboardProvider.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            EmptyStateWidget(
              title: 'No fue posible cargar el dashboard',
              subtitle: dashboardProvider.errorMessage!,
              icon: Icons.warning_amber_rounded,
            ),
          ],
          const SizedBox(height: AppSpacing.xl),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              final cards = [
                SummaryCard(
                  title: 'Ingresos',
                  value: CurrencyFormatter.format(
                    summary.monthlyIncome,
                    currency: currency,
                  ),
                  subtitle: 'Entradas del mes',
                  icon: Icons.south_west_rounded,
                  color: AppColors.success,
                ),
                SummaryCard(
                  title: 'Gastos',
                  value: CurrencyFormatter.format(
                    summary.monthlyExpense,
                    currency: currency,
                  ),
                  subtitle: 'Salidas del mes',
                  icon: Icons.north_east_rounded,
                  color: AppColors.error,
                ),
                SummaryCard(
                  title: 'Ahorro estimado',
                  value: CurrencyFormatter.format(
                    summary.estimatedSavings,
                    currency: currency,
                  ),
                  subtitle:
                      '${summary.savingsRate.toStringAsFixed(1)}% de ahorro',
                  icon: Icons.savings_rounded,
                  color: AppColors.secondary,
                ),
                SummaryCard(
                  title: 'Productos activos',
                  value: '${summary.activeProducts}',
                  subtitle: 'Registrados en Firestore',
                  icon: Icons.account_balance_wallet_rounded,
                ),
              ];

              return GridView.builder(
                itemCount: cards.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: isWide ? 4 : 2,
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  mainAxisExtent: isWide ? 176 : 172,
                ),
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemBuilder: (context, index) => cards[index],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle(
            title: 'Herramientas financieras',
            subtitle: 'Accesos rapidos para administrar tu informacion.',
          ),
          const SizedBox(height: AppSpacing.md),
          LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth > 700;
              return GridView.count(
                crossAxisCount: isWide ? 2 : 1,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: isWide ? 3.6 : 3.2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _QuickAccessCard(
                    title: 'Productos financieros',
                    subtitle: 'Administra tarjetas, prestamos y cuentas',
                    icon: Icons.account_balance_wallet_outlined,
                    color: AppColors.info,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FinancialProductsScreen(),
                        ),
                      );
                    },
                  ),
                  _QuickAccessCard(
                    title: 'Salud financiera',
                    subtitle: 'Revisa score, alertas y recomendaciones',
                    icon: Icons.monitor_heart_outlined,
                    color: AppColors.secondary,
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const FinancialHealthScreen(),
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle(
            title: 'Gastos por categoria',
            subtitle: 'Distribucion de salidas durante el mes actual',
          ),
          const SizedBox(height: AppSpacing.md),
          if (categoryEntries.isEmpty)
            const EmptyStateWidget(
              title: 'Sin gastos este mes',
              subtitle:
                  'Registra gastos para ver su distribucion por categoria.',
              icon: Icons.pie_chart_outline_rounded,
            )
          else
            _ExpensesByCategoryList(
              entries: categoryEntries,
              currency: currency,
            ),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle(
            title: 'Ultimos movimientos',
            subtitle: 'Transacciones recientes guardadas en Firestore',
          ),
          const SizedBox(height: AppSpacing.md),
          if (summary.recentTransactions.isEmpty)
            const EmptyStateWidget(
              title: 'Aun no tienes movimientos registrados',
              subtitle:
                  'Crea tu primer ingreso o gasto para activar el dashboard.',
              icon: Icons.receipt_long_rounded,
            )
          else
            ...summary.recentTransactions.map(
              (transaction) => TransactionTile(transaction: transaction),
            ),
        ],
      ),
    );
  }
}

class _ExpensesByCategoryList extends StatelessWidget {
  const _ExpensesByCategoryList({
    required this.entries,
    required this.currency,
  });

  final List<MapEntry<String, double>> entries;
  final CurrencyType currency;

  @override
  Widget build(BuildContext context) {
    final maxValue = entries.fold<double>(
      0,
      (max, entry) => entry.value > max ? entry.value : max,
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: entries.map((entry) {
          final progress = maxValue == 0 ? 0.0 : entry.value / maxValue;

          return Padding(
            padding: const EdgeInsets.only(bottom: 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        entry.key,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        CurrencyFormatter.format(
                          entry.value,
                          currency: currency,
                        ),
                        textAlign: TextAlign.end,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    minHeight: 8,
                    value: progress.clamp(0, 1),
                    backgroundColor: AppColors.border,
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.secondary,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _QuickAccessCard extends StatelessWidget {
  const _QuickAccessCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
