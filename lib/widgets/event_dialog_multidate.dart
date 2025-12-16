/// Un diálogo que muestra múltiples fechas para un mismo evento.
///
/// Este widget se utiliza cuando un evento tiene varias ocurrencias. Muestra
/// una lista de todas las fechas y horas disponibles para ese evento, destacando
/// la que está actualmente seleccionada. Permite al usuario elegir una ocurrencia
/// diferente de la lista.
library;
import 'package:flutter/material.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/utils/utils.dart' as utils;

class EventDialogMultidate extends StatelessWidget {
  const EventDialogMultidate({
    super.key,
    required this.eventTitle,
    required this.eventDates,
    this.selectedEventId,
  });

  final String eventTitle;
  final List<EventoSupabase> eventDates;
  final String? selectedEventId;

  @override
  Widget build(BuildContext context) {
    final sortedDates = List<EventoSupabase>.from(eventDates);
    sortedDates.sort((a, b) {
      final dateA = a.dia;
      final dateB = b.dia;

      if (dateA == null && dateB == null) return 0;
      if (dateA == null) return 1;
      if (dateB == null) return -1;

      final dateComparison = dateA.compareTo(dateB);

      if (dateComparison == 0) {
        return (a.hora ?? "").compareTo(b.hora ?? "");
      }
      return dateComparison;
    });

    return AlertDialog(
      title: Text('Fechas para "$eventTitle"'),
      content: Container(
        width: double.maxFinite,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: sortedDates.isEmpty
            ? const Center(child: Text('No se encontraron fechas adicionales.'))
            : ListView.builder(
                shrinkWrap: true,
                itemCount: sortedDates.length,
                itemBuilder: (context, index) {
                  final eventEntry = sortedDates[index];
                  final isSelected = eventEntry.id == selectedEventId;

                  String formattedDate = utils.formatDate(eventEntry.dia, formatType: 'SHORT');
                  String formattedTime = utils.formatTime(eventEntry.hora);

                  return ListTile(
                    onTap: () {
                      Navigator.of(context).pop(eventEntry);
                    },
                    leading: Icon(
                      isSelected ? Icons.arrow_forward_ios : Icons.calendar_today_outlined,
                      size: 18,
                      color: isSelected ? Theme.of(context).primaryColor : Colors.grey[700],
                    ),
                    title: Text(
                      '$formattedDate - $formattedTime',
                      style: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Theme.of(context).primaryColor : Theme.of(context).textTheme.bodyLarge?.color,
                      ),
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
