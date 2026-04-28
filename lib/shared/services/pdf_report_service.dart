import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../../core/utils/currency_formatter.dart';
import '../models/monthly_report_model.dart';

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
          pw.Text(
            'FinanSmart',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1B365D'),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Text(
            'Reporte mensual - ${_capitalize(monthLabel)}',
            style: const pw.TextStyle(fontSize: 16),
          ),
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
          pw.Text(
            'Hallazgos clave',
            style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
          ),
          pw.SizedBox(height: 8),
          ...report.highlights.map(
            (item) => pw.Padding(
              padding: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Bullet(text: item),
            ),
          ),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _metricRow(String label, String value) {
    return pw.Container(
      margin: const pw.EdgeInsets.only(bottom: 12),
      padding: const pw.EdgeInsets.all(14),
      decoration: pw.BoxDecoration(
        borderRadius: pw.BorderRadius.circular(12),
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

  String _capitalize(String value) {
    if (value.isEmpty) {
      return value;
    }
    return value[0].toUpperCase() + value.substring(1);
  }
}
