import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
    super.key,
    this.subtitle,
    this.color = AppColors.primary,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 180;
        final cardPadding = isCompact ? 14.0 : 18.0;
        final iconPadding = isCompact ? 8.0 : 10.0;
        final iconSize = isCompact ? 20.0 : 24.0;
        final titleStyle = textTheme.bodyMedium?.copyWith(
          fontSize: isCompact ? 12 : null,
          height: 1.15,
        );
        final valueStyle = textTheme.titleLarge?.copyWith(
          fontSize: isCompact ? 18 : null,
          height: 1.15,
        );
        final subtitleStyle = textTheme.bodyMedium?.copyWith(
          fontSize: isCompact ? 12 : null,
          height: 1.15,
        );

        return Container(
          padding: EdgeInsets.all(cardPadding),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.border),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(iconPadding),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: iconSize),
              ),
              SizedBox(height: isCompact ? 12 : 16),
              Text(
                title,
                style: titleStyle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 6),
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(value, style: valueStyle),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle!,
                  style: subtitleStyle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
