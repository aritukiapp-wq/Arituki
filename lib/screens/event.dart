/// Pantalla principal de la sección de Eventos.
///
/// Esta es la pantalla más importante de la aplicación. Muestra una lista de eventos
/// que se pueden filtrar y ordenar. Permite al usuario:
/// - Ver una lista paginada de eventos.
/// - Realizar búsquedas por texto.
/// - Aplicar filtros por fecha y lugar.
/// - Aplicar filtros jerárquicos de ubicación (Comunidad > Provincia > Ciudad).
/// - Marcar eventos como favoritos o bloquearlos mediante un gesto de deslizamiento (`Dismissible`).
/// - Acceder a opciones para un lugar (favorito/bloqueado) a través de un menú.
/// - Navegar a la pantalla de detalle de un evento, programa o jornada gastronómica.
///
/// Orquesta múltiples providers, siendo `EventPresentationProvider` el principal para
/// obtener la lista de eventos a mostrar.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arituki/models/event_supabase.dart';

// Providers
import 'package:arituki/providers/location_filter_provider.dart';
import 'package:arituki/providers/event_presentation_provider.dart';
import 'package:arituki/providers/favorite_place_provider.dart';
import 'package:arituki/providers/blocked_place_provider.dart';
import 'package:arituki/providers/favorite_event_provider.dart';
import 'package:arituki/providers/blocked_event_provider.dart';
import 'package:arituki/providers/event_filter_provider.dart';

// Widgets
import 'package:arituki/widgets/event_card.dart';
import 'package:arituki/widgets/event_chipchoice.dart';
import 'package:arituki/widgets/location_filters_app_bar_panel.dart';
import 'package:arituki/widgets/empty_state_view.dart';
import 'package:arituki/widgets/app_bar.dart';
import 'package:arituki/theme/app_theme.dart';

// Screens for navigation
import 'package:arituki/screens/event_detail.dart';
import 'package:arituki/screens/programas_programa.dart';
import 'package:arituki/screens/gastro_programa.dart';

class EventScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;

  const EventScreen({super.key, required this.scaffoldKey});

  @override
  State<EventScreen> createState() => _EventScreenState();
}

