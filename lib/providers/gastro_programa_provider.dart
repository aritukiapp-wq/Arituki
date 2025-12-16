/// Gestiona el estado de un programa gastronómico específico.
///
/// Este provider se encarga de:
/// - Obtener la lista de establecimientos o tapas que pertenecen a una ruta
///   gastronómica o programa concreto, utilizando `GastronomiaService`.
/// - Administrar el estado de carga y los errores durante la obtención de datos.
library;
import 'package:flutter/foundation.dart';
import 'package:arituki/models/gastro_supabase.dart';
import 'package:arituki/services/gastro_service.dart';

class GastronomiaProgramaProvider with ChangeNotifier {
  final GastronomiaService _gastronomiaService;

  // --- Internal State ---
  bool _isLoading = false;
  String? _errorMessage;
  List<RutaGastroItem> _itemsDelPrograma = [];

  GastronomiaProgramaProvider({required GastronomiaService gastronomiaService})
      : _gastronomiaService = gastronomiaService;

  // --- Public Getters ---
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<RutaGastroItem> get itemsDelPrograma => _itemsDelPrograma;

  /// Fetches the items for a specific gastronomic route or program.
  Future<void> fetchItemsDelPrograma({required String nombreRutaPadre}) async {
    if (nombreRutaPadre.isEmpty) {
      _itemsDelPrograma = [];
      _errorMessage = "No se especificó una ruta gastronómica.";
      notifyListeners();
      return;
    }

    await _executeLoadingTask(() async {
      _itemsDelPrograma = await _gastronomiaService.fetchItemsDeLaRutaGastronomica(
        nombreRutaPadre: nombreRutaPadre,
      );
    }, "Error al cargar los establecimientos de la ruta.");
  }

  /// A generic wrapper for executing tasks that involve loading and error states.
  Future<void> _executeLoadingTask(Future<void> Function() task, String errorMessage) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await task();
    } catch (e, stackTrace) {
      _errorMessage = errorMessage;
      _itemsDelPrograma = []; // Clear data on error
      if (kDebugMode) {
        print('[GastronomiaProgramaProvider] Task failed: $e\n$stackTrace');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
