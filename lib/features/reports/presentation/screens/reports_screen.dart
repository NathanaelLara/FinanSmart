import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_converter.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../../../shared/services/pdf_report_service.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/widgets/summary_card.dart';
import '../../../../shared/widgets/transaction_tile.dart';
import '../../data/monthly_report_summary.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({super.key});

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<ReportsProvider>().loadReport();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportsProvider>();
    final report = provider.reportSummary;
    final currency = report.displayCurrency;
    final monthLabel = _capitalize(
      DateFormat(
        'MMMM yyyy',
        'es_DO',
      ).format(DateTime(provider.selectedYear, provider.selectedMonth)),
    );
    final categoryEntries = report.expensesByCategory.entries.toList();
    final pdfService = PdfReportService();

    return RefreshIndicator(
      onRefresh: provider.refreshReport,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionTitle(
            title: 'Reportes mensuales',
            subtitle: 'Analiza tus ingresos, gastos y conducta financiera.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _ReportPeriodSelector(provider: provider),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: Text(
                  monthLabel,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              OutlinedButton.icon(
                onPressed: provider.isLoading || !report.hasTransactions
                    ? null
                    : () => _exportReport(context, pdfService, report),
                icon: const Icon(Icons.file_download_outlined),
                label: const Text('Exportar'),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            CurrencyConverter.conversionNote(currency),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (provider.isLoading) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(),
          ],
          if (provider.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            EmptyStateWidget(
              title: 'No fue posible cargar el reporte',
              subtitle: provider.errorMessage!,
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
                    report.totalIncome,
                    currency: currency,
                  ),
                  subtitle: '${report.incomeTransactions} movimientos',
                  icon: Icons.south_west_rounded,
                  color: AppColors.success,
                ),
                SummaryCard(
                  title: 'Gastos',
                  value: CurrencyFormatter.format(
                    report.totalExpense,
                    currency: currency,
                  ),
                  subtitle: '${report.expenseTransactions} movimientos',
                  icon: Icons.north_east_rounded,
                  color: AppColors.error,
                ),
                SummaryCard(
                  title: 'Balance',
                  value: CurrencyFormatter.format(
                    report.netBalance,
                    currency: currency,
                  ),
                  subtitle: '${report.totalTransactions} transacciones',
                  icon: Icons.account_balance_wallet_rounded,
                  color: report.netBalance >= 0
                      ? AppColors.success
                      : AppColors.error,
                ),
                SummaryCard(
                  title: 'Ahorro',
                  value: CurrencyFormatter.format(
                    report.estimatedSavings,
                    currency: currency,
                  ),
                  subtitle:
                      '${report.savingsRate.toStringAsFixed(1)}% del ingreso',
                  icon: Icons.savings_rounded,
                  color: AppColors.secondary,
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
          if (!report.hasTransactions)
            const EmptyStateWidget(
              title: 'Sin movimientos en este periodo',
              subtitle:
                  'Cambia de mes o registra ingresos y gastos para generar el reporte.',
              icon: Icons.summarize_outlined,
            )
          else ...[
            const SectionTitle(
              title: 'Gastos por categoria',
              subtitle: 'Categorias ordenadas de mayor a menor gasto.',
            ),
            const SizedBox(height: AppSpacing.md),
            if (categoryEntries.isEmpty)
              const EmptyStateWidget(
                title: 'Sin gastos registrados',
                subtitle: 'Este periodo no tiene gastos para agrupar.',
                icon: Icons.pie_chart_outline_rounded,
              )
            else
              _CategoryBreakdown(entries: categoryEntries, currency: currency),
            const SizedBox(height: AppSpacing.xl),
            const SectionTitle(
              title: 'Top de gastos',
              subtitle: 'Movimientos de gasto mas altos del periodo.',
            ),
            const SizedBox(height: AppSpacing.md),
            if (report.topExpenses.isEmpty)
              const EmptyStateWidget(
                title: 'Sin gastos destacados',
                subtitle: 'No hay gastos en este mes.',
                icon: Icons.trending_down_rounded,
              )
            else
              ...report.topExpenses.map(
                (transaction) => TransactionTile(transaction: transaction),
              ),
            const SizedBox(height: AppSpacing.xl),
          ],
          const SectionTitle(
            title: 'Conducta financiera',
            subtitle: 'Lectura automatica del comportamiento mensual.',
          ),
          const SizedBox(height: AppSpacing.md),
          _TextListPanel(
            icon: Icons.insights_rounded,
            color: AppColors.secondary,
            items: report.insights,
          ),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle(
            title: 'Recomendaciones',
            subtitle: 'Acciones simples para mejorar el proximo mes.',
          ),
          const SizedBox(height: AppSpacing.md),
          _TextListPanel(
            icon: Icons.task_alt_rounded,
            color: AppColors.success,
            items: report.recommendations,
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(
            label: 'Imprimir reporte',
            icon: Icons.print_outlined,
            onPressed: provider.isLoading || !report.hasTransactions
                ? null
                : () => _printReport(context, pdfService, report),
          ),
        ],
      ),
    );
  }

  Future<void> _printReport(
    BuildContext context,
    PdfReportService pdfService,
    MonthlyReportSummary report,
  ) async {
    final fileName =
        'finansmart_${report.year}_${report.month.toString().padLeft(2, '0')}.pdf';
    await Printing.layoutPdf(
      onLayout: (_) => pdfService.generateMonthlyReportSummary(report),
      name: fileName,
    );
  }

  Future<void> _exportReport(
    BuildContext context,
    PdfReportService pdfService,
    MonthlyReportSummary report,
  ) async {
    final fileName =
        'finansmart_${report.year}_${report.month.toString().padLeft(2, '0')}.pdf';
    final bytes = await pdfService.generateMonthlyReportSummary(report);
    await Printing.sharePdf(bytes: bytes, filename: fileName);
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _ReportPeriodSelector extends StatelessWidget {
  const _ReportPeriodSelector({required this.provider});

  final ReportsProvider provider;

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(7, (index) => currentYear - 5 + index);

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        SizedBox(
          width: 190,
          child: DropdownButtonFormField<int>(
            initialValue: provider.selectedMonth,
            decoration: const InputDecoration(labelText: 'Mes'),
            items: List.generate(12, (index) {
              final month = index + 1;
              return DropdownMenuItem(
                value: month,
                child: Text(
                  _capitalizeStatic(
                    DateFormat('MMMM', 'es_DO').format(DateTime(2024, month)),
                  ),
                ),
              );
            }),
            onChanged: provider.isLoading
                ? null
                : (value) {
                    if (value != null) {
                      provider.changeMonth(value);
                    }
                  },
          ),
        ),
        SizedBox(
          width: 140,
          child: DropdownButtonFormField<int>(
            initialValue: provider.selectedYear,
            decoration: const InputDecoration(labelText: 'Ano'),
            items: years
                .map(
                  (year) => DropdownMenuItem(value: year, child: Text('$year')),
                )
                .toList(),
            onChanged: provider.isLoading
                ? null
                : (value) {
                    if (value != null) {
                      provider.changeYear(value);
                    }
                  },
          ),
        ),
      ],
    );
  }

  static String _capitalizeStatic(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}

class _CategoryBreakdown extends StatelessWidget {
  const _CategoryBreakdown({required this.entries, required this.currency});

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
      decoration: _panelDecoration,
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

BoxDecoration get _panelDecoration => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(24),
  border: Border.all(color: AppColors.border),
);
