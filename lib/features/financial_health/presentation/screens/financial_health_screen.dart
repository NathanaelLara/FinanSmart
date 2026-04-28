import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/widgets/summary_card.dart';
import '../providers/financial_health_provider.dart';

class FinancialHealthScreen extends StatelessWidget {
  const FinancialHealthScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinancialHealthProvider>();
    final health = provider.health;

    return Scaffold(
      appBar: AppBar(title: const Text('Salud financiera')),
      body: health == null
          ? const EmptyStateWidget(
              title: 'Todavia no hay datos suficientes',
              subtitle:
                  'Registra movimientos para calcular tu salud financiera.',
              icon: Icons.monitor_heart_outlined,
            )
          : ListView(
              padding: const EdgeInsets.all(AppSpacing.lg),
              children: [
                const SectionTitle(
                  title: 'Indicadores clave',
                  subtitle:
                      'Lectura simple del comportamiento financiero actual.',
                ),
                const SizedBox(height: AppSpacing.lg),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(28),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            CircularProgressIndicator(
                              value: health.score / 100,
                              strokeWidth: 16,
                              backgroundColor: AppColors.border,
                              color: AppColors.secondary,
                            ),
                            Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    '${health.score}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.headlineMedium,
                                  ),
                                  Text(
                                    '/ 100',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        health.status,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                GridView.count(
                  crossAxisCount: MediaQuery.sizeOf(context).width > 700
                      ? 4
                      : 2,
                  childAspectRatio: 1.2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 16,
                  crossAxisSpacing: 16,
                  children: [
                    SummaryCard(
                      title: 'Deuda / ingreso',
                      value: '${health.debtToIncomeRatio.toStringAsFixed(1)}%',
                      icon: Icons.account_tree_outlined,
                      color: AppColors.warning,
                    ),
                    SummaryCard(
                      title: 'Tasa de ahorro',
                      value: '${health.savingsRate.toStringAsFixed(1)}%',
                      icon: Icons.savings_outlined,
                      color: AppColors.secondary,
                    ),
                    SummaryCard(
                      title: 'Nivel de gasto',
                      value: '${health.expenseRatio.toStringAsFixed(1)}%',
                      icon: Icons.insights_outlined,
                      color: AppColors.error,
                    ),
                    SummaryCard(
                      title: 'Fondo emergencia',
                      value:
                          '${health.emergencyFundMonths.toStringAsFixed(1)} meses',
                      icon: Icons.security_outlined,
                      color: AppColors.info,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                const SectionTitle(title: 'Recomendaciones'),
                const SizedBox(height: AppSpacing.md),
                ...health.insights.map(
                  (insight) => Container(
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
                            color: AppColors.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.lightbulb_outline_rounded,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(insight)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
