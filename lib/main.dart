import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';

import 'core/constants/app_environment.dart';
import 'core/routes/app_routes.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/providers/auth_provider.dart';
import 'features/dashboard/data/dashboard_repository.dart';
import 'features/dashboard/presentation/providers/dashboard_provider.dart';
import 'features/financial_health/data/financial_health_repository.dart';
import 'features/financial_health/presentation/providers/financial_health_provider.dart';
import 'features/financial_products/data/financial_products_repository.dart';
import 'features/financial_products/presentation/providers/financial_products_provider.dart';
import 'features/reports/data/reports_repository.dart';
import 'features/reports/presentation/providers/reports_provider.dart';
import 'features/transactions/data/transactions_repository.dart';
import 'features/transactions/presentation/providers/transactions_provider.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_DO');
  if (AppEnvironment.useFirebase) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  runApp(const FinansmartApp());
}

class FinansmartApp extends StatelessWidget {
  const FinansmartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthProvider(AuthRepository())..restoreSession(),
        ),
        ChangeNotifierProvider(
          create: (_) => TransactionsProvider(TransactionsRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) =>
              FinancialProductsProvider(FinancialProductsRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => ReportsProvider(ReportsRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => FinancialHealthProvider(FinancialHealthRepository()),
        ),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(DashboardRepository()),
        ),
      ],
      child: MaterialApp(
        title: 'FinanSmart',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }
}
