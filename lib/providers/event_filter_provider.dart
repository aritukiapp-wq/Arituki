/// Gestiona el estado de todos los filtros de eventos.
///
/// Este provider centraliza la lógica para:
/// - Filtrar eventos por tipo (evento, lugar o todos).
/// - Filtrar por una consulta de búsqueda de texto.
/// - Filtrar por fecha (usando valores predefinidos como "Hoy", "Mañana", etc.).
/// - Filtrar por un lugar específico.
/// - Excluir eventos de lugares bloqueados por el usuario.
/// - Aplicar todos los filtros activos a una lista de eventos.
/// - Registrar eventos de analítica relacionados con el uso de los filtros.
library;
import 'package:flutter/foundation.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/providers/blocked_place_provider.dart';
import 'package:arituki/services/analytics_service.dart';

/// Defines the filter state for the event list.
enum EventFilterState {
  all,
  eventsOnly,
  placesOnly,
}

/// Manages the state for all event filters, including search, date, and place filters.
class EventFilterProvider with ChangeNotifier {
  final BlockedPlaceProvider _blockedProvider;
  final AnalyticsService _analyticsService;

  // --- Internal State ---
  EventFilterState _filterState = EventFilterState.all;
  String _searchQuery = '';
  String? _selectedDateFilterValue;
  String? _selectedPlaceFilterValue;
  DateTime? _calculatedStartDate;
  DateTime? _calculatedEndDate;

  EventFilterProvider({
    required BlockedPlaceProvider blockedProvider,
    required AnalyticsService analyticsService,
    String? initialDateFilterValue,
  })  : _blockedProvider = blockedProvider,
        _analyticsService = analyticsService {
    if (initialDateFilterValue != null && initialDateFilterValue.isNotEmpty) {
      updateDateFilter(initialDateFilterValue, notify: false);
    }
  }

  // --- Public Getters ---
  EventFilterState get filterState => _filterState;
  String get searchQuery => _searchQuery;
  String? get selectedDateFilterValue => _selectedDateFilterValue;
  String? get selectedPlaceFilterValue => _selectedPlaceFilterValue;
  DateTime? get selectedDate => _calculatedStartDate;
  DateTime? get selectedEndDate => _calculatedEndDate;

  bool get isAnyFilterActive =>
      _searchQuery.isNotEmpty ||
      _selectedDateFilterValue != null ||
      _selectedPlaceFilterValue != null ||
      _filterState != EventFilterState.all;


  // --- Filter Management ---

  void setFilterState(EventFilterState state) {
    if (_filterState == state) return;
    _filterState = state;
    notifyListeners();
  }

  void updateSearchQuery(String query) {
    final newQuery = query.toLowerCase().trim();
    if (_searchQuery == newQuery) return;
    _searchQuery = newQuery;
    _analyticsService.logSearch(searchTerm: newQuery);
    notifyListeners();
  }

  void updateDateFilter(String? dateFilterValue, {bool notify = true}) {
    if (_selectedDateFilterValue == dateFilterValue) return;
    
    _selectedDateFilterValue = dateFilterValue;
    _calculateDateTimesFromFilterValue();
    
    if (notify) {
      notifyListeners();
      _analyticsService.logFilterChange(filterType: 'date', value: dateFilterValue ?? 'none');
    }
  }

  void updatePlaceFilter(String? placeFilterValue, {bool notify = true}) {
    if (_selectedPlaceFilterValue == placeFilterValue) return;
    
    _selectedPlaceFilterValue = placeFilterValue;
    
    if (notify) {
      notifyListeners();
      _analyticsService.logFilterChange(filterType: 'place', value: placeFilterValue ?? 'none');
    }
  }

  void resetAllFilters() {
    if (!isAnyFilterActive) return;

    _filterState = EventFilterState.all;
    _searchQuery = '';
    _selectedDateFilterValue = null;
    _selectedPlaceFilterValue = null;
    _calculatedStartDate = null;
    _calculatedEndDate = null;

    _analyticsService.logFilterChange(filterType: 'all_filters', value: 'reset');
    notifyListeners();
  }

  /// Applies all active filters to a given list of events.
  List<EventoSupabase> applyFilters(List<EventoSupabase> events, {bool ignoreDateFilter = false, bool ignorePlaceFilter = false}) {
    List<EventoSupabase> filtered = List.from(events);

    // Blocked places filter
    final blockedPlaceNames = _blockedProvider.blockedPlaces.map((p) => p.name).toSet();
    if (blockedPlaceNames.isNotEmpty) {
      filtered.removeWhere((event) => blockedPlaceNames.contains(event.lugar));
    }

    // Event type filter
    if (_filterState == EventFilterState.eventsOnly) {
      filtered = filtered.where((event) => event.categoria?.toLowerCase().contains('evento') ?? false).toList();
    } else if (_filterState == EventFilterState.placesOnly) {
      filtered = filtered.where((event) => event.categoria?.toLowerCase().contains('lugar') ?? false).toList();
    }

    // Search query filter
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((event) {
        final title = event.titulo?.toLowerCase() ?? '';
        final place = event.lugar?.toLowerCase() ?? '';
        return title.contains(_searchQuery) || place.contains(_searchQuery);
      }).toList();
    }

