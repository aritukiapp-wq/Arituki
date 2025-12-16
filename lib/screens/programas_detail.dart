/// Pantalla de detalle para un acto o evento individual dentro de un programa.
///
/// Esta pantalla es similar a `EventDetailPage`, pero está diseñada específicamente
/// para mostrar los detalles de un evento que forma parte de un programa de fiestas
/// más grande. Muestra información como el título, descripción, fecha, hora,
/// lugar y precio. También incluye botones de acción para comprar entradas o
/// ver más información si los enlaces están disponibles.
library;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/screens/event_fullscreen_image.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'package:arituki/services/analytics_service.dart';

class ProgramaDetailScreen extends StatefulWidget {
  final EventoSupabase actuacion;

  const ProgramaDetailScreen({
    super.key,
    required this.actuacion,
  });

  @override
  State<ProgramaDetailScreen> createState() => _ProgramaDetailScreenState();
}

class _ProgramaDetailScreenState extends State<ProgramaDetailScreen> {
  late AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _analyticsService = Provider.of<AnalyticsService>(context, listen: false);
      _analyticsService.logProgramaDetailView(
        programaName: widget.actuacion.titulo ?? 'N/A',
      );
    });
  }

  Future<void> _launchUrl(BuildContext context, String? urlString, String linkType) async {
    if (urlString == null || urlString.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay enlace disponible.')),
        );
      }
      return;
    }

    _analyticsService.logProgramaLinkClick(
      programaName: widget.actuacion.titulo ?? 'N/A',
      linkType: linkType,
    );

    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No se pudo abrir el enlace: $urlString')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;

    final String titulo = widget.actuacion.titulo?.isNotEmpty == true
        ? widget.actuacion.titulo!
        : (widget.actuacion.subtitulo?.isNotEmpty == true
            ? widget.actuacion.subtitulo!
            : 'Detalle del Evento');

    final String sinopsis =
        widget.actuacion.sinopsis ?? 'No hay descripción disponible.';
    final String? imagenUrl = widget.actuacion.imageUrl;
    final String? lugar = widget.actuacion.lugar;
    final String? horaActuacion = widget.actuacion.hora;
    final DateTime? diaActuacion = widget.actuacion.diaIni ?? widget.actuacion.dia;
    final String? precio = widget.actuacion.precio;
    final String? ticketUrl = widget.actuacion.ticketUrl;
    final String? eventoUrl = widget.actuacion.eventoUrl;
    final String? programaUrl = widget.actuacion.programaUrl;
    final String? mapsUrl = widget.actuacion.googleMapsUrl;
    final String? edad = widget.actuacion.edad;
    final String? duracion = widget.actuacion.duracion;
    final String? ciudad = widget.actuacion.ciudad;
    final String? provincia = widget.actuacion.provincia;

    final String detailImageHeroTag = 'detailImage_${widget.actuacion.id}';

    String fechaFormateada = 'Fecha no especificada';
    if (diaActuacion != null) {
      try {
        fechaFormateada =
            DateFormat('EEEE, d MMMM y', 'es_ES').format(diaActuacion);
      } catch (e) {
        fechaFormateada =
            "${diaActuacion.day}/${diaActuacion.month}/${diaActuacion.year}";
      }
    }

    final ButtonStyle elevatedButtonStyle = ElevatedButton.styleFrom(
      backgroundColor: colorScheme.primary,
      foregroundColor: colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      textStyle: textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
    );

    List<Widget> actionButtons = [];
    if (ticketUrl != null && ticketUrl.isNotEmpty) {
      actionButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.confirmation_number_outlined),
            label: const Text('Entradas'),
            onPressed: () => _launchUrl(context, ticketUrl, 'entradas'),
            style: elevatedButtonStyle,
          ),
        ),
      );
    }
    if (eventoUrl != null && eventoUrl.isNotEmpty) {
      actionButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.info_outline),
            label: const Text('Más Info'),
            onPressed: () => _launchUrl(context, eventoUrl, 'mas_info'),
            style: elevatedButtonStyle,
          ),
        ),
      );
    }
    if (mapsUrl != null && mapsUrl.isNotEmpty) {
      actionButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.map_outlined),
            label: const Text('Mapa'),
            onPressed: () => _launchUrl(context, mapsUrl, 'maps'),
            style: elevatedButtonStyle,
          ),
        ),
      );
    }
    if (programaUrl != null && programaUrl.isNotEmpty) {
      actionButtons.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
          child: ElevatedButton.icon(
            icon: const Icon(Icons.article_outlined),
            label: const Text('Programa'),
            onPressed: () => _launchUrl(context, programaUrl, 'programa'),
            style: elevatedButtonStyle,
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
          titulo,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (imagenUrl != null && imagenUrl.isNotEmpty)
              GestureDetector(
                onTap: () {
                  _analyticsService.logProgramaLinkClick(
                    programaName: widget.actuacion.titulo ?? 'N/A',
                    linkType: 'fullscreen_image',
                  );
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          FullscreenImagePage(
                            imageUrl: imagenUrl,
                            tag: detailImageHeroTag,
                          ),
                    ),
                  );
                },
                child: Hero(
                  tag: detailImageHeroTag,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.network(
                        imagenUrl,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            height: 250,
                            alignment: Alignment.center,
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            Container(
                              height: 250,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[300],
                                borderRadius: BorderRadius.circular(12.0),
                              ),
                              alignment: Alignment.center,
                              child: Icon(Icons.broken_image_outlined,
                                  size: 60, color: Colors.grey[600]),
                            ),
                      ),
                    ),
                  ),
                ),
              ),
            if (imagenUrl != null && imagenUrl.isNotEmpty)
              const SizedBox(height: 20),

            Text(
              titulo,
              style: textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
            if (widget.actuacion.subtitulo != null &&
                widget.actuacion.subtitulo!.isNotEmpty &&
                widget.actuacion.titulo != widget.actuacion.subtitulo)
              Padding(
                padding: const EdgeInsets.only(top: 4.0),
                child: Text(
                  widget.actuacion.subtitulo!,
                  style: textTheme.titleMedium?.copyWith(
                      color: colorScheme.secondary),
                ),
              ),
            const SizedBox(height: 16),

            _buildDetailSectionTitle(context, 'Detalles del Evento'),
            if (lugar != null && lugar.isNotEmpty)
              _buildDetailRow(
                  context, Icons.location_on_outlined, 'Lugar:', lugar),
            _buildDetailRow(context, Icons.calendar_today_outlined, 'Fecha:',
                fechaFormateada),
            if (horaActuacion != null && horaActuacion.isNotEmpty)
              _buildDetailRow(
                  context, Icons.access_time_outlined, 'Hora:', horaActuacion),
            if (duracion != null && duracion.isNotEmpty)
              _buildDetailRow(
                  context, Icons.timer_outlined, 'Duración:', duracion),
            if (edad != null && edad.isNotEmpty)
              _buildDetailRow(
                  context, Icons.escalator_warning_outlined, 'Público/Edad:',
                  edad),
            if (precio != null && precio.isNotEmpty)
              _buildDetailRow(
                  context, Icons.euro_symbol_outlined, 'Entrada:', precio),
            if ((ciudad != null && ciudad.isNotEmpty) ||
                (provincia != null && provincia.isNotEmpty))
              _buildCityProvinceRow(context, ciudad, provincia),
            const SizedBox(height: 20),

            if (actionButtons.isNotEmpty)
              LayoutBuilder(
                builder: (context, constraints) {
                  const double typicalButtonWidth = 130.0;
                  final bool canFitInRow = (actionButtons.length * 
                      typicalButtonWidth) < constraints.maxWidth;

                  if (canFitInRow && !kIsWeb) {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: actionButtons.map((button) =>
                          Flexible(child: button)).toList(),
                    );
                  } else {
                    return Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8.0,
                      runSpacing: 8.0,
                      children: actionButtons,
                    );
                  }
                },
              ),
            const SizedBox(height: 24),

            _buildDetailSectionTitle(context, 'Descripción'),
            Text(sinopsis, style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .titleLarge
            ?.copyWith(fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildDetailRow(
      BuildContext context, IconData icon, String label, String value) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: theme.colorScheme.secondary),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyLarge,
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCityProvinceRow(BuildContext context, String? city, String? province) {
    final String location = [city, province].where((s) => s != null && s.isNotEmpty).join(', ');
    if (location.isEmpty) return const SizedBox.shrink();

    return _buildDetailRow(context, Icons.public_outlined, 'Ubicación:', location);
  }
}
