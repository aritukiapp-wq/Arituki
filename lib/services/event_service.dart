/// Servicio para interactuar con la tabla de eventos en Supabase.
///
/// Esta clase es la capa de acceso a datos para todo lo relacionado con los
/// eventos. Se encarga de construir y ejecutar consultas complejas a Supabase
/// para obtener listas de eventos paginadas y filtradas por múltiples criterios
/// como búsqueda de texto, rango de fechas, ubicación, etc. También proporciona
/// métodos para obtener el recuento total de eventos que coinciden con los filtros.
library;
import 'package:supabase_flutter/supabase_flutter.dart';

class EventService {
  final SupabaseClient _client;
  final String _eventTableName = 'Eventos';
  final int _eventLimit;
  final String _orderByColumn;
  final bool _ascendingOrder = true;
  final String _secondaryOrderByColumn = 'Hora';
  final bool _secondaryAscendingOrder = true;

  EventService(this._client)
      : _eventLimit = 150,
        _orderByColumn = "Dia";

  String _toYYYYMMDD(DateTime dateTime) {
    return "${dateTime.year.toString().padLeft(4, '0')}-"
        "${dateTime.month.toString().padLeft(2, '0')}-"
        "${dateTime.day.toString().padLeft(2, '0')}";
  }

  Future<int> getEventCount({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? city,
    String? province,
    String? placeName,
    List<String>? excludedPlaces,
  }) async {
    try {
      PostgrestFilterBuilder queryBuilder = _client.from(_eventTableName).select('id, created_at');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        String searchPattern = '%$searchQuery%';
        queryBuilder = queryBuilder.or('Titulo.ilike.$searchPattern,Lugar.ilike.$searchPattern');
      }

      if (startDate != null && endDate != null) {
        queryBuilder = queryBuilder.lte('DiaIni', _toYYYYMMDD(endDate)).gte('DiaFin', _toYYYYMMDD(startDate));
      } else if (startDate != null) {
        queryBuilder = queryBuilder.gte('DiaFin', _toYYYYMMDD(startDate));
      } else if (endDate != null) {
        queryBuilder = queryBuilder.lte('DiaIni', _toYYYYMMDD(endDate));
      }

      if (category != null && category.isNotEmpty) queryBuilder = queryBuilder.eq('Categoria', category);
      if (city != null && city.isNotEmpty) queryBuilder = queryBuilder.eq('Ciudad', city);
      if (province != null && province.isNotEmpty) queryBuilder = queryBuilder.eq('Provincia', province);
      if (placeName != null && placeName.isNotEmpty) queryBuilder = queryBuilder.eq('Lugar', placeName);

      if (excludedPlaces != null && excludedPlaces.isNotEmpty) {
        queryBuilder = queryBuilder.not('Lugar', 'in', excludedPlaces);
      }

      final response = await queryBuilder.count(CountOption.exact);
      return response.count;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchEventsPaginated({
    String? searchQuery,
    DateTime? startDate,
    DateTime? endDate,
    String? category,
    String? city,
    String? province,
    String? placeName,
    String? dayOfWeek,
    List<String>? excludedPlaces, // Nuevo parámetro
    int? limit,
    int offset = 0,
    String? orderBy,
    bool? ascending,
  }) async {
    final int currentLimit = limit ?? _eventLimit;
    final String currentOrderBy = orderBy ?? _orderByColumn;
    final bool currentAscending = ascending ?? _ascendingOrder;

    try {
      PostgrestFilterBuilder filterQuery = _client.from(_eventTableName).select('*, created_at');

      if (searchQuery != null && searchQuery.isNotEmpty) {
        String searchPattern = '%$searchQuery%';
        filterQuery = filterQuery.or('Titulo.ilike.$searchPattern,Lugar.ilike.$searchPattern');
      }

      if (startDate != null && endDate != null) {
        filterQuery = filterQuery.lte('DiaIni', _toYYYYMMDD(endDate)).gte('DiaFin', _toYYYYMMDD(startDate));
      } else if (startDate != null) {
        filterQuery = filterQuery.gte('DiaFin', _toYYYYMMDD(startDate));
      } else if (endDate != null) {
        filterQuery = filterQuery.lte('DiaIni', _toYYYYMMDD(endDate));
      }

      if (category != null && category.isNotEmpty) filterQuery = filterQuery.eq('Categoria', category);
      if (city != null && city.isNotEmpty) filterQuery = filterQuery.eq('Ciudad', city);
      if (province != null && province.isNotEmpty) filterQuery = filterQuery.eq('Provincia', province);
      if (placeName != null && placeName.isNotEmpty) filterQuery = filterQuery.eq('Lugar', placeName);
      if (dayOfWeek != null && dayOfWeek.isNotEmpty) filterQuery = filterQuery.eq('DiaSetmana', dayOfWeek);

      if (excludedPlaces != null && excludedPlaces.isNotEmpty) {
        filterQuery = filterQuery.not('Lugar', 'in', excludedPlaces);
      }

      PostgrestTransformBuilder transformQuery = filterQuery.order(currentOrderBy, ascending: currentAscending);

      if (currentOrderBy == 'Dia' || currentOrderBy == 'DiaIni') {
        if (_secondaryOrderByColumn != currentOrderBy) {
          transformQuery = transformQuery.order(_secondaryOrderByColumn, ascending: _secondaryAscendingOrder);
        }
      }

      transformQuery = transformQuery.range(offset, offset + currentLimit - 1);

      final response = await transformQuery;
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchEventsByExactPlaceNames(List<String> placeNames) async {
     try {
      final response = await _client
          .from(_eventTableName)
          .select('*, created_at')
          .filter('Lugar', 'in', placeNames);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchEventsByTitle(String title) async {
    try {
      final response = await _client
          .from(_eventTableName)
          .select('*, created_at')
          .eq('Titulo', title);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> fetchEventsByIds(List<String> ids) async {
    try {
      final response = await _client
          .from(_eventTableName)
          .select('*, created_at')
          .filter('id', 'in', ids);
      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      rethrow;
    }
  }
}
