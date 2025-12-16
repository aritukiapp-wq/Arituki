/// Gestiona el ciclo de vida de los anuncios de tipo "App Open" de Google AdMob.
///
/// Este servicio se encarga de:
/// - Cargar un anuncio de "App Open" en segundo plano para que esté listo.
/// - Mostrar el anuncio cuando la aplicación vuelve al primer plano.
/// - Controlar los callbacks del anuncio (carga, error, visualización, cierre).
/// - Asegurar que un anuncio no se muestre si ya hay otro en pantalla o si no se ha cargado.
/// - Es utilizado por `AppLifecycleReactor` para saber cuándo mostrar el anuncio.
library;
import 'dart:io';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:flutter/foundation.dart';

// Enum para el estado del anuncio de apertura
enum AppOpenAdState { initial, loading, loaded, error }

class AppOpenAdManager with ChangeNotifier {
  AppOpenAd? _appOpenAd;
  bool _isShowingAd = false;
  bool _isStartupAdShown = false;
  AppOpenAdState _adState = AppOpenAdState.initial;

  AppOpenAdState get adState => _adState;

  // IDs de prueba de Google para "App Open Ad" según la documentación oficial.
  static final String _androidAdUnitId = 'ca-app-pub-6390898456030392/2531920915';
  static final String _iosAdUnitId = 'ca-app-pub-6390898456030392/2531920915';

  String get _adUnitId {
    if (Platform.isAndroid) {
      return _androidAdUnitId;
    } else if (Platform.isIOS) {
      return _iosAdUnitId;
    } else {
      throw UnsupportedError("Unsupported platform for ads");
    }
  }

  bool get isAdAvailable => _appOpenAd != null;

  void loadAd() {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      return;
    }

    if (_isShowingAd || isAdAvailable) {
       return;
    }
    
    _adState = AppOpenAdState.loading;
    notifyListeners();

    AppOpenAd.load(
      adUnitId: _adUnitId,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          _adState = AppOpenAdState.loaded;
          notifyListeners();
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          _adState = AppOpenAdState.error;
          notifyListeners();
        },
      ),
    );
  }

  void showAdIfAvailable({
    bool fromLogin = false,
    VoidCallback? onAdDismissed,
  }) {
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      onAdDismissed?.call();
      return;
    }
    
    if (fromLogin) {
      if (_isStartupAdShown) {
        onAdDismissed?.call();
        return;
      }
    }

    if (!isAdAvailable) {
      onAdDismissed?.call();
      if (_adState != AppOpenAdState.loading) {
        loadAd();
      }
      return;
    }
    if (_isShowingAd) {
      onAdDismissed?.call();
      return;
    }

    _appOpenAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdShowedFullScreenContent: (ad) {
        _isShowingAd = true;
        if (fromLogin) {
          _isStartupAdShown = true;
        }
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _adState = AppOpenAdState.error;
        notifyListeners();
        onAdDismissed?.call();
        loadAd();
      },
      onAdDismissedFullScreenContent: (ad) {
        _isShowingAd = false;
        ad.dispose();
        _appOpenAd = null;
        _adState = AppOpenAdState.initial;
        notifyListeners();
        onAdDismissed?.call();
        loadAd();
      },
    );

    _appOpenAd!.show();
  }

  @override
  void dispose() {
    _appOpenAd?.dispose();
    super.dispose();
  }
}
