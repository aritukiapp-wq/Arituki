/// Servicio para gestionar las interacciones de los usuarios (likes/dislikes) con los eventos.
///
/// Esta clase se comunica directamente con Supabase para:
/// - Añadir y eliminar registros en la tabla `Likes`.
/// - Consultar si un usuario ha interactuado con un evento.
/// - Obtener el recuento total de 'likes' y 'dislikes' de la tabla `Eventos`,
///   que se actualiza mediante triggers en la base de datos.
library;
import 'package:supabase_flutter/supabase_flutter.dart';

class LikeService {
  final SupabaseClient _client;
  static const String _likesTable = 'Likes';
  static const String _eventsTable = 'Eventos';

  LikeService({required SupabaseClient supabaseClient}) : _client = supabaseClient;

  // --- Public API for Likes ---

  Future<void> addLike({required String eventId, required String userId}) =>
      _addInteraction(eventId: eventId, userId: userId, type: 'like');

  Future<void> removeLike({required String eventId, required String userId}) =>
      _removeInteraction(eventId: eventId, userId: userId, type: 'like');

  Future<bool> isEventLikedByUser({required String eventId, required String userId}) =>
      _isEventInteractedByUser(eventId: eventId, userId: userId, type: 'like');

  Future<int> getLikeCountForEvent({required String eventId}) =>
      _getInteractionCountForEvent(eventId: eventId, countColumn: 'likes_count');

  // --- Public API for Dislikes ---

  Future<void> addDislike({required String eventId, required String userId}) =>
      _addInteraction(eventId: eventId, userId: userId, type: 'dislike');

  Future<void> removeDislike({required String eventId, required String userId}) =>
      _removeInteraction(eventId: eventId, userId: userId, type: 'dislike');

  Future<bool> isEventDislikedByUser({required String eventId, required String userId}) =>
      _isEventInteractedByUser(eventId: eventId, userId: userId, type: 'dislike');

  Future<int> getDislikeCountForEvent({required String eventId}) =>
      _getInteractionCountForEvent(eventId: eventId, countColumn: 'dislikes_count');

  // --- Private Generic Implementations ---

  /// Removes any previous interaction (like or dislike) for a given user and event.
  Future<void> _clearPreviousInteraction({required String eventId, required String userId}) async {
    try {
      await _client
          .from(_likesTable)
          .delete()
          .match({'event_id': eventId, 'user_id': userId});
    } catch (e) {
      // Do not rethrow; the subsequent operation should still be attempted.
    }
  }

  /// Adds a new interaction of a specific type.
  Future<void> _addInteraction(
      {required String eventId, required String userId, required String type}) async {
    await _clearPreviousInteraction(eventId: eventId, userId: userId);
    try {
      await _client
          .from(_likesTable)
          .insert({'event_id': eventId, 'user_id': userId, 'interaction_type': type});
    } catch (e) {
      rethrow;
    }
  }

  /// Removes an interaction of a specific type.
  Future<void> _removeInteraction(
      {required String eventId, required String userId, required String type}) async {
    try {
      await _client
          .from(_likesTable)
          .delete()
          .match({'event_id': eventId, 'user_id': userId, 'interaction_type': type});
    } catch (e) {
      rethrow;
    }
  }

  /// Checks if a user has a specific interaction with an event.
  Future<bool> _isEventInteractedByUser(
      {required String eventId, required String userId, required String type}) async {
    try {
      final response = await _client
          .from(_likesTable)
          .select('id')
          .match({'event_id': eventId, 'user_id': userId, 'interaction_type': type})
          .limit(1);
      return response.isNotEmpty;
    } catch (e) {
      return false; // Assume no interaction on error
    }
  }

  /// Gets the total count of a specific interaction type for an event.
  Future<int> _getInteractionCountForEvent(
      {required String eventId, required String countColumn}) async {
    try {
      final response = await _client
          .from(_eventsTable)
          .select(countColumn)
          .eq('id', eventId)
          .single();
      return (response[countColumn] as int?) ?? 0;
    } catch (e) {
      return 0; // Return 0 on error
    }
  }
}
