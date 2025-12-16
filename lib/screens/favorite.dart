/// Pantalla de Favoritos, que muestra los eventos y lugares guardados por el usuario.
///
/// Esta pantalla utiliza un `TabBar` para separar dos vistas:
/// 1.  **Eventos Favoritos**: Muestra una lista de los eventos individuales que el
///     usuario ha marcado como favoritos.
/// 2.  **Lugares Favoritos**: Muestra una lista de todos los eventos que ocurren en
///     los lugares que el usuario ha marcado como favoritos.
///
/// También proporciona acceso a diálogos para ver y gestionar los eventos y
/// lugares que han sido bloqueados.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/providers/favorite_presentation_provider.dart';
import 'package:arituki/providers/favorite_place_provider.dart';
import 'package:arituki/providers/favorite_event_provider.dart';
import 'package:arituki/providers/blocked_place_provider.dart';
import 'package:arituki/providers/blocked_event_provider.dart';
import 'package:arituki/widgets/event_card.dart';
import 'package:arituki/widgets/empty_state_view.dart';
import 'package:arituki/services/navigation_service.dart';
import 'package:arituki/utils/utils.dart' as utils;

class FavoriteEventsScreen extends StatelessWidget {
  const FavoriteEventsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Favoritos'),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(kToolbarHeight),
            child: Material(
              color: Theme.of(context).colorScheme.surface,
              child: TabBar(
                dividerColor: Colors.transparent, // Ocultamos el divisor por defecto para usar el nuestro
                tabs: [
                  // Pestaña de Eventos (Izquierda)
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.favorite),
                        const SizedBox(width: 8),
                        const Text('Eventos'),
                        const Spacer(),
                        IconButton(
                          icon: const Icon(Icons.block, size: 20.0),
                          tooltip: 'Eventos Bloqueados',
                          onPressed: () => _showBlockedEventsDialog(context),
                        ),
                      ],
                    ),
                  ),
                  // Pestaña de Lugares (Derecha) con divisor
                  Tab(
                    child: Container(
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: Colors.grey[300]!, width: 1.0)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.star),
                          const SizedBox(width: 8),
                          const Text('Lugares'),
                          const Spacer(),
                          IconButton(
                            icon: const Icon(Icons.block, size: 20.0),
                            tooltip: 'Lugares Bloqueados',
                            onPressed: () => _showBlockedPlacesDialog(context),
                          ),
                        ],
                      ), 
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          children: [
            _FavoriteEventsTab(), // Contenido de Eventos
            _FavoritePlacesTab(), // Contenido de Lugares
          ],
        ),
      ),
    );
  }
}


class _FavoritePlacesTab extends StatelessWidget {
  const _FavoritePlacesTab();

  @override
  Widget build(BuildContext context) {
    final presentationProvider = context.watch<FavoritesPresentationProvider>();
    final favEventProvider = context.watch<FavoriteEventProvider>();
    final favPlaceProvider = context.watch<FavoritePlaceProvider>();
    final blockedPlaceProvider = context.watch<BlockedPlaceProvider>();

    if (presentationProvider.isLoadingPlaces) {
      return const Center(child: CircularProgressIndicator());
    } else if (presentationProvider.placesErrorMessage.isNotEmpty) {
      return EmptyStateView(icon: Icons.error_outline, title: 'Error', message: presentationProvider.placesErrorMessage);
    } else if (presentationProvider.eventsFromFavoritePlaces.isEmpty) {
      return const EmptyStateView(icon: Icons.star_border, title: 'Sin lugares favoritos', message: 'Aún no has marcado ningún lugar como favorito.');
    } else {
      return ListView.builder(
        itemCount: presentationProvider.eventsFromFavoritePlaces.length,
        itemBuilder: (context, index) {
          final event = presentationProvider.eventsFromFavoritePlaces[index];
          return EventCard(
            event: event,
            isEventFavorite: favEventProvider.isEventFavorite(event.id),
            isPlaceFavorite: favPlaceProvider.isPlaceFavorite(event.lugar ?? ''),
            isPlaceBlocked: blockedPlaceProvider.isPlaceBlocked(event.lugar ?? ''),
            onTap: () => NavigationService.navigateToEventDetail(context, event),
            onFavoriteToggle: () => favEventProvider.toggleFavoriteEvent(eventId: event.id, eventName: event.titulo ?? '', cityName: event.ciudad ?? '', placeName: event.lugar ?? '', eventDate: event.dia, blockedEventProvider: context.read<BlockedEventProvider>()),
            onShowOptions: () => context.read<FavoritePlaceProvider>().removeFavoritePlace(event.lugar ?? ''),
          );
        },
      );
    }
  }
}

