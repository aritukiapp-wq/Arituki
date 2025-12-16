/// Gestiona el estado de los lugares (recintos) favoritos del usuario.
///
/// Este provider se encarga de:
/// - Mantener una lista de los lugares que el usuario ha marcado como favoritos.
/// - Persistir esta lista en `SharedPreferences`.
/// - Proveer un método para añadir o quitar lugares de la lista de favoritos.
/// - Registrar eventos de analítica cuando un usuario gestiona sus lugares favoritos.
library;

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arituki/services/analytics_service.dart';

/// Modelo para representar un lugar favorito.
class FavoritePlace {
  final String name;
  final DateTime addedDate;
  final String? cityName;

  FavoritePlace({
    required this.name,
    required this.addedDate,
    this.cityName,
  });

  factory FavoritePlace.fromJson(Map<String, dynamic> json) {
    return FavoritePlace(
      name: json['name'] as String,
      addedDate: DateTime.parse(json['addedDate'] as String),
      cityName: json['cityName'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'addedDate': addedDate.toIso8601String(),
      'cityName': cityName,
    };
  }
}

class FavoritePlaceProvider extends ChangeNotifier {
  final SharedPreferences _prefs;
  final AnalyticsService _analyticsService;

  static const _kFavoritePlacesKey = 'favorite_places_v2'; // Clave actualizada

  List<FavoritePlace> _favoritePlaces = [];

  FavoritePlaceProvider({
    required SharedPreferences prefs,
    required AnalyticsService analyticsService,
  })
      : _prefs = prefs,
        _analyticsService = analyticsService {
    _loadFavoritePlaces();
  }

  /// A read-only view of the list of favorite places.
  List<FavoritePlace> get favoritePlaces => List.unmodifiable(_favoritePlaces);

  /// Checks if a specific place is marked as a favorite.
  bool isPlaceFavorite(String placeName) {
    return _favoritePlaces.any((place) => place.name == placeName);
  }

  /// Toggles a place's favorite status and persists the change.
  Future<void> toggleFavoriteStatus(String placeName, {String? cityName}) async {
    final index = _favoritePlaces.indexWhere((place) => place.name == placeName);
    final isCurrentlyFavorite = index != -1;

    if (isCurrentlyFavorite) {
      _favoritePlaces.removeAt(index);
    } else {
      _favoritePlaces.add(FavoritePlace(
        name: placeName,
        addedDate: DateTime.now(),
        cityName: cityName,
      ));
    }

    // Log del evento de analítica con el nuevo método unificado
    await _analyticsService.logPlaceFavoriteToggle(
      placeName: placeName,
      isFavorite: !isCurrentlyFavorite,
    );

    await _saveAndNotify();
  }
  
  /// Mantenido por retrocompatibilidad temporal con la UI de favoritos.
  Future<void> removeFavoritePlace(String placeName) async {
    await toggleFavoriteStatus(placeName);
  }

  /// Loads the list of favorite places from local storage.
  void _loadFavoritePlaces() {
    try {
      final String? favoriteListJson = _prefs.getString(_kFavoritePlacesKey);
      if (favoriteListJson != null) {
        final List<dynamic> decodedList = jsonDecode(favoriteListJson);
        _favoritePlaces = decodedList.map((item) => FavoritePlace.fromJson(item as Map<String, dynamic>)).toList();
      }
    } catch (e) {
      _favoritePlaces = []; // In case of error, start with an empty list
    }
    notifyListeners();
  }

  /// Saves the current list of favorite places to SharedPreferences and notifies listeners.
  Future<void> _saveAndNotify() async {
    try {
      final List<Map<String, dynamic>> encodedList = _favoritePlaces.map((place) => place.toJson()).toList();
      await _prefs.setString(_kFavoritePlacesKey, jsonEncode(encodedList));
      notifyListeners();
    } catch (e) {
      rethrow;
    }
  }
}
