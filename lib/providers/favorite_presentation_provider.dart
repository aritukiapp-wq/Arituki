/// Orquesta la presentación de la sección de "Favoritos".
///
/// Este provider combina datos de dos fuentes de favoritos distintas:
/// 1.  **Eventos de Lugares Favoritos**: Escucha a `FavoritePlaceProvider` y, cuando
///     cambia, busca todos los eventos futuros que ocurren en esos lugares.
/// 2.  **Eventos Individuales Favoritos**: Escucha a `FavoriteEventProvider` y, cuando
///     cambia, busca los detalles completos de cada evento marcado como favorito.
///
/// Se encarga de la lógica de carga, el manejo de errores y la presentación
/// de ambas listas de eventos a la UI de la sección de Favoritos.
library;
import 'package:flutter/foundation.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/repositories/event_repository.dart';
import 'package:arituki/providers/favorite_place_provider.dart';
import 'package:arituki/providers/favorite_event_provider.dart';

class FavoritesPresentationProvider with ChangeNotifier {
  final EventRepository _eventRepository;
  FavoritePlaceProvider? _favoritePlaceProvider;
  FavoriteEventProvider? _favoriteEventProvider;

  bool _isLoadingPlaces = true;
  String _placesErrorMessage = '';
  List<EventoSupabase> _eventsFromFavoritePlaces = [];

  bool _isLoadingEvents = true;
  String _eventsErrorMessage = '';
  List<EventoSupabase> _favoriteEventDetails = [];

  FavoritesPresentationProvider(this._eventRepository);

  bool get isLoadingPlaces => _isLoadingPlaces;
  String get placesErrorMessage => _placesErrorMessage;
  List<EventoSupabase> get eventsFromFavoritePlaces => _eventsFromFavoritePlaces;

  bool get isLoadingEvents => _isLoadingEvents;
  String get eventsErrorMessage => _eventsErrorMessage;
  List<EventoSupabase> get favoriteEventDetails => _favoriteEventDetails;

  void updateDependencies({
    required FavoritePlaceProvider favoritePlaceProvider,
    required FavoriteEventProvider favoriteEventProvider,
  }) {
    if (_favoritePlaceProvider != favoritePlaceProvider) {
      _favoritePlaceProvider?.removeListener(_onFavoritePlacesChanged);
      _favoritePlaceProvider = favoritePlaceProvider;
      _favoritePlaceProvider?.addListener(_onFavoritePlacesChanged);
      _loadEventsFromFavoritePlaces();
    }

    if (_favoriteEventProvider != favoriteEventProvider) {
      _favoriteEventProvider?.removeListener(_onFavoriteEventsChanged);
      _favoriteEventProvider = favoriteEventProvider;
      _favoriteEventProvider?.addListener(_onFavoriteEventsChanged);
      _loadFavoriteEventDetails();
    }
  }

  @override
  void dispose() {
    _favoritePlaceProvider?.removeListener(_onFavoritePlacesChanged);
    _favoriteEventProvider?.removeListener(_onFavoriteEventsChanged);
    super.dispose();
  }

  void _onFavoritePlacesChanged() {
    _loadEventsFromFavoritePlaces();
  }

  void _onFavoriteEventsChanged() {
    _loadFavoriteEventDetails();
  }

  Future<void> _loadEventsFromFavoritePlaces() async {
    if (_favoritePlaceProvider == null) return;

    _isLoadingPlaces = true;
    _placesErrorMessage = '';
    notifyListeners();

    final Set<String> favoritePlaceNames = _favoritePlaceProvider!.favoritePlaces.map((p) => p.name).toSet();

    if (favoritePlaceNames.isEmpty) {
      _eventsFromFavoritePlaces = [];
      _isLoadingPlaces = false;
      notifyListeners();
      return;
    }

    try {
      final fetchedEvents = await _eventRepository.fetchEventsByExactPlaceNames(favoritePlaceNames.toList());
      fetchedEvents.sort((a, b) => (a.dia ?? DateTime(0)).compareTo(b.dia ?? DateTime(0)));
      _eventsFromFavoritePlaces = fetchedEvents;
    } catch (e) {
      _placesErrorMessage = 'Error al cargar eventos de lugares favoritos.';
    } finally {
      _isLoadingPlaces = false;
      notifyListeners();
    }
  }

  Future<void> _loadFavoriteEventDetails() async {
    if (_favoriteEventProvider == null) return;

    _isLoadingEvents = true;
    _eventsErrorMessage = '';
    notifyListeners();

    final favoriteEventIds = _favoriteEventProvider!.favoriteEvents.map((e) => e.id).toList();

    if (favoriteEventIds.isEmpty) {
      _favoriteEventDetails = [];
      _isLoadingEvents = false;
      notifyListeners();
      return;
    }

    try {
      final fetchedEvents = await _eventRepository.fetchEventsByIds(favoriteEventIds);
      final hoy = DateTime.now();
      final ayer = DateTime(hoy.year, hoy.month, hoy.day - 1);
      fetchedEvents.removeWhere((evento) => evento.diaFin != null && evento.diaFin!.isBefore(ayer));
      fetchedEvents.sort((a, b) => (a.dia ?? DateTime(0)).compareTo(b.dia ?? DateTime(0)));
      _favoriteEventDetails = fetchedEvents;
    } catch (e) {
      _eventsErrorMessage = 'Error al cargar los detalles de los eventos favoritos.';
    } finally {
      _isLoadingEvents = false;
      notifyListeners();
    }
  }
}
