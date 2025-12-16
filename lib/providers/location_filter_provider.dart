/// Gestiona los filtros de ubicación jerárquicos (Comunidad > Provincia > Ciudad).
///
/// Este provider se encarga de:
/// - Obtener los datos de ubicación (comunidades, provincias, ciudades) del `EventRepository`.
/// - Gestionar la selección del usuario en cascada: al seleccionar una comunidad, se
///   cargan sus provincias; al seleccionar una provincia, se cargan sus ciudades.
/// - Persistir la última selección del usuario en `SharedPreferences`.
/// - Exponer las listas de ubicaciones disponibles y seleccionadas, así como los
///   estados de carga y error, a la UI.
library;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arituki/repositories/event_repository.dart';
import 'package:arituki/services/analytics_service.dart';

class LocationFilterProvider with ChangeNotifier {
  final EventRepository _eventRepository;
  final AnalyticsService _analyticsService;
  final SharedPreferences _prefs;

  // --- Preference Keys ---
  static const _comunidadKey = 'selected_event_comunidad_pref_v1';
  static const _provinceKey = 'selected_event_province_pref_v1';
  static const _citiesKey = 'selected_event_cities_pref_v1';

  // --- State for Comunidades ---
  List<String> _comunidades = [];
  String? _selectedComunidad;
  bool _isLoadingComunidades = false;
  String? _comunidadError;

  // --- State for Provinces ---
  List<String> _provinces = [];
  String? _selectedProvince;
  bool _isLoadingProvinces = false;
  String? _provinceError;

  // --- State for Cities ---
  List<String> _availableCities = [];
  List<String> _selectedCities = [];
  bool _isLoadingCities = false;
  String? _cityError;

  bool _isReady = false;

  LocationFilterProvider({
    required EventRepository eventRepository,
    required AnalyticsService analyticsService,
    required SharedPreferences prefs,
  })
      : _eventRepository = eventRepository,
        _analyticsService = analyticsService,
        _prefs = prefs {
    _initialize();
  }

  // --- Public Getters ---
  bool get isReady => _isReady;
  
  // Comunidad Getters
  List<String> get comunidades => List.unmodifiable(_comunidades);
  String? get selectedComunidad => _selectedComunidad;
  bool get isLoadingComunidades => _isLoadingComunidades;
  String? get comunidadError => _comunidadError;

  // Province Getters
  List<String> get provinces => List.unmodifiable(_provinces);
  String? get selectedProvince => _selectedProvince;
  bool get isLoadingProvinces => _isLoadingProvinces;
  String? get provinceError => _provinceError;

  // City Getters
  List<String> get availableCitiesForProvince => List.unmodifiable(_availableCities);
  List<String> get selectedEventCities => List.unmodifiable(_selectedCities);
  String? get appBarSelectedCity => _selectedCities.isNotEmpty ? _selectedCities.first : null;
  bool get isLoadingCities => _isLoadingCities;
  String? get cityError => _cityError;

  /// Kicks off the initial loading sequence for the provider.
  Future<void> _initialize() async {
    await loadComunidades();
    _isReady = true;
    notifyListeners();
  }

  /// Loads the list of Comunidades and attempts to restore the previously selected state.
  Future<void> loadComunidades() async {
    await _executeTask(
      loadingSetter: (val) => _isLoadingComunidades = val,
      errorSetter: (val) => _comunidadError = val,
      task: () async {
        _comunidades = await _eventRepository.getDistinctComunidades();
        _comunidades.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
        
        final savedComunidad = _prefs.getString(_comunidadKey);
        if (savedComunidad != null && _comunidades.contains(savedComunidad)) {
          await _selectComunidadInternal(savedComunidad, fromUser: false);
        } else {
          // If no valid saved comunidad, clear downstream selections
          _resetProvinces();
          _resetCities();
        }
      },
      errorMessage: "Error al cargar comunidades",
    );
  }

  /// Sets the selected Comunidad and triggers loading the corresponding Provinces.
  Future<void> selectComunidad(String? comunidad) async {
    if (_selectedComunidad == comunidad) return;
    await _selectComunidadInternal(comunidad, fromUser: true);
    _analyticsService.logLocationFilterChange(filterType: 'comunidad', comunidad: comunidad);
  }

