/// Un widget que muestra una fila de `ChoiceChip` para filtrar por día.
///
/// Este componente toma una lista de fechas en formato "YYYY-MM-DD", las formatea
/// para su visualización (ej. "Lun 23"), y permite al usuario seleccionar un día
/// para filtrar la lista de películas o sesiones.
library;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:arituki/theme/app_theme.dart';

class CineDayFilterChips extends StatelessWidget {
  final List<String> availableDays; // "YYYY-MM-DD"
  final String? selectedDay; // "YYYY-MM-DD" o null
  final ValueChanged<String?> onDaySelected;

  const CineDayFilterChips({
    super.key,
    required this.availableDays,
    required this.selectedDay,
    required this.onDaySelected,
  });

  String _formatDayForDisplay(String dayStringYYYYMMDD) {
    try {
      final date = DateTime.parse(dayStringYYYYMMDD);
      return DateFormat('EEE d', 'es_ES').format(date);
    } catch (e) {
      return dayStringYYYYMMDD;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (availableDays.isEmpty) {
      return const SizedBox.shrink();
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      // Se elimina el Padding horizontal interno para que se alinee con el contenedor padre.
      // El padding vertical se puede manejar desde el padre si es necesario.
      child: Row(
        children: availableDays.map((dayValue) {
          final bool isSelected = selectedDay == dayValue;
          final String labelText = _formatDayForDisplay(dayValue);

          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.kChipSpacing),
            child: ChoiceChip(
              label: Text(labelText),
              selected: isSelected,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onSelected: (bool currentChipSelectedState) {
                if (currentChipSelectedState) {
                  onDaySelected(dayValue);
                } else {
                  onDaySelected(null);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
