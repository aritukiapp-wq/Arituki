/// Un widget que muestra un menú desplegable para seleccionar una comunidad autónoma.
///
/// Este es el primer nivel en el filtro de ubicación jerárquico. Muestra las
/// comunidades autónomas obtenidas de `LocationFilterProvider`. La selección de
/// una comunidad por parte del usuario actualiza el provider, lo que a su vez
/// dispara la carga de las provincias correspondientes.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arituki/providers/location_filter_provider.dart';

class LocationCommunityDropbox extends StatelessWidget {
  const LocationCommunityDropbox({super.key});

  @override
  Widget build(BuildContext context) {
    final locationProvider = context.watch<LocationFilterProvider>();

    if (locationProvider.isLoadingComunidades && !locationProvider.isReady) {
      return _buildStateIndicator(Icons.cloud_sync_outlined, "Cargando comunidades...");
    }

    if (locationProvider.comunidadError != null) {
      return _buildStateIndicator(Icons.error_outline, locationProvider.comunidadError!, isError: true);
    }

    if (locationProvider.comunidades.isEmpty && locationProvider.isReady) {
      return _buildStateIndicator(Icons.map_outlined, "No hay comunidades disponibles");
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
      child: DropdownButtonFormField<String>(
        key: ValueKey(locationProvider.selectedComunidad),
        decoration: InputDecoration(
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          filled: true,
          fillColor: Colors.white.withAlpha(230),
        ),
        initialValue: locationProvider.selectedComunidad,
        hint: const Text(
          'Selecciona una comunidad',
          style: TextStyle(fontSize: 14, color: Colors.black54, fontStyle: FontStyle.italic),
        ),
        isExpanded: true,
        isDense: true,
        icon: Row(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (locationProvider.isLoadingComunidades)
              const SizedBox(width: 24, height: 24, child: Padding(padding: EdgeInsets.all(4.0), child: CircularProgressIndicator(strokeWidth: 2)))
            else
              const Icon(Icons.arrow_drop_down, color: Colors.black),
            if (locationProvider.selectedComunidad != null)
              GestureDetector(
                onTap: () {
                  context.read<LocationFilterProvider>().selectComunidad(null);
                },
                child: const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.clear, size: 20, color: Colors.black54),
                ),
              ),
          ],
        ),
        style: TextStyle(
          color: Colors.black,
          fontSize: 15,
          fontWeight: locationProvider.selectedComunidad != null ? FontWeight.bold : FontWeight.normal,
        ),
        dropdownColor: Colors.white,
        items: locationProvider.comunidades.map<DropdownMenuItem<String>>((String value) {
          return DropdownMenuItem<String>(
            value: value,
            child: Text(value, overflow: TextOverflow.ellipsis),
          );
        }).toList(),
        onChanged: (String? newValue) {
          context.read<LocationFilterProvider>().selectComunidad(newValue);
        },
      ),
    );
  }

  Widget _buildStateIndicator(IconData icon, String message, {bool isError = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14.0, horizontal: 16.0), 
      child: Row(
        children: [
          Icon(icon, size: 20, color: isError ? Colors.red : Colors.grey[700]),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: TextStyle(color: isError ? Colors.red : Colors.grey[700]))),
        ],
      ),
    );
  }
}
