/// Pantalla que muestra el detalle de una jornada o ruta gastronómica.
///
/// Esta pantalla recibe una "jornada" (que es un `EventoSupabase` con categoría
/// "Gastronomia") y muestra su información principal en la cabecera (título,
/// imagen, descripción, fechas).
///
/// Luego, utiliza el `GastronomiaProgramaProvider` para obtener y mostrar una
/// lista de todos los establecimientos o tapas (`RutaGastroItem`) que
/// pertenecen a esta jornada, utilizando el título de la jornada como clave
/// para la búsqueda.
library;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/models/gastro_supabase.dart';
import 'package:arituki/providers/gastro_programa_provider.dart';
import 'package:arituki/services/analytics_service.dart';
import 'package:arituki/services/gastro_service.dart';
import 'package:arituki/widgets/gastro_programlist.dart';

import 'package:arituki/screens/event_fullscreen_image.dart';
import 'package:arituki/utils/utils.dart' as utils;

class GastronomiaProgramaScreen extends StatefulWidget {
  final EventoSupabase jornada;

  const GastronomiaProgramaScreen({super.key, required this.jornada});

  @override
  State<GastronomiaProgramaScreen> createState() =>
      _GastronomiaProgramaScreenState();
}

class _GastronomiaProgramaScreenState extends State<GastronomiaProgramaScreen> {
  late AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _analyticsService = Provider.of<AnalyticsService>(context, listen: false);

