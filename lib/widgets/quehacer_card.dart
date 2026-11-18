import 'package:flutter/material.dart';
import '../models/quehacer.dart';
import '../theme/app_theme.dart';

/// Tarjeta reutilizable para visualizar y gestionar un [Quehacer].
class QuehacerCard extends StatelessWidget {
  const QuehacerCard({
    super.key,
    required this.quehacer,
    required this.responsable,
    required this.esResponsable,
    required this.esAdmin,
    required this.onTap,
    required this.onLongPress,
    this.onCheckboxChanged,
    this.onOptionsPressed,
    this.onCommentsPressed,
  });

  final Quehacer quehacer;
  final String responsable;
  final bool esResponsable;
  final bool esAdmin;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  final ValueChanged<bool?>? onCheckboxChanged;
  final VoidCallback? onOptionsPressed;
  final VoidCallback? onCommentsPressed;

  @override
  Widget build(BuildContext context) {
    final q = quehacer;

    return Card(
      key: Key('item_quehacer_${q.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColors.borde, width: 1.2),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Checkbox(
                  key: Key('checkbox_quehacer_${q.id}'),
                  value: q.hecho,
                  activeColor: AppColors.verdeOliva,
                  visualDensity: VisualDensity.compact,
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  onChanged: esResponsable ? onCheckboxChanged : null,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        Text(
                          q.titulo,
                          key: Key('titulo_quehacer_${q.id}'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            decoration: q.hecho ? TextDecoration.lineThrough : null,
                            color: q.hecho ? AppColors.textoSecundario.withValues(alpha: 0.6) : AppColors.textoPrincipal,
                          ),
                        ),
                        Container(
                          key: Key('badge_estado_${q.id}'),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: q.hecho ? AppColors.verdeOliva.withValues(alpha: 0.14) : AppColors.arenaTaupe.withValues(alpha: 0.22),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              Icon(
                                q.hecho
                                    ? Icons.check_circle_rounded
                                    : Icons.pending_actions_rounded,
                                size: 16,
                                color: q.hecho
                                    ? AppColors.verdeOliva
                                    : AppColors.bronceMocha,
                              ),
                              Text(
                                q.hecho ? 'Hecho' : 'Pendiente',
                                key: Key('texto_estado_${q.id}'),
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: q.hecho
                                      ? AppColors.verdeOliva
                                      : AppColors.bronceMocha,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (q.recurrente)
                          Container(
                            key: Key('badge_recurrente_${q.id}'),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.azulPizarra.withValues(alpha: 0.22),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: AppColors.azulPizarra.withValues(alpha: 0.45),
                              ),
                            ),
                            child: const Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Icon(
                                  Icons.repeat_rounded,
                                  size: 14,
                                  color: Color(0xFF385266),
                                ),
                                Text(
                                  'Semanal',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF385266),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 16,
                      runSpacing: 6,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 4,
                          children: [
                            const Icon(
                              Icons.person_outline_rounded,
                              size: 16,
                              color: Colors.black54,
                            ),
                            Text(
                              responsable,
                              key: Key('responsable_quehacer_${q.id}'),
                              style: const TextStyle(
                                fontSize: 13,
                                color: Colors.black87,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        if (q.fechaLimite != null)
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 4,
                            children: [
                              const Icon(
                                Icons.calendar_today_outlined,
                                size: 14,
                                color: Colors.black54,
                              ),
                              Text(
                                '${q.fechaLimite!.day.toString().padLeft(2, '0')}/${q.fechaLimite!.month.toString().padLeft(2, '0')}/${q.fechaLimite!.year}',
                                key: Key('fecha_quehacer_${q.id}'),
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                        InkWell(
                          key: Key('boton_comentarios_${q.id}'),
                          borderRadius: BorderRadius.circular(8),
                          onTap: onCommentsPressed ?? onTap,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: const Wrap(
                              crossAxisAlignment: WrapCrossAlignment.center,
                              spacing: 4,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 14,
                                  color: AppColors.verdeOliva,
                                ),
                                Text(
                                  'Comentarios',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: AppColors.verdeOliva,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (esAdmin)
                IconButton(
                  key: Key('boton_opciones_quehacer_${q.id}'),
                  tooltip: 'Opciones del quehacer',
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: Colors.black45,
                  ),
                  onPressed: onOptionsPressed,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
