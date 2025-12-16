/// Pantalla de detalle para un evento, mostrando toda su información.
///
/// Esta pantalla es fundamental y presenta los detalles completos de un evento,
/// incluyendo:
/// - Título, subtítulo, imagen y descripción.
/// - Información práctica como lugar, fecha, hora, precio y edad recomendada.
/// - Botones de acción para comprar entradas, ver más información o acceder a mapas.
/// - Una sección de interacción para que los usuarios puedan dar "like" o "dislike".
/// - Un diálogo para ver otras fechas del mismo evento si es un evento recurrente.
///
/// Utiliza `EventDetailProvider` para gestionar el estado de la pantalla, como la
/// selección de una ocurrencia diferente del evento y la carga de datos de interacción.
library;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/providers/event_detail_provider.dart';
import 'package:arituki/providers/event_interaction_provider.dart';
import 'package:arituki/repositories/event_repository.dart';
import 'package:arituki/services/analytics_service.dart';

import 'package:arituki/widgets/event_dialog_multidate.dart';
import 'package:arituki/screens/event_fullscreen_image.dart';
import 'package:arituki/utils/utils.dart' as utils;

class EventDetailPage extends StatelessWidget {
  final EventoSupabase event;

  const EventDetailPage({super.key, required this.event});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<EventDetailProvider>(
      create: (context) => EventDetailProvider(
        initialEvent: event,
        interactionProvider: context.read<EventInteractionProvider>(),
        analyticsService: context.read<AnalyticsService>(),
        eventRepository: context.read<EventRepository>(),
      ),
      child: Consumer<EventDetailProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Scaffold(
              appBar: AppBar(),
              body: const Center(child: CircularProgressIndicator()),
            );
          }
          return _EventDetailView(event: provider.displayEvent);
        },
      ),
    );
  }
}

class _EventDetailView extends StatelessWidget {
  final EventoSupabase event;