      _analyticsService.logGastroProgramaView(
        programaName: widget.jornada.titulo ?? 'N/A',
      );
    });
  }

  Widget _buildGastroDatesSection(BuildContext context, DateTime? diaIni, DateTime? diaFin) {
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    const double indentPadding = 28.0;

    List<Widget> dateChildren = [];

    if (diaIni == null && diaFin == null) {
      return const SizedBox.shrink();
    }

    dateChildren.add(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.calendar_today_outlined, size: 20, color: colorScheme.primary),
          const SizedBox(width: 12),
          Text('Fechas:', style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
        ],
      ),
    );

    if (diaIni != null) {
      dateChildren.add(
        Padding(
          padding: const EdgeInsets.only(left: indentPadding, top: 4.0),
          child: Text(utils.formatDate(diaIni, formatType: 'LONG'), style: textTheme.bodyMedium),
        ),
      );
    }

    if (diaFin != null && (diaIni == null || !DateUtils.isSameDay(diaIni, diaFin))) {
      dateChildren.add(
        Padding(
          padding: EdgeInsets.only(left: indentPadding, top: diaIni == null ? 4.0 : 2.0),
          child: Text(utils.formatDate(diaFin, formatType: 'LONG'), style: textTheme.bodyMedium),
        ),
      );
    } else if (diaIni != null && diaFin != null && DateUtils.isSameDay(diaIni, diaFin) && dateChildren.length == 2) {
      // No añadir diaFin si es el mismo que diaIni y diaIni ya fue añadido.
    }

    if (dateChildren.length <= 1) {
        return const SizedBox.shrink(); 
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: dateChildren,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme
        .of(context)
        .textTheme;
    final colorScheme = Theme
        .of(context)
        .colorScheme;

    final String jornadaTitleForAppBar =
        widget.jornada.titulo ?? "Detalles de la Ruta";

    final String? nombreRutaPadreParaFiltrar = widget.jornada.titulo;
    final String heroTagJornada = 'jornada_image_${widget.jornada.id}';

    return ChangeNotifierProvider<GastronomiaProgramaProvider>(
      create: (contextBajoProvider) {
        final gastronomiaService =
        Provider.of<GastronomiaService>(contextBajoProvider, listen: false);
        final provider = GastronomiaProgramaProvider(
            gastronomiaService: gastronomiaService);

        provider.fetchItemsDelPrograma(
              nombreRutaPadre: nombreRutaPadreParaFiltrar ?? '');
        
        return provider;
      },
      child: Scaffold(
        body: CustomScrollView(
          slivers: <Widget>[
            SliverAppBar(
              expandedHeight: 250.0,
              floating: false,
              pinned: true,
              stretch: true,
              flexibleSpace: FlexibleSpaceBar(
                centerTitle: true,
                titlePadding:
                const EdgeInsets.symmetric(horizontal: 48, vertical: 12),
                title: Text(
                  jornadaTitleForAppBar,
                  style: textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      shadows: [
                        const Shadow(
                            blurRadius: 1.5,
                            color: Colors.black38,
                            offset: Offset(0.75, 0.75))
                      ]),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                background: (widget.jornada.imageUrl != null &&
                    widget.jornada.imageUrl!.isNotEmpty)
                    ? GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            FullscreenImagePage(
                              imageUrl: widget.jornada.imageUrl!,
                              tag: heroTagJornada,
                            ),
                      ),
                    );
                  },
                  child: Hero(
                    tag: heroTagJornada,
                    child: Image.network(
                      widget.jornada.imageUrl!,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          Container(
                            color: Colors.grey[300],
                            child: Center(
                                child: Icon(Icons.broken_image_outlined,
                                    size: 60, color: Colors.grey[600])),
                          ),
                      loadingBuilder: (BuildContext context, Widget child,
                          ImageChunkEvent? loadingProgress) {
                        if (loadingProgress == null) {
                          return child;
                        }
                        return Center(
                          child: CircularProgressIndicator(
                            value: loadingProgress.expectedTotalBytes !=
                                null
                                ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                                : null,
                          ),
                        );
                      },
                    ),
                  ),
                )
                    : Container(
                  color: colorScheme.secondaryContainer.withAlpha(
                      (0.3 * 255).round()),
                  child: Icon(
                    Icons.restaurant_menu_outlined,
                    size: 100,
                    color: colorScheme.onSecondaryContainer.withAlpha(
                        (0.5 * 255).round()),
                  ),
                ),
                stretchModes: const [StretchMode.zoomBackground],
              ),
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Información General', // MODIFICADO
                        style: textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    if (widget.jornada.sinopsis != null &&
                        widget.jornada.sinopsis!.isNotEmpty) ...[
                      Text('Descripción:', // MODIFICADO
                          style: textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(widget.jornada.sinopsis!,
                          style: textTheme.bodyLarge,
                          textAlign: TextAlign.justify),
                      const SizedBox(height: 16),
                    ],
                    _buildGastroDatesSection(context, widget.jornada.diaIni, widget.jornada.diaFin), // MODIFICADO
                    
                    if (widget.jornada.lugar != null &&
                        widget.jornada.lugar!.isNotEmpty)
                      _buildDetailRow(context, Icons.location_on_outlined,
                          'Zona Principal:', widget.jornada.lugar!)
                    else
                      if (widget.jornada.ciudad !=  null && widget.jornada.ciudad!.isNotEmpty)
                        _buildDetailRow(context, Icons.location_city_outlined,
                            'Ciudad:', widget.jornada.ciudad!),
                    const SizedBox(height: 24),
                    const Divider(thickness: 1),
                    const SizedBox(height: 16),
                    Text('Establecimientos Participantes:',
                        style: textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
            Consumer<GastronomiaProgramaProvider>(
              builder: (contextConsumidor, programaProvider, child) {
                if (programaProvider.isLoading && programaProvider.itemsDelPrograma.isEmpty) {
                  return const SliverToBoxAdapter(
                      child: Center(
                          heightFactor: 4, child: CircularProgressIndicator()));
                }

                if (programaProvider.errorMessage != null) {
                  return SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0), 
                        child: Text(programaProvider.errorMessage!),
                      ),
                    ),
                  );
                }

                if (programaProvider.itemsDelPrograma.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(
                      child: Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Text('No hay establecimientos participantes en esta ruta.'),
                      ),
                    ),
                  );
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate(
                        (BuildContext context, int index) {
                      final RutaGastroItem itemDeRuta = programaProvider.itemsDelPrograma[index];
                      return GastronomiaProgramaCard(item: itemDeRuta);
                    },
                    childCount: programaProvider.itemsDelPrograma.length,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: Theme.of(context).textTheme.bodyLarge,
                children: [
                  TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.bold)),
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
