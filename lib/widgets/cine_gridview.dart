/// Un widget que muestra una cuadrícula de películas.
///
/// Este widget toma una lista de objetos `PeliculaSupabase` y los muestra en
/// un `GridView`. Cada película se representa con un widget `CineCard`.
/// Maneja la acción de pulsar sobre una película a través de un callback.
library;
import 'package:flutter/material.dart';
import 'package:arituki/models/cine_supabase.dart';
import 'package:arituki/widgets/cine_card.dart';

class CineGridView extends StatelessWidget {
  final List<PeliculaSupabase> peliculas;
  final Function(PeliculaSupabase) onPeliculaTap;

  const CineGridView(
      {super.key, required this.peliculas, required this.onPeliculaTap});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.only(top: 4.0, left: 4.0, right: 4.0, bottom: 12.0),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 300,
        crossAxisSpacing: 0.0,
        mainAxisSpacing: 0.0,
        childAspectRatio: 0.7,
      ),
      itemCount: peliculas.length,
      itemBuilder: (context, index) {
        final pelicula = peliculas[index];
        return CineCard(
          pelicula: pelicula,
          onTap: () => onPeliculaTap(pelicula),
        );
      },
    );
  }
}
