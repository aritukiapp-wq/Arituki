/// Un diálogo que muestra la lista de lugares bloqueados por el usuario.
///
/// Este widget consume `BlockedPlaceProvider` para obtener la lista de lugares
/// bloqueados y los muestra en una lista. Cada elemento de la lista tiene un
/// botón que permite al usuario desbloquear el lugar correspondiente, eliminándolo
/// de la lista y persistiendo el cambio a través del provider.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arituki/providers/blocked_place_provider.dart';
import 'package:arituki/utils/utils.dart' as utils;

class BlockedPlacesDialog extends StatelessWidget {
  const BlockedPlacesDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final blockedProvider = context.watch<BlockedPlaceProvider>();
    final blockedPlaces = blockedProvider.blockedPlaces;

    return AlertDialog(
      title: const Text('Lugares bloqueados'),
      content: blockedPlaces.isEmpty
          ? const Text('No hay lugares bloqueados actualmente.')
          : Container(
              width: double.maxFinite,
              constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: blockedPlaces.length,
                itemBuilder: (context, index) {
                  final blockedPlace = blockedPlaces[index];
                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 4.0, right: 16.0),
                    leading: IconButton(
                      icon: const Icon(Icons.lock_open_outlined, color: Colors.green),
                      tooltip: 'Desbloquear este lugar',
                      onPressed: () {
                        blockedProvider.toggleBlockedStatus(blockedPlace.name, cityName: blockedPlace.cityName);
                      },
                    ),
                    title: Text(
                      blockedPlace.name,
                      style: TextStyle(color: theme.colorScheme.onSurface),
                    ),
                    subtitle: Text(
                      "Bloqueado el ${utils.formatDate(blockedPlace.blockingDate, formatType: 'SHORT')}",
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  );
                },
              ),
            ),
      actions: <Widget>[
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
          },
          child: const Text('Cerrar'),
        ),
      ],
    );
  }
}
