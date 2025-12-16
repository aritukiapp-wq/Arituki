/// Un widget de tarjeta para mostrar una sesión de cine específica.
///
/// Esta tarjeta se utiliza en la pantalla de detalle de una película para listar
/// cada una de las sesiones disponibles. Muestra el día, la fecha, el nombre del
/// cine, la tecnología (ej. 3D) y la hora de la sesión.
///
/// Si hay una URL para comprar entradas, la tarjeta es interactiva y, al pulsarla,
/// muestra un diálogo de confirmación antes de redirigir al usuario a la web de compra.
library;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:arituki/models/cine_supabase.dart';
import 'package:arituki/services/analytics_service.dart';

class CineSessionCard extends StatelessWidget {
  final PeliculaSupabase sesion;

  const CineSessionCard({
    super.key,
    required this.sesion,
  });

  Future<void> _launchURL(String urlString) async {
    final Uri url = Uri.parse(urlString);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
    }
  }

  String _formatDayOfWeek(String? dateString) {
    if (dateString == null || dateString.isEmpty) return '';
    try {
      final date = DateTime.parse(dateString);
      String dayName = DateFormat('EEEE', 'es_ES').format(date);
      return dayName[0].toUpperCase() + dayName.substring(1);
    } catch (e) {
      return '';
    }
  }

  String _formatShortDate(String? dateString) {
    if (dateString == null || dateString.isEmpty) return 'N/D';
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('d MMM', 'es_ES').format(date);
    } catch (e) {
      return dateString;
    }
  }

  String _formatDisplayTime(String? timeString) {
    if (timeString == null || timeString.isEmpty) return 'N/H';
    try {
      final parts = timeString.split(':');
      if (parts.length >= 2) {
        return '${parts[0]}:${parts[1]}';
      }
      return timeString;
    } catch (e) {
      return timeString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    final theme = Theme.of(context);

    final String diaSemana = _formatDayOfWeek(sesion.dia);
    final String fechaFormateada = _formatShortDate(sesion.dia);
    final String horaSesion = _formatDisplayTime(sesion.hora);
    final String nombreCine = sesion.cine ?? 'Cine no especificado';
    final String tecnologiaCine = sesion.tecnologia ?? '';

    return Card(
      // Estilos de elevación, margen, clip y forma eliminados para usar el CardTheme global.
      child: InkWell(
        onTap: (sesion.ticketUrl != null && sesion.ticketUrl!.isNotEmpty)
            ? () {
                showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AlertDialog(
                      title: const Text('Atención'),
                      content: const Text(
                        'Antes de comprar la entrada, compruebe bien que se corresponde al cine, día y hora deseada.',
                      ),
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
                            _launchURL(sesion.ticketUrl!);

                            analyticsService.logCineTicketLinkClick(
                              movieTitle: sesion.titulo ?? 'Título desconocido',
                              cinemaName: nombreCine,
                            );
                          },
                        ),
                      ],
                    );
                  },
                );
              }
            : null,
        child: Padding(
          padding:
              const EdgeInsets.symmetric(horizontal: 12.0, vertical: 10.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              Container(
                width: 75,
                constraints: const BoxConstraints(minHeight: 40),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (diaSemana.isNotEmpty)
                      Text(
                        diaSemana,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    if (fechaFormateada != 'N/D')
                      Text(
                        fechaFormateada,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  constraints: const BoxConstraints(minHeight: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        nombreCine,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (tecnologiaCine.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          tecnologiaCine,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ]
                    ],
                  ),
                ),
              ),
              if (horaSesion != 'N/H')
                Padding(
                  padding: const EdgeInsets.only(left: 12.0),
                  child: Container(
                    constraints: const BoxConstraints(minHeight: 40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          horaSesion,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                        if (sesion.ticketUrl != null &&
                            sesion.ticketUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 2.0),
                            child: Icon(
                              Icons.local_activity_outlined,
                              color: theme.colorScheme.secondary,
                              size: 18,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
