/// Pantalla de detalle de un ítem gastronómico (restaurante, bar, tapa).
///
/// Muestra la información completa de un establecimiento o plato específico
/// dentro de una ruta o jornada gastronómica. Incluye:
/// - Imagen, nombre, descripción.
/// - Detalles como dirección, teléfono, precio.
/// - Botones de acción para llamar por teléfono, visitar la web, ver en el mapa
///   o acceder a redes sociales.
library;
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:arituki/models/gastro_supabase.dart';
import 'package:arituki/services/analytics_service.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:arituki/screens/event_fullscreen_image.dart';

class GastronomiaDetailScreen extends StatefulWidget {
  final RutaGastroItem itemRuta;

  const GastronomiaDetailScreen({
    super.key,
    required this.itemRuta,
  });

  @override
  State<GastronomiaDetailScreen> createState() =>
      _GastronomiaDetailScreenState();
}

class _GastronomiaDetailScreenState extends State<GastronomiaDetailScreen> {
  late AnalyticsService _analyticsService;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _analyticsService = Provider.of<AnalyticsService>(context, listen: false);

      _analyticsService.logGastroDetailView(
        jornadaName: widget.itemRuta.restaurante ?? 'N/A',
      );
    });
  }

  Future<void> _launchUrl(String? urlString, {
    bool isEmail = false,
    bool isPhone = false,
    String linkType = 'unknown',
  }) async {
    if (urlString == null || urlString.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No hay enlace disponible.')),
      );
      return;
    }

    final gastroName = widget.itemRuta.restaurante ?? 'N/A';

    if (isPhone) {
      _analyticsService.logGastroLinkClick(jornadaName: gastroName, linkType: 'phone');
    } else if (linkType == 'maps') {
      _analyticsService.logGastroLinkClick(jornadaName: gastroName, linkType: 'maps');
    } else {
      _analyticsService.logGastroLinkClick(jornadaName: gastroName, linkType: linkType);
    }

    Uri url;
    if (isEmail) {
      url = Uri(scheme: 'mailto', path: urlString);
    } else if (isPhone) {
      url = Uri(scheme: 'tel', path: urlString);
    } else {
      if (!urlString.startsWith('http://') && !urlString.startsWith('https://')) {
        urlString = 'https://$urlString';
      }
      try {
        url = Uri.parse(urlString);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Enlace no válido: $urlString')),
        );
        return;
      }
    }

    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      debugPrint('No se pudo lanzar $url');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('No se pudo abrir: $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final colorScheme = theme.colorScheme;

    final String? restaurante = widget.itemRuta.restaurante;
    final String? tapa = widget.itemRuta.tapa;
    final String mainTitle = (tapa != null && tapa.isNotEmpty) ? tapa : (restaurante ?? 'Detalle');
    final String appBarTitle = restaurante ?? 'Detalle';
    final String detailImageHeroTag = 'ruta_gastro_item_image_${widget.itemRuta.id}';

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (widget.itemRuta.imageUrl != null && widget.itemRuta.imageUrl!.isNotEmpty)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => FullscreenImagePage(imageUrl: widget.itemRuta.imageUrl!, tag: detailImageHeroTag))),
                child: Hero(
                  tag: detailImageHeroTag,
                  child: Center(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12.0),
                      child: Image.network(
                        widget.itemRuta.imageUrl!,
                        width: double.infinity, height: 250, fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => Container(alignment: Alignment.center, child: Icon(Icons.restaurant_menu_outlined, size: 60, color: Colors.grey[600])),
                      ),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 20),
            Text(
              mainTitle,
              style: textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: colorScheme.primary),
            ),
            if (widget.itemRuta.tipo != null && widget.itemRuta.tipo!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(widget.itemRuta.tipo!, style: textTheme.titleLarge?.copyWith(color: colorScheme.secondary, fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 16),
            _buildDetailSectionTitle(context, 'Información'),
            if (restaurante != null && restaurante.isNotEmpty && mainTitle != restaurante) _buildDetailRow(context, Icons.storefront_outlined, 'Establecimiento:', restaurante),
            if (widget.itemRuta.tipo != null && widget.itemRuta.tipo!.isNotEmpty) _buildDetailRow(context, Icons.category_outlined, 'Tipo:', widget.itemRuta.tipo!),
            if (widget.itemRuta.ciudad != null && widget.itemRuta.ciudad!.isNotEmpty) _buildDetailRow(context, Icons.location_city_outlined, 'Ciudad:', widget.itemRuta.ciudad!),
            if (widget.itemRuta.direccion != null && widget.itemRuta.direccion!.isNotEmpty) _buildDetailRow(context, Icons.location_on_outlined, 'Dirección:', widget.itemRuta.direccion!),
            if (widget.itemRuta.telefono != null && widget.itemRuta.telefono!.isNotEmpty) _buildDetailRow(context, Icons.phone_outlined, 'Teléfono:', widget.itemRuta.telefono!),
            if (widget.itemRuta.precio != null && widget.itemRuta.precio!.isNotEmpty) _buildDetailRow(context, Icons.euro_symbol_outlined, 'Precio:', widget.itemRuta.precio!),
            const SizedBox(height: 20),
            if (widget.itemRuta.sinopsis != null && widget.itemRuta.sinopsis!.isNotEmpty) ...[
              _buildDetailSectionTitle(context, 'Descripción'),
              Text(widget.itemRuta.sinopsis!, style: textTheme.bodyLarge?.copyWith(height: 1.5), textAlign: TextAlign.justify),
              const SizedBox(height: 20),
            ],
            _buildActionButtons(context),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailSectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 12.0, bottom: 8.0),
      child: Text(title, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
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
          const SizedBox(width: 12),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: theme.textTheme.bodyLarge,
                children: [
                  TextSpan(text: '$label ', style: const TextStyle(fontWeight: FontWeight.w600)),
                  TextSpan(text: value),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    final theme = Theme.of(context);
    final buttonStyle = ElevatedButton.styleFrom(
      backgroundColor: theme.colorScheme.primary,
      foregroundColor: theme.colorScheme.onPrimary,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      textStyle: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.bold),
    );

    final socialButtonStyle = IconButton.styleFrom(
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      foregroundColor: theme.colorScheme.onSurfaceVariant,
    );

    List<Widget> actionButtons = [];
    if (widget.itemRuta.telefono != null) actionButtons.add(ElevatedButton.icon(icon: const Icon(Icons.call_outlined), label: const Text('Llamar'), onPressed: () => _launchUrl(widget.itemRuta.telefono, isPhone: true), style: buttonStyle));
    if (widget.itemRuta.eventoUrl != null || widget.itemRuta.wwwUrl != null) actionButtons.add(ElevatedButton.icon(icon: const Icon(Icons.public), label: const Text('Web'), onPressed: () => _launchUrl(widget.itemRuta.eventoUrl ?? widget.itemRuta.wwwUrl, linkType: 'web'), style: buttonStyle));
    if (widget.itemRuta.googleUrl != null) actionButtons.add(ElevatedButton.icon(icon: const Icon(Icons.map_outlined), label: const Text('Mapa'), onPressed: () => _launchUrl(widget.itemRuta.googleUrl, linkType: 'maps'), style: buttonStyle));
    if (widget.itemRuta.email != null) actionButtons.add(ElevatedButton.icon(icon: const Icon(Icons.email_outlined), label: const Text('Email'), onPressed: () => _launchUrl(widget.itemRuta.email, isEmail: true), style: buttonStyle));
    
    List<Widget> socialButtons = [];
    if (widget.itemRuta.facebook != null) socialButtons.add(IconButton(icon: const FaIcon(FontAwesomeIcons.facebook), onPressed: () => _launchUrl(widget.itemRuta.facebook, linkType: 'facebook'), style: socialButtonStyle));
    if (widget.itemRuta.instagram != null) socialButtons.add(IconButton(icon: const FaIcon(FontAwesomeIcons.instagram), onPressed: () => _launchUrl(widget.itemRuta.instagram, linkType: 'instagram'), style: socialButtonStyle));
    if (widget.itemRuta.xUrl != null) socialButtons.add(IconButton(icon: const FaIcon(FontAwesomeIcons.twitter), onPressed: () => _launchUrl(widget.itemRuta.xUrl, linkType: 'x'), style: socialButtonStyle));

    if (actionButtons.isEmpty && socialButtons.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      children: [
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8.0,
          runSpacing: 8.0,
          children: actionButtons,
        ),
        if (actionButtons.isNotEmpty && socialButtons.isNotEmpty) const SizedBox(height: 12),
        if (socialButtons.isNotEmpty)
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12.0,
            children: socialButtons,
          ),
      ],
    );
  }
}
