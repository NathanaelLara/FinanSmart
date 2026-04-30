import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../../../shared/widgets/empty_state_widget.dart';
import '../../../../shared/widgets/section_title.dart';
import '../providers/bank_notifications_provider.dart';
import '../../data/bank_notification_transaction_candidate.dart';

class BankNotificationsScreen extends StatefulWidget {
  const BankNotificationsScreen({super.key});

  @override
  State<BankNotificationsScreen> createState() =>
      _BankNotificationsScreenState();
}

class _BankNotificationsScreenState extends State<BankNotificationsScreen>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BankNotificationsProvider>().initialize();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      context.read<BankNotificationsProvider>().refreshPermissionStatus();
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BankNotificationsProvider>();

    return Scaffold(
      appBar: AppBar(title: const Text('Lectura de consumos bancarios')),
      body: provider.isAndroid
          ? _AndroidContent(provider: provider)
          : const _UnsupportedPlatformMessage(),
    );
  }
}

class _AndroidContent extends StatelessWidget {
  const _AndroidContent({required this.provider});

  final BankNotificationsProvider provider;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () async {
        await provider.refreshPermissionStatus();
        await provider.loadCandidates();
      },
      child: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          _PermissionCard(provider: provider),
          const SizedBox(height: AppSpacing.lg),
          _ModeCard(provider: provider),
          const SizedBox(height: AppSpacing.xl),
          const SectionTitle(
            title: 'Consumos detectados',
            subtitle: 'Sugerencias pendientes antes de guardarlas como gasto.',
          ),
          const SizedBox(height: AppSpacing.md),
          if (provider.errorMessage != null) ...[
            _ErrorBanner(message: provider.errorMessage!),
            const SizedBox(height: AppSpacing.md),
          ],
          if (provider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (provider.candidates.isEmpty)
            const EmptyStateWidget(
              icon: Icons.notifications_none_rounded,
              title: 'Sin consumos pendientes',
              subtitle:
                  'Las notificaciones bancarias compatibles apareceran aqui.',
            )
          else
            ...provider.candidates.map((candidate) {
              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: _CandidateCard(candidate: candidate),
              );
            }),
        ],
      ),
    );
  }
}

class _PermissionCard extends StatelessWidget {
  const _PermissionCard({required this.provider});

  final BankNotificationsProvider provider;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                provider.isListeningEnabled
                    ? Icons.check_circle_rounded
                    : Icons.info_rounded,
                color: provider.isListeningEnabled
                    ? AppColors.success
                    : AppColors.warning,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  provider.isListeningEnabled ? 'Activo' : 'Inactivo',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          const Text(
            'FinanSmart puede leer notificaciones del dispositivo solo si activas el acceso en Android. Se filtran apps bancarias y no se guardan conversaciones ni texto completo de notificaciones.',
          ),
          const SizedBox(height: AppSpacing.md),
          FilledButton.icon(
            onPressed: provider.openNotificationSettings,
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Activar lectura de notificaciones'),
          ),
        ],
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({required this.provider});

  final BankNotificationsProvider provider;

  @override
  Widget build(BuildContext context) {
    return _SurfaceCard(
      child: SwitchListTile(
        contentPadding: EdgeInsets.zero,
        value: provider.autoSaveEnabled,
        onChanged: provider.toggleAutoSave,
        title: const Text('Guardar automaticamente'),
        subtitle: Text(
          provider.autoSaveEnabled
              ? 'Los consumos detectados se guardaran como gasto.'
              : 'Preguntar antes de guardar. Recomendado.',
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate});

  final BankNotificationTransactionCandidate candidate;

  @override
  Widget build(BuildContext context) {
    final provider = context.read<BankNotificationsProvider>();
    return _SurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  candidate.bankName,
                  style: Theme.of(context).textTheme.titleMedium,
                ),
              ),
              Text(
                CurrencyFormatter.format(
                  candidate.amount,
                  currency: candidate.currency,
                ),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(candidate.merchantName),
          const SizedBox(height: 6),
          Text(
            '${candidate.maskedCard} · ${candidate.detectedCategory.displayName}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton.icon(
                onPressed: () => provider.acceptCandidate(candidate),
                icon: const Icon(Icons.check_rounded),
                label: const Text('Aceptar'),
              ),
              OutlinedButton.icon(
                onPressed: () => _showEditDialog(context, candidate),
                icon: const Icon(Icons.edit_rounded),
                label: const Text('Editar'),
              ),
              TextButton.icon(
                onPressed: () => provider.rejectCandidate(candidate.id),
                icon: const Icon(Icons.close_rounded),
                label: const Text('Rechazar'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _showEditDialog(
    BuildContext context,
    BankNotificationTransactionCandidate candidate,
  ) async {
    final merchantController = TextEditingController(
      text: candidate.merchantName,
    );
    final amountController = TextEditingController(
      text: candidate.amount.toStringAsFixed(2),
    );
    var category = candidate.detectedCategory;

    final saved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Editar consumo'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: merchantController,
                      decoration: const InputDecoration(labelText: 'Comercio'),
                    ),
                    TextField(
                      controller: amountController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(labelText: 'Monto'),
                    ),
                    DropdownButtonFormField<TransactionCategory>(
                      initialValue: category,
                      decoration: const InputDecoration(labelText: 'Categoria'),
                      items: TransactionCategory.values.map((item) {
                        return DropdownMenuItem(
                          value: item,
                          child: Text(item.displayName),
                        );
                      }).toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() => category = value);
                        }
                      },
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Guardar'),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !context.mounted) {
      return;
    }
    final amount = double.tryParse(amountController.text.replaceAll(',', ''));
    if (amount == null || amount <= 0) {
      return;
    }
    await context.read<BankNotificationsProvider>().saveCandidateAsTransaction(
      candidate,
      merchantName: merchantController.text.trim(),
      amount: amount,
      category: category,
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  const _ErrorBanner({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(message, style: const TextStyle(color: AppColors.error)),
    );
  }
}

class _UnsupportedPlatformMessage extends StatelessWidget {
  const _UnsupportedPlatformMessage();

  @override
  Widget build(BuildContext context) {
    return const Center(child: Text('Disponible solo en Android'));
  }
}

class _SurfaceCard extends StatelessWidget {
  const _SurfaceCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}
