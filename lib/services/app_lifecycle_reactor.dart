/// Reacciona a los eventos del ciclo de vida de la aplicación para gestionar la
/// visualización de anuncios.
///
/// Esta clase observa el estado del ciclo de vida de la aplicación. Cuando la
/// aplicación vuelve al primer plano (estado `resumed`), invoca al `AppOpenAdManager`
/// para mostrar un anuncio de "App Open" si está disponible. También se encarga
/// de inicializar y liberar los recursos del gestor de anuncios.
library;
import 'package:flutter/widgets.dart';
import 'app_open_ad_manager.dart';

class AppLifecycleReactor with WidgetsBindingObserver {
  final AppOpenAdManager appOpenAdManager;

  AppLifecycleReactor({required this.appOpenAdManager});

  void init() {
    WidgetsBinding.instance.addObserver(this);
    appOpenAdManager.loadAd();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      appOpenAdManager.showAdIfAvailable();
    }
  }

  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    appOpenAdManager.dispose(); 
  }
}
