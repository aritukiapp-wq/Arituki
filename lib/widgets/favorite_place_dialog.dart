/// Un diálogo que presenta opciones para un lugar específico (favorito/bloqueado).
///
/// Este widget muestra un `AlertDialog` que permite al usuario añadir o quitar
/// un lugar de su lista de favoritos, así como bloquearlo o desbloquearlo.
/// El estado actual (favorito/bloqueado) se pasa como parámetro para mostrar
/// los textos y los iconos correctos.
library;
import 'package:flutter/material.dart';

// Definición del tipo de callback esperado, incluyendo los nuevos parámetros
typedef EventInteractionCallback = void Function(
    String placeName, // El nombre del lugar/SubLugar específico
    String eventId, // ID del evento principal
    String eventName, // Nombre del evento principal
    String cityName, // Ciudad del evento
    String? eventCategory // Categoría del evento (opcional)
    );

class FavoritePlaceDialog extends StatelessWidget { // CLASE RENOMBRADA AQUÍ
  final String placeName; // Nombre del SubLugar específico
  final String eventId; // ID del evento principal (cambiado de int a String para consistencia)
  final String eventName; // Nombre del evento principal
  final String cityName; // Ciudad del evento
  final String? eventCategory; // Categoría del evento (opcional)
  final bool isCurrentlyFavorite;
  final bool isCurrentlyBlocked;
  final EventInteractionCallback onFavoriteSelected; // Tipo de callback modificado
  final EventInteractionCallback onBlockSelected; // Tipo de callback modificado

  const FavoritePlaceDialog({ // CONSTRUCTOR ACTUALIZADO AQUÍ
    super.key,
    required this.placeName,
    required this.eventId, // Sigue siendo requerido
    required this.eventName, // Nuevo, requerido
    required this.cityName, // Nuevo, requerido
    this.eventCategory, // Nuevo, opcional
    required this.isCurrentlyFavorite,
    required this.isCurrentlyBlocked,
    required this.onFavoriteSelected, // Firma de callback actualizada
    required this.onBlockSelected, // Firma de callback actualizada
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Opciones para "$placeName"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(
              isCurrentlyFavorite ? Icons.star : Icons.star_border_outlined,
              color: isCurrentlyFavorite
                  ? Theme
                  .of(context)
                  .colorScheme
                  .primary
                  : Colors.grey,
            ),
            title: Text(
              isCurrentlyFavorite
                  ? 'Quitar de Favoritos'
                  : 'Añadir a Favoritos',
            ),
            onTap: () {
              // Ahora pasamos todos los parámetros requeridos por el callback
              onFavoriteSelected(
                  placeName, eventId, eventName, cityName, eventCategory);
            },
          ),
          ListTile(
            leading: Icon(
              isCurrentlyBlocked
                  ? Icons.do_not_disturb_on_outlined
                  : Icons.block_outlined,
              color: isCurrentlyBlocked
                  ? Theme
                  .of(context)
                  .colorScheme
                  .error
                  : Colors.grey,
            ),
            title: Text(
              isCurrentlyBlocked ? 'Desbloquear Lugar' : 'Bloquear Lugar',
            ),
            onTap: () {
              // Ahora pasamos todos los parámetros requeridos por el callback
              onBlockSelected(
                  placeName, eventId, eventName, cityName, eventCategory);
            },
          ),
        ],
      ),
      actions: <Widget>[
        TextButton(
          child: const Text('Cerrar'),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ],
    );
  }
}