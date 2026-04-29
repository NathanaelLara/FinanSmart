import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/financial_product_model.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../../../shared/widgets/custom_button.dart';
import '../../../../shared/widgets/custom_text_field.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/section_title.dart';
import '../providers/financial_products_provider.dart';

class FinancialProductsScreen extends StatefulWidget {
  const FinancialProductsScreen({super.key});

  @override
  State<FinancialProductsScreen> createState() =>
      _FinancialProductsScreenState();
}

class _FinancialProductsScreenState extends State<FinancialProductsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        context.read<FinancialProductsProvider>().loadProducts();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinancialProductsProvider>();
    final products = provider.filteredProducts;

    return RefreshIndicator(
      onRefresh: provider.loadProducts,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          const SectionTitle(
            title: 'Productos financieros',
            subtitle: 'Administra tarjetas, prestamos, cuentas e inversiones.',
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              ChoiceChip(
                label: const Text('Todos'),
                selected: provider.selectedType == null,
                onSelected: (_) => provider.setTypeFilter(null),
              ),
              ...FinancialProductType.values.map(
                (type) => ChoiceChip(
                  label: Text(type.displayName),
                  selected: provider.selectedType == type,
                  onSelected: (_) => provider.setTypeFilter(type),
                ),
              ),
              ChoiceChip(
                label: const Text('Todas'),
                selected: provider.selectedCurrency == null,
                onSelected: (_) => provider.setCurrencyFilter(null),
              ),
              ChoiceChip(
                label: const Text('DOP'),
                selected: provider.selectedCurrency == CurrencyType.dop,
                onSelected: (_) => provider.setCurrencyFilter(CurrencyType.dop),
              ),
              ChoiceChip(
                label: const Text('USD'),
                selected: provider.selectedCurrency == CurrencyType.usd,
                onSelected: (_) => provider.setCurrencyFilter(CurrencyType.usd),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          CustomButton(
            label: 'Agregar producto',
            icon: Icons.add_card_rounded,
            isLoading: provider.isLoading,
            onPressed: () => _openProductForm(context),
          ),
          if (provider.isLoading) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(),
          ],
          if (provider.errorMessage != null) ...[
            const SizedBox(height: AppSpacing.lg),
            EmptyStateWidget(
              title: 'No fue posible cargar tus productos',
              subtitle: provider.errorMessage!,
              icon: Icons.warning_amber_rounded,
            ),
          ],
          const SizedBox(height: AppSpacing.lg),
          if (!provider.isLoading && products.isEmpty)
            const EmptyStateWidget(
              title: 'Aun no tienes productos financieros registrados',
              subtitle:
                  'Agrega una tarjeta, prestamo o cuenta para analizar mejor tu salud financiera.',
              icon: Icons.account_balance_wallet_outlined,
            )
          else
            ...products.map(
              (product) => _FinancialProductCard(
                product: product,
                onEdit: () => _openProductForm(context, product: product),
                onDeactivate: product.isActive
                    ? () => _deactivateProduct(context, product)
                    : null,
                onDelete: () => _deleteProduct(context, product),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _openProductForm(
    BuildContext context, {
    FinancialProductModel? product,
  }) async {
    final result = await showModalBottomSheet<_ProductFormResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _ProductFormSheet(product: product),
    );

    if (result == null || !context.mounted) {
      return;
    }

    final provider = context.read<FinancialProductsProvider>();
    final success = product == null
        ? await provider.addProduct(
            name: result.name,
            type: result.type,
            institutionName: result.institutionName,
            currency: result.currency,
            balance: result.balance,
            limitAmount: result.limitAmount,
            interestRate: result.interestRate,
            minimumPayment: result.minimumPayment,
            monthlyPayment: result.monthlyPayment,
            dueDay: result.dueDay,
            notes: result.notes,
          )
        : await provider.updateProduct(
            FinancialProductModel(
              id: product.id,
              userId: product.userId,
              name: result.name,
              type: result.type,
              institutionName: result.institutionName,
              currency: result.currency,
              balance: result.balance,
              limitAmount: result.limitAmount,
              interestRate: result.interestRate,
              minimumPayment: result.minimumPayment,
              monthlyPayment: result.monthlyPayment,
              dueDay: result.dueDay,
              paymentDate: product.paymentDate,
              openingDate: product.openingDate,
              notes: result.notes,
              isActive: product.isActive,
              createdAt: product.createdAt,
              updatedAt: product.updatedAt,
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
                ? product == null
                      ? 'Producto guardado.'
                      : 'Producto actualizado.'
                : provider.errorMessage ?? 'No fue posible guardar.',
          ),
        ),
      );
  }

  Future<void> _deactivateProduct(
    BuildContext context,
    FinancialProductModel product,
  ) async {
    final provider = context.read<FinancialProductsProvider>();
    final success = await provider.deactivateProduct(product.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Producto desactivado.'
                : provider.errorMessage ?? 'No fue posible desactivar.',
          ),
        ),
      );
  }

  Future<void> _deleteProduct(
    BuildContext context,
    FinancialProductModel product,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar producto'),
        content: Text('Quieres eliminar "${product.name}"?'),
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

    final provider = context.read<FinancialProductsProvider>();
    final success = await provider.deleteProduct(product.id);
    if (!context.mounted) {
      return;
    }
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            success
                ? 'Producto eliminado.'
                : provider.errorMessage ?? 'No fue posible eliminar.',
          ),
        ),
      );
  }
}

