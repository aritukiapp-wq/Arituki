/// Gestiona la lógica y el estado para la ordenación de eventos.
///
/// Este provider permite a los usuarios seleccionar un criterio de ordenación
/// (como fecha o título) y una dirección (ascendente o descendente). Luego,
/// proporciona una función para ordenar una lista de eventos según la
/// configuración seleccionada.
library;
import 'package:flutter/foundation.dart';
import 'package:arituki/models/event_supabase.dart';

/// Defines the criteria available for sorting events.
enum EventSortCriteria {
  date, // Sort by date and time
  title, // Sort by title
}

/// Manages the state for event sorting logic.
class EventSortProvider with ChangeNotifier {
  EventSortCriteria _currentSortCriteria = EventSortCriteria.date;
  bool _isAscending = true;

  EventSortCriteria get currentSortCriteria => _currentSortCriteria;
  bool get isAscending => _isAscending;

  /// Sets the sort order and notifies listeners if there is a change.
  void setSortOrder(EventSortCriteria criteria, bool ascending) {
    if (_currentSortCriteria == criteria && _isAscending == ascending) {
      return; // No change, no need to notify
    }

    _currentSortCriteria = criteria;
    _isAscending = ascending;
    
    notifyListeners();
  }

  /// Sorts a list of events based on the current sort criteria and direction.
  List<EventoSupabase> sortEvents(List<EventoSupabase> events) {
    if (events.isEmpty) return [];

    List<EventoSupabase> sortedEvents = List.from(events);

    sortedEvents.sort((a, b) {
      int comparisonResult;

      switch (_currentSortCriteria) {
        case EventSortCriteria.date:
          comparisonResult = _compareByDate(a, b);
          break;
        case EventSortCriteria.title:
          comparisonResult = _compareByTitle(a, b);
          break;
      }

      return _isAscending ? comparisonResult : -comparisonResult;
    });

    return sortedEvents;
  }

  /// Compares two events by their title.
  int _compareByTitle(EventoSupabase a, EventoSupabase b) {
    final titleA = a.titulo?.toLowerCase() ?? '';
    final titleB = b.titulo?.toLowerCase() ?? '';
    return titleA.compareTo(titleB);
  }

  /// Compares two events by their date and time.
  int _compareByDate(EventoSupabase a, EventoSupabase b) {
    final dateA = a.dia;
    final dateB = b.dia;

    if (dateA == null && dateB == null) return 0;
    if (dateA == null) return 1; // Nulls are considered greater
    if (dateB == null) return -1;

    int comparison = dateA.compareTo(dateB);
    if (comparison != 0) return comparison;

    // If dates are the same, compare by time
    final timeA = a.hora;
    final timeB = b.hora;

    if (timeA == null || timeA.isEmpty) return 1;
    if (timeB == null || timeB.isEmpty) return -1;

    // Direct string comparison is safe and robust if format is consistent (HH:mm:ss)
    return timeA.compareTo(timeB);
  }
}
