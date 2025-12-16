/// Pantalla principal de la sección de Cine.
///
/// Esta pantalla muestra la cartelera de cine para la ciudad seleccionada.
/// Permite al usuario:
/// - Ver una cuadrícula de las películas disponibles.
/// - Filtrar las películas por día de la semana.
/// - Buscar películas por título.
/// - Cambiar la ciudad para ver su cartelera a través del panel de filtros en la AppBar.
/// - Navegar a la pantalla de detalle de una película (`CineDetailScreen`) al seleccionarla.
///
/// Utiliza `CineProvider` para obtener y gestionar los datos de las películas y
/// `CineCitySelectionProvider` para la selección de la ciudad.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:arituki/models/cine_supabase.dart';
import 'package:arituki/providers/cine_provider.dart';
import 'package:arituki/providers/cine_city_provider.dart';
import 'package:arituki/widgets/cine_gridview.dart';
import 'package:arituki/widgets/cine_chipchoice_date.dart';
import 'package:arituki/screens/cine_detail.dart';
import 'package:arituki/widgets/location_filters_app_bar_panel.dart';
import 'package:arituki/widgets/empty_state_view.dart';
import 'package:arituki/widgets/app_bar.dart'; // Import the new widget
import 'package:arituki/theme/app_theme.dart';

class CineScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const CineScreen({super.key, required this.scaffoldKey});

  @override
  State<CineScreen> createState() => _CineScreenState();
}

class _CineScreenState extends State<CineScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isAppBarFiltersPanelVisible = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      context.read<CineProvider>().setSearchTerm(_searchController.text);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _handlePeliculaTap(BuildContext context, PeliculaSupabase peliculaSeleccionada) {
    final cineProvider = context.read<CineProvider>();
    final List<PeliculaSupabase> todasLasPeliculasDelServicio = cineProvider.allMoviesForCity;

    if (peliculaSeleccionada.titulo == null || peliculaSeleccionada.titulo!.isEmpty) {
      return;
    }

    final List<PeliculaSupabase> sesionesParaEstaPelicula = todasLasPeliculasDelServicio
        .where((p) => p.titulo == peliculaSeleccionada.titulo)
        .toList();

    sesionesParaEstaPelicula.sort((a, b) {
      int compareDia = (a.dia ?? "").compareTo(b.dia ?? "");
      if (compareDia != 0) return compareDia;
      int compareHora = (a.hora ?? "").compareTo(b.hora ?? "");
      if (compareHora != 0) return compareHora;
      return (a.cine ?? "").toLowerCase().compareTo((b.cine ?? "").toLowerCase());
    });

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CineDetailScreen(
          peliculaPrincipal: peliculaSeleccionada,
          sesionesPelicula: sesionesParaEstaPelicula,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cineCitySelection = context.watch<CineCitySelectionProvider>();
    final selectedCineCity = cineCitySelection.selectedCineCity;
    final cineProvider = context.watch<CineProvider>();

    String? cityNameToShow;
    const nonDisplayableCityValues = {
      CineCitySelectionProvider.defaultCityValueLoading,
      CineCitySelectionProvider.noCitiesAvailable,
      CineCitySelectionProvider.initializingMessage,
      CineCitySelectionProvider.selectCityPrompt,
    };

    if (!nonDisplayableCityValues.contains(selectedCineCity)) {
      cityNameToShow = selectedCineCity;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Cartelera de Cine',
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
                preferredSize: const Size.fromHeight(80.0),
                child: LocationFiltersAppBarPanel(
                  screenType: ActiveFilterScreenType.cine,
                ),
              )
            : null,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar película por título...',
                prefixIcon: const Icon(Icons.search, size: AppTheme.kSearchIconSize),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: AppTheme.kSearchIconSize),
                        onPressed: () => _searchController.clear(),
                      )
                    : null,
              ),
              style: const TextStyle(fontSize: AppTheme.kSearchInputFontSize),
            ),
          ),
          const SizedBox(height: AppTheme.kVerticalPadding),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: CineDayFilterChips(
              availableDays: cineProvider.availableMovieDays,
              selectedDay: cineProvider.selectedDayFilter,
              onDaySelected: (day) => context.read<CineProvider>().setDayFilter(day),
            ),
          ),
          const SizedBox(height: AppTheme.kVerticalPadding),
          Expanded(
            child: _buildBodyContent(context, cineProvider, cineCitySelection),
          ),
        ],
      ),
    );
  }

  Widget _buildBodyContent(
      BuildContext context, CineProvider cineProvider, CineCitySelectionProvider cityProvider) {
    final selectedCineCity = cityProvider.selectedCineCity;
    if (selectedCineCity == CineCitySelectionProvider.initializingMessage ||
        selectedCineCity == CineCitySelectionProvider.defaultCityValueLoading ||
        selectedCineCity == CineCitySelectionProvider.selectCityPrompt) {
      return Center(child: Text(selectedCineCity, textAlign: TextAlign.center));
    }

    if (selectedCineCity == CineCitySelectionProvider.noCitiesAvailable) {
      return const EmptyStateView(
        icon: Icons.location_city,
        title: 'No hay ciudades disponibles',
        message: 'No hay ciudades de cine disponibles para mostrar cartelera.',
      );
    }

    if (cineProvider.isLoading) {
      return const Center(
          child: CircularProgressIndicator(key: Key("cine_screen_loading_movies_indicator")));
    }

    if (cineProvider.error != null) {
      return EmptyStateView(
        icon: Icons.error_outline,
        title: 'Error al cargar las películas',
        message: cineProvider.error!,
      );
    }

    final peliculasUnicasParaGrid = cineProvider.filteredMovies;

    if (peliculasUnicasParaGrid.isEmpty) {
      return const EmptyStateView(
        icon: Icons.theaters,
        title: 'No hay películas que mostrar',
        message: 'Prueba a cambiar los filtros o la ciudad seleccionada.',
      );
    }

    return CineGridView(
      peliculas: peliculasUnicasParaGrid,
      onPeliculaTap: (peliculaSeleccionada) => _handlePeliculaTap(context, peliculaSeleccionada),
    );
  }
}
