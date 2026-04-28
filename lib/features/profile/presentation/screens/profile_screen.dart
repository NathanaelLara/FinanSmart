import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_spacing.dart';
import '../../../../core/routes/app_routes.dart';
import '../../../../shared/models/transaction_model.dart';
import '../../../../shared/widgets/section_title.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    if (user == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 30,
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                child: Text(
                  user.name.substring(0, 1).toUpperCase(),
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(color: AppColors.primary),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        const SectionTitle(
          title: 'Configuracion',
          subtitle: 'Preferencias basicas del proyecto y la experiencia demo.',
        ),
        const SizedBox(height: AppSpacing.md),
        _ProfileCard(
          child: DropdownButtonFormField<CurrencyType>(
            initialValue: user.preferredCurrency,
            decoration: const InputDecoration(labelText: 'Moneda principal'),
            items: const [
              DropdownMenuItem(
                value: CurrencyType.dop,
                child: Text('Pesos dominicanos'),
              ),
              DropdownMenuItem(
                value: CurrencyType.usd,
                child: Text('Dolares estadounidenses'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                context.read<AuthProvider>().updatePreferredCurrency(value);
              }
            },
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const _ProfileCard(
          child: ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.cloud_outlined),
            title: Text('Backend preparado para Firebase'),
            subtitle: Text(
              'Listo para integrar Authentication y Cloud Firestore.',
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.xl),
        FilledButton.tonalIcon(
          onPressed: () async {
            await context.read<AuthProvider>().logout();
            if (!context.mounted) {
              return;
            }
            Navigator.pushNamedAndRemoveUntil(
              context,
              AppRoutes.login,
              (_) => false,
            );
          },
          icon: const Icon(Icons.logout_rounded),
          label: const Text('Cerrar sesion'),
        ),
      ],
    );
  }
}

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({required this.child});

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
