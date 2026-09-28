import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum MetricTrend { up, down }

/// Tarjeta de métrica para los tableros de courier y el histórico del cliente
/// (09 §8.3): título discreto, valor destacado y, si la feature lo conoce, la
/// variación respecto al periodo anterior.
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.subtitle,
    this.trend,
    this.trendLabel,
    this.onTap,
  });

  final String title;
  final String value;
  final IconData icon;
  final String? subtitle;
  final MetricTrend? trend;
  final String? trendLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final card = Card(
      elevation: 1,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Row(
          children: [
            _Icono(icon: icon),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(title, style: theme.textTheme.labelMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          value,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                      if (trend != null && trendLabel != null)
                        Padding(
                          padding: const EdgeInsets.only(left: AppSpacing.sm),
                          child: _Tendencia(trend: trend!, label: trendLabel!),
                        ),
                    ],
                  ),
                  if (subtitle case final subtitle?) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(subtitle, style: theme.textTheme.labelSmall),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );

    final onTap = this.onTap;
    if (onTap == null) {
      return card;
    }
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: card,
    );
  }
}

class _Icono extends StatelessWidget {
  const _Icono({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: AppColors.quickbiteOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppRadius.button),
      ),
      child: Icon(icon, size: 20, color: AppColors.quickbiteOrange),
    );
  }
}

class _Tendencia extends StatelessWidget {
  const _Tendencia({required this.trend, required this.label});

  final MetricTrend trend;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = trend == MetricTrend.up
        ? AppColors.successGreen
        : AppColors.errorRed;
    final icon = trend == MetricTrend.up
        ? Icons.trending_up
        : Icons.trending_down;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: AppSpacing.xs),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}
