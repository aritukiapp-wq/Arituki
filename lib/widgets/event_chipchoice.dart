/// Un widget que muestra una combinación de filtros de fecha y lugar.
///
/// Este widget es responsable de renderizar dos filas de `FilterChip`:
/// una para seleccionar un rango de fechas predefinido (ej. "Hoy", "Esta semana")
/// y otra para filtrar por un lugar específico. El estado de los filtros
/// (qué está seleccionado) se obtiene de `EventFilterProvider`, mientras que la
/// lista de lugares disponibles se obtiene de `EventPresentationProvider`.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arituki/providers/event_presentation_provider.dart';
import 'package:arituki/providers/event_filter_provider.dart'; // Importar el provider correcto

class EventFilterChipsCombined extends StatelessWidget {
  const EventFilterChipsCombined({super.key});

  @override
  Widget build(BuildContext context) {
    // Usamos watch en ambos para que el widget se reconstruya si cualquiera de los dos cambia
    final presentationProvider = context.watch<EventPresentationProvider>();
    final filterProvider = context.watch<EventFilterProvider>(); // Obtener el provider de filtros

    final dateFilterOptions = [
      'Hoy',
      'Mañana',
      'Este finde',
      'Esta semana',
      'Próx. finde',
      'Próx. semana',
      'Próx. 30 días',
      'Tras 30 días',
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildChipRow(
          context,
          options: dateFilterOptions,
          // Leer el valor del provider correcto
          selectedValue: filterProvider.selectedDateFilterValue, 
          // La acción sigue en el presentationProvider, lo cual es correcto
          onSelected: (value) => presentationProvider.updateDateFilter(value),
        ),
        if (presentationProvider.uniqueFilteredPlaceNames.isNotEmpty) ...[
          const SizedBox(height: 8.0),
          _buildChipRow(
            context,
            options: presentationProvider.uniqueFilteredPlaceNames,
            // Leer el valor del provider correcto
            selectedValue: filterProvider.selectedPlaceFilterValue,
            // La acción sigue en el presentationProvider
            onSelected: (value) => presentationProvider.updatePlaceFilter(value),
          ),
        ]
      ],
    );
  }

  Widget _buildChipRow(
    BuildContext context,
    {
      required List<String> options,
      required String? selectedValue,
      required ValueChanged<String?> onSelected,
    }
  ) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Se elimina el padding para que el widget respete el alineamiento del padre.
      child: Row(
        children: options.map((option) {
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(option),
              selected: selectedValue == option,
              onSelected: (selected) {
                onSelected(selected ? option : null);
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
