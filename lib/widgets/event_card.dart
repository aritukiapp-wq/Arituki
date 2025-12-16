/// Un widget de tarjeta para mostrar la información resumida de un evento en una lista.
///
/// Esta tarjeta es uno de los componentes más importantes de la UI. Muestra:
/// - La imagen del evento.
/// - El título, que también funciona como botón para marcar el evento como favorito.
/// - El lugar, que funciona como botón para mostrar más opciones del lugar (favorito/bloqueado).
/// - La fecha y la ciudad del evento.
///
/// El estado de favorito/bloqueado se indica visualmente a través de los iconos.
library;
import 'package:flutter/material.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/utils/utils.dart' as utils;
import 'package:arituki/services/navigation_service.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:arituki/theme/app_theme.dart';

class EventCard extends StatelessWidget {
  final EventoSupabase event;
  final bool isEventFavorite;
  final bool isPlaceFavorite;
  final bool isEventBlocked;
  final bool isPlaceBlocked;
  final VoidCallback onTap;
  final VoidCallback onFavoriteToggle;
  final VoidCallback onShowOptions;

  const EventCard({
    super.key,
    required this.event,
    this.isEventFavorite = false,
    this.isPlaceFavorite = false,
    this.isEventBlocked = false,
    this.isPlaceBlocked = false,
    required this.onTap,
    required this.onFavoriteToggle,
    required this.onShowOptions,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final String? imageUrl = event.imageUrl;
    final bool isMultiDay = event.diaIni != null &&
                          event.diaFin != null &&
                          !DateUtils.isSameDay(event.diaIni!, event.diaFin!);

    final Color? cardColor = isMultiDay ? (theme.brightness == Brightness.dark ? Colors.blue[100] : Colors.blue[50]) : null;

    // Determinar si es una tarjeta especial que necesita colores de texto forzados
    final bool isSpecialCard = isMultiDay && theme.brightness == Brightness.dark;
    final Color? specialTextColor = isSpecialCard ? Colors.grey[850] : null;
    final Color? specialIconColor = isSpecialCard ? Colors.grey[700] : theme.colorScheme.onSurface.withAlpha(153);

    return Card(
      color: cardColor,
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12.0),
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.kCardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- IMAGE --- 
              GestureDetector(
                onTap: () {
                  if (imageUrl != null && imageUrl.isNotEmpty) {
                    NavigationService.navigateToFullscreenImage(context, imageUrl, "event_image_${event.id}");
                  }
                },
                child: Hero(
                  tag: "event_image_${event.id}",
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(AppTheme.kCardImageBorderRadius),
                    child: imageUrl != null && imageUrl.isNotEmpty
                        ? CachedNetworkImage(
                            imageUrl: imageUrl,
                            width: 90,
                            height: 90,
                            fit: BoxFit.cover,
                            placeholder: (context, url) => Container(width: 90, height: 90, color: theme.colorScheme.surfaceContainerHighest, child: const Center(child: Icon(Icons.image, color: Colors.grey, size: 30))),
                            errorWidget: (context, url, error) => Container(width: 90, height: 90, color: theme.colorScheme.surfaceContainerHighest, child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 30))),
                          )
                        : Container(width: 90, height: 90, decoration: BoxDecoration(color: theme.colorScheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(AppTheme.kCardImageBorderRadius)), child: Center(child: Icon(Icons.event, color: Colors.grey[600], size: 40))),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // --- DETAILS COLUMN ---
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildDetailRow(
                      onTap: onFavoriteToggle,
                      icon: isEventFavorite ? Icons.favorite : Icons.favorite_border,
                      iconColor: isEventFavorite ? Colors.red : specialIconColor,
                      text: event.titulo ?? 'Evento sin título',
                      textStyle: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: specialTextColor, // Aplicar color especial
                      ),
                      maxLines: 2,
                    ),
                    const SizedBox(height: 5),
                    if (event.lugar != null && event.lugar!.isNotEmpty)
                      _buildDetailRow(
                        onTap: onShowOptions,
                        icon: isPlaceFavorite ? Icons.star : Icons.star_border,
                        iconColor: isPlaceFavorite ? Colors.amber[600] : specialIconColor,
                        text: event.lugar!,
                        textStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: specialTextColor, // Aplicar color especial
                        ),
                      ),
                    const SizedBox(height: 5),
                     _buildDetailRow(
                        text: utils.formatEventDates(event.diaIni, event.diaFin, event.hora),
                        textStyle: theme.textTheme.bodyMedium?.copyWith(
                          color: specialTextColor, // Aplicar color especial
                        ),
                    ),
                    const SizedBox(height: 5),
                    if (event.ciudad != null && event.ciudad!.isNotEmpty)
                       _buildDetailRow(
                          text: event.ciudad!,
                          textStyle: theme.textTheme.bodyMedium?.copyWith(
                            color: specialTextColor, // Aplicar color especial
                          ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required String text,
    IconData? icon,
    TextStyle? textStyle,
    Color? iconColor,
    VoidCallback? onTap,
    int maxLines = 1,
  }) {
    Widget iconWidget = SizedBox(
      width: 22, // Ancho fijo para alinear el texto
      child: icon != null
          ? Icon(icon, size: 18, color: iconColor)
          : null,
    );

    if (onTap != null) {
      iconWidget = InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: iconWidget,
      );
    }

    Widget textContent = Text(text, style: textStyle, maxLines: maxLines, overflow: TextOverflow.ellipsis);
    if (onTap != null) {
      textContent = InkWell(
        onTap: onTap,
        child: textContent,
      );
    }
    Widget textWidget = Flexible(child: textContent);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          iconWidget,
          const SizedBox(width: 6),
          textWidget,
        ],
      ),
    );
  }
}
