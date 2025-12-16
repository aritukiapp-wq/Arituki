/// Gestiona el estado de la pantalla de detalle de una película.
///
/// Este provider recibe todas las sesiones de una película y se encarga de:
/// - Filtrar las sesiones por día y por cine.
/// - Actualizar dinámicamente los filtros de días y cines disponibles en función
///   de la selección actual del usuario.
/// - Exponer la lista de sesiones filtradas y los filtros disponibles a la UI.
library;
import 'package:flutter/foundation.dart';
import 'package:arituki/models/cine_supabase.dart';

class CineDetailProvider with ChangeNotifier {
  final List<PeliculaSupabase> _allSessions;

  // --- Internal State ---
  String? _selectedDay;
  String? _selectedCinema;

  List<String> _availableDays = [];
  List<String> _availableCinemas = [];
  List<PeliculaSupabase> _filteredSessions = [];

  CineDetailProvider({required List<PeliculaSupabase> allSessions})
      : _allSessions = allSessions {
    _updateFiltersAndSessions();
  }

  // --- Public Getters ---
  String? get selectedDay => _selectedDay;
  String? get selectedCinema => _selectedCinema;
  List<String> get availableDays => _availableDays;
  List<String> get availableCinemas => _availableCinemas;
  List<PeliculaSupabase> get filteredSessions => _filteredSessions;

  /// Selects a day and updates the available filters and session list.
  void selectDay(String? day) {
    if (_selectedDay == day) return;
    _selectedDay = day;
    _updateFiltersAndSessions();
  }

  /// Selects a cinema and updates the available filters and session list.
  void selectCinema(String? cinema) {
    if (_selectedCinema == cinema) return;
    _selectedCinema = cinema;
    _updateFiltersAndSessions();
  }

  /// Core logic to recalculate available filters and the final session list.
  /// This method is called whenever a filter selection changes.
  void _updateFiltersAndSessions() {
    // 1. Recalculate available days.
    // These are the days available for the currently selected cinema (if any).
    List<PeliculaSupabase> sessionsForDayCalc = _allSessions;
    if (_selectedCinema != null) {
      sessionsForDayCalc = _allSessions.where((s) => s.cine == _selectedCinema).toList();
    }
    _availableDays = _getUniqueSortedStrings(sessionsForDayCalc, (s) => s.dia);

    // 2. Recalculate available cinemas.
    // These are the cinemas available for the currently selected day (if any).
    List<PeliculaSupabase> sessionsForCinemaCalc = _allSessions;
    if (_selectedDay != null) {
      sessionsForCinemaCalc = _allSessions.where((s) => s.dia == _selectedDay).toList();
    }
    _availableCinemas = _getUniqueSortedStrings(sessionsForCinemaCalc, (s) => s.cine);

    // 3. Validate selected filters. If a selection is no longer in the available
    // list, reset it to prevent an invalid state.
    if (_selectedDay != null && !_availableDays.contains(_selectedDay)) {
      _selectedDay = null;
    }
    if (_selectedCinema != null && !_availableCinemas.contains(_selectedCinema)) {
      _selectedCinema = null;
    }

    // 4. Apply final filters to get the sessions to display.
    // This runs *after* validation, in case a filter was reset.
    List<PeliculaSupabase> tempSessions = _allSessions;
    if (_selectedDay != null) {
      tempSessions = tempSessions.where((s) => s.dia == _selectedDay).toList();
    }
    if (_selectedCinema != null) {
      tempSessions = tempSessions.where((s) => s.cine == _selectedCinema).toList();
    }
    _filteredSessions = tempSessions;

    notifyListeners();
  }

  /// Extracts unique, non-null, sorted string values from a list of sessions.
  List<String> _getUniqueSortedStrings(List<PeliculaSupabase> sessions, String? Function(PeliculaSupabase) getValue) {
    return sessions
        .map(getValue)
        .whereType<String>()
        .toSet()
        .toList()
      ..sort();
  }
}
