/// Un panel que contiene los filtros de ubicación para ser mostrado en un `AppBar`.
///
/// Este widget es el panel desplegable que aparece debajo de la `AppBar` principal.
/// Tiene dos modos, determinados por `ActiveFilterScreenType`:
/// 1.  `eventosEtc`: Muestra una jerarquía de menús desplegables para Comunidad,
///     Provincia y Ciudad.
/// 2.  `cine`: Muestra un único menú desplegable para seleccionar la ciudad del cine.
///
/// Utiliza los widgets `LocationCommunityDropbox`, `LocationProvinceDropbox`,
/// `LocationCitySingleSelectDropbox` y `_CineCityDropdown` para renderizar los
/// filtros correspondientes.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arituki/providers/cine_city_provider.dart';
import 'package:arituki/widgets/location_community_dropbox.dart';
import 'package:arituki/widgets/location_province_dropbox.dart';
import 'package:arituki/widgets/location_city_dropbox.dart';

enum ActiveFilterScreenType {
  eventosEtc, // Para Eventos, Festivales, Gastronomía
  cine
}

class LocationFiltersAppBarPanel extends StatelessWidget {
  final ActiveFilterScreenType screenType;

  const LocationFiltersAppBarPanel({super.key, required this.screenType});

  @override
  Widget build(BuildContext context) {
    Widget content;

    if (screenType == ActiveFilterScreenType.eventosEtc) {
      content = const Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          LocationCommunityDropbox(),
          LocationProvinceDropbox(),
          LocationCitySingleSelectDropbox(), // Usando el nuevo widget para ciudad
        ],
      );
    } else { // screenType == ActiveFilterScreenType.cine
      content = const _CineCityDropdown();
    }

    return Material(
      elevation: 2.0,
      color: Colors.blueGrey[50],
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0),
        child: content,
      ),
    );
  }
}

class _CineCityDropdown extends StatelessWidget {
  const _CineCityDropdown();

  @override
  Widget build(BuildContext context) {
    final cineCityProvider = context.watch<CineCitySelectionProvider>();

    if (cineCityProvider.isLoadingCineCities && !cineCityProvider.isReady) {
       return const Center(child: Padding(padding: EdgeInsets.all(8.0), child: CircularProgressIndicator()));
    }

    if (cineCityProvider.cineCityError != null) {
      return Padding(
        padding: const EdgeInsets.all(16.0),
        child: Text(cineCityProvider.cineCityError!),
      );
    }

    return Padding(
       padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: DropdownButtonFormField<String>(
        key: ValueKey(cineCityProvider.selectedCineCity), // Key para reconstrucción
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          filled: true,
          fillColor: Colors.white.withAlpha(230),
        ),
        initialValue: cineCityProvider.selectedCineCity, // Propiedad actualizada
        hint: const Text('Selecciona una ciudad', style: TextStyle(fontSize: 14, color: Colors.black54)),
        isExpanded: true,
        icon: cineCityProvider.isLoadingCineCities 
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
            : const Icon(Icons.arrow_drop_down, color: Colors.black),
        items: cineCityProvider.cineCities.map((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value),
          );
        }).toList(),
        onChanged: (String? newValue) {
          cineCityProvider.selectCineCity(newValue);
        },
      ),
    );
  }
}
