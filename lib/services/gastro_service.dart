/// Servicio para gestionar los datos de gastronomía desde Supabase.
///
/// Esta clase encapsula la comunicación con la base de datos para obtener
/// información sobre eventos gastronómicos y los detalles de las rutas o jornadas,
/// incluyendo los establecimientos participantes.
library;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/models/gastro_supabase.dart';

class GastronomiaService {
  final SupabaseClient _supabaseClient;

  GastronomiaService({required SupabaseClient supabaseClient}) : _supabaseClient = supabaseClient;

  Future<List<EventoSupabase>> getJornadasGastronomicasPrincipales({
    String? comunidad,
    String? provincia,
    String? ciudad,
  }) async {
    var queryBuilder = _supabaseClient
        .from('Eventos')
        .select('*, created_at') // Use lowercase created_at
        .eq('Categoria', 'Gastronomia');

    if (comunidad != null && comunidad.isNotEmpty) {
      queryBuilder = queryBuilder.eq('Comunidad', comunidad);
    }
    if (provincia != null && provincia.isNotEmpty) {
      queryBuilder = queryBuilder.eq('Provincia', provincia);
    }
    if (ciudad != null && ciudad.isNotEmpty) {
      queryBuilder = queryBuilder.eq('Ciudad', ciudad);
    }
    
    final orderedQuery = queryBuilder.order('DiaFin', ascending: true, nullsFirst: false);
    return _executeAndMap(orderedQuery, EventoSupabase.fromJson, 'getJornadasGastronomicasPrincipales');
  }

  Future<List<RutaGastroItem>> fetchItemsDeLaRutaGastronomica(
      {required String nombreRutaPadre}) async {
    if (nombreRutaPadre.isEmpty) return [];

    final query = _supabaseClient
        .from('RutaGastro')
        .select()
        .eq('NombreRuta', nombreRutaPadre)
        .order('Restaurante', ascending: true);

    return _executeAndMap(query, RutaGastroItem.fromJson, 'fetchItemsDeLaRutaGastronomica');
  }

  Future<List<T>> _executeAndMap<T>(
    dynamic query,
    T Function(Map<String, dynamic>) fromJson,
    String methodName,
  ) async {
    try {
      final response = await query;
      final items = (response as List).map((item) => fromJson(item as Map<String, dynamic>)).toList();
      return items;
    } catch (e) {
      rethrow;
    }
  }
}
