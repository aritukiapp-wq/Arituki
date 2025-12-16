/// Gestiona el estado de la selección de ciudad para la sección de cines.
///
/// Este provider se encarga de:
/// - Obtener la lista de ciudades disponibles con cines desde `CineService`.
/// - Manejar la selección de ciudad por parte del usuario.
/// - Persistir la ciudad seleccionada en `SharedPreferences` para futuras sesiones.
/// - Exponer el estado de carga, errores y la ciudad seleccionada a la UI.
library;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arituki/services/cine_service.dart';
import 'package:arituki/services/analytics_service.dart';

class CineCitySelectionProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final CineService _cineService;
  final AnalyticsService _analyticsService;

  // --- Constants ---
  static const String _cineCityPrefKey = 'selected_cine_city';
  static const String defaultCity = 'Zaragoza';

  // UI State Messages
  static const String initializingMessage = 'Cargando ciudades...';
  static const String defaultCityValueLoading = 'Cargando...';
  static const String noCitiesAvailable = 'No hay cines disponibles';
  static const String selectCityPrompt = 'Elige una ciudad';

  // --- Internal State ---
  List<String> _cities = [initializingMessage];
  String _selectedCity = initializingMessage;
  bool _isLoading = false;
  String? _error;
  bool _isReady = false;

  CineCitySelectionProvider({
    required SharedPreferences prefs,
    required CineService cineService,
    required AnalyticsService analyticsService,
  })  : _prefs = prefs,
        _cineService = cineService,
        _analyticsService = analyticsService {
    _initializeData();
  }

  // --- Public Getters ---
  List<String> get cineCities => _cities;
  String get selectedCineCity => _selectedCity;
  bool get isLoadingCineCities => _isLoading;
  String? get cineCityError => _error;
  bool get isReady => _isReady;

  /// Initializes the provider by loading cities and the user's saved preference.
  Future<void> _initializeData() async {
    final savedCity = _prefs.getString(_cineCityPrefKey);
    await loadCineCities(savedCityOverride: savedCity);
  }

  /// Fetches the list of cities with cinemas from the service.
  Future<void> loadCineCities({String? savedCityOverride, bool isRefresh = false}) async {
    if (_isLoading && !isRefresh) return;

    await _executeTask(() async {
      final fetchedCities = await _cineService.getDistinctCineCities();
      final uniqueCities = fetchedCities.where((city) => city.isNotEmpty).toSet().toList();
      uniqueCities.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

      if (uniqueCities.isEmpty) {
        _cities = [noCitiesAvailable];
        _selectedCity = noCitiesAvailable;
      } else {
        _cities = uniqueCities;
        _selectedCity = _determineCityToSelect(uniqueCities, savedCityOverride);
      }

      // Persist the selected city only after a successful fetch.
      await _saveSelectedCityPreference(_selectedCity);
      _isReady = true;
    }, initialLoadingState: isRefresh || _cities.contains(initializingMessage));
  }

  /// Sets the selected city and persists the choice.
  Future<void> selectCineCity(String? newCity) async {
    if (newCity == null || newCity == _selectedCity || !_cities.contains(newCity)) {
      return;
    }

    _selectedCity = newCity;
    _error = null;
    await _saveSelectedCityPreference(newCity);
    _analyticsService.logFilterChange(filterType: 'cine_city', value: newCity);
    notifyListeners();
  }

  /// Refreshes the list of available cities.
  Future<void> refreshCineCities() async {
    await loadCineCities(isRefresh: true);
  }

  /// A generic wrapper for executing tasks that involve loading and error states.
  Future<void> _executeTask(Future<void> Function() task, {bool initialLoadingState = true}) async {
    _isLoading = true;
    _error = null;
    if (initialLoadingState) {
      _cities = [defaultCityValueLoading];
      _selectedCity = defaultCityValueLoading;
    }
    notifyListeners();

    try {
      await task();
    } catch (e) {
      _error = "Error al cargar ciudades de cine.";
      _cities = [noCitiesAvailable];
      _selectedCity = noCitiesAvailable;
      _isReady = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Determines which city should be selected based on availability and saved preferences.
  String _determineCityToSelect(List<String> availableCities, String? savedCity) {
    // 1. Prefer the saved city if it's valid and available.
    if (savedCity != null && availableCities.contains(savedCity)) {
      return savedCity;
    }
    // 2. Otherwise, prefer the default city if available.
    if (availableCities.contains(defaultCity)) {
      return defaultCity;
    }
    // 3. Fallback to the first available city.
    if (availableCities.isNotEmpty) {
      return availableCities.first;
    }
    // 4. If no cities are available, show the corresponding message.
    return noCitiesAvailable;
  }

  /// Saves the selected city to SharedPreferences.
  Future<void> _saveSelectedCityPreference(String? cityName) async {
    if (cityName == null || [noCitiesAvailable, initializingMessage, selectCityPrompt].contains(cityName)) {
      await _prefs.remove(_cineCityPrefKey);
    } else {
      await _prefs.setString(_cineCityPrefKey, cityName);
    }
  }
}
