import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/budget_model.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/widgets/summary_card.dart';
import '../../data/budget_progress.dart';
import '../providers/budgets_provider.dart';

class BudgetsScreen extends StatefulWidget {
  const BudgetsScreen({super.key});

  @override
  State<BudgetsScreen> createState() => _BudgetsScreenState();
}

class _BudgetsScreenState extends State<BudgetsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<BudgetsProvider>().loadBudgets();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BudgetsProvider>();
    final summary = provider.summary;
    final currency = summary.displayCurrency;
    final monthLabel = _capitalize(
      DateFormat(
        'MMMM yyyy',
        'es_DO',
      ).format(DateTime(provider.selectedYear, provider.selectedMonth)),
    );

    return RefreshIndicator(
      onRefresh: provider.refreshBudgets,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionTitle(
            title: 'Presupuestos',
            subtitle:
                'Define limites por categoria y compara contra tus gastos reales.',
          ),
          const SizedBox(height: AppSpacing.lg),
          _BudgetPeriodSelector(provider: provider),
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
                onPressed: provider.isLoading
                    ? null
                    : () => _openBudgetForm(context),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Agregar'),
              ),
            ],
          ),
          if (provider.isLoading) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(),
          ],
          if (provider.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            EmptyStateWidget(
              title: 'No fue posible cargar presupuestos',
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
                  title: 'Presupuestado',
                  value: CurrencyFormatter.format(
                    summary.totalBudgeted,
                    currency: currency,
                  ),
                  subtitle: '${summary.activeBudgets} activos',
                  icon: Icons.account_balance_wallet_outlined,
                  color: AppColors.info,
                ),
                SummaryCard(
                  title: 'Gastado',
                  value: CurrencyFormatter.format(
                    summary.totalSpent,
                    currency: currency,
                  ),
                  subtitle: 'Categorias presupuestadas',
                  icon: Icons.receipt_long_outlined,
                  color: AppColors.error,
                ),
                SummaryCard(
                  title: 'Restante',
                  value: CurrencyFormatter.format(
                    summary.totalRemaining,
                    currency: currency,
                  ),
                  subtitle: 'Disponible estimado',
                  icon: Icons.savings_outlined,
                  color: summary.totalRemaining >= 0
                      ? AppColors.success
                      : AppColors.error,
                ),
                SummaryCard(
                  title: 'Excedidos',
                  value: '${summary.exceededBudgets}',
                  subtitle: 'Sobre el limite',
                  icon: Icons.warning_amber_rounded,
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
          if (!summary.hasBudgets)
            const EmptyStateWidget(
              title: 'Aun no tienes presupuestos registrados para este mes',
              subtitle:
                  'Crea un presupuesto por categoria para controlar mejor tus gastos.',
              icon: Icons.track_changes_outlined,
            )
          else ...[
            const SectionTitle(
              title: 'Progreso por categoria',
              subtitle: 'Uso real contra el limite definido.',
            ),
            const SizedBox(height: AppSpacing.md),
            ...summary.budgets.map(
              (progress) => _BudgetProgressCard(
                progress: progress,
                onEdit: () => _openBudgetForm(context, budget: progress.budget),
                onDeactivate: () => _deactivateBudget(context, progress.budget),
                onDelete: () => _deleteBudget(context, progress.budget),
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          CustomButton(
            label: 'Agregar presupuesto',
            icon: Icons.add_rounded,
            isLoading: provider.isLoading,
            onPressed: () => _openBudgetForm(context),
          ),
        ],
      ),
    );
  }

  Future<void> _openBudgetForm(
    BuildContext context, {
    BudgetModel? budget,
  }) async {
    final result = await showModalBottomSheet<_BudgetFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _BudgetFormSheet(
        budget: budget,
        initialMonth: context.read<BudgetsProvider>().selectedMonth,
        initialYear: context.read<BudgetsProvider>().selectedYear,
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    final provider = context.read<BudgetsProvider>();
    final success = budget == null
        ? await provider.addBudget(
            category: result.category,
            currency: result.currency,
            limitAmount: result.limitAmount,
            month: result.month,
            year: result.year,
            notes: result.notes,
          )
        : await provider.updateBudget(
            budget.copyWith(
              categoryId: result.category.firestoreId,
              categoryName: result.category.displayName,
              currency: result.currency,
              limitAmount: result.limitAmount,
              month: result.month,
              year: result.year,
              notes: result.notes,
            ),
          );

    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? budget == null
                      ? 'Presupuesto guardado.'
                      : 'Presupuesto actualizado.'
                : provider.errorMessage ?? 'No fue posible guardar.',
          ),
        ),
      );
  }

  Future<void> _deactivateBudget(
    BuildContext context,
    BudgetModel budget,
  ) async {
    final provider = context.read<BudgetsProvider>();
    final success = await provider.deactivateBudget(budget.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Presupuesto desactivado.'
                : provider.errorMessage ?? 'No fue posible desactivar.',
          ),
        ),
      );
  }

  Future<void> _deleteBudget(BuildContext context, BudgetModel budget) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar presupuesto'),
        content: Text(
          'Quieres eliminar el presupuesto de ${budget.categoryName}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !context.mounted) {
      return;
    }

    final provider = context.read<BudgetsProvider>();
    final success = await provider.deleteBudget(budget.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Presupuesto eliminado.'
                : provider.errorMessage ?? 'No fue posible eliminar.',
          ),
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

