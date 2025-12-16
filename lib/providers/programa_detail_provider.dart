/// Gestiona el estado de la pantalla de detalle de un programa de fiestas.
///
/// Este provider se encarga de:
/// - Recibir el título de un programa principal.
/// - Obtener todos los eventos o actos asociados a ese programa a través de `ProgramaService`.
/// - Administrar los estados de carga y error durante la obtención de los detalles.
library;
import 'package:flutter/foundation.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/services/programas_service.dart';

class ProgramaDetailProvider with ChangeNotifier {
  final ProgramaService _programaService;
  final String _programaIdentifier;

  // --- Internal State ---
  bool _isLoading = true;
  String? _errorMessage;
  List<EventoSupabase> _items = [];

  // --- Public Getters ---
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  List<EventoSupabase> get items => List.unmodifiable(_items);

  ProgramaDetailProvider({
    required ProgramaService programaService,
    required String programaTitulo,
  })  : _programaService = programaService,
        _programaIdentifier = programaTitulo {
    if (_programaIdentifier.isEmpty) {
      _isLoading = false;
      _errorMessage = "El identificador del programa no es válido.";
    } else {
      fetchProgramaDetails();
    }
  }

  /// Fetches the items for the program.
  Future<void> fetchProgramaDetails() async {
    await _executeLoadingTask(() async {
      _items = await _programaService.getItemsDelPrograma(
        tituloProgramaPadre: _programaIdentifier,
      );
    }, "Error al cargar los detalles del programa.");
  }

  /// Retries the fetch operation.
  Future<void> refresh() async {
    if (_programaIdentifier.isNotEmpty) {
      await fetchProgramaDetails();
    }
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
      _items = []; // Clear data on error
      if (kDebugMode) {
        print('[ProgramaDetailProvider] Task failed for "$_programaIdentifier": $e\n$stackTrace');
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
