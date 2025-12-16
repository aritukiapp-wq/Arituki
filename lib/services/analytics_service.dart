/// Servicio de analítica que abstrae la implementación de Firebase Analytics.
///
/// Esta clase centraliza todos los eventos de analítica de la aplicación.
/// Permite registrar acciones del usuario como vistas de detalle, interacciones
/// con favoritos, uso de filtros y clics en enlaces, entre otros.
library;

import 'package:firebase_analytics/firebase_analytics.dart';

class AnalyticsService {
  final FirebaseAnalytics _analytics;

  AnalyticsService(this._analytics);

  // --- Vistas de Pantalla ---
  Future<void> logScreenView(String screenName) async {
    await _analytics.logScreenView(screenName: screenName);
  }

  // --- Navegación e Interacciones UI Generales ---
  Future<void> logBottomNavBarTapped({required String itemName}) async {
    await _analytics.logEvent(name: 'ui_bottom_nav_tap', parameters: _sanitize({'item': itemName}));
  }

  // --- Vistas de Detalle ---
  Future<void> logEventDetailView({required String eventName, String? placeName, String? cityName}) async {
    await _analytics.logEvent(name: 'view_event_detail', parameters: _sanitize({'name': eventName, 'place': placeName, 'city': cityName}));
  }

  Future<void> logProgramaDetailView({required String programaName}) async {
    await _analytics.logEvent(name: 'view_programa_detail', parameters: _sanitize({'name': programaName}));
  }

  Future<void> logGastroDetailView({required String jornadaName}) async {
    await _analytics.logEvent(name: 'view_gastro_detail', parameters: _sanitize({'name': jornadaName}));
  }
  
  Future<void> logGastroProgramaView({required String programaName}) async {
    await _analytics.logEvent(name: 'view_gastro_programa', parameters: _sanitize({'name': programaName}));
  }

  // --- Clics en Enlaces ---
  Future<void> logEventLinkClick({required String eventName, required String linkType}) async {
    await _analytics.logEvent(name: 'click_event_link', parameters: _sanitize({'name': eventName, 'type': linkType}));
  }

  Future<void> logProgramaLinkClick({required String programaName, required String linkType}) async {
    await _analytics.logEvent(name: 'click_programa_link', parameters: _sanitize({'name': programaName, 'type': linkType}));
  }

  Future<void> logCineTicketLinkClick({required String movieTitle, required String cinemaName}) async {
    await _analytics.logEvent(name: 'click_cine_ticket', parameters: _sanitize({'movie': movieTitle, 'cinema': cinemaName}));
  }

  Future<void> logGastroLinkClick({required String jornadaName, required String linkType}) async {
    await _analytics.logEvent(name: 'click_gastro_link', parameters: _sanitize({'name': jornadaName, 'type': linkType}));
  }

  // --- Interacciones de Favoritos y Bloqueos ---
  Future<void> logEventFavoriteToggle({required String eventName, required bool isFavorite}) async {
    await _analytics.logEvent(name: 'toggle_event_favorite', parameters: _sanitize({'name': eventName, 'is_favorite': isFavorite.toString()}));
  }

  Future<void> logPlaceFavoriteToggle({required String placeName, required bool isFavorite}) async {
    await _analytics.logEvent(name: 'toggle_place_favorite', parameters: _sanitize({'name': placeName, 'is_favorite': isFavorite.toString()}));
  }

  Future<void> logEventBlockToggle({required String eventName, required bool isBlocked}) async {
    await _analytics.logEvent(name: 'toggle_event_block', parameters: _sanitize({'name': eventName, 'is_blocked': isBlocked.toString()}));
  }

  Future<void> logPlaceBlockToggle({required String placeName, required bool isBlocked}) async {
    await _analytics.logEvent(name: 'toggle_place_block', parameters: _sanitize({'name': placeName, 'is_blocked': isBlocked.toString()}));
  }

  // --- Interacciones con Likes/Dislikes ---
  Future<void> logEventInteraction({required String eventName, required String interaction}) async {
    await _analytics.logEvent(name: 'interact_event', parameters: _sanitize({'name': eventName, 'interaction': interaction}));
  }

  // --- Filtros y Búsqueda ---
  Future<void> logSearch({required String searchTerm}) async {
    if (searchTerm.isNotEmpty) {
      await _analytics.logSearch(searchTerm: searchTerm);
    }
  }

  Future<void> logFilterChange({required String filterType, required String value}) async {
    await _analytics.logEvent(name: 'change_filter', parameters: _sanitize({'type': filterType, 'value': value}));
  }

  Future<void> logLocationFilterChange({
    required String filterType, // 'comunidad', 'provincia', 'ciudad'
    String? comunidad,
    String? province,
    List<String>? cities,
  }) async {
    await _analytics.logEvent(
      name: 'change_location_filter',
      parameters: _sanitize({
        'type': filterType,
        'comunidad': comunidad,
        'province': province,
        'cities': cities?.join(','),
      }),
    );
  }

  // --- Utilidad privada para sanitizar parámetros ---
  Map<String, Object> _sanitize(Map<String, Object?> parameters) {
    final sanitized = <String, Object>{};
    parameters.forEach((key, value) {
      if (value is String && value.length > 100) {
        sanitized[key] = value.substring(0, 100);
      } else if (value != null) {
        sanitized[key] = value;
      }
    });
    return sanitized;
  }
}
