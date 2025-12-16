/// Un widget de tarjeta para mostrar una jornada o evento gastronómico.
///
/// Esta tarjeta se utiliza en la pantalla principal de "Gastronomía" para listar
/// los eventos gastronómicos. Muestra la imagen de la jornada, su título,
/// las fechas y la ubicación. Es interactiva y navega a la pantalla de detalle
/// de la jornada (`GastronomiaProgramaScreen`) al ser pulsada.
library;
import 'package:flutter/material.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/theme/app_theme.dart';
import 'package:arituki/utils/utils.dart' as utils;
import 'package:cached_network_image/cached_network_image.dart';
import 'package:arituki/services/navigation_service.dart';

class GastronomiaCard extends StatelessWidget {
  final EventoSupabase jornada;
  final VoidCallback onTap;

  const GastronomiaCard({super.key, required this.jornada, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final String? imageUrl = jornada.imageUrl;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(AppTheme.kCardPadding),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (imageUrl != null && imageUrl.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    NavigationService.navigateToFullscreenImage(context, imageUrl, "gastro_image_${jornada.id}");
                  },
                  child: Hero(
                    tag: "gastro_image_${jornada.id}",
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(AppTheme.kCardImageBorderRadius),
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        width: 90,
                        height: 90,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.image, color: Colors.grey, size: 30)),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 90,
                          height: 90,
                          color: Colors.grey[300],
                          child: const Center(child: Icon(Icons.broken_image, color: Colors.grey, size: 30)),
                        ),
                      ),
                    ),
                  ),
                )
              else
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(AppTheme.kCardImageBorderRadius)),
                  child: const Center(child: Icon(Icons.restaurant, color: Colors.grey, size: 40)),
                ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      jornada.titulo ?? 'Jornada sin nombre',
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4.0),
                    Text(
                      utils.formatEventDates(jornada.diaIni, jornada.diaFin, null),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (jornada.lugar != null && jornada.lugar!.isNotEmpty) ...[
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 14.0, color: Colors.grey[600]),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              jornada.lugar!,
                              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                    if (jornada.ciudad != null && jornada.ciudad!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.business, size: 14.0, color: Colors.grey[600]),
                          const SizedBox(width: 4.0),
                          Expanded(
                            child: Text(
                              jornada.ciudad!,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                                fontStyle: FontStyle.italic,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ], 
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
