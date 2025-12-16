/// Un widget que muestra una lista de actos o eventos de un programa.
///
/// Este widget toma una lista de `EventoSupabase` y los muestra en una `ListView`.
/// Cada elemento de la lista es un `ListTile` simple que muestra el título y la fecha
/// del acto. Es interactivo y ejecuta una acción `onTap` cuando se pulsa sobre un
/// elemento.
library;
import 'package:flutter/material.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/theme/app_theme.dart';
import 'package:arituki/utils/utils.dart' as utils;

class ProgramaProgramList extends StatelessWidget {
  final List<EventoSupabase> items;
  final Function(EventoSupabase) onTap;

  const ProgramaProgramList(
      {super.key, required this.items, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: AppTheme.kListViewPadding,
      itemCount: items.length,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: ListTile(
            title: Text(item.titulo ?? 'Actuación sin nombre'),
            subtitle: Text(utils.formatEventDates(item.diaIni, item.diaFin, item.hora)),
            onTap: () => onTap(item),
          ),
        );
      },
    );
  }
}
