/// Un widget que muestra un menú desplegable para seleccionar una ciudad.
///
/// Este `DropdownButtonFormField` se utiliza en el panel de filtros de ubicación.
/// Se rellena con la lista de ciudades disponibles de `LocationFilterProvider`
/// y permite al usuario seleccionar una. La selección se actualiza en el provider
/// y se registra un evento de analítica.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arituki/providers/location_filter_provider.dart';
import 'package:arituki/services/analytics_service.dart';

class LocationCitySingleSelectDropbox extends StatelessWidget {
  const LocationCitySingleSelectDropbox({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationFilterProvider>();
    final analyticsService = context.read<AnalyticsService>();

    bool isDisabled = !locationProvider.isReady || 
                      locationProvider.selectedProvince == null ||
                      locationProvider.isLoadingProvinces;

    String hintText = 'Selecciona una ciudad';
    if (locationProvider.selectedProvince == null) {
      hintText = 'Selecciona una provincia';
    } else if (locationProvider.isLoadingCities) {
      hintText = 'Cargando ciudades...';
    } else if (locationProvider.cityError != null) {
      hintText = locationProvider.cityError!;
    } else if (locationProvider.availableCitiesForProvince.isEmpty) {
      hintText = 'No hay ciudades';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: DropdownButtonFormField<String>(
        key: ValueKey(locationProvider.appBarSelectedCity), // Añadimos una key
        decoration: InputDecoration(
          labelText: 'Ciudad',
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          filled: true,
          fillColor: Colors.white.withAlpha(230),
          enabled: !isDisabled,
        ),
        initialValue: locationProvider.appBarSelectedCity,
        hint: Text(
          hintText,
          style: TextStyle(
            fontSize: 14,
            color: isDisabled || locationProvider.cityError != null ? Colors.grey[700] : Colors.black54,
            fontStyle: FontStyle.italic,
          ),
        ),
        isExpanded: true,
        isDense: true,
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (locationProvider.isLoadingCities)
              const SizedBox(width: 24, height: 24, child: Padding(padding: EdgeInsets.all(4.0), child: CircularProgressIndicator(strokeWidth: 2)))
            else
              const Icon(Icons.arrow_drop_down, color: Colors.black),
            if (locationProvider.appBarSelectedCity != null)
              GestureDetector(
                onTap: () {
                  context.read<LocationFilterProvider>().selectAppBarCity(null);
                  analyticsService.logLocationFilterChange(
                    filterType: 'ciudad',
                    comunidad: locationProvider.selectedComunidad,
                    province: locationProvider.selectedProvince,
                    cities: [],
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.clear, size: 20, color: Colors.black54),
                ),
              ),
          ],
        ),
        style: TextStyle(
          color: isDisabled ? Colors.grey[700] : Colors.black,
          fontSize: 15,
          fontWeight: locationProvider.appBarSelectedCity != null ? FontWeight.bold : FontWeight.normal,
        ),
        dropdownColor: Colors.white,
        items: locationProvider.availableCitiesForProvince.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: isDisabled
            ? null
            : (String? newValue) {
                context.read<LocationFilterProvider>().selectAppBarCity(newValue);
                analyticsService.logLocationFilterChange(
                  filterType: 'ciudad',
                  comunidad: locationProvider.selectedComunidad,
                  province: locationProvider.selectedProvince,
                  cities: newValue != null ? [newValue] : [],
                );
              },
      ),
    );
  }
}
