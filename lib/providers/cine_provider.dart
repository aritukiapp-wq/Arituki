// ignore: dangling_library_doc_comments
/// Gestiona el estado y la lógica de la sección de cines.
///
/// Este provider se encarga de:
/// - Obtener las películas de la ciudad seleccionada a través de `CineService`.
/// - Filtrar las películas por término de búsqueda y día.
/// - Mantener y exponer el estado de carga, errores y la lista de películas filtradas.
/// - Actualizar su estado en respuesta a cambios en `CineCitySelectionProvider`.
library;
import 'package:flutter/foundation.dart';
import 'package:arituki/models/cine_supabase.dart';
import 'package:arituki/services/cine_service.dart';
import 'package:arituki/providers/cine_city_provider.dart';

class CineProvider with ChangeNotifier {
  final CineService _cineService;

  // Internal state
  bool _isLoading = false;
  String? _error;
  List<PeliculaSupabase> _allMoviesForCity = [];
  String _searchTerm = '';
  String? _selectedDayFilter;
  List<String> _availableMovieDays = [];
  String? _currentCity;

  CineProvider(this._cineService);

  // Public getters for the UI
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? get selectedDayFilter => _selectedDayFilter;
  List<String> get availableMovieDays => _availableMovieDays;
  List<PeliculaSupabase> get allMoviesForCity => _allMoviesForCity;

  /// Returns a list of movies filtered by the current search term and day filter.
  /// It also ensures that each movie title appears only once.
  List<PeliculaSupabase> get filteredMovies {
    List<PeliculaSupabase> movies = _allMoviesForCity;

    if (_selectedDayFilter != null) {
      movies = movies.where((p) => p.dia == _selectedDayFilter).toList();
    }

    if (_searchTerm.isNotEmpty) {
      movies = movies
          .where((p) =>
              p.titulo?.toLowerCase().contains(_searchTerm.toLowerCase()) ?? false)
          .toList();
    }

    return _getUniquePeliculasByTituloSync(movies);
  }

  /// Called by the ProxyProvider to update dependencies and trigger data fetching.
  void updateDependencies(CineCitySelectionProvider cineCityProvider) {
    final newCity = cineCityProvider.selectedCineCity;
    // Fetch only if the city has changed and the provider is ready.
    if (cineCityProvider.isReady && newCity != _currentCity) {
      _currentCity = newCity;
      fetchPeliculasForCity(newCity);
    }
  }

  /// Fetches movies for the selected city from the repository.
  Future<void> fetchPeliculasForCity(String? city) async {
    // Do not fetch if the city is null, empty, or a placeholder value.
    if (city == null ||
        city.isEmpty ||
        city == CineCitySelectionProvider.defaultCityValueLoading ||
        city == CineCitySelectionProvider.noCitiesAvailable ||
        city == CineCitySelectionProvider.initializingMessage ||
        city == CineCitySelectionProvider.selectCityPrompt) {
      _allMoviesForCity = [];
      _availableMovieDays = [];
      _selectedDayFilter = null;
      notifyListeners();
      return;
    }

    await _executeLoadingTask(() async {
      final movies = await _cineService.getPeliculas(ciudad: city);
      movies.sort((a, b) => 
          (a.titulo ?? '').toLowerCase().compareTo((b.titulo ?? '').toLowerCase()));
      _allMoviesForCity = movies;

      // After fetching, update the list of available days for filtering.
      _updateAvailableDays();
    }, errorMessage: "Error al cargar las películas.");
  }

  /// Updates the list of unique, sorted days based on the current movies.
  void _updateAvailableDays() {
    final newDays = _allMoviesForCity
        .map((p) => p.dia)
        .whereType<String>()
        .where((d) => d.isNotEmpty)
        .toSet()
        .toList();
    newDays.sort();
    _availableMovieDays = newDays;

    // If the selected day filter is no longer valid, reset it.
    if (_selectedDayFilter != null && !newDays.contains(_selectedDayFilter)) {
      _selectedDayFilter = null;
    }
  }

  /// A generic wrapper for executing tasks that involve loading and error states.
  Future<void> _executeLoadingTask(
      Future<void> Function() task,
      {required String errorMessage}) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await task();
    } catch (e) {
      _error = errorMessage;
      _allMoviesForCity = [];
      _availableMovieDays = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Methods to update state from the UI

  /// Sets the search term for filtering movies.
  void setSearchTerm(String term) {
    if (_searchTerm != term) {
      _searchTerm = term;
      notifyListeners();
    }
  }

  /// Sets the selected day for filtering movies.
  void setDayFilter(String? day) {
    if (_selectedDayFilter != day) {
      _selectedDayFilter = day;
      notifyListeners();
    }
  }

  /// Returns a list of movies with unique titles.
  List<PeliculaSupabase> _getUniquePeliculasByTituloSync(
      List<PeliculaSupabase> peliculas) {
    final Set<String> titulosVistos = {};
    final List<PeliculaSupabase> peliculasUnicas = [];
    for (var pelicula in peliculas) {
      if (pelicula.titulo != null && pelicula.titulo!.isNotEmpty) {
        if (titulosVistos.add(pelicula.titulo!)) {
          peliculasUnicas.add(pelicula);
        }
      }
    }
    return peliculasUnicas;
  }
}
