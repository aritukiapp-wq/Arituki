/// Servicio para obtener datos de ubicación desde Supabase.
///
/// Esta clase se encarga de realizar llamadas a la base de datos, incluyendo
/// tanto consultas directas a tablas como llamadas a funciones RPC (Remote Procedure Call),
/// para obtener listas de ubicaciones geográficas como comunidades autónomas,
/// provincias y ciudades. Es la capa de acceso a datos para los filtros de ubicación.
library;
import 'package:supabase_flutter/supabase_flutter.dart';

class LocationService {
  final SupabaseClient _client;

  LocationService({required SupabaseClient supabaseClient}) : _client = supabaseClient;

  Future<List<String>> fetchDistinctEventComunidades() async {
    try {
      final response = await _client.from('Eventos').select('Comunidad');
      final Set<String> comunidades = response
          .map((row) => row['Comunidad'] as String?)
          .where((c) => c != null && c.isNotEmpty)
          .cast<String>()
          .toSet();
      final sortedList = comunidades.toList()..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return sortedList;
    } catch (e) {
      rethrow;
    }
  }

  Future<List<String>> fetchDistinctEventProvinces({String? comunidadName}) async {
    return _executeRpc(
      rpcName: 'get_distinct_event_provinces',
      params: comunidadName != null ? {'p_comunidad_nombre': comunidadName} : null,
      resultColumn: 'provincia_nombre',
      methodName: 'fetchDistinctEventProvinces',
    );
  }

  Future<List<String>> fetchCitiesForProvince(String provinceName) async {
    if (provinceName.isEmpty) return [];
    return _executeRpc(
      rpcName: 'get_distinct_cities_for_province',
      params: {'param_provincia': provinceName},
      resultColumn: 'ciudad_nombre',
      methodName: 'fetchCitiesForProvince',
    );
  }

  Future<List<String>> fetchDistinctEventCities() async {
    return _executeRpc(
      rpcName: 'get_distinct_event_cities',
      resultColumn: 'ciudad_nombre',
      methodName: 'fetchDistinctEventCities',
    );
  }

  Future<List<String>> getUniquePlaceNamesForGeoFilter({
    required DateTime startDate,
    required DateTime endDate,
    String? city,
    String? province,
  }) async {
    String? rpcName;
    Map<String, dynamic>? rpcParams;

    if (city != null && city.isNotEmpty) {
      rpcName = 'get_unique_lugares_for_city_date';
      rpcParams = {
        'param_ciudad': city,
        'param_fecha_desde': startDate.toIso8601String(),
        'param_fecha_hasta': endDate.toIso8601String(),
      };
    } else if (province != null && province.isNotEmpty) {
      rpcName = 'get_unique_lugares_for_province_date';
      rpcParams = {
        'param_provincia': province,
        'param_fecha_desde': startDate.toIso8601String(),
        'param_fecha_hasta': endDate.toIso8601String(),
      };
    }

    if (rpcName == null) return [];

    return _executeRpc(
      rpcName: rpcName,
      params: rpcParams,
      resultColumn: 'Lugar', // Assuming 'Lugar' or 'lugar_nombre'
      alternativeColumn: 'lugar_nombre',
      methodName: 'getUniquePlaceNamesForGeoFilter',
    );
  }

  /// Generic helper to execute an RPC call and parse a list of strings.
  Future<List<String>> _executeRpc({
    required String rpcName,
    required String resultColumn,
    String? alternativeColumn,
    Map<String, dynamic>? params,
    required String methodName,
  }) async {
    try {
      final response = await _client.rpc(rpcName, params: params);

      if (response is! List) {
        return [];
      }

      final resultList = response
          .map((item) {
            if (item is Map<String, dynamic>) {
              return (item[resultColumn] ?? (alternativeColumn != null ? item[alternativeColumn] : null)) as String?;
            }
            return null;
          })
          .whereType<String>()
          .where((s) => s.isNotEmpty)
          .toSet()
          .toList();

      resultList.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      return resultList;
    } catch (e) {
      rethrow;
    }
  }
}
