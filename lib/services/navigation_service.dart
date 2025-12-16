/// Servicio de navegación para centralizar y simplificar la navegación entre pantallas.
///
/// Esta clase proporciona métodos estáticos para navegar a pantallas específicas
/// de la aplicación, como la pantalla de detalle de un evento o una vista de
/// imagen a pantalla completa. Ayuda a desacoplar la lógica de navegación de
/// los widgets de la UI, haciendo el código más limpio y fácil de mantener.
library;
import 'package:flutter/material.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/screens/event_detail.dart';
import 'package:arituki/screens/event_fullscreen_image.dart';

class NavigationService {
  static void navigateToEventDetail(BuildContext context, EventoSupabase event) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EventDetailPage(event: event),
      ),
    );
  }

  static void navigateToFullscreenImage(BuildContext context, String imageUrl, String heroTag) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FullscreenImagePage(
          imageUrl: imageUrl,
          tag: heroTag,
        ),
        fullscreenDialog: true,
      ),
    );
  }
}
