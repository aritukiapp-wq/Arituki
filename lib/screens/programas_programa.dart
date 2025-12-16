/// Pantalla que muestra el detalle de un programa de fiestas completo.
///
/// Esta pantalla recibe un "programa" (que es un `EventoSupabase` con categoría
/// "Programa") y muestra su información principal en una cabecera con una
/// imagen expansible (`SliverAppBar`).
///
/// A continuación, utiliza `ProgramaDetailProvider` para obtener y mostrar una
/// lista de todos los actos o eventos individuales que pertenecen a este programa,
/// utilizando el título del programa como clave para la búsqueda. Cada uno de
/// estos actos es navegable a su propia pantalla de detalle (`ProgramaDetailScreen`).
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/providers/programa_detail_provider.dart';
import 'package:arituki/services/programas_service.dart';
import 'package:arituki/widgets/programas_card.dart';
import 'package:arituki/screens/event_fullscreen_image.dart';
import 'package:arituki/screens/programas_detail.dart'; // Importar la pantalla de detalle
import 'package:arituki/utils/utils.dart' as utils;

class ProgramaProgramaScreen extends StatelessWidget {
  final EventoSupabase programa;

  const ProgramaProgramaScreen({super.key, required this.programa});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ProgramaDetailProvider>(
      create: (_) => ProgramaDetailProvider(
        programaService: context.read<ProgramaService>(),
        programaTitulo: programa.titulo ?? '',
      ),
      child: Scaffold(
        body: Consumer<ProgramaDetailProvider>(
          builder: (context, provider, child) {
            return CustomScrollView(
              slivers: <Widget>[
                _buildSliverAppBar(context, programa),
                _buildHeaderSection(context, programa),
                _buildBodyContent(context, provider),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSliverAppBar(BuildContext context, EventoSupabase programa) {
    final textTheme = Theme.of(context).textTheme;
    final heroTag = 'programa_image_${programa.id}';

    return SliverAppBar(
      expandedHeight: 250.0,
      floating: false,
      pinned: true,
      stretch: true,
      flexibleSpace: FlexibleSpaceBar(
        centerTitle: true,
        titlePadding: const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
        title: Text(
          programa.titulo ?? "Detalles del Programa",
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
            shadows: [const Shadow(blurRadius: 1.5, color: Colors.black38, offset: Offset(0.75, 0.75))]
          ),
          textAlign: TextAlign.center,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        background: (programa.imageUrl != null && programa.imageUrl!.isNotEmpty)
            ? GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => FullscreenImagePage(
                      imageUrl: programa.imageUrl!,
                      tag: heroTag,
                    ),
                  ),
                ),
                child: Hero(
                  tag: heroTag,
                  child: Image.network(
                    programa.imageUrl!,
                    fit: BoxFit.cover,
                    // ... (loading and error builders)
                  ),
                ),
              )
            : Container(
                color: Theme.of(context).colorScheme.secondaryContainer.withAlpha(100),
                child: Icon(
                  Icons.festival_outlined,
                  size: 100,
                  color: Theme.of(context).colorScheme.onSecondaryContainer.withAlpha(150),
                ),
              ),
        stretchModes: const [StretchMode.zoomBackground],
      ),
    );
  }

  Widget _buildHeaderSection(BuildContext context, EventoSupabase programa) {
    final textTheme = Theme.of(context).textTheme;
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             if (programa.sinopsis != null && programa.sinopsis!.isNotEmpty) ...[
              Text('Descripción', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(programa.sinopsis!, style: textTheme.bodyLarge, textAlign: TextAlign.justify),
              const SizedBox(height: 16),
            ],
            _buildDetailRow(context, Icons.calendar_today_outlined, 'Fechas:', utils.formatEventDates(programa.diaIni, programa.diaFin, null)),
            _buildDetailRow(context, Icons.location_on_outlined, 'Lugar:', programa.lugar),
            _buildDetailRow(context, Icons.location_city_outlined, 'Ciudad:', programa.ciudad),
            const SizedBox(height: 24),
            const Divider(thickness: 1),
            const SizedBox(height: 16),
            Text('Programación del Evento', style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildBodyContent(BuildContext context, ProgramaDetailProvider provider) {
    final textTheme = Theme.of(context).textTheme;
    if (provider.isLoading) {
      return const SliverToBoxAdapter(child: Center(heightFactor: 4, child: CircularProgressIndicator()));
    }

    if (provider.errorMessage != null) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_off_outlined, color: Theme.of(context).colorScheme.error, size: 48),
                const SizedBox(height: 16),
                Text('Error al cargar la programación', style: textTheme.titleMedium, textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text(provider.errorMessage ?? 'No se pudo obtener la información. Inténtalo de nuevo.', style: textTheme.bodySmall, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                ElevatedButton.icon(
                  icon: const Icon(Icons.refresh_outlined),
                  label: const Text('Reintentar'),
                  onPressed: () => provider.refresh(),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (provider.items.isEmpty) {
      return SliverToBoxAdapter(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.event_note_outlined, size: 50, color: Colors.grey[600]),
                const SizedBox(height: 16),
                Text('No hay eventos específicos en la programación de este programa.', style: textTheme.bodyMedium, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      );
    }

    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 0.0, vertical: 8.0),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final item = provider.items[index];
            return ProgramaCard(
              programa: item,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProgramaDetailScreen(actuacion: item),
                  ),
                );
              },
            );
          },
          childCount: provider.items.length,
        ),
      ),
    );
  }
  
  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String? value) {
    if (value == null || value.isEmpty || value == 'N/A') {
      return const SizedBox.shrink();
    }
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Text('$label ', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.bodyMedium)),
        ],
      ),
    );
  }
}
