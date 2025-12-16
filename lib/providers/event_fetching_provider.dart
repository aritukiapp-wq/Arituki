/// Gestiona la obtención de eventos desde el repositorio, aplicando filtros y paginación.
///
/// Este provider es el núcleo de la carga de datos para la lista de eventos.
/// Se encarga de:
/// - Escuchar cambios en los providers de filtros (`EventFilterProvider`,
///   `LocationFilterProvider`, `BlockedPlaceProvider`).
/// - Lanzar una nueva búsqueda en el `EventRepository` cuando los filtros cambian.
/// - Manejar la paginación (carga inicial y "cargar más").
/// - Mantener el estado de la lista de eventos crudos (`_allEvents`), los estados
///   de carga (`isLoadingInitial`, `isLoadingMore`), y los errores.
/// - Evitar peticiones duplicadas a la API mediante un sistema de caché de consulta.
library;
import 'package:flutter/foundation.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/repositories/event_repository.dart';
import 'package:arituki/providers/event_filter_provider.dart';
import 'package:arituki/providers/location_filter_provider.dart';
import 'package:arituki/providers/blocked_place_provider.dart';

class EventFetchingProvider with ChangeNotifier {
  final EventRepository _eventRepository;
  EventFilterProvider? _filterProvider;
  LocationFilterProvider? _locationFilterProvider;
  BlockedPlaceProvider? _blockedPlaceProvider;

  List<EventoSupabase> _allEvents = [];
  bool _hasMoreEvents = true;
  bool _isLoadingInitial = false;
  bool _isLoadingMore = false;
  String? _errorMessage;
  int _totalEventsCount = 0;
  bool _firstLoadAttempted = false;
  String? _lastQueryCache;

  static const int _eventsPerPage = 150;

  EventFetchingProvider({required EventRepository eventRepository}) : _eventRepository = eventRepository;

  List<EventoSupabase> get allEvents => _allEvents;
  bool get hasMoreEvents => _hasMoreEvents;
  bool get isLoadingInitial => _isLoadingInitial;
  bool get isLoadingMore => _isLoadingMore;
  String? get errorMessage => _errorMessage;
  int get totalDatabaseEventCount => _totalEventsCount;
  bool get isAnyEventLoaded => _firstLoadAttempted;

  void updateDependencies(EventFilterProvider fp, LocationFilterProvider lfp, BlockedPlaceProvider bpp) {
    bool needsInitialLoad = false;

    if (_filterProvider != fp) {
      _filterProvider?.removeListener(refreshEvents);
      _filterProvider = fp;
      _filterProvider?.addListener(refreshEvents);
      needsInitialLoad = true;
    }

    if (_locationFilterProvider != lfp) {
      _locationFilterProvider?.removeListener(refreshEvents);
      _locationFilterProvider = lfp;
      _locationFilterProvider?.addListener(refreshEvents);
      needsInitialLoad = true;
    }

    if (_blockedPlaceProvider != bpp) {
      _blockedPlaceProvider?.removeListener(refreshEvents);
      _blockedPlaceProvider = bpp;
      _blockedPlaceProvider?.addListener(refreshEvents);
      needsInitialLoad = true;
    }

    if (needsInitialLoad || !_firstLoadAttempted) {
      _loadInitialData();
    }
  }

  @override
  void dispose() {
    _filterProvider?.removeListener(refreshEvents);
    _locationFilterProvider?.removeListener(refreshEvents);
    _blockedPlaceProvider?.removeListener(refreshEvents);
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    if (_isLoadingInitial || _filterProvider == null || _locationFilterProvider == null || !_locationFilterProvider!.isReady) {
      return;
    }

    final queryCache = _generateQueryCache();
    if (queryCache == _lastQueryCache && _firstLoadAttempted) {
      return;
    }

    _isLoadingInitial = true;
    _errorMessage = null;
    _lastQueryCache = queryCache;
    notifyListeners();

    try {
      final results = await _fetchEvents(0);
      _allEvents = results['events'];
      _totalEventsCount = results['count'];
      _hasMoreEvents = _allEvents.length < _totalEventsCount;
    } catch (e) {
      _errorMessage = "Error al cargar los eventos.";
      _allEvents = [];
      _totalEventsCount = 0;
      _hasMoreEvents = false;
    } finally {
      _isLoadingInitial = false;
      _firstLoadAttempted = true;
      notifyListeners();
    }
  }