    // Date filter
    if (!ignoreDateFilter && _searchQuery.isEmpty && _selectedDateFilterValue != null && _calculatedStartDate != null && _calculatedEndDate != null) {
      filtered = filtered.where((event) => _isEventInDateRange(event, _calculatedStartDate!, _calculatedEndDate!)).toList();
    }
    
    // Place filter
    if (!ignorePlaceFilter && _selectedPlaceFilterValue != null) {
      filtered = filtered.where((event) => event.lugar == _selectedPlaceFilterValue).toList();
    }

    return filtered;
  }
  
  bool _isEventInDateRange(EventoSupabase event, DateTime filterStart, DateTime filterEnd) {
      final eventStart = event.diaIni ?? event.dia;
      if (eventStart == null) return false;

      final eventStartDate = DateTime(eventStart.year, eventStart.month, eventStart.day);
      
      if (event.diaFin != null) {
        final eventEndDate = DateTime(event.diaFin!.year, event.diaFin!.month, event.diaFin!.day);
        return !eventStartDate.isAfter(filterEnd) && !eventEndDate.isBefore(filterStart);
      } else {
        return !eventStartDate.isBefore(filterStart) && !eventStartDate.isAfter(filterEnd);
      }
  }

  // --- Date Calculation Logic ---
  
  void _calculateDateTimesFromFilterValue() {
    if (_selectedDateFilterValue == null) {
      _calculatedStartDate = null;
      _calculatedEndDate = null;
      return;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedDateFilterValue) {
      case 'Hoy':
        _calculatedStartDate = today;
        _calculatedEndDate = _endOfDay(today);
        break;
      case 'Mañana':
        final tomorrow = today.add(const Duration(days: 1));
        _calculatedStartDate = tomorrow;
        _calculatedEndDate = _endOfDay(tomorrow);
        break;
      case 'Este finde':
        final weekend = _calculateThisWeekend(today);
        _calculatedStartDate = weekend.start;
        _calculatedEndDate = weekend.end;
        break;
      case 'Esta semana':
        _calculatedStartDate = today.subtract(Duration(days: today.weekday - DateTime.monday));
        _calculatedEndDate = _endOfDay(_calculatedStartDate!.add(const Duration(days: 6)));
        break;
      case 'Próx. finde':
        final nextWeekend = _calculateNextWeekend(today);
        _calculatedStartDate = nextWeekend.start;
        _calculatedEndDate = nextWeekend.end;
        break;
      case 'Próx. semana':
        final nextWeek = _calculateNextWeek(today);
        _calculatedStartDate = nextWeek.start;
        _calculatedEndDate = nextWeek.end;
        break;
      case 'Próx. 30 días':
        _calculatedStartDate = today;
        _calculatedEndDate = _endOfDay(today.add(const Duration(days: 29)));
        break;
      case 'Tras 30 días':
        _calculatedStartDate = today.add(const Duration(days: 30));
        _calculatedEndDate = _endOfDay(today.add(const Duration(days: 395))); // ~1 year
        break;
      default:
        _calculatedStartDate = null;
        _calculatedEndDate = null;
    }
  }

  ({DateTime start, DateTime end}) _calculateThisWeekend(DateTime today) {
    final daysUntilSaturday = DateTime.saturday - today.weekday;
    final saturday = today.add(Duration(days: daysUntilSaturday));
    return (start: saturday, end: _endOfDay(saturday.add(const Duration(days: 1))));
  }

  ({DateTime start, DateTime end}) _calculateNextWeekend(DateTime today) {
    final daysUntilSaturday = DateTime.saturday - today.weekday;
    final nextSaturday = today.add(Duration(days: daysUntilSaturday + 7));
    return (start: nextSaturday, end: _endOfDay(nextSaturday.add(const Duration(days: 1))));
  }

  ({DateTime start, DateTime end}) _calculateNextWeek(DateTime today) {
    int daysUntilNextMonday = DateTime.monday - today.weekday;
    if (daysUntilNextMonday <= 0) daysUntilNextMonday += 7;
    final startOfNextWeek = today.add(Duration(days: daysUntilNextMonday));
    return (start: startOfNextWeek, end: _endOfDay(startOfNextWeek.add(const Duration(days: 6))));
  }

  DateTime _endOfDay(DateTime date) {
    return DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
  }
}
