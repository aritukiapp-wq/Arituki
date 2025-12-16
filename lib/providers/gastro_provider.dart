/// Gestiona el estado de la sección de gastronomía.
///
/// Este provider se encarga de:
/// - Obtener los eventos gastronómicos (jornadas) a través de `GastronomiaService`.
/// - Filtrar los resultados según la ubicación seleccionada en `LocationFilterProvider`.
/// - Administrar los estados de carga y error durante la obtención de datos.
library;
import 'package:flutter/foundation.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/services/gastro_service.dart';
import 'package:arituki/providers/location_filter_provider.dart';

class GastronomiaProvider with ChangeNotifier {
  final GastronomiaService _gastronomiaService;

  // Internal state
  bool _isLoading = false;
  List<EventoSupabase> _jornadas = [];
  String? _errorMessage;

  // Current filter state to prevent unnecessary fetches
  String? _currentComunidad;
  String? _currentProvincia;
  String? _currentCiudad;

  GastronomiaProvider({required GastronomiaService gastronomiaService})
      : _gastronomiaService = gastronomiaService;

  // Public getters
  bool get isLoading => _isLoading;
  List<EventoSupabase> get jornadas => _jornadas;
  String? get errorMessage => _errorMessage;

  /// Called by the ProxyProvider to update dependencies and trigger data fetching
  /// when the location filter changes.
  void updateDependencies(LocationFilterProvider locationFilterProvider) {
    final newComunidad = locationFilterProvider.selectedComunidad;
    final newProvincia = locationFilterProvider.selectedProvince;
    final newCiudad = locationFilterProvider.appBarSelectedCity;

    if (_currentComunidad != newComunidad ||
        _currentProvincia != newProvincia ||
        _currentCiudad != newCiudad) {
      _currentComunidad = newComunidad;
      _currentProvincia = newProvincia;
      _currentCiudad = newCiudad;

      fetchJornadas(
        comunidad: newComunidad,
        provincia: newProvincia,
        ciudad: newCiudad,
      );
    }
  }

  /// Fetches gastronomic events from the service based on location filters.
  Future<void> fetchJornadas({
    String? comunidad,
    String? provincia,
    String? ciudad,
  }) async {
    await _executeLoadingTask(() async {
      _jornadas = await _gastronomiaService.getJornadasGastronomicasPrincipales(
        comunidad: comunidad,
        provincia: provincia,
        ciudad: ciudad,
      );
    }, errorMessage: "Error al obtener las jornadas gastronómicas.");
  }

  /// A generic wrapper for executing tasks that involve loading and error states.
  Future<void> _executeLoadingTask(Future<void> Function() task, {required String errorMessage}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await task();
    } catch (e, stackTrace) {
      _errorMessage = errorMessage;
      _jornadas = []; // Clear data on error
      if (kDebugMode) {
        print(
            '[GastronomiaProvider] Error al obtener jornadas: $e\n$stackTrace');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
