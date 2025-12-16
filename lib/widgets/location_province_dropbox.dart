/// Un widget que muestra un menú desplegable para seleccionar una provincia.
///
/// Este `DropdownButtonFormField` se utiliza en el panel de filtros de ubicación.
/// Depende de la selección de una comunidad para activarse y se rellena con la
/// lista de provincias de `LocationFilterProvider`. La selección del usuario
/// actualiza el provider y dispara la carga de ciudades, además de registrar
/// un evento de analítica.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arituki/providers/location_filter_provider.dart';
import 'package:arituki/services/analytics_service.dart';

class LocationProvinceDropbox extends StatelessWidget {
  const LocationProvinceDropbox({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationFilterProvider>();
    final analyticsService = context.read<AnalyticsService>();

    bool isDisabled = !locationProvider.isReady || 
                      locationProvider.selectedComunidad == null ||
                      locationProvider.isLoadingComunidades;

    String hintText = 'Selecciona una provincia';
    if (locationProvider.selectedComunidad == null) {
      hintText = 'Selecciona una comunidad';
    } else if (locationProvider.isLoadingProvinces) {
      hintText = 'Cargando provincias...';
    } else if (locationProvider.provinceError != null) {
      hintText = locationProvider.provinceError!;
    } else if (locationProvider.provinces.isEmpty) {
      hintText = 'No hay provincias';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: DropdownButtonFormField<String>(
        key: ValueKey(locationProvider.selectedProvince),
        decoration: InputDecoration(
          labelText: 'Provincia',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          filled: true,
          fillColor: Colors.white.withAlpha(230),
          enabled: !isDisabled,
        ),
        initialValue: locationProvider.selectedProvince,
        hint: Text(
          hintText,
          style: TextStyle(
            fontSize: 14,
            color: isDisabled || locationProvider.provinceError != null ? Colors.grey[700] : Colors.black54,
            fontStyle: FontStyle.italic,
          ),
        ),
        isExpanded: true,
        isDense: true,
        icon: Row(
          mainAxisSize: MainAxisSize.min, // Para que la fila no ocupe más espacio del necesario
          children: <Widget>[
            if (locationProvider.isLoadingProvinces)
              const SizedBox(width: 24, height: 24, child: Padding(padding: EdgeInsets.all(4.0), child: CircularProgressIndicator(strokeWidth: 2)))
            else
              const Icon(Icons.arrow_drop_down, color: Colors.black),
            if (locationProvider.selectedProvince != null)
              GestureDetector(
                onTap: () {
                  context.read<LocationFilterProvider>().selectProvince(null);
                  analyticsService.logLocationFilterChange(
                    filterType: 'provincia',
                    comunidad: locationProvider.selectedComunidad,
                    province: null,
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 8.0), // Añade espacio entre la flecha y la X
                  child: Icon(Icons.clear, size: 20, color: Colors.black54),
                ),
              ),
          ],
        ),
        style: TextStyle(
          color: isDisabled ? Colors.grey[700] : Colors.black,
          fontSize: 15,
          fontWeight: locationProvider.selectedProvince != null ? FontWeight.bold : FontWeight.normal,
        ),
        dropdownColor: Colors.white,
        items: locationProvider.provinces.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: isDisabled
            ? null
            : (String? newValue) {
                context.read<LocationFilterProvider>().selectProvince(newValue);
                analyticsService.logLocationFilterChange(
                  filterType: 'provincia',
                  comunidad: locationProvider.selectedComunidad,
                  province: newValue,
                );
              },
      ),
    );
  }
}
