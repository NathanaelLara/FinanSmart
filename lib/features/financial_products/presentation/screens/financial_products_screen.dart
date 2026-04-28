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

class FinancialProductsScreen extends StatelessWidget {
  const FinancialProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<FinancialProductsProvider>();

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        const SectionTitle(
          title: 'Tarjetas y prestamos',
          subtitle: 'Monitorea deuda, limite disponible y proximos pagos.',
        ),
        const SizedBox(height: AppSpacing.md),
        CustomButton(
          label: 'Agregar producto',
          icon: Icons.add_card_rounded,
          onPressed: () => _showAddProductSheet(context),
        ),
        const SizedBox(height: AppSpacing.lg),
        if (provider.products.isEmpty)
          const EmptyStateWidget(
            title: 'Aun no tienes productos financieros',
            subtitle:
                'Registra tus tarjetas y prestamos para medir tu nivel de deuda.',
            icon: Icons.credit_card_off_rounded,
          )
        else
          ...provider.products.map(
            (product) => Container(
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
                          color:
                              (product.type == FinancialProductType.creditCard
                                      ? AppColors.info
                                      : AppColors.warning)
                                  .withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Icon(
                          product.type == FinancialProductType.creditCard
                              ? Icons.credit_card_rounded
                              : Icons.request_quote_rounded,
                          color: product.type == FinancialProductType.creditCard
                              ? AppColors.info
                              : AppColors.warning,
                        ),
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
                              product.type == FinancialProductType.creditCard
                                  ? 'Tarjeta de credito'
                                  : 'Prestamo',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
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
                      _MetricPill(
                        label: 'Limite',
                        value: CurrencyFormatter.format(
                          product.limit,
                          currency: product.currency,
                        ),
                      ),
                      _MetricPill(
                        label: 'Pago mensual',
                        value: CurrencyFormatter.format(
                          product.monthlyPayment ?? 0,
                          currency: product.currency,
                        ),
                      ),
                      _MetricPill(
                        label: 'Interes',
                        value:
                            '${(product.interestRate ?? 0).toStringAsFixed(1)}%',
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

  Future<void> _showAddProductSheet(BuildContext context) async {
    final nameController = TextEditingController();
    final balanceController = TextEditingController();
    final limitController = TextEditingController();
    final paymentController = TextEditingController();
    final rateController = TextEditingController();
    var selectedType = FinancialProductType.creditCard;
    var selectedCurrency = CurrencyType.dop;
    final formKey = GlobalKey<FormState>();

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return StatefulBuilder(
          builder: (context, setState) {
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
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField<FinancialProductType>(
                          initialValue: selectedType,
                          decoration: const InputDecoration(
                            labelText: 'Tipo de producto',
                          ),
                          items: FinancialProductType.values
                              .map(
                                (type) => DropdownMenuItem(
                                  value: type,
                                  child: Text(
                                    type == FinancialProductType.creditCard
                                        ? 'Tarjeta de credito'
                                        : 'Prestamo',
                                  ),
                                ),
                              )
                              .toList(),
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => selectedType = value);
                            }
                          },
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomTextField(
                          controller: nameController,
                          label: 'Nombre',
                          validator: (value) =>
                              value == null || value.trim().isEmpty
                              ? 'Ingresa un nombre'
                              : null,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomTextField(
                          controller: balanceController,
                          label: 'Balance actual',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _numberValidator,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomTextField(
                          controller: limitController,
                          label: 'Limite o monto aprobado',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _numberValidator,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomTextField(
                          controller: paymentController,
                          label: 'Pago mensual',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _numberValidator,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        CustomTextField(
                          controller: rateController,
                          label: 'Tasa de interes',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                          validator: _numberValidator,
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
                          selected: {selectedCurrency},
                          onSelectionChanged: (selection) {
                            setState(() => selectedCurrency = selection.first);
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        CustomButton(
                          label: 'Guardar producto',
                          onPressed: () async {
                            if (!formKey.currentState!.validate()) {
                              return;
                            }

                            await context
                                .read<FinancialProductsProvider>()
                                .addProduct(
                                  name: nameController.text.trim(),
                                  type: selectedType,
                                  balance: double.parse(
                                    balanceController.text.trim(),
                                  ),
                                  limit: double.parse(
                                    limitController.text.trim(),
                                  ),
                                  monthlyPayment: double.parse(
                                    paymentController.text.trim(),
                                  ),
                                  interestRate: double.parse(
                                    rateController.text.trim(),
                                  ),
                                  currency: selectedCurrency,
                                );
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obligatorio';
    }
    if (double.tryParse(value) == null) {
      return 'Numero invalido';
    }
    return null;
  }
}

class _MetricPill extends StatelessWidget {
  const _MetricPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
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
          Text(value, style: Theme.of(context).textTheme.titleMedium),
        ],
      ),
    );
  }
}
