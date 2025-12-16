/// Un AppBar personalizado y reutilizable para las pantallas principales.
///
/// Este widget encapsula la estructura común del `AppBar` de la aplicación,
/// incluyendo un título, un botón para abrir el menú lateral (`Drawer`),
/// y un botón para mostrar/ocultar un panel de filtros.
///
/// También puede mostrar opcionalmente el nombre de una ciudad seleccionada y
/// alojar un widget adicional en su parte inferior (generalmente el panel de filtros).
library;
import 'package:flutter/material.dart';

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final String? cityNameToShow;
  final bool isFilterPanelVisible;
  final VoidCallback onFilterPressed;
  final VoidCallback onMenuPressed; // Parámetro añadido
  final PreferredSizeWidget? bottomWidget;

  const CustomAppBar({
    super.key,
    required this.title,
    this.cityNameToShow,
    required this.isFilterPanelVisible,
    required this.onFilterPressed,
    required this.onMenuPressed, // Parámetro añadido
    this.bottomWidget,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.menu),
        tooltip: 'Abrir menú',
        onPressed: onMenuPressed, // Conectamos la acción
      ),
      title: Text(title),
      actions: [
        if (cityNameToShow != null)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(right: 4.0),
              child: Text(
                cityNameToShow!,
                style: TextStyle(
                  color: Theme.of(context).appBarTheme.foregroundColor,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        IconButton(
          icon: Icon(isFilterPanelVisible
              ? Icons.filter_list_off
              : Icons.filter_list),
          tooltip: 'Filtros de ubicación',
          onPressed: onFilterPressed,
        ),
      ],
      bottom: bottomWidget,
    );
  }

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (bottomWidget?.preferredSize.height ?? 0.0));
}
