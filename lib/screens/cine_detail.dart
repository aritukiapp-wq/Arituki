/// Pantalla de detalle de una película.
///
/// Muestra toda la información detallada de una película específica, incluyendo
/// su póster, sinopsis, director, reparto, etc. También presenta una sección
/// interactiva para ver todas las sesiones disponibles para esa película.
///
/// El usuario puede filtrar las sesiones por día y por cine. La lógica de este
/// filtrado es gestionada por el `CineDetailProvider`, que se instancia en esta
/// pantalla.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:arituki/models/cine_supabase.dart';
import 'package:arituki/providers/cine_detail_provider.dart';
import 'package:arituki/screens/event_fullscreen_image.dart';
import 'package:arituki/widgets/cine_card_detail.dart'; // Importamos la tarjeta individual
import 'package:arituki/widgets/cine_chipchoice_date.dart';
import 'package:arituki/widgets/cine_chipchoice_cine.dart';

class CineDetailScreen extends StatelessWidget {
  final PeliculaSupabase peliculaPrincipal;
  final List<PeliculaSupabase> sesionesPelicula;

  const CineDetailScreen({
    super.key,
    required this.peliculaPrincipal,
    required this.sesionesPelicula,
  });

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => CineDetailProvider(allSessions: sesionesPelicula),
      child: Consumer<CineDetailProvider>(
        builder: (context, provider, child) {
          return Scaffold(
            appBar: AppBar(
              title: Text(peliculaPrincipal.titulo ?? 'Detalle de Película'),
            ),
            body: SingleChildScrollView(
              // Se elimina el padding global para un control más preciso
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildHeader(context, peliculaPrincipal),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0),
                      child: _buildDetails(context, peliculaPrincipal),
                    ),
                    const SizedBox(height: 20),
                    _buildSessions(context, provider),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, PeliculaSupabase pelicula) {
    final heroTag = 'cineImage_${pelicula.id}';
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (pelicula.imageUrl != null && pelicula.imageUrl!.isNotEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FullscreenImagePage(
                        imageUrl: pelicula.imageUrl!,
                        tag: heroTag,
                      ),
                    ),
                  );
                },
                child: Hero(
                  tag: heroTag,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      pelicula.imageUrl!,
                      fit: BoxFit.cover,
                      height: 300,
                      width: double.infinity,
                       loadingBuilder: (context, child, progress) => progress == null
                          ? child
                          : const SizedBox(height: 300, child: Center(child: CircularProgressIndicator())),
                      errorBuilder: (context, error, stackTrace) => Container(
                        height: 300,
                        color: Colors.grey[300],
                        child: Center(child: Icon(Icons.movie_creation_outlined, size: 100, color: Colors.grey[600])),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Text(pelicula.titulo ?? 'Sin título', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
      ],
    );
  }

  Widget _buildDetails(BuildContext context, PeliculaSupabase pelicula) {
    String anioPaisDisplay = [pelicula.anio?.toString(), pelicula.pais]
        .where((s) => s != null && s.isNotEmpty)
        .join('  •  ');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (anioPaisDisplay.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 10.0),
            child: Text(anioPaisDisplay, style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.grey[700])),
          ),
        _buildDetailRow(context, 'Género', pelicula.genero, icon: Icons.category_outlined),
        _buildDetailRow(context, 'Duración', pelicula.duracion, icon: Icons.timer_outlined),
        _buildDetailRow(context, 'Calificación', _formatRating(pelicula.ratingAvg, pelicula.ratingCount), icon: Icons.star_border_outlined),
        _buildDetailRow(context, 'Edad', pelicula.edad, icon: Icons.person_outline),
        _buildDetailRow(context, 'Director', pelicula.director, icon: Icons.movie_filter_outlined),
        _buildDetailRow(context, 'Reparto', pelicula.reparto, icon: Icons.groups_outlined),
        if (pelicula.sinopsis != null && pelicula.sinopsis!.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Sinopsis:', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(pelicula.sinopsis!, style: Theme.of(context).textTheme.bodyMedium, textAlign: TextAlign.justify),
        ],
      ],
    );
  }

  Widget _buildSessions(BuildContext context, CineDetailProvider provider) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Text('Sesiones Disponibles:', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 8),
        if (provider.availableDays.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 4.0),
            child: CineDayFilterChips(
              availableDays: provider.availableDays,
              selectedDay: provider.selectedDay,
              onDaySelected: provider.selectDay,
            ),
          ),
        if (provider.availableCinemas.isNotEmpty)
          Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 4.0, 16.0, 8.0),
            child: CineCinemaFilterChips(
              availableCinemas: provider.availableCinemas,
              selectedCinema: provider.selectedCinema,
              onCinemaSelected: provider.selectCinema,
            ),
          ),
        if (provider.filteredSessions.isNotEmpty)
          ...provider.filteredSessions.map((sesion) {
            // Eliminamos el margen horizontal de la Card para alinear con el padding del padre
            return Theme(
              data: Theme.of(context).copyWith(
                cardTheme: Theme.of(context).cardTheme.copyWith(margin: const EdgeInsets.symmetric(vertical: 6.0)),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: CineSessionCard(sesion: sesion),
              ),
            );
          })
        else
          Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                (provider.selectedDay != null || provider.selectedCinema != null)
                    ? 'No hay sesiones que coincidan con los filtros seleccionados.'
                    : 'Selecciona un día y/o cine para ver las sesiones.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String? value, {IconData? icon}) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[Icon(icon, size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant), const SizedBox(width: 8)],
          Text('$label: ', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }

  String _formatRating(double? ratingAvg, int? ratingCount) {
    if (ratingAvg == null) return 'No disponible';
    String output = ratingAvg.toStringAsFixed(1);
    if (ratingCount != null && ratingCount > 0) {
      output += ' ($ratingCount valoraciones)';
    }
    return output;
  }
}
