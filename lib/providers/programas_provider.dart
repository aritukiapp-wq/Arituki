/// Gestiona el estado de la sección de programas de fiestas y eventos.
///
/// Este provider se encarga de:
/// - Obtener los programas principales a través de `ProgramaService`.
/// - Filtrar los programas según la ubicación seleccionada en `LocationFilterProvider`.
/// - Administrar los estados de carga y error durante la obtención de datos.
library;
import 'package:flutter/foundation.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/services/programas_service.dart';
import 'package:arituki/providers/location_filter_provider.dart';

class ProgramasProvider with ChangeNotifier {
  final ProgramaService _programaService;

  // Internal state
  bool _isLoading = false;
  List<EventoSupabase> _programas = [];
  String? _errorMessage;

  // Current filter state to prevent unnecessary fetches
  String? _currentComunidad;
  String? _currentProvincia;
  String? _currentCiudad;

  ProgramasProvider({required ProgramaService programaService})
      : _programaService = programaService;

  // Public getters
  bool get isLoading => _isLoading;
  List<EventoSupabase> get programas => _programas;
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

      fetchProgramas(
        comunidad: newComunidad,
        provincia: newProvincia,
        ciudad: newCiudad,
      );
    }
  }

  /// Fetches programs from the service based on location filters.
  Future<void> fetchProgramas({
    String? comunidad,
    String? provincia,
    String? ciudad,
  }) async {
    await _executeLoadingTask(() async {
      _programas = await _programaService.getProgramasPrincipales(
        comunidad: comunidad,
        provincia: provincia,
        ciudad: ciudad,
      );
    }, errorMessage: "Error al obtener los programas.");
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
      _programas = []; // Clear data on error
      if (kDebugMode) {
        print(
            '[ProgramasProvider] Error al obtener programas: $e\n$stackTrace');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
