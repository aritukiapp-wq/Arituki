/// Gestiona el estado de los 'likes' para los eventos y la interacción del usuario.
///
/// Este provider se encarga de:
/// - Obtener y mantener el estado de 'like' de un usuario para un evento específico.
/// - Registrar y eliminar 'likes' a través del `LikeService`.
/// - Realizar actualizaciones optimistas de la UI para una respuesta instantánea.
/// - Mantener el recuento global de 'likes' para los eventos.
/// - Manejar el estado de carga y los errores durante las operaciones de 'like'.
library;
import 'package:flutter/foundation.dart';
import 'package:arituki/services/like_service.dart';

class LikeProvider with ChangeNotifier {
  final LikeService _likeService;
  final String? _currentUserId;

  String? get currentUserId => _currentUserId;

  final Map<String, String?> _userInteractions = {};
  final Map<String, int> _globalLikes = {};
  final Map<String, int> _globalDislikes = {};

  Map<String, String?> get userInteractions => Map.unmodifiable(_userInteractions);
  Map<String, int> get globalLikes => Map.unmodifiable(_globalLikes);
  Map<String, int> get globalDislikes => Map.unmodifiable(_globalDislikes);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  LikeProvider({
    required LikeService likeService,
    required String? currentUserId,
  })  : _likeService = likeService,
        _currentUserId = currentUserId;

  Future<void> _executeTask(Future<void> Function() task, {String? errorMessage}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await task();
    } catch (e) {
      _errorMessage = errorMessage ?? "Ocurrió un error inesperado.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadInitialInteractionAndCounts(String eventId) async {
    if (eventId.isEmpty) return;

    await _executeTask(() async {
      if (_currentUserId != null && _currentUserId.isNotEmpty) {
        final isLiked = await _likeService.isEventLikedByUser(eventId: eventId, userId: _currentUserId);
        _userInteractions[eventId] = isLiked ? 'like' : null;
      } else {
        _userInteractions[eventId] = null;
      }

      _globalLikes[eventId] = await _likeService.getLikeCountForEvent(eventId: eventId);
      _globalDislikes[eventId] = 0; // Assuming dislikes are not implemented yet

    }, errorMessage: "Error al cargar datos de interacción para el evento $eventId.");
  }

  Future<void> toggleLike(String eventId) async {
    await _toggleInteraction(eventId, 'like');
  }

  Future<void> _toggleInteraction(String eventId, String interactionType) async {
    if (eventId.isEmpty || (_currentUserId == null || _currentUserId.isEmpty)) {
      _errorMessage = "Debes iniciar sesión para interactuar.";
      notifyListeners();
      return;
    }

    final originalInteraction = _userInteractions[eventId];
    final originalLikes = _globalLikes[eventId] ?? 0;

    // Optimistic UI update
    _isLoading = true;
    _errorMessage = null;
    if (_userInteractions[eventId] == interactionType) {
      _userInteractions[eventId] = null;
      _globalLikes[eventId] = (originalLikes > 0) ? originalLikes - 1 : 0;
    } else {
      _userInteractions[eventId] = interactionType;
      _globalLikes[eventId] = originalLikes + 1;
    }
    notifyListeners();

    try {
      if (_userInteractions[eventId] == interactionType) {
        await _likeService.addLike(eventId: eventId, userId: _currentUserId);
      } else {
        await _likeService.removeLike(eventId: eventId, userId: _currentUserId);
      }
      // Fetch the accurate count from the server after the operation
      _globalLikes[eventId] = await _likeService.getLikeCountForEvent(eventId: eventId);
    } catch (e) {
      _errorMessage = "Error al procesar la interacción.";
      // Revert optimistic update
      _userInteractions[eventId] = originalInteraction;
      _globalLikes[eventId] = originalLikes;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearEventData(String eventId) {
    if (eventId.isEmpty) return;
    _userInteractions.remove(eventId);
    _globalLikes.remove(eventId);
    _globalDislikes.remove(eventId);
    notifyListeners();
  }
}
