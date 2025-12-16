/// Gestiona el estado de la pantalla de detalle de un evento.
///
/// Este provider se encarga de:
/// - Mantener el estado del evento que se está mostrando actualmente, que puede
///   ser el evento inicial o una de sus otras "ocurrencias" (si es un evento recurrente).
/// - Cargar los datos de interacción del usuario (likes/dislikes) para el evento.
/// - Registrar el evento de analítica cuando se visualiza la pantalla.
library;

import 'package:flutter/foundation.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/providers/event_interaction_provider.dart';
import 'package:arituki/repositories/event_repository.dart';
import 'package:arituki/services/analytics_service.dart';

class EventDetailProvider with ChangeNotifier {
  final EventoSupabase _initialEvent;
  final EventInteractionProvider _interactionProvider;
  final AnalyticsService _analyticsService;
  final EventRepository _eventRepository;

  // --- Internal State ---
  EventoSupabase? _selectedOccurrence;
  List<EventoSupabase> _allOccurrences = [];
  bool _isLoading = false;
  String? _error;

  EventDetailProvider({
    required EventoSupabase initialEvent,
    required EventInteractionProvider interactionProvider,
    required AnalyticsService analyticsService,
    required EventRepository eventRepository,
  })  : _initialEvent = initialEvent,
        _interactionProvider = interactionProvider,
        _analyticsService = analyticsService,
        _eventRepository = eventRepository;

  // --- Public Getters ---
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  /// Returns the event that should be currently displayed in the UI.
  EventoSupabase get displayEvent => _selectedOccurrence ?? _initialEvent;
  
  /// Returns all available occurrences for the event.
  List<EventoSupabase> get allOccurrences => _allOccurrences;

  /// Initializes the provider by loading necessary data.
  Future<void> initialize() async {
    await _executeTask(() async {
      // Tareas iniciales
      final interactionFuture = _interactionProvider.ensureEventDataLoaded(_initialEvent.id);
      _analyticsService.logEventDetailView(
        eventName: _initialEvent.titulo ?? 'N/A',
        placeName: _initialEvent.lugar,
        cityName: _initialEvent.ciudad,
      );

      // Búsqueda de eventos recurrentes
      Future<List<EventoSupabase>> occurrencesFuture;
      if (_initialEvent.titulo != null && _initialEvent.titulo!.isNotEmpty) {
        occurrencesFuture = _eventRepository.fetchEventsByTitle(_initialEvent.titulo!);
      } else {
        occurrencesFuture = Future.value([_initialEvent]);
      }
      
      // Esperar a que ambas tareas terminen
      final results = await Future.wait([interactionFuture, occurrencesFuture]);
      
      final occurrences = results[1] as List<EventoSupabase>;

      if (occurrences.isNotEmpty) {
        occurrences.sort((a, b) => (a.dia ?? DateTime(0)).compareTo(b.dia ?? DateTime(0)));
        _allOccurrences = occurrences;
      } else {
        _allOccurrences = [_initialEvent];
      }
    });
  }

  /// Selects a different occurrence of the same event.
  void selectOccurrence(EventoSupabase newOccurrence) {
    if (newOccurrence.id == displayEvent.id) return;

    _selectedOccurrence = newOccurrence;
    // No es necesario recargar toda la lista de ocurrencias.
    // Solo cargamos los datos de interacción para la nueva selección.
    _executeTask(() async {
      await _interactionProvider.ensureEventDataLoaded(newOccurrence.id);
    });
    notifyListeners();
  }

  /// A generic wrapper for executing tasks that involve loading and error states.
  Future<void> _executeTask(Future<void> Function() task) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await task();
    } catch (e) {
      _error = "Se ha producido un error.";
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
