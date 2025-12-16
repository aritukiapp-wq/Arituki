/// Servicio para gestionar los datos de los programas de fiestas desde Supabase.
///
/// Esta clase se encarga de obtener los programas principales de fiestas,
/// filtrados por ubicación, así como los eventos o actos individuales que
/// componen un programa específico.
library;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:arituki/models/event_supabase.dart';

class ProgramaService {
  final SupabaseClient _supabaseClient;
  final String _tableName = 'Eventos';

  ProgramaService({required SupabaseClient supabaseClient}) : _supabaseClient = supabaseClient;

  /// Fetches main programs based on location filters.
  Future<List<EventoSupabase>> getProgramasPrincipales({
    String? comunidad,
    String? provincia,
    String? ciudad,
  }) async {
    PostgrestFilterBuilder query = _supabaseClient
        .from(_tableName)
        .select('*, created_at')
        .eq('Categoria', 'Programa');

    if (comunidad != null && comunidad.isNotEmpty) {
      query = query.eq('Comunidad', comunidad);
    }
    if (provincia != null && provincia.isNotEmpty) {
      query = query.eq('Provincia', provincia);
    }
    if (ciudad != null && ciudad.isNotEmpty) {
      query = query.eq('Ciudad', ciudad);
    }

    final orderedQuery = query.order('DiaFin', ascending: true, nullsFirst: false);
    return _executeAndMapQuery(orderedQuery, 'getProgramasPrincipales');
  }

  /// Fetches all items belonging to a parent program.
  Future<List<EventoSupabase>> getItemsDelPrograma({
    required String tituloProgramaPadre,
  }) async {
    if (tituloProgramaPadre.isEmpty) return [];

    final query = _supabaseClient
        .from(_tableName)
        .select('*, created_at')
        .eq('Categoria', tituloProgramaPadre)
        .order('DiaFin', ascending: true, nullsFirst: false)
        .order('Hora', ascending: true);

    return _executeAndMapQuery(query, 'getItemsDelPrograma');
  }

  /// Helper to execute a query and map the results to a list of EventoSupabase.
  Future<List<EventoSupabase>> _executeAndMapQuery(
    dynamic query,
    String methodName,
  ) async {
    try {
      final response = await query;
      
      final items = (response as List)
          .map((item) => EventoSupabase.fromJson(item as Map<String, dynamic>))
          .toList();

      return items;
    } catch (e) {
      rethrow;
    }
  }
}
