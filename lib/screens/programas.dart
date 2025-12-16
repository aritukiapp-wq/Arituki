/// Pantalla principal de la sección de Programas.
///
/// Muestra una lista de los programas de fiestas y eventos culturales principales,
/// filtrados por la ubicación seleccionada. Permite al usuario:
/// - Ver una lista de programas (ej. "Fiestas del Pilar").
/// - Cambiar la ubicación para filtrar los resultados.
/// - Navegar a la pantalla de detalle de un programa (`ProgramaProgramaScreen`)
///   al seleccionarlo, donde se verán todos los actos de ese programa.
///
/// Utiliza `ProgramasProvider` para obtener los datos y `LocationFilterProvider`
/// para gestionar el filtrado por ubicación.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/providers/programas_provider.dart';
import 'package:arituki/providers/location_filter_provider.dart';
import 'package:arituki/screens/programas_programa.dart';
import 'package:arituki/widgets/programas_card.dart';
import 'package:arituki/widgets/location_filters_app_bar_panel.dart';
import 'package:arituki/widgets/app_bar.dart';
import 'package:arituki/widgets/empty_state_view.dart';

class ProgramasScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const ProgramasScreen({super.key, required this.scaffoldKey});

  @override
  State<ProgramasScreen> createState() => _ProgramasScreenState();
}

class _ProgramasScreenState extends State<ProgramasScreen> {
  bool _isAppBarFiltersPanelVisible = false;

  @override
  Widget build(BuildContext context) {
    final locationFilterProvider = context.watch<LocationFilterProvider>();
    final programaProvider = context.watch<ProgramasProvider>();

    String? cityNameToShow;
    final selectedCities = locationFilterProvider.selectedEventCities;

    if (selectedCities.length == 1) {
      cityNameToShow = selectedCities.first;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Programas',
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
      body: _buildBody(context, programaProvider, locationFilterProvider),
    );
  }

  Widget _buildBody(
      BuildContext context,
      ProgramasProvider programaProvider,
      LocationFilterProvider locationFilterProvider) {
    if (programaProvider.isLoading && programaProvider.programas.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (programaProvider.errorMessage != null) {
      return EmptyStateView(
        icon: Icons.error_outline,
        title: 'Error al cargar los programas',
        message: programaProvider.errorMessage ?? 'Ocurrió un error desconocido.',
        actionButton: ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          onPressed: () => context.read<ProgramasProvider>().fetchProgramas(
                comunidad: locationFilterProvider.selectedComunidad,
                provincia: locationFilterProvider.selectedProvince,
                ciudad: locationFilterProvider.appBarSelectedCity,
              ),
        ),
      );
    }

    if (programaProvider.programas.isEmpty && !programaProvider.isLoading) {
      return EmptyStateView(
        icon: Icons.festival_outlined,
        title: 'No hay programas disponibles',
        message:
            'No se encontraron programas para la ubicación seleccionada. Prueba a cambiar el filtro.',
        actionButton: ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Actualizar'),
          onPressed: () => context.read<ProgramasProvider>().fetchProgramas(
                comunidad: locationFilterProvider.selectedComunidad,
                provincia: locationFilterProvider.selectedProvince,
                ciudad: locationFilterProvider.appBarSelectedCity,
              ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => context.read<ProgramasProvider>().fetchProgramas(
            comunidad: locationFilterProvider.selectedComunidad,
            provincia: locationFilterProvider.selectedProvince,
            ciudad: locationFilterProvider.appBarSelectedCity,
          ),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
        itemCount: programaProvider.programas.length,
        itemBuilder: (context, index) {
          final EventoSupabase programa = programaProvider.programas[index];
          return ProgramaCard(
            programa: programa,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => ProgramaProgramaScreen(
                    programa: programa,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
