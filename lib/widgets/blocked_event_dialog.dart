/// Un diálogo que muestra la lista de eventos bloqueados por el usuario.
///
/// Este widget consume `BlockedEventProvider` para obtener la lista de eventos
/// bloqueados y los muestra en una lista. Cada elemento de la lista tiene un
/// botón que permite al usuario desbloquear el evento correspondiente, eliminándolo
/// de la lista y persistiendo el cambio a través del provider.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import 'package:arituki/providers/blocked_event_provider.dart';
import 'package:arituki/providers/favorite_event_provider.dart';

class BlockedEventsDialog extends StatelessWidget {
  const BlockedEventsDialog({super.key});

  @override
  Widget build(BuildContext context) {
    final blockedEventProvider = context.watch<BlockedEventProvider>();
    final favoriteEventProvider = context.read<FavoriteEventProvider>();
    final List<BlockedEvent> blockedEvents = blockedEventProvider.blockedEvents;

    return AlertDialog(
      title: const Text('Eventos Bloqueados'),
      content: blockedEvents.isEmpty
          ? const Text('No hay eventos bloqueados actualmente.')
          : SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.5,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: blockedEvents.length,
                itemBuilder: (context, index) {
                  final blockedEvent = blockedEvents[index];
                  final formattedDate = DateFormat('dd/MM/yyyy').format(blockedEvent.blockingDate);

                  return ListTile(
                    contentPadding: const EdgeInsets.only(left: 4.0, right: 16.0),
                    leading: IconButton(
                      icon: const Icon(Icons.lock_open_outlined, color: Colors.green),
                      tooltip: 'Desbloquear este evento',
                      onPressed: () {
                        blockedEventProvider.toggleBlockedEvent(
                          eventId: blockedEvent.id,
                          eventName: blockedEvent.eventName,
                          eventDate: blockedEvent.blockingDate,
                          cityName: blockedEvent.cityName,
                          placeName: blockedEvent.placeName,
                          favoriteEventProvider: favoriteEventProvider,
                        );
                        ScaffoldMessenger.of(context).removeCurrentSnackBar();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Evento "${blockedEvent.eventName}" desbloqueado.')),
                        );
                      },
                    ),
                    title: Text(blockedEvent.eventName),
                    subtitle: Text(formattedDate),
                  );
                },
              ),
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