  Future<void> loadMoreEvents() async {
    if (_isLoadingMore || !_hasMoreEvents) return;

    _isLoadingMore = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await _fetchEvents(_allEvents.length);
      _allEvents.addAll(results['events']);
      _totalEventsCount = results['count'];
      _hasMoreEvents = _allEvents.length < _totalEventsCount;
    } catch (e) {
      _errorMessage = "Error al cargar más eventos.";
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  Future<void> refreshEvents() async {
    _lastQueryCache = null;
    await _loadInitialData();
  }

  Future<Map<String, dynamic>> _fetchEvents(int offset) async {
    if (_filterProvider == null || _locationFilterProvider == null || _blockedPlaceProvider == null) {
      throw Exception("Providers not initialized");
    }

    final searchQuery = _filterProvider!.searchQuery;
    final excludedPlaces = _blockedPlaceProvider!.blockedPlaces.map((place) => place.name).toList();

    // Si hay un término de búsqueda, ignora otros filtros
    if (searchQuery.isNotEmpty) {
      final count = await _eventRepository.getEventCount(
        searchQuery: searchQuery,
        excludedPlaces: excludedPlaces,
      );
      if (count == 0) return {'events': [], 'count': 0};

      final events = await _eventRepository.fetchEvents(
        limit: _eventsPerPage,
        offset: offset,
        searchQuery: searchQuery,
        excludedPlaces: excludedPlaces,
      );
      return {'events': events, 'count': count};
    }

    // Si no hay búsqueda, usa los filtros
    final city = _locationFilterProvider!.selectedEventCities.isNotEmpty ? _locationFilterProvider!.selectedEventCities.first : null;
    final province = _locationFilterProvider!.selectedProvince;

    final count = await _eventRepository.getEventCount(
      startDate: _filterProvider!.selectedDate,
      endDate: _filterProvider!.selectedEndDate,
      city: city,
      province: province,
      selectedPlaceName: _filterProvider!.selectedPlaceFilterValue,
      excludedPlaces: excludedPlaces,
    );

    if (count == 0) {
      return {'events': [], 'count': 0};
    }

    final events = await _eventRepository.fetchEvents(
      limit: _eventsPerPage,
      offset: offset,
      startDate: _filterProvider!.selectedDate,
      endDate: _filterProvider!.selectedEndDate,
      city: city,
      province: province,
      selectedPlaceName: _filterProvider!.selectedPlaceFilterValue,
      excludedPlaces: excludedPlaces,
    );

    return {'events': events, 'count': count};
  }

  String _generateQueryCache() {
    if (_filterProvider == null || _locationFilterProvider == null || _blockedPlaceProvider == null) return '';

    final searchQuery = _filterProvider!.searchQuery;
    final blockedPlacesKey = _blockedPlaceProvider!.blockedPlaces.map((p) => p.name).toList()..sort();

    // Si hay búsqueda, la caché depende solo de la búsqueda y los bloqueos
    if (searchQuery.isNotEmpty) {
      return 'search-$searchQuery-${blockedPlacesKey.join(',')}';
    }

    // Si no, la caché depende de los filtros
    final city = _locationFilterProvider!.selectedEventCities.isNotEmpty ? _locationFilterProvider!.selectedEventCities.first : null;
    final province = _locationFilterProvider!.selectedProvince;

    return 'filter-${_filterProvider!.selectedDate}-${_filterProvider!.selectedEndDate}-'
           '$city-$province-${_filterProvider!.selectedPlaceFilterValue}-'
           '${blockedPlacesKey.join(',')}';
  }
}
