/// Gestiona las interacciones del usuario con los eventos, como 'likes' y 'dislikes'.
///
/// Este provider centraliza la lógica para:
/// - Reflejar el estado de autenticación del usuario (`AuthProvider`).
/// - Cargar el estado de interacción (like/dislike) de un usuario para eventos específicos desde `LikeService`.
/// - Manejar las acciones de 'like' y 'dislike' con actualizaciones optimistas de la UI.
/// - Persistir las interacciones del usuario localmente usando `SharedPreferences` para mantener el estado entre sesiones.
/// - Registrar eventos de analítica para las interacciones.
/// - Sincronizar el recuento global de likes/dislikes desde el servicio.
library;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arituki/providers/auth_provider.dart';
import 'package:arituki/services/analytics_service.dart';
import 'package:arituki/services/like_service.dart';

class EventInteractionProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final AnalyticsService _analyticsService;
  final LikeService _likeService;

  // --- Internal State ---
  String? _currentUserId;
  Map<String, String?> _userInteractions = {}; // eventId -> 'like' or 'dislike'
  final Map<String, int> _globalLikes = {};
  final Map<String, int> _globalDislikes = {};
  bool _isLoading = false;
  String? _error;

  EventInteractionProvider({
    required SharedPreferences prefs,
    required AuthProvider authProvider,
    required AnalyticsService analyticsService,
    required LikeService likeService,
  })
      : _prefs = prefs,
        _analyticsService = analyticsService,
        _likeService = likeService {
    updateAuth(authProvider);
  }

  // --- Public Getters ---
  bool get isLoading => _isLoading;
  String? get error => _error;
  String? getInteractionForEvent(String eventId) => _userInteractions[eventId];
  int getLikesForEvent(String eventId) => _globalLikes[eventId] ?? 0;
  int getDislikesForEvent(String eventId) => _globalDislikes[eventId] ?? 0;

  /// Updates the provider's state when the authenticated user changes.
  void updateAuth(AuthProvider authProvider) {
    final newUserId = authProvider.currentUser?.id;
    if (_currentUserId != newUserId) {
      _currentUserId = newUserId;
      _loadUserInteractionsFromPrefs();
      _globalLikes.clear();
      _globalDislikes.clear();
      notifyListeners();
    }
  }

  /// Ensures that the interaction data for a given event is loaded.
  Future<void> ensureEventDataLoaded(String eventId) async {
    if (eventId.isEmpty || _globalLikes.containsKey(eventId)) return;
    await loadEventDataFromService(eventId);
  }

  /// Loads interaction data for a specific event from the remote service.
  Future<void> loadEventDataFromService(String eventId) async {
    if (eventId.isEmpty) return;

    _isLoading = true;
    _error = null;

    try {
      if (_currentUserId != null) {
        final isLiked = await _likeService.isEventLikedByUser(eventId: eventId, userId: _currentUserId!);
        if (isLiked) {
          _userInteractions[eventId] = 'like';
        } else {
          final isDisliked = await _likeService.isEventDislikedByUser(eventId: eventId, userId: _currentUserId!);
          if (isDisliked) _userInteractions[eventId] = 'dislike';
        }
      }
      _globalLikes[eventId] = await _likeService.getLikeCountForEvent(eventId: eventId);
      _globalDislikes[eventId] = await _likeService.getDislikeCountForEvent(eventId: eventId);
    } catch (e) {
      _error = "Error al cargar las interacciones.";
    } finally {
      _isLoading = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifyListeners();
      });
    }
  }

  /// Toggles a 'like' interaction for an event.
  Future<void> toggleLike(String eventId, String eventName, {String? placeName, String? cityName}) async {
    await _toggleInteraction('like', eventId, eventName, placeName: placeName, cityName: cityName);
  }

  /// Toggles a 'dislike' interaction for an event.
  Future<void> toggleDislike(String eventId, String eventName, {String? placeName, String? cityName}) async {
    await _toggleInteraction('dislike', eventId, eventName, placeName: placeName, cityName: cityName);
  }

  /// Centralized logic for toggling an interaction (like/dislike).
  Future<void> _toggleInteraction(String interaction, String eventId, String eventName, {String? placeName, String? cityName}) async {
    if (_currentUserId == null) {
      _error = "Debes iniciar sesión para interactuar.";
      notifyListeners();
      return;
    }

    final originalInteraction = _userInteractions[eventId];
    final isCurrentlyInteracted = originalInteraction == interaction;
    
    // Optimistic UI update
    _userInteractions[eventId] = isCurrentlyInteracted ? null : interaction;
    notifyListeners();

    try {
      if (isCurrentlyInteracted) {
        if (interaction == 'like') await _likeService.removeLike(eventId: eventId, userId: _currentUserId!);
        if (interaction == 'dislike') await _likeService.removeDislike(eventId: eventId, userId: _currentUserId!);
      } else {
        if (interaction == 'like') {
          await _likeService.addLike(eventId: eventId, userId: _currentUserId!);
          _analyticsService.logEventInteraction(eventName: eventName, interaction: 'like');
        }
        if (interaction == 'dislike') {
          await _likeService.addDislike(eventId: eventId, userId: _currentUserId!);
          _analyticsService.logEventInteraction(eventName: eventName, interaction: 'dislike');
        }
      }
      // Refresh data from server and save to local preferences
      await loadEventDataFromService(eventId);
      await _saveCurrentUserInteractions();
    } catch (e) {
      // Revert optimistic update on error
      _userInteractions[eventId] = originalInteraction;
      _error = "Error al procesar la interacción.";
      notifyListeners();
    }
  }

  // --- Persistence ---

  String _getUserInteractionsKey() => _currentUserId != null ? 'eventUserInteractions_$_currentUserId' : '';

  void _loadUserInteractionsFromPrefs() {
    if (_currentUserId == null) {
      _userInteractions = {};
      notifyListeners();
      return;
    }
    try {
      final interactionsJson = _prefs.getString(_getUserInteractionsKey());
      if (interactionsJson != null) {
        _userInteractions = Map<String, String?>.from(jsonDecode(interactionsJson));
      }
    } catch (e) {
      _userInteractions = {};
    }
    notifyListeners();
  }

  Future<void> _saveCurrentUserInteractions() async {
    if (_currentUserId == null) return;
    try {
      await _prefs.setString(_getUserInteractionsKey(), jsonEncode(_userInteractions));
    } catch (e) {
      rethrow;
    }
  }
}
