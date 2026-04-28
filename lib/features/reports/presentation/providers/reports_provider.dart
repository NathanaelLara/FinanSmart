import 'package:flutter/material.dart';

import '../../../../shared/models/monthly_report_model.dart';
import '../../data/reports_repository.dart';

class ReportsProvider extends ChangeNotifier {
  ReportsProvider(this._reportsRepository);

  final ReportsRepository _reportsRepository;

  List<MonthlyReportModel> _reports = [];

  List<MonthlyReportModel> get reports => _reports;

  Future<void> loadReports() async {
    _reports = await _reportsRepository.getReports();
    notifyListeners();
  }
}
