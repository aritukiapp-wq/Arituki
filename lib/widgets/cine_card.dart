/// Un widget que muestra una tarjeta para una película en una cuadrícula.
///
/// Presenta la imagen del póster de la película y su título. Está diseñado para
/// ser utilizado dentro de un `GridView` y es interactiv, permitiendo
/// ejecutar una acción `onTap` cuando el usuario lo pulsa.
library;
import 'package:flutter/material.dart';
import 'package:arituki/models/cine_supabase.dart'; // Ajusta la ruta a tu modelo

class CineCard extends StatelessWidget {
  final PeliculaSupabase pelicula;
  final VoidCallback? onTap;

  const CineCard({
    super.key,
    required this.pelicula,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      // Para que el borde redondeado afecte a la imagen
      elevation: 3.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10.0),
      ),
      child: InkWell( // Para hacer la tarjeta tapeable
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          // Para que la imagen ocupe todo el ancho
          children: <Widget>[
            // Imagen de la Película
            Expanded(
              child: (pelicula.imageUrl != null &&
                  pelicula.imageUrl!.isNotEmpty)
                  ? Image.network(
                pelicula.imageUrl!,
                fit: BoxFit.cover,
                loadingBuilder: (BuildContext context, Widget child,
                    ImageChunkEvent? loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Center(
                    child: CircularProgressIndicator(
                      value: loadingProgress.expectedTotalBytes != null
                          ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                          : null,
                      strokeWidth: 2.0,
                    ),
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    Container(
                      color: Colors.grey[300],
                      child: Center(child: Icon(
                          Icons.movie_creation_outlined, size: 40,
                          color: Colors.grey[600])),
                    ),
              )
                  : Container(
                color: Colors.grey[300],
                child: Center(child: Icon(
                    Icons.movie_creation_outlined, size: 40,
                    color: Colors.grey[600])),
              ),
            ),
            // Título de la Película
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                pelicula.titulo ?? 'Título no disponible',
                style: Theme
                    .of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: 14, // Ajusta según necesites
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}