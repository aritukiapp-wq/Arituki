/// Orquesta la presentación final de la lista de eventos a la UI.
///
/// Este es un "meta-provider" que actúa como el director de orquesta para la
/// lista de eventos. Escucha a los providers de obtención de datos (`EventFetchingProvider`),
/// filtrado (`EventFilterProvider`), ordenación (`EventSortProvider`) y bloqueo
/// (`BlockedEventProvider`), y combina sus resultados para producir la lista
/// final de eventos que se debe mostrar al usuario.
///
/// Su principal responsabilidad es recalcular la lista de eventos presentada
/// cada vez que uno de sus proveedores dependientes notifica un cambio.
library;
import 'package:flutter/foundation.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/providers/event_fetching_provider.dart';
import 'package:arituki/providers/event_filter_provider.dart';
import 'package:arituki/providers/event_sort_provider.dart';
import 'package:arituki/providers/blocked_event_provider.dart';

class EventPresentationProvider with ChangeNotifier {
  EventFetchingProvider _fetchingProvider;
  EventFilterProvider _filterProvider;
  EventSortProvider _sortProvider;
  BlockedEventProvider _blockedEventProvider;

  List<EventoSupabase> _presentedEvents = [];
  List<String> _uniquePlaceNames = [];

  EventPresentationProvider({
    required EventFetchingProvider fetchingProvider,
    required EventFilterProvider filterProvider,
    required EventSortProvider sortProvider,
    required BlockedEventProvider blockedEventProvider,
  })
      : _fetchingProvider = fetchingProvider,
        _filterProvider = filterProvider,
        _sortProvider = sortProvider,
        _blockedEventProvider = blockedEventProvider {
    _addListeners();
    _processEvents();
  }

  // --- Public Getters ---
  List<EventoSupabase> get presentedEvents => _presentedEvents;
  List<String> get uniqueFilteredPlaceNames => _uniquePlaceNames;
  bool get isLoadingInitial => _fetchingProvider.isLoadingInitial;
  bool get isLoadingMore => _fetchingProvider.isLoadingMore;
  String get errorMessage => _fetchingProvider.errorMessage ?? '';
  bool get hasMoreEvents => _fetchingProvider.hasMoreEvents;
  bool get isAnyEventLoaded => _fetchingProvider.isAnyEventLoaded;

  // --- Delegated Methods ---
  Future<void> refreshEvents() => _fetchingProvider.refreshEvents();
  Future<void> loadMoreEvents() => _fetchingProvider.loadMoreEvents();
  void updateSearchQuery(String query) => _filterProvider.updateSearchQuery(query);
  void updateDateFilter(String? dateFilterName) => _filterProvider.updateDateFilter(dateFilterName);
  void updatePlaceFilter(String? placeValue) => _filterProvider.updatePlaceFilter(placeValue);

  @override
  void dispose() {
    _removeListeners();
    super.dispose();
  }

  /// Updates the provider's dependencies and re-processes the event list.
  void updateDependencies({
    required EventFetchingProvider newFetchingProvider,
    required EventFilterProvider newFilterProvider,
    required EventSortProvider newSortProvider,
    required BlockedEventProvider newBlockedEventProvider,
  }) {
    final needsUpdate = _fetchingProvider != newFetchingProvider ||
        _filterProvider != newFilterProvider ||
        _sortProvider != newSortProvider ||
        _blockedEventProvider != newBlockedEventProvider;

    if (needsUpdate) {
      _removeListeners();
      _fetchingProvider = newFetchingProvider;
      _filterProvider = newFilterProvider;
      _sortProvider = newSortProvider;
      _blockedEventProvider = newBlockedEventProvider;
      _addListeners();
      _processEvents();
    }
  }

  void _addListeners() {
    _fetchingProvider.addListener(_processEvents);
    _filterProvider.addListener(_processEvents);
    _sortProvider.addListener(_processEvents);
    _blockedEventProvider.addListener(_processEvents);
  }

  void _removeListeners() {
    _fetchingProvider.removeListener(_processEvents);
    _filterProvider.removeListener(_processEvents);
    _sortProvider.removeListener(_processEvents);
    _blockedEventProvider.removeListener(_processEvents);
  }

  /// The core logic for processing and presenting events.
  /// This method is the heart of the provider, orchestrating all data transformations.
  void _processEvents() {
    final allEvents = _fetchingProvider.allEvents;

    // 1. First, determine the list of available place names based on the raw, unfiltered data.
    final unblockedEvents = allEvents.where((e) => !_blockedEventProvider.isEventBlocked(e.id)).toList();
    _uniquePlaceNames = _extractUniquePlaceNames(unblockedEvents);

    // 2. Check if the currently selected place filter is still valid. If not, clear it.
    final selectedPlace = _filterProvider.selectedPlaceFilterValue;
    bool wasFilterReset = false;
    if (selectedPlace != null && !_uniquePlaceNames.contains(selectedPlace)) {
      _filterProvider.updatePlaceFilter(null, notify: false); // Update without notifying listeners yet
      wasFilterReset = true;
    }

    // 3. Apply all filters (including the potentially reset place filter).
    List<EventoSupabase> filteredEvents = _filterProvider.applyFilters(allEvents);

    // 4. Exclude blocked events from the final list.
    filteredEvents.removeWhere((event) => _blockedEventProvider.isEventBlocked(event.id));

    // 5. Sort the filtered events.
    final sortedEvents = _sortProvider.sortEvents(filteredEvents);

    // 6. Update the state and notify listeners.
    if (!listEquals(_presentedEvents, sortedEvents) || wasFilterReset) {
      _presentedEvents = sortedEvents;
    }
    
    notifyListeners();
  }

  /// Extracts a sorted list of unique place names from a list of events.
  List<String> _extractUniquePlaceNames(List<EventoSupabase> events) {
    final placeNames = events
        .map((event) => event.lugar?.trim())
        .whereType<String>() // Filters out nulls and ensures the type is non-nullable
        .where((lugar) => lugar.isNotEmpty) // Further filter out empty strings
        .toSet()
        .toList();

    placeNames.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    return placeNames;
  }
}