class _EventScreenState extends State<EventScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isAppBarFiltersPanelVisible = false;

  @override
  void initState() {
    super.initState();
    final presentationProvider = context.read<EventPresentationProvider>();
    _searchController.addListener(() => presentationProvider.updateSearchQuery(_searchController.text));
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.9) {
        presentationProvider.loadMoreEvents();
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) => presentationProvider.refreshEvents());
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
  
  void _navigateToDetail(BuildContext context, EventoSupabase event) {
    if (event.categoria == 'Programa') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ProgramaProgramaScreen(programa: event),
        ),
      );
    } else if (event.categoria == 'Gastronomia') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => GastronomiaProgramaScreen(jornada: event),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => EventDetailPage(event: event),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentationProvider = context.watch<EventPresentationProvider>();
    final locationProvider = context.watch<LocationFilterProvider>();

    String? cityNameToShow;
    if (locationProvider.selectedEventCities.length == 1) {
      cityNameToShow = locationProvider.selectedEventCities.first;
    }

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Eventos',
        cityNameToShow: cityNameToShow,
        isFilterPanelVisible: _isAppBarFiltersPanelVisible,
        onFilterPressed: () => setState(() => _isAppBarFiltersPanelVisible = !_isAppBarFiltersPanelVisible),
        onMenuPressed: () => widget.scaffoldKey.currentState?.openDrawer(),
        bottomWidget: _isAppBarFiltersPanelVisible
            ? PreferredSize(
                preferredSize: const Size.fromHeight(200.0),
                child: LocationFiltersAppBarPanel(screenType: ActiveFilterScreenType.eventosEtc),
              )
            : null,
      ),
      body: GestureDetector(
        onTap: () {
          FocusManager.instance.primaryFocus?.unfocus();
        },
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16.0, 8.0, 16.0, 0.0),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Buscar por título o lugar...',
                  prefixIcon: const Icon(Icons.search, size: AppTheme.kSearchIconSize),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: AppTheme.kSearchIconSize),
                          onPressed: () {
                            _searchController.clear();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                        )
                      : null,
                ),
              ),
            ),
            const SizedBox(height: 8.0),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16.0),
              child: EventFilterChipsCombined(),
            ),
            Expanded(
              child: _buildContent(context, presentationProvider),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(BuildContext context, EventPresentationProvider presentationProvider) {
    if (presentationProvider.isLoadingInitial && presentationProvider.presentedEvents.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (presentationProvider.errorMessage.isNotEmpty && presentationProvider.presentedEvents.isEmpty) {
      return EmptyStateView(
        icon: Icons.error_outline,
        title: 'Error al cargar eventos',
        message: presentationProvider.errorMessage,
        actionButton: ElevatedButton.icon(
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          onPressed: () => presentationProvider.refreshEvents(),
        ),
      );
    }

    if (presentationProvider.presentedEvents.isEmpty && presentationProvider.isAnyEventLoaded) {
      return EmptyStateView(
        icon: Icons.sentiment_dissatisfied_outlined,
        title: "No hay eventos que coincidan",
        message: "Prueba a cambiar los filtros o la búsqueda.",
        actionButton: ElevatedButton.icon(
          icon: const Icon(Icons.filter_alt_off_outlined),
          label: const Text('Limpiar filtros'),
          onPressed: () {
            context.read<EventFilterProvider>().resetAllFilters();
            _searchController.clear();
          },
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => presentationProvider.refreshEvents(),
      child: ListView.builder(
        controller: _scrollController,
        itemCount: presentationProvider.presentedEvents.length + (presentationProvider.isLoadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == presentationProvider.presentedEvents.length) {
            return const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()));
          }
          final event = presentationProvider.presentedEvents[index];
          
          return Dismissible(
            key: ValueKey(event.id),
            background: Container(
              color: Colors.green,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerLeft,
              child: const Row(mainAxisAlignment: MainAxisAlignment.start, children: [Icon(Icons.star, color: Colors.white), SizedBox(width: 8), Text('Favorito', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))]),
            ),
            secondaryBackground: Container(
              color: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              alignment: Alignment.centerRight,
              child: const Row(mainAxisAlignment: MainAxisAlignment.end, children: [Text('Bloquear', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)), SizedBox(width: 8), Icon(Icons.block, color: Colors.white)]),
            ),
            confirmDismiss: (direction) async {
              if (direction == DismissDirection.startToEnd) {
                await context.read<FavoriteEventProvider>().toggleFavoriteEvent(
                      eventId: event.id,
                      eventName: event.titulo ?? '',
                      cityName: event.ciudad ?? '',
                      placeName: event.lugar ?? '',
                      eventDate: event.dia,
                      blockedEventProvider: context.read<BlockedEventProvider>(),
                    );
                return false;
              } else {
                return true; // Permitir el dismiss para bloquear
              }
            },
            onDismissed: (direction) {
              if (direction == DismissDirection.endToStart) {
                context.read<BlockedEventProvider>().toggleBlockedEvent(
                      eventId: event.id,
                      eventDate: event.dia,
                      eventName: event.titulo,
                      cityName: event.ciudad,
                      placeName: event.lugar,
                      favoriteEventProvider: context.read<FavoriteEventProvider>(),
                    );
              }
            },
            child: EventCard(
              event: event,
              isEventFavorite: context.watch<FavoriteEventProvider>().isEventFavorite(event.id),
              isPlaceFavorite: context.watch<FavoritePlaceProvider>().isPlaceFavorite(event.lugar ?? ''),
              onTap: () => _navigateToDetail(context, event),
              onFavoriteToggle: () => context.read<FavoriteEventProvider>().toggleFavoriteEvent(
                eventId: event.id,
                eventName: event.titulo ?? '',
                cityName: event.ciudad ?? '',
                placeName: event.lugar ?? '',
                eventDate: event.dia,
                blockedEventProvider: context.read<BlockedEventProvider>(),
              ),
              onShowOptions: () => _showPlaceOptionsDialog(context, event),
            ),
          );
        },
      ),
    );
  }

  void _showPlaceOptionsDialog(BuildContext context, EventoSupabase event) {
    final placeId = event.lugar;
    if (placeId == null || placeId.isEmpty) return;

    showDialog(
      context: context,
      builder: (dialogContext) {
        final theme = Theme.of(dialogContext);
        final favProvider = context.read<FavoritePlaceProvider>();
        final blockedProvider = context.read<BlockedPlaceProvider>();
        return AlertDialog(
          title: Text(event.lugar!),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              ListTile(
                leading: Icon(favProvider.isPlaceFavorite(placeId) ? Icons.star : Icons.star_border),
                title: Text(favProvider.isPlaceFavorite(placeId) ? 'Quitar de favoritos' : 'Añadir a favoritos'),
                iconColor: favProvider.isPlaceFavorite(placeId) ? Colors.amber : theme.colorScheme.onSurface.withAlpha(179),
                textColor: theme.colorScheme.onSurface,
                onTap: () {
                  favProvider.toggleFavoriteStatus(placeId, cityName: event.ciudad);
                  Navigator.of(dialogContext).pop();
                },
              ),
              ListTile(
                leading: Icon(blockedProvider.isPlaceBlocked(placeId) ? Icons.block : Icons.block_outlined),
                title: Text(blockedProvider.isPlaceBlocked(placeId) ? 'Desbloquear lugar' : 'Bloquear este lugar'),
                iconColor: blockedProvider.isPlaceBlocked(placeId) ? theme.colorScheme.error : theme.colorScheme.onSurface.withAlpha(179),
                textColor: theme.colorScheme.onSurface,
                onTap: () {
                  blockedProvider.toggleBlockedStatus(placeId, cityName: event.ciudad);
                  Navigator.of(dialogContext).pop();
                },
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(child: const Text('Cerrar'), onPressed: () => Navigator.of(dialogContext).pop()),
          ],
        );
      },
    );
  }
}
