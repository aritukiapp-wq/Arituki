/// Un widget que muestra una fila de `ChoiceChip` para filtrar por cine.
///
/// Este componente toma una lista de nombres de cines disponibles y muestra
/// un chip por cada uno. Permite al usuario seleccionar un único cine para
/// filtrar la lista de sesiones. Cuando se selecciona un cine, se registra un
/// evento de analítica.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arituki/services/analytics_service.dart';
import 'package:arituki/theme/app_theme.dart';

class CineCinemaFilterChips extends StatelessWidget {
  final List<String> availableCinemas;
  final String? selectedCinema;
  final ValueChanged<String?> onCinemaSelected;

  const CineCinemaFilterChips({
    super.key,
    required this.availableCinemas,
    required this.selectedCinema,
    required this.onCinemaSelected,
  });

  @override
  Widget build(BuildContext context) {
    if (availableCinemas.isEmpty) {
      return const SizedBox.shrink();
    }

    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: availableCinemas.map((cinemaName) {
          final bool isSelected = selectedCinema == cinemaName;

          return Padding(
            padding: const EdgeInsets.only(right: AppTheme.kChipSpacing),
            child: ChoiceChip(
              label: Text(cinemaName),
              selected: isSelected,
              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              onSelected: (bool currentChipSelectedState) {
                String? newSelectedCinemaForCallback;
                String? cinemaForAnalytics;

                if (currentChipSelectedState) {
                  newSelectedCinemaForCallback = cinemaName;
                  cinemaForAnalytics = cinemaName;
                } else {
                  newSelectedCinemaForCallback = null;
                  cinemaForAnalytics = null;
                }

                onCinemaSelected(newSelectedCinemaForCallback);

                analyticsService.logFilterChange(
                  filterType: 'cine_cinema',
                  value: cinemaForAnalytics ?? 'ninguno',
                );
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