class _BudgetProgressCard extends StatelessWidget {
  const _BudgetProgressCard({
    required this.progress,
    required this.onEdit,
    required this.onDeactivate,
    required this.onDelete,
  });

  final BudgetProgress progress;
  final VoidCallback onEdit;
  final VoidCallback onDeactivate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(progress);
    final budget = progress.budget;
    final progressValue = (progress.usagePercentage / 100).clamp(0.0, 1.0);

    return Container(
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
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      budget.categoryName,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      progress.statusLabel,
                      style: Theme.of(
                        context,
                      ).textTheme.bodyMedium?.copyWith(color: color),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_BudgetAction>(
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (action) {
                  switch (action) {
                    case _BudgetAction.edit:
                      onEdit();
                    case _BudgetAction.deactivate:
                      onDeactivate();
                    case _BudgetAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: _BudgetAction.edit,
                    child: Text('Editar'),
                  ),
                  PopupMenuItem(
                    value: _BudgetAction.deactivate,
                    child: Text('Desactivar'),
                  ),
                  PopupMenuItem(
                    value: _BudgetAction.delete,
                    child: Text('Eliminar'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: progressValue,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricPill(
                label: 'Limite',
                value: CurrencyFormatter.format(
                  budget.limitAmount,
                  currency: budget.currency,
                ),
              ),
              _MetricPill(
                label: 'Gastado',
                value: CurrencyFormatter.format(
                  progress.spentAmount,
                  currency: budget.currency,
                ),
              ),
              _MetricPill(
                label: 'Restante',
                value: CurrencyFormatter.format(
                  progress.remainingAmount,
                  currency: budget.currency,
                ),
              ),
              _MetricPill(
                label: 'Uso',
                value: '${progress.usagePercentage.toStringAsFixed(1)}%',
              ),
            ],
          ),
          if (budget.notes?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            Text(budget.notes!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  Color _statusColor(BudgetProgress progress) {
    if (progress.isExceeded || progress.usagePercentage >= 100) {
      return AppColors.error;
    }
    if (progress.isNearLimit) {
      return AppColors.warning;
    }
    return AppColors.success;
  }
}

class _BudgetPeriodSelector extends StatelessWidget {
  const _BudgetPeriodSelector({required this.provider});

  final BudgetsProvider provider;

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

class _BudgetFormSheet extends StatefulWidget {
  const _BudgetFormSheet({
    this.budget,
    required this.initialMonth,
    required this.initialYear,
  });

  final BudgetModel? budget;
  final int initialMonth;
  final int initialYear;

  @override
  State<_BudgetFormSheet> createState() => _BudgetFormSheetState();
}

class _BudgetFormSheetState extends State<_BudgetFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _limitController;
  late final TextEditingController _notesController;
  late TransactionCategory _selectedCategory;
  late CurrencyType _selectedCurrency;
  late int _selectedMonth;
  late int _selectedYear;

  @override
  void initState() {
    super.initState();
    final budget = widget.budget;
    _selectedCategory = TransactionCategoryX.fromFirestoreId(
      budget?.categoryId,
    );
    _selectedCurrency = budget?.currency ?? CurrencyType.dop;
    _selectedMonth = budget?.month ?? widget.initialMonth;
    _selectedYear = budget?.year ?? widget.initialYear;
    _limitController = TextEditingController(
      text: budget == null ? '' : budget.limitAmount.toStringAsFixed(2),
    );
    _notesController = TextEditingController(text: budget?.notes ?? '');
  }

  @override
  void dispose() {
    _limitController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentYear = DateTime.now().year;
    final years = List.generate(7, (index) => currentYear - 5 + index);
    final isEditing = widget.budget != null;

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: SafeArea(
          top: false,
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isEditing ? 'Editar presupuesto' : 'Nuevo presupuesto',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<TransactionCategory>(
                    initialValue: _selectedCategory,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: TransactionCategory.values
                        .map(
                          (category) => DropdownMenuItem(
                            value: category,
                            child: Text(category.displayName),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCategory = value);
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _limitController,
                    label: 'Monto limite',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _limitValidator,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 170,
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedMonth,
                          decoration: const InputDecoration(labelText: 'Mes'),
                          items: List.generate(12, (index) {
                            final month = index + 1;
                            return DropdownMenuItem(
                              value: month,
                              child: Text(
                                _BudgetPeriodSelector._capitalizeStatic(
                                  DateFormat(
                                    'MMMM',
                                    'es_DO',
                                  ).format(DateTime(2024, month)),
                                ),
                              ),
                            );
                          }),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedMonth = value);
                            }
                          },
                        ),
                      ),
                      SizedBox(
                        width: 130,
                        child: DropdownButtonFormField<int>(
                          initialValue: _selectedYear,
                          decoration: const InputDecoration(labelText: 'Ano'),
                          items: years
                              .map(
                                (year) => DropdownMenuItem(
                                  value: year,
                                  child: Text('$year'),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _selectedYear = value);
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  SegmentedButton<CurrencyType>(
                    showSelectedIcon: false,
                    segments: const [
                      ButtonSegment(
                        value: CurrencyType.dop,
                        label: Text('DOP'),
                      ),
                      ButtonSegment(
                        value: CurrencyType.usd,
                        label: Text('USD'),
                      ),
                    ],
                    selected: {_selectedCurrency},
                    onSelectionChanged: (selection) {
                      setState(() => _selectedCurrency = selection.first);
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Notas'),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  CustomButton(
                    label: isEditing
                        ? 'Guardar cambios'
                        : 'Guardar presupuesto',
                    icon: Icons.save_outlined,
                    onPressed: _submit,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    Navigator.pop(
      context,
      _BudgetFormResult(
        category: _selectedCategory,
        currency: _selectedCurrency,
        limitAmount: double.parse(
          _limitController.text.trim().replaceAll(',', '.'),
        ),
        month: _selectedMonth,
        year: _selectedYear,
        notes: _emptyToNull(_notesController.text),
      ),
    );
  }

  String? _limitValidator(String? value) {
    final amount = double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
    if (amount == null) {
      return 'Monto invalido';
    }
    if (amount <= 0) {
      return 'El monto debe ser mayor que cero';
    }
    return null;
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _BudgetFormResult {
  const _BudgetFormResult({
    required this.category,
    required this.currency,
    required this.limitAmount,
    required this.month,
    required this.year,
    this.notes,
  });

  final TransactionCategory category;
  final CurrencyType currency;
  final double limitAmount;
  final int month;
  final int year;
  final String? notes;
}

enum _BudgetAction { edit, deactivate, delete }

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        ],
      ),
    );
  }
}
