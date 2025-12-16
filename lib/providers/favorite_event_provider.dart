/// Gestiona el estado de los eventos marcados como favoritos por el usuario.
///
/// Este provider se encarga de:
/// - Mantener una lista de los eventos que el usuario ha añadido a favoritos.
/// - Persistir esta lista en `SharedPreferences` para mantenerla entre sesiones.
/// - Proveer métodos para añadir, eliminar y verificar si un evento es favorito.
/// - Limpiar automáticamente los eventos favoritos que ya han pasado.
/// - Registrar eventos de analítica cuando un usuario marca un evento como favorito.
library;
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arituki/providers/blocked_event_provider.dart';
import 'package:arituki/services/analytics_service.dart';

/// Modelo para representar un evento favorito.
class FavoriteEvent {
  final String id;
  final String eventName;
  final DateTime addedDate;
  final String? cityName;
  final String? placeName;

  FavoriteEvent({
    required this.id,
    required this.eventName,
    required this.addedDate,
    this.cityName,
    this.placeName,
  });

  factory FavoriteEvent.fromJson(Map<String, dynamic> json) {
    return FavoriteEvent(
      id: json['id'] as String,
      eventName: json['eventName'] as String? ?? 'Evento sin título',
      addedDate: DateTime.parse(json['date'] as String),
      cityName: json['cityName'] as String?,
      placeName: json['placeName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventName': eventName,
      'date': addedDate.toIso8601String(),
      'cityName': cityName,
      'placeName': placeName,
    };
  }
}

class FavoriteEventProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final AnalyticsService _analyticsService;

  static const _kFavoriteEventsKey = 'favorite_events_v3'; // Key actualizada

  // --- Internal State ---
  List<FavoriteEvent> _favoriteEvents = [];

  FavoriteEventProvider({
    required SharedPreferences prefs,
    required AnalyticsService analyticsService,
  })
      : _prefs = prefs,
        _analyticsService = analyticsService {
    _loadFavoriteEvents();
  }

  // --- Public Getters ---
  List<FavoriteEvent> get favoriteEvents => _favoriteEvents;

  bool isEventFavorite(String eventId) {
    return _favoriteEvents.any((event) => event.id == eventId);
  }

  Future<void> toggleFavoriteEvent({
    required String eventId,
    required String eventName,
    required String cityName,
    required String placeName,
    required BlockedEventProvider blockedEventProvider,
    DateTime? eventDate,
  }) async {
    await _executeTask(() async {
      final index = _favoriteEvents.indexWhere((event) => event.id == eventId);
      final isCurrentlyFavorite = index != -1;

      if (isCurrentlyFavorite) {
        _favoriteEvents.removeAt(index);
      } else {
        _favoriteEvents.add(FavoriteEvent(
          id: eventId,
          eventName: eventName,
          addedDate: eventDate ?? DateTime.now(),
          cityName: cityName,
          placeName: placeName,
        ));
        await blockedEventProvider.removeBlockedEventById(eventId);
      }

      await _analyticsService.logEventFavoriteToggle(
        eventName: eventName,
        isFavorite: !isCurrentlyFavorite,
      );
    });
  }

  Future<void> removeFavoriteEventById(String eventId) async {
    final initialLength = _favoriteEvents.length;
    _favoriteEvents.removeWhere((event) => event.id == eventId);

    if (_favoriteEvents.length < initialLength) {
      await _executeTask(() async {}, notify: true);
    }
  }

  Future<void> _loadFavoriteEvents() async {
    try {
      final favoriteEventsString = _prefs.getString(_kFavoriteEventsKey);
      if (favoriteEventsString != null) {
        final List<dynamic> decodedList = jsonDecode(favoriteEventsString);
        _favoriteEvents = decodedList
            .whereType<Map<String, dynamic>>()
            .map((item) => FavoriteEvent.fromJson(item))
            .toList();
      }
      await _clearPastEvents();
    } catch (e) {
      _favoriteEvents = [];
    }
    notifyListeners();
  }

  Future<void> _executeTask(Future<void> Function() task, {bool notify = true}) async {
    try {
      await task();
      final favoriteEventsString = jsonEncode(_favoriteEvents.map((e) => e.toJson()).toList());
      await _prefs.setString(_kFavoriteEventsKey, favoriteEventsString);
      if (notify) {
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _clearPastEvents() async {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    _favoriteEvents.removeWhere((event) {
      return event.addedDate.isBefore(todayDateOnly.subtract(const Duration(days: 30))); // Cleanup after 30 days
    });
  }
}
