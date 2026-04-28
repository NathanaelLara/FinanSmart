import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/services/pdf_report_service.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/section_title.dart';
import '../providers/reports_provider.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ReportsProvider>();
    final pdfService = PdfReportService();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SectionTitle(
          title: 'Reportes mensuales',
          subtitle: 'Descarga o imprime resumentes listos para presentar.',
        ),
        const SizedBox(height: AppSpacing.lg),
        if (provider.reports.isEmpty)
          const EmptyStateWidget(
            title: 'No hay reportes disponibles',
            subtitle:
                'Genera movimientos mensuales para empezar a construir tus reportes.',
            icon: Icons.picture_as_pdf_outlined,
          )
        else
          ...provider.reports.map(
            (report) => Container(
              margin: const EdgeInsets.only(bottom: 14),
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _capitalize(
                      DateFormat('MMMM yyyy', 'es_DO').format(report.month),
                    ),
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ingresos: ${CurrencyFormatter.format(report.totalIncome, currency: report.currency)}',
                  ),
                  Text(
                    'Gastos: ${CurrencyFormatter.format(report.totalExpense, currency: report.currency)}',
                  ),
                  Text(
                    'Ahorro neto: ${CurrencyFormatter.format(report.netSavings, currency: report.currency)}',
                  ),
                  Text(
                    'Tasa de ahorro: ${report.savingsRate.toStringAsFixed(1)}%',
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      OutlinedButton.icon(
                        onPressed: () async {
                          await Printing.layoutPdf(
                            onLayout: (_) =>
                                pdfService.generateMonthlyReport(report),
                            name:
                                'finansmart_${DateFormat('yyyy_MM').format(report.month)}.pdf',
                          );
                        },
                        icon: const Icon(Icons.print_outlined),
                        label: const Text('Imprimir'),
                      ),
                      OutlinedButton.icon(
                        onPressed: () async {
                          final bytes = await pdfService.generateMonthlyReport(
                            report,
                          );
                          await Printing.sharePdf(
                            bytes: bytes,
                            filename:
                                'finansmart_${DateFormat('yyyy_MM').format(report.month)}.pdf',
                          );
                        },
                        icon: const Icon(Icons.file_download_outlined),
                        label: const Text('Descargar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
