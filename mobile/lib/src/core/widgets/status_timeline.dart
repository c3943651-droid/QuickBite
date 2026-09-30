import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

enum TimelineStepState { completed, current, pending, cancelled }

/// Un paso del timeline. La feature que lo usa traduce su enumerado de dominio
/// a estos estados, de modo que `core/widgets` no conoce el vocabulario de
/// pedidos.
class TimelineStep {
  const TimelineStep({
    required this.label,
    required this.icon,
    this.timestamp,
    this.state = TimelineStepState.pending,
  });

  final String label;
  final IconData icon;
  final String? timestamp;
  final TimelineStepState state;
}

/// Timeline de estados con marca de tiempo, paso actual resaltado y pulso suave
/// (09 §8.12, 07.1 SCR-ORDER-01).
///
/// Un pedido cancelado no tiene paso actual: se marca el último punto de
/// control con la cruz y el resto queda en gris, sin pulso.
class StatusTimeline extends StatefulWidget {
  const StatusTimeline({super.key, required this.steps});

  final List<TimelineStep> steps;

  @override
  State<StatusTimeline> createState() => _StatusTimelineState();
}

class _StatusTimelineState extends State<StatusTimeline>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulso = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _pulso.dispose();
    super.dispose();
  }

  bool get _hayActual =>
      widget.steps.any((paso) => paso.state == TimelineStepState.current);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (var i = 0; i < widget.steps.length; i++)
          _Paso(
            paso: widget.steps[i],
            esUltimo: i == widget.steps.length - 1,
            pulso: _hayActual ? _pulso : null,
          ),
      ],
    );
  }
}

class _Paso extends StatelessWidget {
  const _Paso({required this.paso, required this.esUltimo, this.pulso});

  final TimelineStep paso;
  final bool esUltimo;
  final Animation<double>? pulso;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _Marca(paso: paso, esUltimo: esUltimo, pulso: pulso),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: esUltimo ? 0 : AppSpacing.lg),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    paso.label,
                    style: theme.textTheme.bodyLarge?.copyWith(
                      fontWeight: paso.state == TimelineStepState.completed
                          ? FontWeight.w600
                          : FontWeight.w400,
                      color: paso.state == TimelineStepState.pending
                          ? AppColors.inkMuted
                          : theme.colorScheme.onSurface,
                    ),
                  ),
                  if (paso.timestamp case final timestamp?) ...[
                    const SizedBox(height: 2),
                    Text(
                      timestamp,
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: AppColors.inkMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Marca extends StatelessWidget {
  const _Marca({required this.paso, required this.esUltimo, this.pulso});

  final TimelineStep paso;
  final bool esUltimo;
  final Animation<double>? pulso;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 24,
      child: Column(
        children: [
          _Punto(step: paso, pulso: pulso),
          if (!esUltimo)
            Expanded(
              child: Container(
                width: 2,
                color: paso.state == TimelineStepState.completed
                    ? AppColors.success
                    : AppColors.surfaceMuted,
              ),
            ),
        ],
      ),
    );
  }
}

class _Punto extends StatelessWidget {
  const _Punto({required this.step, this.pulso});

  final TimelineStep step;
  final Animation<double>? pulso;

  @override
  Widget build(BuildContext context) {
    final punto = switch (step.state) {
      TimelineStepState.completed => Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.success,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.check, size: 14, color: AppColors.white),
      ),
      TimelineStepState.current => _PuntoActual(icon: step.icon, pulso: pulso),
      TimelineStepState.cancelled => Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.error,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.close, size: 14, color: AppColors.white),
      ),
      TimelineStepState.pending => Container(
        width: 24,
        height: 24,
        decoration: BoxDecoration(
          color: AppColors.surfaceMuted,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.inkMuted, width: 1),
        ),
        child: Icon(step.icon, size: 12, color: AppColors.inkMuted),
      ),
    };

    return KeyedSubtree(
      key: switch (step.state) {
        TimelineStepState.current => const ValueKey('timeline-current'),
        TimelineStepState.completed => ValueKey(
          'timeline-completed-${step.label}',
        ),
        TimelineStepState.cancelled => ValueKey(
          'timeline-cancelled-${step.label}',
        ),
        TimelineStepState.pending => ValueKey('timeline-pending-${step.label}'),
      },
      child: punto,
    );
  }
}

class _PuntoActual extends StatelessWidget {
  const _PuntoActual({required this.icon, this.pulso});

  final IconData icon;
  final Animation<double>? pulso;

  @override
  Widget build(BuildContext context) {
    const halo = 24.0;
    const radio = 20.0;

    final punto = Container(
      width: radio,
      height: radio,
      decoration: BoxDecoration(
        color: AppColors.accent,
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: 12, color: AppColors.white),
    );

    if (pulso == null) {
      return SizedBox(
        width: halo,
        height: halo,
        child: Center(child: punto),
      );
    }

    return SizedBox(
      width: halo,
      height: halo,
      child: Center(
        child: ScaleTransition(
          scale: Tween<double>(
            begin: 0.85,
            end: 1.1,
          ).animate(CurvedAnimation(parent: pulso!, curve: Curves.easeInOut)),
          child: punto,
        ),
      ),
    );
  }
}