class _FavoriteEventsTab extends StatelessWidget {
  const _FavoriteEventsTab();

  @override
  Widget build(BuildContext context) {
    final presentationProvider = context.watch<FavoritesPresentationProvider>();
    final favEventProvider = context.watch<FavoriteEventProvider>();
    final favPlaceProvider = context.watch<FavoritePlaceProvider>();
    final blockedEventProvider = context.watch<BlockedEventProvider>();

    if (presentationProvider.isLoadingEvents) {
      return const Center(child: CircularProgressIndicator());
    } else if (presentationProvider.eventsErrorMessage.isNotEmpty) {
      return EmptyStateView(icon: Icons.error_outline, title: 'Error', message: presentationProvider.eventsErrorMessage);
    } else if (presentationProvider.favoriteEventDetails.isEmpty) {
      return const EmptyStateView(icon: Icons.favorite_border, title: 'Sin eventos favoritos', message: 'Aún no has marcado ningún evento como favorito.');
    } else {
      return ListView.builder(
        itemCount: presentationProvider.favoriteEventDetails.length,
        itemBuilder: (context, index) {
          final event = presentationProvider.favoriteEventDetails[index];
          return EventCard(
            event: event,
            isEventFavorite: favEventProvider.isEventFavorite(event.id),
            isEventBlocked: blockedEventProvider.isEventBlocked(event.id),
            isPlaceFavorite: favPlaceProvider.isPlaceFavorite(event.lugar ?? ''),
            onTap: () => NavigationService.navigateToEventDetail(context, event),
            onFavoriteToggle: () => favEventProvider.toggleFavoriteEvent(eventId: event.id, eventName: event.titulo ?? '', cityName: event.ciudad ?? '', placeName: event.lugar ?? '', eventDate: event.dia, blockedEventProvider: context.read<BlockedEventProvider>()),
            onShowOptions: () => _showFavoriteEventOptionsDialog(context, event),
          );
        },
      );
    }
  }
}

void _showFavoriteEventOptionsDialog(BuildContext context, EventoSupabase event) { /* Implementación original */ }

void _showBlockedPlacesDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        title: const Text('Lugares Bloqueados'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer<BlockedPlaceProvider>(
            builder: (context, provider, child) {
              if (provider.blockedPlaces.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No hay lugares bloqueados.')));
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: provider.blockedPlaces.length,
                itemBuilder: (context, index) {
                  final blockedPlace = provider.blockedPlaces[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    horizontalTitleGap: 8.0,
                    leading: IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.lock_open_outlined),
                      tooltip: 'Desbloquear',
                      onPressed: () => provider.toggleBlockedStatus(blockedPlace.name, cityName: blockedPlace.cityName),
                    ),
                    title: Text(blockedPlace.name, style: TextStyle(color: theme.colorScheme.onSurface)),
                    subtitle: Text(
                      "Bloqueado el ${utils.formatDate(blockedPlace.blockingDate, formatType: 'SHORT')}",
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [TextButton(child: const Text('Cerrar'), onPressed: () => Navigator.of(dialogContext).pop())],
      );
    },
  );
}

void _showBlockedEventsDialog(BuildContext context) {
  showDialog(
    context: context,
    builder: (BuildContext dialogContext) {
      final theme = Theme.of(dialogContext);
      return AlertDialog(
        title: const Text('Eventos Bloqueados'),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer<BlockedEventProvider>(
            builder: (context, provider, child) {
              if (provider.blockedEvents.isEmpty) {
                return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No hay eventos bloqueados.')));
              }
              return ListView.builder(
                shrinkWrap: true,
                itemCount: provider.blockedEvents.length,
                itemBuilder: (context, index) {
                  final blockedEvent = provider.blockedEvents[index];
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    horizontalTitleGap: 8.0,
                    leading: IconButton(
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.lock_open_outlined),
                      tooltip: 'Desbloquear',
                      onPressed: () {
                        provider.toggleBlockedEvent(
                          eventId: blockedEvent.id,
                          favoriteEventProvider: context.read<FavoriteEventProvider>(),
                        );
                      },
                    ),
                    title: Text(
                      blockedEvent.eventName,
                      style: TextStyle(color: theme.colorScheme.onSurface), // Color explícito para garantizar contraste
                    ),
                    subtitle: Text(
                      "Bloqueado el ${utils.formatDate(blockedEvent.blockingDate, formatType: 'SHORT')}",
                      style: theme.textTheme.bodySmall?.copyWith(fontSize: 12),
                    ),
                  );
                },
              );
            },
          ),
        ),
        actions: [TextButton(child: const Text('Cerrar'), onPressed: () => Navigator.of(dialogContext).pop())],
      );
    },
  );
}
