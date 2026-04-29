import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_converter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/widgets/summary_card.dart';
import '../providers/financial_health_provider.dart';

class FinancialHealthScreen extends StatefulWidget {
  const FinancialHealthScreen({super.key});

  @override
  State<FinancialHealthScreen> createState() => _FinancialHealthScreenState();
}

class _FinancialHealthScreenState extends State<FinancialHealthScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FinancialHealthProvider>().loadFinancialHealth();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinancialHealthProvider>();
    final summary = provider.summary;
    final currency = summary.displayCurrency;
    final scoreColor = _scoreColor(summary.score);

    return Scaffold(
      appBar: AppBar(title: const Text('Salud financiera')),
      body: RefreshIndicator(
        onRefresh: provider.refreshFinancialHealth,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            if (provider.isLoading)
              const Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.md),
                child: LinearProgressIndicator(),
              ),
            if (provider.errorMessage != null) ...[
              EmptyStateWidget(
                title: 'No fue posible calcular tu salud financiera',
                subtitle: provider.errorMessage!,
                icon: Icons.warning_amber_rounded,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            if (!summary.hasEnoughData && !provider.isLoading) ...[
              const EmptyStateWidget(
                title: 'Todavia no hay informacion suficiente',
                subtitle:
                    'Registra ingresos, gastos y productos financieros para calcular tu salud financiera.',
                icon: Icons.monitor_heart_outlined,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: AppColors.border),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.04),
                    blurRadius: 16,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  SizedBox(
                    width: 190,
                    height: 190,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CircularProgressIndicator(
                          value: (summary.score / 100).clamp(0, 1),
                          strokeWidth: 16,
                          backgroundColor: AppColors.border,
                          color: scoreColor,
                        ),
                        Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                summary.score.toStringAsFixed(0),
                                style: Theme.of(context)
                                    .textTheme
                                    .headlineMedium
                                    ?.copyWith(color: scoreColor),
                              ),
                              Text(
                                '/ 100',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    summary.level,
                    style: Theme.of(
                      context,
                    ).textTheme.titleLarge?.copyWith(color: scoreColor),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    CurrencyConverter.conversionNote(currency),
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
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
                    subtitle: 'Mes actual',
                    icon: Icons.south_west_rounded,
                    color: AppColors.success,
                  ),
                  SummaryCard(
                    title: 'Gastos',
                    value: CurrencyFormatter.format(
                      summary.monthlyExpense,
                      currency: currency,
                    ),
                    subtitle: summary.topExpenseCategory == null
                        ? 'Mes actual'
                        : 'Mayor: ${summary.topExpenseCategory}',
                    icon: Icons.north_east_rounded,
                    color: AppColors.error,
                  ),
                  SummaryCard(
                    title: 'Ahorro',
                    value: CurrencyFormatter.format(
                      summary.monthlySavings,
                      currency: currency,
                    ),
                    subtitle: '${summary.savingsRate.toStringAsFixed(1)}%',
                    icon: Icons.savings_rounded,
                    color: AppColors.secondary,
                  ),
                  SummaryCard(
                    title: 'Deuda / ingreso',
                    value: '${summary.debtToIncomeRatio.toStringAsFixed(1)}%',
                    subtitle: CurrencyFormatter.format(
                      summary.monthlyDebtPayments,
                      currency: currency,
                    ),
                    icon: Icons.account_tree_outlined,
                    color: AppColors.warning,
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
              title: 'Indicadores de deuda',
              subtitle: 'Compromisos financieros activos del usuario.',
            ),
            const SizedBox(height: AppSpacing.md),
            _MetricsPanel(
              items: [
                _MetricLine(
                  'Deuda total estimada',
                  CurrencyFormatter.format(
                    summary.totalDebt,
                    currency: currency,
                  ),
                ),
                _MetricLine(
                  'Pagos mensuales',
                  CurrencyFormatter.format(
                    summary.monthlyDebtPayments,
                    currency: currency,
                  ),
                ),
                _MetricLine('Productos activos', '${summary.activeProducts}'),
                _MetricLine(
                  'Categoria con mayor gasto',
                  summary.topExpenseCategory == null
                      ? 'No disponible'
                      : '${summary.topExpenseCategory} (${CurrencyFormatter.format(summary.topExpenseCategoryAmount, currency: currency)})',
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionTitle(title: 'Fortalezas financieras'),
            const SizedBox(height: AppSpacing.md),
            _TextListPanel(
              icon: Icons.check_circle_outline_rounded,
              color: AppColors.success,
              items: summary.strengths,
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionTitle(title: 'Alertas financieras'),
            const SizedBox(height: AppSpacing.md),
            _TextListPanel(
              icon: Icons.warning_amber_rounded,
              color: AppColors.warning,
              items: summary.alerts,
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionTitle(title: 'Recomendaciones'),
            const SizedBox(height: AppSpacing.md),
            _TextListPanel(
              icon: Icons.lightbulb_outline_rounded,
              color: AppColors.secondary,
              items: summary.recommendations,
            ),
          ],
        ),
      ),
    );
  }

  Color _scoreColor(double score) {
    if (score >= 80) {
      return AppColors.success;
    }
    if (score >= 60) {
      return AppColors.secondary;
    }
    if (score >= 40) {
      return AppColors.warning;
    }
    return AppColors.error;
  }
}

class _MetricsPanel extends StatelessWidget {
  const _MetricsPanel({required this.items});

  final List<_MetricLine> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _panelDecoration,
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        item.label,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Flexible(
                      child: Text(
                        item.value,
                        textAlign: TextAlign.end,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _TextListPanel extends StatelessWidget {
  const _TextListPanel({
    required this.icon,
    required this.color,
    required this.items,
  });

  final IconData icon;
  final Color color;
  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: _panelDecoration,
      child: Column(
        children: items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, color: color, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(child: Text(item)),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _MetricLine {
  const _MetricLine(this.label, this.value);

  final String label;
  final String value;
}

BoxDecoration get _panelDecoration => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: AppColors.border),
);