class _FinancialProductCard extends StatelessWidget {
  const _FinancialProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
    this.onDeactivate,
  });

  final FinancialProductModel product;
  final VoidCallback onEdit;
  final VoidCallback? onDeactivate;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = product.isActive ? AppColors.info : AppColors.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(_iconForType(product.type), color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.type.displayName} • ${product.institutionName}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
              PopupMenuButton<_ProductAction>(
                icon: const Icon(Icons.more_horiz_rounded),
                onSelected: (action) {
                  switch (action) {
                    case _ProductAction.edit:
                      onEdit();
                    case _ProductAction.deactivate:
                      onDeactivate?.call();
                    case _ProductAction.delete:
                      onDelete();
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: _ProductAction.edit,
                    child: Text('Editar'),
                  ),
                  if (onDeactivate != null)
                    const PopupMenuItem(
                      value: _ProductAction.deactivate,
                      child: Text('Desactivar'),
                    ),
                  const PopupMenuItem(
                    value: _ProductAction.delete,
                    child: Text('Eliminar'),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              _MetricPill(
                label: 'Balance',
                value: CurrencyFormatter.format(
                  product.balance,
                  currency: product.currency,
                ),
              ),
              if (product.limitAmount != null)
                _MetricPill(
                  label: 'Limite',
                  value: CurrencyFormatter.format(
                    product.limitAmount!,
                    currency: product.currency,
                  ),
                ),
              if (product.minimumPayment != null)
                _MetricPill(
                  label: 'Pago minimo',
                  value: CurrencyFormatter.format(
                    product.minimumPayment!,
                    currency: product.currency,
                  ),
                ),
              if (product.monthlyPayment != null)
                _MetricPill(
                  label: 'Cuota mensual',
                  value: CurrencyFormatter.format(
                    product.monthlyPayment!,
                    currency: product.currency,
                  ),
                ),
              if (product.interestRate != null)
                _MetricPill(
                  label: 'Interes',
                  value: '${product.interestRate!.toStringAsFixed(1)}%',
                ),
              if (product.dueDay != null)
                _MetricPill(label: 'Dia limite', value: '${product.dueDay}'),
              _MetricPill(
                label: 'Estado',
                value: product.isActive ? 'Activo' : 'Inactivo',
              ),
            ],
          ),
          if (product.notes?.trim().isNotEmpty == true) ...[
            const SizedBox(height: AppSpacing.md),
            Text(product.notes!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }

  IconData _iconForType(FinancialProductType type) {
    switch (type) {
      case FinancialProductType.bankAccount:
      case FinancialProductType.savingsAccount:
        return Icons.account_balance_rounded;
      case FinancialProductType.creditCard:
        return Icons.credit_card_rounded;
      case FinancialProductType.loan:
        return Icons.request_quote_rounded;
      case FinancialProductType.investment:
        return Icons.trending_up_rounded;
      case FinancialProductType.other:
        return Icons.account_balance_wallet_rounded;
    }
  }
}

class _ProductFormSheet extends StatefulWidget {
  const _ProductFormSheet({this.product});

  final FinancialProductModel? product;

  @override
  State<_ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<_ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _institutionController;
  late final TextEditingController _balanceController;
  late final TextEditingController _limitController;
  late final TextEditingController _minimumPaymentController;
  late final TextEditingController _monthlyPaymentController;
  late final TextEditingController _interestController;
  late final TextEditingController _dueDayController;
  late final TextEditingController _notesController;
  late FinancialProductType _selectedType;
  late CurrencyType _selectedCurrency;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _selectedType = product?.type ?? FinancialProductType.creditCard;
    _selectedCurrency = product?.currency ?? CurrencyType.dop;
    _nameController = TextEditingController(text: product?.name ?? '');
    _institutionController = TextEditingController(
      text: product?.institutionName ?? '',
    );
    _balanceController = TextEditingController(
      text: product == null ? '' : product.balance.toStringAsFixed(2),
    );
    _limitController = TextEditingController(
      text: product?.limitAmount == null
          ? ''
          : product!.limitAmount!.toStringAsFixed(2),
    );
    _minimumPaymentController = TextEditingController(
      text: product?.minimumPayment == null
          ? ''
          : product!.minimumPayment!.toStringAsFixed(2),
    );
    _monthlyPaymentController = TextEditingController(
      text: product?.monthlyPayment == null
          ? ''
          : product!.monthlyPayment!.toStringAsFixed(2),
    );
    _interestController = TextEditingController(
      text: product?.interestRate == null
          ? ''
          : product!.interestRate!.toStringAsFixed(2),
    );
    _dueDayController = TextEditingController(
      text: product?.dueDay == null ? '' : '${product!.dueDay}',
    );
    _notesController = TextEditingController(text: product?.notes ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _institutionController.dispose();
    _balanceController.dispose();
    _limitController.dispose();
    _minimumPaymentController.dispose();
    _monthlyPaymentController.dispose();
    _interestController.dispose();
    _dueDayController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.product != null;

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
                    isEditing ? 'Editar producto' : 'Nuevo producto',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  DropdownButtonFormField<FinancialProductType>(
                    initialValue: _selectedType,
                    decoration: const InputDecoration(labelText: 'Tipo'),
                    items: FinancialProductType.values
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(type.displayName),
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
                  CustomTextField(
                    controller: _nameController,
                    label: 'Nombre del producto',
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _institutionController,
                    label: 'Institucion financiera',
                    validator: _requiredValidator,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _balanceController,
                    label: 'Balance actual',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _requiredNumberValidator,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _limitController,
                    label: 'Limite o monto aprobado',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _optionalNumberValidator,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _minimumPaymentController,
                    label: 'Pago minimo',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _optionalNumberValidator,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _monthlyPaymentController,
                    label: 'Cuota mensual',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _optionalNumberValidator,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _interestController,
                    label: 'Tasa de interes (%)',
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _optionalNumberValidator,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  CustomTextField(
                    controller: _dueDayController,
                    label: 'Dia de pago o corte',
                    keyboardType: TextInputType.number,
                    validator: _optionalDayValidator,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  TextFormField(
                    controller: _notesController,
                    minLines: 2,
                    maxLines: 4,
                    decoration: const InputDecoration(labelText: 'Notas'),
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
                    label: isEditing ? 'Guardar cambios' : 'Guardar producto',
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
      _ProductFormResult(
        name: _nameController.text.trim(),
        type: _selectedType,
        institutionName: _institutionController.text.trim(),
        currency: _selectedCurrency,
        balance: _parseRequiredDouble(_balanceController.text),
        limitAmount: _parseOptionalDouble(_limitController.text),
        minimumPayment: _parseOptionalDouble(_minimumPaymentController.text),
        monthlyPayment: _parseOptionalDouble(_monthlyPaymentController.text),
        interestRate: _parseOptionalDouble(_interestController.text),
        dueDay: _parseOptionalInt(_dueDayController.text),
        notes: _emptyToNull(_notesController.text),
      ),
    );
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }
    return null;
  }

  String? _requiredNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }
    return _optionalNumberValidator(value);
  }

  String? _optionalNumberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    if (double.tryParse(value.trim().replaceAll(',', '.')) == null) {
      return 'Numero invalido';
    }
    return null;
  }

  String? _optionalDayValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null;
    }
    final day = int.tryParse(value.trim());
    if (day == null || day < 1 || day > 31) {
      return 'Ingresa un dia entre 1 y 31';
    }
    return null;
  }

  double _parseRequiredDouble(String value) {
    return double.parse(value.trim().replaceAll(',', '.'));
  }

  double? _parseOptionalDouble(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return double.parse(trimmed.replaceAll(',', '.'));
  }

  int? _parseOptionalInt(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) {
      return null;
    }
    return int.parse(trimmed);
  }

  String? _emptyToNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }
}

class _ProductFormResult {
  const _ProductFormResult({
    required this.name,
    required this.type,
    required this.institutionName,
    required this.currency,
    required this.balance,
    this.limitAmount,
    this.interestRate,
    this.minimumPayment,
    this.monthlyPayment,
    this.dueDay,
    this.notes,
  });

  final String name;
  final FinancialProductType type;
  final String institutionName;
  final CurrencyType currency;
  final double balance;
  final double? limitAmount;
  final double? interestRate;
  final double? minimumPayment;
  final double? monthlyPayment;
  final int? dueDay;
  final String? notes;
}

enum _ProductAction { edit, deactivate, delete }

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
