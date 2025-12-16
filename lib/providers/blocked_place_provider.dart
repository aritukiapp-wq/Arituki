/// Gestiona el estado de los lugares (recintos) bloqueados por el usuario.
///
/// Este provider se encarga de:
/// - Mantener una lista de los lugares que el usuario ha decidido bloquear.
/// - Persistir esta lista en `SharedPreferences` para que la decisión se mantenga entre sesiones.
/// - Proveer métodos para bloquear, desbloquear y verificar si un lugar está bloqueado.
/// - Registrar eventos de analítica cuando un usuario bloquea un lugar.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arituki/services/analytics_service.dart';

/// Modelo para representar un lugar bloqueado.
class BlockedPlace {
  final String name;
  final DateTime blockingDate;
  final String? cityName;

  BlockedPlace({
    required this.name,
    required this.blockingDate,
    this.cityName,
  });

  factory BlockedPlace.fromJson(Map<String, dynamic> json) {
    return BlockedPlace(
      name: json['name'] as String,
      blockingDate: DateTime.parse(json['blockingDate'] as String),
      cityName: json['cityName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'blockingDate': blockingDate.toIso8601String(),
      'cityName': cityName,
    };
  }
}

class BlockedPlaceProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final AnalyticsService _analyticsService;

  static const _kBlockedPlacesKey = 'blocked_places_v2'; // Clave actualizada para evitar conflictos con la versión anterior

  List<BlockedPlace> _blockedPlaces = [];

  BlockedPlaceProvider({
    required SharedPreferences prefs,
    required AnalyticsService analyticsService,
  })
      : _prefs = prefs,
        _analyticsService = analyticsService {
    _loadBlockedPlaces();
  }

  /// A read-only view of the list of blocked places.
  List<BlockedPlace> get blockedPlaces => List.unmodifiable(_blockedPlaces);

  /// Checks if a specific place is marked as blocked.
  bool isPlaceBlocked(String placeName) {
    return _blockedPlaces.any((place) => place.name == placeName);
  }

  /// Toggles a place's blocked status and persists the change.
  Future<void> toggleBlockedStatus(String placeName, {String? cityName}) async {
    final index = _blockedPlaces.indexWhere((place) => place.name == placeName);
    final isCurrentlyBlocked = index != -1;

    if (isCurrentlyBlocked) {
      // Si ya está, lo quitamos (desbloquear)
      _blockedPlaces.removeAt(index);
    } else {
      // Si no está, lo añadimos (bloquear)
      _blockedPlaces.add(BlockedPlace(
        name: placeName,
        blockingDate: DateTime.now(),
        cityName: cityName,
      ));
    }

    // Log del evento de analítica con el nuevo método unificado
    await _analyticsService.logPlaceBlockToggle(
      placeName: placeName,
      isBlocked: !isCurrentlyBlocked, // El nuevo estado es el opuesto al anterior
    );

    await _saveAndNotify();
  }

  /// Loads the list of blocked places from local storage.
  void _loadBlockedPlaces() {
    try {
      final String? blockedListJson = _prefs.getString(_kBlockedPlacesKey);
      if (blockedListJson != null) {
        final List<dynamic> decodedList = jsonDecode(blockedListJson);
        _blockedPlaces = decodedList.map((item) => BlockedPlace.fromJson(item)).toList();
      }
    } catch (e) {
      _blockedPlaces = []; // In case of error, start with an empty list
    }
    notifyListeners();
  }

  /// Saves the current list of blocked places to SharedPreferences and notifies listeners.
  Future<void> _saveAndNotify() async {
    try {
      final List<Map<String, dynamic>> encodedList = _blockedPlaces.map((place) => place.toJson()).toList();
      await _prefs.setString(_kBlockedPlacesKey, jsonEncode(encodedList));
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
