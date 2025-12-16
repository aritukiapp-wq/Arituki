/// Un widget de tarjeta para mostrar un ítem de una ruta gastronómica.
///
/// Esta tarjeta se utiliza dentro de la pantalla de detalle de una jornada
/// (`GastronomiaProgramaScreen`) para listar cada uno de los establecimientos
/// o tapas participantes. Muestra la imagen, el nombre del establecimiento,
/// el nombre de la tapa (si existe), la dirección y el precio. Es interactiva
/// y navega a la pantalla de detalle del ítem (`GastronomiaDetailScreen`) al ser pulsada.
library;
import 'package:flutter/material.dart';
import 'package:arituki/models/gastro_supabase.dart'; // Modelo RutaGastroItem
import 'package:arituki/screens/gastro_detail.dart'; // Pantalla de detalle
import 'package:arituki/screens/event_fullscreen_image.dart'; // Para imagen a pantalla completa

class GastronomiaProgramaCard extends StatelessWidget {
  final RutaGastroItem item;

  const GastronomiaProgramaCard({
    super.key,
    required this.item,
  });

  @override
  Widget build(BuildContext context) {
    final TextTheme textTheme = Theme
        .of(context)
        .textTheme;
    final ColorScheme colorScheme = Theme
        .of(context)
        .colorScheme;

    final String nombreEstablecimiento = item.restaurante ??
        'Establecimiento no disponible';
    final String? nombreTapaOferta = item
        .tapa;
    final String? direccion = item.direccion;
    final String? precio = item.precio;
    final String? imagenUrl = item.imageUrl;

    final String imageHeroTag = 'ruta_gastro_item_list_image_${item.id}';

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) =>
                GastronomiaDetailScreen(
                  itemRuta: item,
                ),
          ),
        );
      },
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (imagenUrl != null && imagenUrl.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FullscreenImagePage(
                              imageUrl: imagenUrl,
                              tag: imageHeroTag,
                            ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: imageHeroTag,
                    child: Container(
                      width: 85.0,
                      height: 105.0,
                      margin: const EdgeInsets.only(right: 12.0),
                      clipBehavior: Clip.antiAlias,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8.0),
                        color: colorScheme.surfaceContainerHighest.withAlpha(
                            (0.3 * 255).round()),
                      ),
                      child: Image.network(
                        imagenUrl,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) {
                            return child;
                          }
                          return Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  colorScheme.primary),
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                  loadingProgress.expectedTotalBytes!
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            alignment: Alignment.center,
                            child: Icon(
                              Icons.restaurant_outlined,
                              color: colorScheme.onSurfaceVariant.withAlpha(
                                  (0.6 * 255).round()),
                              size: 35,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                )
              else
                Container( // Placeholder si no hay imagen
                  width: 85.0,
                  height: 105.0,
                  margin: const EdgeInsets.only(right: 12.0),
                  decoration: BoxDecoration(
                    color: colorScheme.surfaceContainerHighest.withAlpha(
                        (0.3 * 255).round()),
                    borderRadius: BorderRadius.circular(8.0),
                  ),
                  child: Icon(
                    Icons.storefront_outlined,
                    color: colorScheme.onSurfaceVariant.withAlpha(
                        (0.6 * 255).round()),
                    size: 40,
                  ),
                ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Text(
                      nombreEstablecimiento,
                      style: textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (nombreTapaOferta != null &&
                        nombreTapaOferta.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 3.0, bottom: 4.0),
                        child: Text(
                          nombreTapaOferta,
                          style: textTheme.bodyMedium?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]
                    else
                      ...[
                        if ((direccion != null && direccion.isNotEmpty) ||
                            (precio != null && precio.isNotEmpty))
                          const SizedBox(height: 4.0),
                      ],
                    if (direccion != null && direccion.isNotEmpty)
                      _buildInfoRow(
                        context,
                        icon: Icons.location_on_outlined,
                        text: direccion,
                      ),
                    if (precio != null && precio.isNotEmpty)
                      _buildInfoRow(
                          context,
                          icon: Icons.paid_outlined,
                          text: precio,
                          textStyle: textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600
                          )
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, {
    required IconData icon,
    required String text,
    TextStyle? textStyle,
  }) {
    final textTheme = Theme
        .of(context)
        .textTheme;
    final colorScheme = Theme
        .of(context)
        .colorScheme;

    if (text
        .trim()
        .isEmpty) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 4.0, bottom: 2.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15,
              color: colorScheme.primary.withAlpha((0.9 * 255).round())),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: textStyle ??
                  textTheme.bodySmall?.copyWith(
                      color: colorScheme.onSurfaceVariant.withAlpha(
                          (0.9 * 255).round())),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
