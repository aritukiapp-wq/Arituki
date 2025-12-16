/// Servicio para interactuar con la tabla de cines en Supabase.
///
/// Esta clase encapsula toda la lógica para realizar consultas a la base de datos
/// relacionadas con las películas y los cines. Proporciona métodos para obtener
/// películas filtradas por ciudad, género o cine, y para obtener una lista de
/// las ciudades que tienen cines disponibles.
library;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arituki/models/cine_supabase.dart'; // Asegúrate que la ruta sea correcta

class CineService {
  final SupabaseClient _supabaseClient;
  final String _tableName = 'Cine';

  CineService({required SupabaseClient supabaseClient}) : _supabaseClient = supabaseClient;

  /// Fetches a list of movies based on optional filters.
  Future<List<PeliculaSupabase>> getPeliculas({
    String? ciudad,
    String? genero,
    String? cineLocal,
  }) async {
    return _executeSelectQuery(
      queryBuilder: (query) {
        if (ciudad != null && ciudad.isNotEmpty && ciudad != 'Todas las ciudades') {
          query = query.eq('Ciudad', ciudad);
        }
        if (genero != null && genero.isNotEmpty && genero != 'Todos') {
          query = query.ilike('Etiqueta', '%$genero%');
        }
        if (cineLocal != null && cineLocal.isNotEmpty && cineLocal != 'Todos los Cines') {
          query = query.eq('Cine', cineLocal);
        }
        return query.order('Titulo', ascending: true);
      },
      methodName: 'getPeliculas',
    );
  }

  /// Fetches a list of distinct city names that have cinemas.
  Future<List<String>> getDistinctCineCities() async {
    try {
      final response = await _supabaseClient.rpc('get_distinct_cine_cities');

      if (response is! List) {
        throw Exception("Invalid response format from RPC: expected a List.");
      }

      final cities = response
          .map((item) => (item as Map<String, dynamic>)['ciudad'] as String?)
          .whereType<String>()
          .toList();

      return cities;
    } catch (e) {
      rethrow;
    }
  }

  // --- Private Helper Methods ---

  /// Executes a Supabase select query and maps the result to a list of [PeliculaSupabase].
  Future<List<PeliculaSupabase>> _executeSelectQuery({
    required PostgrestBuilder Function(PostgrestFilterBuilder<List<Map<String, dynamic>>>) queryBuilder,
    required String methodName,
  }) async {
    try {
      final query = queryBuilder(_supabaseClient.from(_tableName).select('*, created_at'));
      final response = await query;

      if (response is! List) {
        throw Exception("Invalid response format: expected a List.");
      }

      final peliculas = response
          .map((json) => PeliculaSupabase.fromJson(json as Map<String, dynamic>))
          .toList();

      return peliculas;
    } catch (e) {
      rethrow;
    }
  }
}
