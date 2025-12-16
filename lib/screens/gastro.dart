/// Pantalla principal de la sección de Gastronomía.
///
/// Esta pantalla muestra una lista de las jornadas y eventos gastronómicos
/// principales, filtrados por la ubicación seleccionada en el panel de filtros
/// de la AppBar. Permite al usuario:
/// - Ver una lista de las jornadas gastronómicas.
/// - Cambiar la ubicación para filtrar los resultados.
/// - Navegar a la pantalla de detalle de una jornada (`GastronomiaProgramaScreen`)
///   al seleccionarla.
///
/// Utiliza `GastronomiaProvider` para obtener los datos y `LocationFilterProvider`
/// para gestionar el filtrado por ubicación.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/providers/gastro_provider.dart';
import 'package:arituki/providers/location_filter_provider.dart';
import 'package:arituki/screens/gastro_programa.dart';
import 'package:arituki/widgets/gastro_card.dart';
import 'package:arituki/widgets/location_filters_app_bar_panel.dart';
import 'package:arituki/widgets/app_bar.dart';
import 'package:arituki/widgets/empty_state_view.dart';

class GastronomiaScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const GastronomiaScreen({super.key, required this.scaffoldKey});

  @override
  State<GastronomiaScreen> createState() => _GastronomiaScreenState();
}

class _GastronomiaScreenState extends State<GastronomiaScreen> {
  bool _isAppBarFiltersPanelVisible = false;

  @override
  Widget build(BuildContext context) {
    final locationFilterProvider = context.watch<LocationFilterProvider>();
    final gastronomiaProvider = context.watch<GastronomiaProvider>();

    String? cityNameToShow;
    final selectedCities = locationFilterProvider.selectedEventCities;

    if (selectedCities.length == 1) {
      cityNameToShow = selectedCities.first;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Gastronomía',
        cityNameToShow: cityNameToShow,
        isFilterPanelVisible: _isAppBarFiltersPanelVisible,
        onFilterPressed: () {
          setState(() {
            _isAppBarFiltersPanelVisible = !_isAppBarFiltersPanelVisible;
          });
        },
        onMenuPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
        bottomWidget: _isAppBarFiltersPanelVisible
            ? PreferredSize(
                preferredSize: const Size.fromHeight(200.0),
                child: LocationFiltersAppBarPanel(
                  screenType: ActiveFilterScreenType.eventosEtc,
                ),
              )
            : null,
      ),
      body: _buildBody(context, gastronomiaProvider, locationFilterProvider),
    );
  }

  Widget _buildBody(
      BuildContext context,
      GastronomiaProvider gastronomiaProvider,
      LocationFilterProvider locationFilterProvider) {
    if (gastronomiaProvider.isLoading && gastronomiaProvider.jornadas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (gastronomiaProvider.errorMessage != null) {
      return EmptyStateView(
        icon: Icons.restaurant_menu_outlined,
        title: 'Error al cargar las jornadas',
        message: gastronomiaProvider.errorMessage ?? 'Ocurrió un error desconocido.',
        actionButton: ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          onPressed: () => context.read<GastronomiaProvider>().fetchJornadas(
                comunidad: locationFilterProvider.selectedComunidad,
                provincia: locationFilterProvider.selectedProvince,
                ciudad: locationFilterProvider.appBarSelectedCity,
              ),
        ),
      );
    }

    if (gastronomiaProvider.jornadas.isEmpty && !gastronomiaProvider.isLoading) {
      return EmptyStateView(
        icon: Icons.local_dining_outlined,
        title: 'No hay jornadas disponibles',
        message:
            'No se encontraron jornadas para la ubicación seleccionada. Prueba a cambiar el filtro.',
        actionButton: ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
          onPressed: () => context.read<GastronomiaProvider>().fetchJornadas(
                comunidad: locationFilterProvider.selectedComunidad,
                provincia: locationFilterProvider.selectedProvince,
                ciudad: locationFilterProvider.appBarSelectedCity,
              ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<GastronomiaProvider>().fetchJornadas(
            comunidad: locationFilterProvider.selectedComunidad,
            provincia: locationFilterProvider.selectedProvince,
            ciudad: locationFilterProvider.appBarSelectedCity,
          ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        itemCount: gastronomiaProvider.jornadas.length,
        itemBuilder: (context, index) {
          final EventoSupabase jornada = gastronomiaProvider.jornadas[index];
          return GastronomiaCard(
            jornada: jornada,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => GastronomiaProgramaScreen(jornada: jornada),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