  Future<void> _selectComunidadInternal(String? comunidad, {required bool fromUser}) async {
    _selectedComunidad = comunidad;
    await _prefs.setString(_comunidadKey, comunidad ?? '');
    
    _resetProvinces();
    _resetCities();
    notifyListeners();

    if (comunidad != null) {
      await loadProvinces(fromUser: fromUser);
    }
  }

  /// Loads provinces for the currently selected Comunidad.
  Future<void> loadProvinces({required bool fromUser}) async {
    if (_selectedComunidad == null) return;

    await _executeTask(
      loadingSetter: (val) => _isLoadingProvinces = val,
      errorSetter: (val) => _provinceError = val,
      task: () async {
        _provinces = await _eventRepository.getDistinctProvinces(comunidadName: _selectedComunidad!);
        _provinces.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        final savedProvince = _prefs.getString(_provinceKey);
        if (!fromUser && savedProvince != null && _provinces.contains(savedProvince)) {
          await _selectProvinceInternal(savedProvince, fromUser: false);
        }
      },
      errorMessage: "Error al cargar provincias",
    );
  }

  /// Sets the selected Province and triggers loading the corresponding Cities.
  Future<void> selectProvince(String? province) async {
    if (_selectedProvince == province) return;
    await _selectProvinceInternal(province, fromUser: true);
  }

  Future<void> _selectProvinceInternal(String? province, {required bool fromUser}) async {
    _selectedProvince = province;
    await _prefs.setString(_provinceKey, province ?? '');

    _resetCities();
    notifyListeners();

    if (province != null) {
      await loadCities(fromUser: fromUser);
    }
  }

  /// Loads cities for the currently selected Province.
  Future<void> loadCities({required bool fromUser}) async {
    if (_selectedProvince == null) return;

    await _executeTask(
      loadingSetter: (val) => _isLoadingCities = val,
      errorSetter: (val) => _cityError = val,
      task: () async {
        _availableCities = await _eventRepository.getCitiesForProvince(_selectedProvince!);
        _availableCities.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

        if (!fromUser) {
          final savedCitiesJson = _prefs.getString(_citiesKey);
          if (savedCitiesJson != null) {
            try {
              final savedCities = List<String>.from(jsonDecode(savedCitiesJson));
              _selectedCities = savedCities.where((c) => _availableCities.contains(c)).toList();
            } catch (e) {
              _selectedCities = [];
            }
          }
        }
      },
      errorMessage: "Error al cargar ciudades",
    );
  }

  /// Sets the final list of selected cities.
  void setSelectedCities(List<String> cities) {
    final validCities = cities.where((c) => _availableCities.contains(c)).toList();
    if (listEquals(_selectedCities, validCities)) return;

    _selectedCities = validCities;
    _prefs.setString(_citiesKey, jsonEncode(validCities));
    notifyListeners();
  }

  /// Sets a single city, typically from the app bar. This clears other selections.
  void selectAppBarCity(String? city) {
    List<String> newSelection = (city != null && _availableCities.contains(city)) ? [city] : [];
    setSelectedCities(newSelection);
  }
  
  /// Refreshes all filter data from the source.
  Future<void> refresh() async {
    await _initialize();
  }

  /// Resets all filters and re-initializes the provider.
  Future<void> clearAllFiltersAndPreferences() async {
    _isReady = false;
    notifyListeners();
    
    await _prefs.remove(_comunidadKey);
    await _prefs.remove(_provinceKey);
    await _prefs.remove(_citiesKey);
    
    _resetComunidades();
    _resetProvinces();
    _resetCities();

    await _initialize();
  }

  // --- Private Helpers ---

  void _resetComunidades() {
    _comunidades = [];
    _selectedComunidad = null;
    _comunidadError = null;
  }

  void _resetProvinces() {
    _provinces = [];
    _selectedProvince = null;
    _provinceError = null;
  }

  void _resetCities() {
    _availableCities = [];
    _selectedCities = [];
    _cityError = null;
  }

  /// Generic wrapper for executing async tasks with loading and error handling.
  Future<void> _executeTask({
    required Function(bool) loadingSetter,
    required Function(String?) errorSetter,
    required Future<void> Function() task,
    required String errorMessage,
  }) async {
    loadingSetter(true);
    errorSetter(null);
    notifyListeners();

    try {
      await task();
    } catch (e) {
      errorSetter(errorMessage);
    } finally {
      loadingSetter(false);
      notifyListeners();
    }
  }
}
