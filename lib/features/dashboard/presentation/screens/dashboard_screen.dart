import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/widgets/summary_card.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../dashboard/presentation/providers/dashboard_provider.dart';
import '../../../financial_products/presentation/providers/financial_products_provider.dart';
import '../../../reports/presentation/providers/reports_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final transactionsProvider = context.watch<TransactionsProvider>();
    final productsProvider = context.watch<FinancialProductsProvider>();
    final reportsProvider = context.watch<ReportsProvider>();
    final dashboardProvider = context.watch<DashboardProvider>();

    final user = authProvider.currentUser;
    final currency =
        user?.preferredCurrency ?? transactionsProvider.defaultCurrency;
    final overview = dashboardProvider.buildOverview(
      transactions: transactionsProvider.transactions,
      products: productsProvider.products,
    );

    final greetingName = user?.name.split(' ').first ?? 'Usuario';

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
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
              Text(
                CurrencyFormatter.format(overview.balance, currency: currency),
                style: Theme.of(
                  context,
                ).textTheme.headlineLarge?.copyWith(color: Colors.white),
              ),
              const SizedBox(height: 12),
              Text(
                'Resumen actualizado al ${DateFormat('dd MMM yyyy', 'es_DO').format(DateTime.now())}',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 700;

            return GridView.builder(
              itemCount: 4,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: isWide ? 4 : 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: isWide ? 176 : 172,
              ),
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index) {
                final cards = [
                  SummaryCard(
                    title: 'Ingresos',
                    value: CurrencyFormatter.format(
                      overview.income,
                      currency: currency,
                    ),
                    subtitle: 'Entradas del mes',
                    icon: Icons.south_west_rounded,
                    color: AppColors.success,
                  ),
                  SummaryCard(
                    title: 'Gastos',
                    value: CurrencyFormatter.format(
                      overview.expense,
                      currency: currency,
                    ),
                    subtitle: 'Salidas del mes',
                    icon: Icons.north_east_rounded,
                    color: AppColors.error,
                  ),
                  SummaryCard(
                    title: 'Ahorro estimado',
                    value: CurrencyFormatter.format(
                      overview.estimatedSavings,
                      currency: currency,
                    ),
                    subtitle: 'Disponible al cierre',
                    icon: Icons.savings_rounded,
                    color: AppColors.secondary,
                  ),
                  SummaryCard(
                    title: 'Productos activos',
                    value: '${overview.activeProducts}',
                    subtitle: 'Tarjetas y prestamos',
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                ];

                return cards[index];
              },
            );
          },
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle(
          title: 'Tendencia financiera',
          subtitle: 'Comportamiento mensual de ahorro neto',
        ),
        const SizedBox(height: AppSpacing.md),
        if (reportsProvider.reports.isEmpty)
          const EmptyStateWidget(
            title: 'Todavia no hay datos suficientes',
            subtitle: 'Registra movimientos para ver tu tendencia financiera.',
            icon: Icons.show_chart_rounded,
          )
        else
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppColors.border),
            ),
            height: 260,
            child: LineChart(
              LineChartData(
                borderData: FlBorderData(show: false),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 5000,
                ),
                titlesData: FlTitlesData(
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 44,
                      getTitlesWidget: (value, meta) => Text(
                        '${(value / 1000).round()}k',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index < 0 ||
                            index >= reportsProvider.reports.length) {
                          return const SizedBox.shrink();
                        }
                        final label = DateFormat(
                          'MMM',
                          'es_DO',
                        ).format(reportsProvider.reports[index].month);
                        return Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            label,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        );
                      },
                    ),
                  ),
                ),
                lineBarsData: [
                  LineChartBarData(
                    isCurved: true,
                    color: AppColors.secondary,
                    barWidth: 4,
                    dotData: const FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.secondary.withValues(alpha: 0.14),
                    ),
                    spots: List.generate(
                      reportsProvider.reports.length,
                      (index) => FlSpot(
                        index.toDouble(),
                        reportsProvider.reports[index].netSavings,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle(
          title: 'Alertas del mes',
          subtitle: 'Eventos importantes y oportunidades de mejora',
        ),
        const SizedBox(height: AppSpacing.md),
        if (dashboardProvider.alerts.isEmpty)
          const EmptyStateWidget(
            title: 'Sin alertas por ahora',
            subtitle: 'Cuando haya eventos importantes apareceran aqui.',
            icon: Icons.notifications_none_rounded,
          )
        else
          ...dashboardProvider.alerts.map(
            (alert) => Container(
              margin: const EdgeInsets.only(bottom: 12),
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
                      color: AppColors.warning.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.notifications_active_outlined,
                      color: AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: Text(alert)),
                ],
              ),
            ),
          ),
      ],
    );
  }
}
