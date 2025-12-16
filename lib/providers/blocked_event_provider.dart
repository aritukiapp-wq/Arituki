/// Gestiona el estado de los eventos bloqueados por el usuario.
///
/// Este provider se encarga de:
/// - Mantener una lista de los eventos que el usuario ha decidido bloquear.
/// - Persistir esta lista en `SharedPreferences` para que la decisión se mantenga entre sesiones.
/// - Proveer métodos para bloquear, desbloquear y verificar si un evento está bloqueado.
/// - Limpiar automáticamente los eventos bloqueados que ya han pasado.
/// - Registrar eventos de analítica cuando un usuario bloquea un evento.
library;

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arituki/providers/favorite_event_provider.dart';
import 'package:arituki/services/analytics_service.dart';

/// Modelo para representar un evento bloqueado.
class BlockedEvent {
  final String id;
  final String eventName;
  final DateTime blockingDate;
  final String? cityName;
  final String? placeName;

  BlockedEvent({
    required this.id,
    required this.eventName,
    required this.blockingDate,
    this.cityName,
    this.placeName,
  });

  factory BlockedEvent.fromJson(Map<String, dynamic> json) {
    return BlockedEvent(
      id: json['id'] as String,
      eventName: json['eventName'] as String? ?? json['title'] as String? ?? 'Evento sin título',
      blockingDate: DateTime.parse(json['date'] as String),
      cityName: json['cityName'] as String?,
      placeName: json['placeName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'eventName': eventName,
      'date': blockingDate.toIso8601String(),
      'cityName': cityName,
      'placeName': placeName,
    };
  }
}

class BlockedEventProvider with ChangeNotifier {
  final SharedPreferences _prefs;
  final AnalyticsService _analyticsService;

  static const _kBlockedEventsKey = 'blocked_events_v4';

  // --- Internal State ---
  bool _isLoading = false;
  String? _error;
  List<BlockedEvent> _blockedEvents = [];

  BlockedEventProvider({
    required SharedPreferences prefs,
    required AnalyticsService analyticsService,
  })  : _prefs = prefs,
        _analyticsService = analyticsService {
    _loadBlockedEvents();
  }

  // --- Public Getters ---
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<BlockedEvent> get blockedEvents => _blockedEvents;

  bool isEventBlocked(String eventId) {
    return _blockedEvents.any((event) => event.id == eventId);
  }

  Future<void> toggleBlockedEvent({
    required String eventId,
    required FavoriteEventProvider favoriteEventProvider,
    DateTime? eventDate,
    String? eventName,
    String? cityName,
    String? placeName,
  }) async {
    await _executeTask(() async {
      final index = _blockedEvents.indexWhere((event) => event.id == eventId);
      final isCurrentlyBlocked = index != -1;

      if (isCurrentlyBlocked) {
        _blockedEvents.removeAt(index);
      } else {
        _blockedEvents.add(BlockedEvent(
          id: eventId,
          eventName: eventName ?? 'Evento sin título',
          blockingDate: eventDate ?? DateTime.now(),
          cityName: cityName,
          placeName: placeName,
        ));
        await favoriteEventProvider.removeFavoriteEventById(eventId);
      }

      // Log del evento de analítica con el nuevo método
      await _analyticsService.logEventBlockToggle(
        eventName: eventName ?? 'Evento sin título',
        isBlocked: !isCurrentlyBlocked, // Si no estaba bloqueado, ahora lo está (y viceversa)
      );
    });
  }

  Future<void> removeBlockedEventById(String eventId) async {
    final initialLength = _blockedEvents.length;
    _blockedEvents.removeWhere((event) => event.id == eventId);

    if (_blockedEvents.length < initialLength) {
      await _executeTask(() async {}, notify: true);
    }
  }

  Future<void> _loadBlockedEvents() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final blockedEventsString = _prefs.getString(_kBlockedEventsKey);
      if (blockedEventsString != null) {
        final List<dynamic> decodedList = jsonDecode(blockedEventsString);
        _blockedEvents = decodedList
            .whereType<Map<String, dynamic>>()
            .map((item) => BlockedEvent.fromJson(item))
            .toList();
      }
      await _clearPastEvents();
    } catch (e) {
      _error = "Error al cargar eventos bloqueados.";
      _blockedEvents = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _executeTask(Future<void> Function() task, {bool notify = true}) async {
    _error = null;
    try {
      await task();
      final List<Map<String, dynamic>> encodedList = _blockedEvents.map((e) => e.toJson()).toList();
      await _prefs.setString(_kBlockedEventsKey, jsonEncode(encodedList));
      if (notify) {
        notifyListeners();
      }
    } catch (e) {
      _error = "Ocurrió un error al guardar los cambios.";
      if (notify) {
        notifyListeners();
      }
    }
  }

  Future<void> _clearPastEvents() async {
    final today = DateTime.now();
    final todayDateOnly = DateTime(today.year, today.month, today.day);

    _blockedEvents.removeWhere((event) {
      return event.blockingDate.isBefore(todayDateOnly);
    });
  }
}
