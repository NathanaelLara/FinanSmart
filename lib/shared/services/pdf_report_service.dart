import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/currency_converter.dart';
import '../../core/utils/currency_formatter.dart';
import '../../features/reports/data/monthly_report_summary.dart';
import '../models/monthly_report_model.dart';
import '../models/transaction_model.dart';

class PdfReportService {
  Future<Uint8List> generateMonthlyReport(MonthlyReportModel report) async {
    final pdf = pw.Document();
    final monthLabel = DateFormat('MMMM yyyy', 'es_DO').format(report.month);

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(),
        ),
        build: (context) => [
          _header('Reporte mensual - ${_capitalize(monthLabel)}'),
          pw.SizedBox(height: 24),
          _metricRow(
            'Ingresos',
            CurrencyFormatter.format(
              report.totalIncome,
              currency: report.currency,
            ),
          ),
          _metricRow(
            'Gastos',
            CurrencyFormatter.format(
              report.totalExpense,
              currency: report.currency,
            ),
          ),
          _metricRow(
            'Ahorro neto',
            CurrencyFormatter.format(
              report.netSavings,
              currency: report.currency,
            ),
          ),
          _metricRow(
            'Tasa de ahorro',
            '${report.savingsRate.toStringAsFixed(1)}%',
          ),
          pw.SizedBox(height: 24),
          _sectionTitle('Hallazgos clave'),
          ...report.highlights.map(_bullet),
        ],
      ),
    );

    return pdf.save();
  }

  Future<Uint8List> generateMonthlyReportSummary(
    MonthlyReportSummary report,
  ) async {
    final pdf = pw.Document();
    final monthLabel = DateFormat(
      'MMMM yyyy',
      'es_DO',
    ).format(DateTime(report.year, report.month));
    final currency = report.displayCurrency;

    pdf.addPage(
      pw.MultiPage(
        pageTheme: pw.PageTheme(
          margin: const pw.EdgeInsets.all(32),
          theme: pw.ThemeData.withFont(),
        ),
        build: (context) => [
          _header('Reporte mensual - ${_capitalize(monthLabel)}'),
          pw.SizedBox(height: 8),
          pw.Text(
            CurrencyConverter.conversionNote(currency),
            style: pw.TextStyle(fontSize: 9, color: PdfColors.grey700),
          ),
          pw.SizedBox(height: 20),
          _sectionTitle('Resumen del periodo'),
          _metricRow(
            'Ingresos',
            CurrencyFormatter.format(report.totalIncome, currency: currency),
          ),
          _metricRow(
            'Gastos',
            CurrencyFormatter.format(report.totalExpense, currency: currency),
          ),
          _metricRow(
            'Balance neto',
            CurrencyFormatter.format(report.netBalance, currency: currency),
          ),
          _metricRow(
            'Ahorro estimado',
            CurrencyFormatter.format(
              report.estimatedSavings,
              currency: currency,
            ),
          ),
          _metricRow(
            'Porcentaje de ahorro',
            '${report.savingsRate.toStringAsFixed(1)}%',
          ),
          _metricRow('Total de transacciones', '${report.totalTransactions}'),
          _metricRow('Ingresos registrados', '${report.incomeTransactions}'),
          _metricRow('Gastos registrados', '${report.expenseTransactions}'),
          pw.SizedBox(height: 18),
          _sectionTitle('Gastos por categoria'),
          if (report.expensesByCategory.isEmpty)
            pw.Text('No hay gastos registrados para este periodo.')
          else
            _categoryTable(report),
          pw.SizedBox(height: 18),
          _sectionTitle('Top de gastos'),
          if (report.topExpenses.isEmpty)
            pw.Text('No hay gastos destacados para este periodo.')
          else
            _topExpensesTable(report),
          pw.SizedBox(height: 18),
          _sectionTitle('Conducta financiera'),
          ...report.insights.map(_bullet),
          pw.SizedBox(height: 18),
          _sectionTitle('Recomendaciones'),
          ...report.recommendations.map(_bullet),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _header(String title) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          'FinanSmart',
          style: pw.TextStyle(
            fontSize: 24,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#1B365D'),
          ),
        ),
        pw.SizedBox(height: 6),
        pw.Text(title, style: const pw.TextStyle(fontSize: 16)),
      ],
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 8),
      child: pw.Text(
        title,
        style: pw.TextStyle(fontSize: 15, fontWeight: pw.FontWeight.bold),
      ),
    );
  }

  pw.Widget _metricRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 8),
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(10),
        color: PdfColor.fromHex('#F7F9FC'),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label),
          pw.Text(value, style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ),
    );
  }

  pw.Widget _categoryTable(MonthlyReportSummary report) {
    return pw.TableHelper.fromTextArray(
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#EAF0F7')),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      data: [
        ['Categoria', 'Monto'],
        ...report.expensesByCategory.entries.map(
          (entry) => [
            entry.key,
            CurrencyFormatter.format(
              entry.value,
              currency: report.displayCurrency,
            ),
          ],
        ),
      ],
    );
  }

  pw.Widget _topExpensesTable(MonthlyReportSummary report) {
    return pw.TableHelper.fromTextArray(
      headerDecoration: pw.BoxDecoration(color: PdfColor.fromHex('#EAF0F7')),
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
      cellAlignment: pw.Alignment.centerLeft,
      data: [
        ['Descripcion', 'Categoria', 'Monto original', 'Fecha'],
        ...report.topExpenses.map(
          (transaction) => [
            transaction.description,
            transaction.categoryName ?? transaction.category.displayName,
            CurrencyFormatter.format(
              transaction.amount,
              currency: transaction.currency,
            ),
            DateFormat('dd/MM/yyyy').format(transaction.transactionDate),
          ],
        ),
      ],
    );
  }

  pw.Widget _bullet(String item) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 6),
      child: pw.Bullet(text: item),
    );
  }

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
