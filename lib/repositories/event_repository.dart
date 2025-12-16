/// Repositorio central para la gestión de datos de eventos y ubicaciones.
///
/// Este repositorio actúa como una fachada, combinando `EventService` y `LocationService`
/// para proporcionar un único punto de acceso a los datos de eventos y ubicaciones. Se encarga de:
/// - Obtener eventos con paginación y filtros complejos.
/// - Obtener recuentos de eventos.
/// - Buscar eventos por título, ID o nombre de lugar.
/// - Obtener listas de comunidades, provincias y ciudades.
/// - Abstraer la lógica de la fuente de datos (los servicios) de la lógica de negocio (los providers).
library;
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/services/event_service.dart';
import 'package:arituki/services/location_service.dart';

class EventRepository {
  final EventService _eventService;
  final LocationService _locationService;
  final String instanceId;

  EventRepository({
    required EventService eventService,
    required LocationService locationService,
  })
      : _eventService = eventService,
        _locationService = locationService,
        instanceId = DateTime.now().microsecondsSinceEpoch.toRadixString(16);

  // --- Métodos de EventService ---

  Future<List<EventoSupabase>> fetchEvents({
    required int limit,
    required int offset,
    DateTime? startDate,
    DateTime? endDate,
    String? city,
    String? province,
    String? selectedPlaceName,
    String? searchQuery,
    List<String>? excludedPlaces,
  }) async {
    return _executeDataFetchingOperation(
      () => _eventService.fetchEventsPaginated(
        limit: limit,
        offset: offset,
        startDate: startDate,
        endDate: endDate,
        city: city,
        province: province,
        placeName: _normalizePlaceFilter(selectedPlaceName),
        searchQuery: searchQuery,
        excludedPlaces: excludedPlaces,
      ),
      'fetchEvents',
    );
  }

  Future<int> getEventCount({
    DateTime? startDate,
    DateTime? endDate,
    String? city,
    String? province,
    String? selectedPlaceName,
    String? searchQuery,
    List<String>? excludedPlaces,
  }) async {
    try {
      final count = await _eventService.getEventCount(
        startDate: startDate,
        endDate: endDate,
        city: city,
        province: province,
        placeName: _normalizePlaceFilter(selectedPlaceName),
        searchQuery: searchQuery,
        excludedPlaces: excludedPlaces,
      );
      return count;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<EventoSupabase>> fetchEventsByExactPlaceNames(List<String> placeNames) async {
    if (placeNames.isEmpty) return [];
    return _executeDataFetchingOperation(
      () => _eventService.fetchEventsByExactPlaceNames(placeNames),
      'fetchEventsByExactPlaceNames',
    );
  }

  Future<List<EventoSupabase>> fetchEventsByTitle(String title) async {
    return _executeDataFetchingOperation(
      () => _eventService.fetchEventsByTitle(title),
      'fetchEventsByTitle',
    );
  }

  Future<List<EventoSupabase>> fetchEventsByIds(List<String> eventIds) async {
    if (eventIds.isEmpty) return [];
    return _executeDataFetchingOperation(
      () => _eventService.fetchEventsByIds(eventIds),
      'fetchEventsByIds',
    );
  }

  // --- Métodos de LocationService ---

  Future<List<String>> getDistinctComunidades() => 
    _executeLocationServiceOperation(_locationService.fetchDistinctEventComunidades, 'getDistinctComunidades');

  Future<List<String>> getDistinctProvinces({String? comunidadName}) => 
    _executeLocationServiceOperation(() => _locationService.fetchDistinctEventProvinces(comunidadName: comunidadName), 'getDistinctProvinces');

  Future<List<String>> getCitiesForProvince(String provinceName) =>
    _executeLocationServiceOperation(() => _locationService.fetchCitiesForProvince(provinceName), 'getCitiesForProvince');


  // --- Private Helpers ---

  String? _normalizePlaceFilter(String? placeName) {
    if (placeName == null || placeName.isEmpty || placeName.toLowerCase() == 'todos') {
      return null;
    }
    return placeName;
  }

  List<EventoSupabase> _mapToEventoSupabaseList(List<Map<String, dynamic>> rawData) {
    return rawData.map((json) => EventoSupabase.fromJson(json)).toList();
  }

  Future<List<EventoSupabase>> _executeDataFetchingOperation(
    Future<List<Map<String, dynamic>>> Function() serviceCall,
    String methodName,
  ) async {
    try {
      final rawData = await serviceCall();
      final events = _mapToEventoSupabaseList(rawData);
      return events;
    } catch (e) {
      rethrow;
    }
  }
  
  Future<List<String>> _executeLocationServiceOperation(
    Future<List<String>> Function() serviceCall,
    String methodName,
  ) async {
     try {
      final result = await serviceCall();
      return result;
    } catch (e) {
      rethrow;
    }
  }
}
