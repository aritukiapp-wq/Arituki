/// El repositorio para gestionar las interacciones de 'likes' de los eventos.
///
/// Este repositorio actúa como una capa de abstracción sobre el `LikeService`,
/// desacoplando la lógica de la aplicación de la implementación específica del
/// servicio de datos. Proporciona métodos claros y específicos para las
/// operaciones relacionadas con los 'likes', como añadir, eliminar y contar likes,
/// y verificar el estado de un like para un usuario.
library;
import 'package:arituki/services/like_service.dart'; // Asegúrate que esta ruta sea correcta

class LikeRepository {
  final LikeService _likeService;

  LikeRepository({required LikeService likeService})
      : _likeService = likeService;

  /// Añade un "Me Gusta" a un evento para un usuario específico.
  Future<void> addLike(
      {required String eventId, required String userId}) async {
    try {
      await _likeService.addLike(eventId: eventId, userId: userId);
    } catch (e) {
      rethrow; // Re-lanza la excepción para que la UI o el Provider puedan manejarla
    }
  }

  /// Elimina un "Me Gusta" de un evento para un usuario específico.
  Future<void> removeLike(
      {required String eventId, required String userId}) async {
    try {
      await _likeService.removeLike(eventId: eventId, userId: userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Verifica si un evento específico ha sido marcado como "Me Gusta" por un usuario.
  Future<bool> isEventLikedByUser(
      {required String eventId, required String userId}) async {
    try {
      return await _likeService.isEventLikedByUser(
          eventId: eventId, userId: userId);
    } catch (e) {
      rethrow;
    }
  }

  /// Obtiene el conteo total de "Me Gusta" para un evento específico.
  Future<int> getLikeCountForEvent({required String eventId}) async {
    try {
      return await _likeService.getLikeCountForEvent(eventId: eventId);
    } catch (e) {
      rethrow;
    }
  }

// Si añades más métodos a LikeService (ej: fetchUserLikedEvents),
// deberías añadir los métodos correspondientes aquí que deleguen a _likeService.
// Ejemplo:
// Future<List<String>> fetchUserLikedEventIds({required String userId}) async {
//   try {
//     // Suponiendo que LikeService tiene un método así:
//     // return await _likeService.fetchUserLikedEventIds(userId: userId);
//     throw UnimplementedError('fetchUserLikedEventIds no implementado en LikeService aún');
//   } catch (e, stackTrace) {
//     rethrow;
//   }
// }
}