  const _EventDetailView({required this.event});

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<EventDetailProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          event.titulo ?? 'Detalle del Evento',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeaderImage(context, event),
            const SizedBox(height: 24.0),
            _buildHeaderTitles(context, event),
            const SizedBox(height: 24.0),
            _buildDetailsSection(context, event, provider.allOccurrences),
            const SizedBox(height: 24.0),
            _buildActionButtons(context, event),
            const SizedBox(height: 24.0),
            Center(child: _buildLikeDislikeSection(context, event)),
            const SizedBox(height: 24.0),
            _buildDescriptionSection(context, event),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderImage(BuildContext context, EventoSupabase eventData) {
    if (eventData.imageUrl == null || eventData.imageUrl!.isEmpty) {
      return const SizedBox.shrink();
    }
    return GestureDetector(
      onTap: () => Navigator.push(
          context, MaterialPageRoute(builder: (_) => FullscreenImagePage(imageUrl: eventData.imageUrl!, tag: eventData.imageUrl!))),
      child: Hero(
        tag: eventData.imageUrl!,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12.0),
          child: Image.network(eventData.imageUrl!, width: double.infinity, height: 250, fit: BoxFit.cover, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, size: 48)),
        ),
      ),
    );
  }

  Widget _buildHeaderTitles(BuildContext context, EventoSupabase eventData) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(eventData.titulo ?? 'Sin Título', style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: theme.colorScheme.primary)),
        if (eventData.subtitulo != null && eventData.subtitulo!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4.0),
            child: Text(eventData.subtitulo!, style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary, fontStyle: FontStyle.italic)),
          ),
      ],
    );
  }

  Widget _buildDetailsSection(BuildContext context, EventoSupabase eventData, List<EventoSupabase> allOccurrences) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailSectionTitle(context, 'Detalles del Evento'),
        if (eventData.lugar != null && eventData.lugar!.isNotEmpty) _buildDetailRow(context, Icons.location_on_outlined, 'Lugar:', eventData.lugar!),
        _buildDateRow(context, eventData, allOccurrences),
        if (eventData.fechaInscripIni != null || eventData.fechaInscripFin != null)
          _buildDetailRow(context, Icons.edit_calendar_outlined, 'Inscripción:',
              utils.formatEventDates(eventData.fechaInscripIni, eventData.fechaInscripFin, null)),
        if (eventData.precio != null && eventData.precio!.isNotEmpty) _buildDetailRow(context, Icons.sell_outlined, 'Precio:', eventData.precio!),
        if (eventData.edad != null && eventData.edad!.isNotEmpty) _buildDetailRow(context, Icons.face_outlined, 'Edad:', eventData.edad!),
      ],
    );
  }

  Widget _buildDateRow(BuildContext context, EventoSupabase eventData, List<EventoSupabase> allOccurrences) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.calendar_today_outlined, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 12.0),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyLarge,
                children: <TextSpan>[
                  const TextSpan(text: "Fecha: ", style: TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: utils.formatEventDates(eventData.dia, eventData.diaFin, eventData.hora)),
                ],
              ),
            ),
          ),
          if (allOccurrences.length > 1)
            IconButton(
              icon: const Icon(Icons.calendar_month_outlined),
              tooltip: 'Ver otras fechas',
              onPressed: () => _showOccurrencesDialog(context, allOccurrences, eventData),
            ),
        ],
      ),
    );
  }

  void _showOccurrencesDialog(BuildContext context, List<EventoSupabase> allOccurrences, EventoSupabase currentEvent) async {
    final selectedEvent = await showDialog<EventoSupabase>(
      context: context,
      builder: (BuildContext dialogContext) {
        return EventDialogMultidate(
          eventTitle: currentEvent.titulo ?? 'Evento',
          eventDates: allOccurrences,
          selectedEventId: currentEvent.id,
        );
      },
    );
    if (selectedEvent != null && context.mounted) {
      context.read<EventDetailProvider>().selectOccurrence(selectedEvent);
    }
  }

  Widget _buildActionButtons(BuildContext context, EventoSupabase eventData) {
    final theme = Theme.of(context);
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
    );

    final buttons = <Widget>[];
    if (eventData.ticketUrl != null) buttons.add(ElevatedButton.icon(icon: const Icon(Icons.confirmation_number_outlined), label: const Text('Entradas'), onPressed: () => _showTicketConfirmationDialog(context, eventData), style: buttonStyle));
    if (eventData.eventoUrl != null) buttons.add(ElevatedButton.icon(icon: const Icon(Icons.info_outline), label: const Text('Más Info'), onPressed: () => _launchUrl(context, eventData, eventData.eventoUrl, 'mas_info'), style: buttonStyle));
    if (eventData.googleMapsUrl != null) buttons.add(ElevatedButton.icon(icon: const Icon(Icons.map_outlined), label: const Text('Mapa'), onPressed: () => _launchUrl(context, eventData, eventData.googleMapsUrl, 'maps'), style: buttonStyle));
    if (eventData.programaUrl != null) buttons.add(ElevatedButton.icon(icon: const Icon(Icons.article_outlined), label: const Text('Programa'), onPressed: () => _launchUrl(context, eventData, eventData.programaUrl, 'programa'), style: buttonStyle));

    if (buttons.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        const double typicalButtonWidth = 130.0;
        final bool canFitInRow = (buttons.length * typicalButtonWidth) < constraints.maxWidth;

        if (canFitInRow && !kIsWeb) {
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: buttons.map((button) => Flexible(child: button)).toList(),
          );
        } else {
          return Wrap(
            alignment: WrapAlignment.center,
            spacing: 8.0,
            runSpacing: 8.0,
            children: buttons,
          );
        }
      },
    );
  }

  void _showTicketConfirmationDialog(BuildContext context, EventoSupabase event) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          title: const Text('Comprar entradas'),
          content: const Text('Estás a punto de salir de la aplicación para comprar las entradas. ¿Quieres continuar?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
              },
            ),
            TextButton(
              child: const Text('Continuar'),
              onPressed: () {
                Navigator.of(dialogContext).pop();
                _launchUrl(context, event, event.ticketUrl, 'entradas');
              },
            ),
          ],
        );
      },
    );
  }

  Future<void> _launchUrl(BuildContext context, EventoSupabase event, String? urlString, String linkType) async {
    if (urlString == null) return;
    final Uri? url = Uri.tryParse(urlString);
    
    final analyticsService = context.read<AnalyticsService>();
    analyticsService.logEventLinkClick(
      eventName: event.titulo ?? 'N/A',
      linkType: linkType,
    );

    if (!context.mounted) return;
    final messenger = ScaffoldMessenger.of(context);

    if (url != null && await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if(context.mounted){
          messenger.showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $urlString')),
        );
      }
    }
  }

  Widget _buildLikeDislikeSection(BuildContext context, EventoSupabase eventData) {
    final theme = Theme.of(context);
    final interactionProvider = context.watch<EventInteractionProvider>();
    final userInteraction = interactionProvider.getInteractionForEvent(eventData.id);
    final likes = interactionProvider.getLikesForEvent(eventData.id);
    final dislikes = interactionProvider.getDislikesForEvent(eventData.id);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        InkWell(
          onTap: () {
            context.read<EventInteractionProvider>().toggleLike(
                  eventData.id,
                  eventData.titulo ?? 'N/A',
                  placeName: eventData.lugar,
                  cityName: eventData.ciudad,
                );
          },
          borderRadius: BorderRadius.circular(24.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Row(
              children: [
                Icon(
                  userInteraction == 'like' ? Icons.thumb_up : Icons.thumb_up_outlined,
                  color: userInteraction == 'like' ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8.0),
                Text(likes.toString(), style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16.0),
        InkWell(
          onTap: () {
            context.read<EventInteractionProvider>().toggleDislike(
                  eventData.id,
                  eventData.titulo ?? 'N/A',
                  placeName: eventData.lugar,
                  cityName: eventData.ciudad,
                );
          },
          borderRadius: BorderRadius.circular(24.0),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
            child: Row(
              children: [
                Icon(
                  userInteraction == 'dislike' ? Icons.thumb_down : Icons.thumb_down_outlined,
                  color: userInteraction == 'dislike' ? theme.colorScheme.error : theme.colorScheme.onSurface,
                ),
                const SizedBox(width: 8.0),
                Text(dislikes.toString(), style: theme.textTheme.bodyLarge),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection(BuildContext context, EventoSupabase eventData) {
    if (eventData.sinopsis == null || eventData.sinopsis!.trim().isEmpty) {
      return const SizedBox.shrink();
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDetailSectionTitle(context, 'Descripción'),
        Text(eventData.sinopsis!, style: Theme.of(context).textTheme.bodyLarge),
      ],
    );
  }

  Widget _buildDetailSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 12.0),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyLarge,
                children: <TextSpan>[
                  TextSpan(text: "$label ", style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
