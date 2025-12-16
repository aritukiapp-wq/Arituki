/// Un diálogo que presenta opciones para un evento favorito.
///
/// Este widget muestra un `AlertDialog` que permite al usuario añadir o quitar
/// un evento de su lista de favoritos. El estado actual (si es favorito o no)
/// se pasa como parámetro para mostrar el texto y el icono correctos.
library;
import 'package:flutter/material.dart';
import 'package:arituki/models/event_supabase.dart'; // Asegúrate que la ruta es correcta

class FavoriteEventDialog extends StatelessWidget {
  final EventoSupabase event;
  final bool isCurrentlyFavorite;
  final VoidCallback onToggleFavorite;
  // Opcional: si quieres añadir bloqueo de evento individual desde aquí
  // final bool? isCurrentlyBlocked; 
  // final VoidCallback? onToggleBlock;

  const FavoriteEventDialog({
    super.key,
    required this.event,
    required this.isCurrentlyFavorite,
    required this.onToggleFavorite,
    // this.isCurrentlyBlocked,
    // this.onToggleBlock,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(event.titulo ?? 'Opciones de Evento'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          ListTile(
            leading: Icon(
              isCurrentlyFavorite ? Icons.favorite : Icons.favorite_border,
              color: isCurrentlyFavorite ? Colors.red : Colors.grey,
            ),
            title: Text(
              isCurrentlyFavorite ? 'Quitar de Favoritos' : 'Añadir a Favoritos',
            ),
            onTap: onToggleFavorite,
          ),
          // Opcional: ListTile para bloquear/desbloquear evento individual
          // if (isCurrentlyBlocked != null && onToggleBlock != null)
          //   ListTile(
          //     leading: Icon(
          //       isCurrentlyBlocked! ? Icons.block : Icons.settings_backup_restore,
          //       color: isCurrentlyBlocked! ? Colors.orange : Colors.grey,
          //     ),
          //     title: Text(
          //       isCurrentlyBlocked! ? 'Desbloquear Evento' : 'Bloquear Evento',
          //     ),
          //     onTap: onToggleBlock,
          //   ),
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
