import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_spacing.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../../shared/widgets/transaction_tile.dart';
import '../providers/transactions_provider.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionsProvider>().loadTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<TransactionsProvider>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SectionTitle(
          title: 'Registro de ingresos y gastos',
          subtitle: 'Filtra por tipo y moneda para una lectura clara.',
        ),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ChoiceChip(
              label: const Text('Todo'),
              selected: provider.selectedType == null,
              onSelected: (_) => provider.setTransactionType(null),
            ),
            ChoiceChip(
              label: const Text('Ingresos'),
              selected: provider.selectedType == TransactionType.income,
              onSelected: (_) =>
                  provider.setTransactionType(TransactionType.income),
            ),
            ChoiceChip(
              label: const Text('Gastos'),
              selected: provider.selectedType == TransactionType.expense,
              onSelected: (_) =>
                  provider.setTransactionType(TransactionType.expense),
            ),
            ChoiceChip(
              label: const Text('Todas'),
              selected: provider.selectedCurrency == null,
              onSelected: (_) => provider.setCurrency(null),
            ),
            ChoiceChip(
              label: const Text('DOP'),
              selected: provider.selectedCurrency == CurrencyType.dop,
              onSelected: (_) => provider.setCurrency(CurrencyType.dop),
            ),
            ChoiceChip(
              label: const Text('USD'),
              selected: provider.selectedCurrency == CurrencyType.usd,
              onSelected: (_) => provider.setCurrency(CurrencyType.usd),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.lg),
        CustomButton(
          label: 'Agregar movimiento',
          icon: Icons.add_rounded,
          onPressed: () => _openTransactionForm(context),
          isLoading: provider.isLoading,
        ),
        const SizedBox(height: AppSpacing.lg),
        if (provider.isLoading && provider.transactions.isEmpty)
          const Center(child: CircularProgressIndicator())
        else if (provider.errorMessage != null && provider.transactions.isEmpty)
          EmptyStateWidget(
            title: 'No fue posible cargar tus movimientos',
            subtitle: provider.errorMessage!,
            icon: Icons.warning_amber_rounded,
          )
        else if (provider.filteredTransactions.isEmpty)
          const EmptyStateWidget(
            title: 'No hay movimientos en este filtro',
            subtitle:
                'Agrega una transaccion para empezar a medir tu flujo de caja.',
            icon: Icons.receipt_long_rounded,
          )
        else
          ...provider.filteredTransactions.map(
            (transaction) => TransactionTile(
              transaction: transaction,
              onEdit: () =>
                  _openTransactionForm(context, transaction: transaction),
              onDelete: () => _confirmDelete(context, transaction),
            ),
          ),
      ],
    );
  }

  Future<void> _openTransactionForm(
    BuildContext context, {
    TransactionModel? transaction,
  }) async {
    final provider = context.read<TransactionsProvider>();
    final result = await showModalBottomSheet<_TransactionFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _TransactionFormSheet(
        transaction: transaction,
        initialCurrency: provider.selectedCurrency ?? CurrencyType.dop,
      ),
    );

    if (result == null || !context.mounted) {
      return;
    }

    final isEditing = transaction != null;
    final success = isEditing
        ? await provider.updateTransaction(
            transaction.copyWith(
              description: result.description,
              amount: result.amount,
              type: result.type,
              category: result.category,
              currency: result.currency,
            ),
          )
        : await provider.addTransaction(
            title: result.description,
            amount: result.amount,
            type: result.type,
            category: result.category,
            currency: result.currency,
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
                ? isEditing
                      ? 'Movimiento actualizado.'
                      : 'Movimiento guardado.'
                : provider.errorMessage ??
                      'No fue posible guardar el movimiento.',
          ),
        ),
      );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    TransactionModel transaction,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar movimiento'),
        content: Text('Quieres eliminar "${transaction.description}"?'),
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

    final provider = context.read<TransactionsProvider>();
    final success = await provider.deleteTransaction(transaction.id);

    if (!context.mounted) {
      return;
    }

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Movimiento eliminado.'
                : provider.errorMessage ?? 'No fue posible eliminar.',
          ),
        ),
      );
  }
}

class _TransactionFormSheet extends StatefulWidget {
  const _TransactionFormSheet({
    required this.initialCurrency,
    this.transaction,
  });

  final TransactionModel? transaction;
  final CurrencyType initialCurrency;

  @override
  State<_TransactionFormSheet> createState() => _TransactionFormSheetState();
}

class _TransactionFormSheetState extends State<_TransactionFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _descriptionController;
  late final TextEditingController _amountController;
  late TransactionType _selectedType;
  late TransactionCategory _selectedCategory;
  late CurrencyType _selectedCurrency;

  bool get _isEditing => widget.transaction != null;

  @override
  void initState() {
    super.initState();
    final transaction = widget.transaction;
    _descriptionController = TextEditingController(
      text: transaction?.description ?? '',
    );
    _amountController = TextEditingController(
      text: transaction?.amount.toStringAsFixed(2) ?? '',
    );
    _selectedType = transaction?.type ?? TransactionType.expense;
    _selectedCategory = transaction?.category ?? TransactionCategory.food;
    _selectedCurrency = transaction?.currency ?? widget.initialCurrency;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                    _isEditing ? 'Editar movimiento' : 'Nuevo movimiento',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _descriptionController,
                    label: 'Titulo',
                    validator: (value) => value == null || value.trim().isEmpty
                        ? 'Ingresa un titulo'
                        : null,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _amountController,
                    label: 'Monto',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final normalizedValue = value?.replaceAll(',', '.');
                      final amount = double.tryParse(
                        normalizedValue?.trim() ?? '',
                      );
                      if (amount == null) {
                        return 'Monto invalido';
                      }
                      if (amount <= 0) {
                        return 'El monto debe ser mayor que cero';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<TransactionType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: TransactionType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              type == TransactionType.income
                                  ? 'Ingreso'
                                  : 'Gasto',
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedType = value);
                      }
                    },
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
                  const SizedBox(height: AppSpacing.lg),
                  CustomButton(
                    label: _isEditing
                        ? 'Guardar cambios'
                        : 'Guardar movimiento',
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

    final amount = double.parse(
      _amountController.text.trim().replaceAll(',', '.'),
    );

    Navigator.pop(
      context,
      _TransactionFormResult(
        description: _descriptionController.text.trim(),
        amount: amount,
        type: _selectedType,
        category: _selectedCategory,
        currency: _selectedCurrency,
      ),
    );
  }
}

class _TransactionFormResult {
  const _TransactionFormResult({
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.currency,
  });

  final String description;
  final double amount;
  final TransactionType type;
  final TransactionCategory category;
  final CurrencyType currency;
}
