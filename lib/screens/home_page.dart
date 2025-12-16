/// La pantalla principal de la aplicación que contiene la navegación por pestañas.
///
/// Esta pantalla es el contenedor principal después de que el usuario ha iniciado sesión.
/// Implementa una `BottomNavigationBar` para cambiar entre las diferentes secciones
/// principales de la aplicación: Eventos, Favoritos, Cine, Programas y Gastronomía.
///
/// También se encarga de:
/// - Gestionar un `Drawer` para opciones secundarias como Contacto y Cerrar Sesión.
/// - Mostrar un banner de publicidad en la parte inferior.
/// - Coordinar la carga inicial de datos cuando se cambia de pestaña para optimizar
///   el rendimiento y la experiencia del usuario.
library;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:arituki/services/analytics_service.dart';
import 'package:arituki/screens/privacy_policy_page.dart';

import 'package:arituki/providers/location_filter_provider.dart';
import 'package:arituki/providers/cine_city_provider.dart';

import 'package:arituki/screens/event.dart';
import 'package:arituki/screens/favorite.dart';
import 'package:arituki/screens/cine.dart';
import 'package:arituki/screens/programas.dart';
import 'package:arituki/screens/gastro.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  BannerAd? _bannerAd;
  bool _isBannerAdLoaded = false;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  static const int _eventScreenIndex = 0;
  static const int _cineScreenIndex = 2;
  static const int _gastronomiaScreenIndex = 4;

  @override
  void initState() {
    super.initState();
    _loadBannerAd();
    _handleInitialSetup();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadDataForSelectedTab(_selectedIndex, isInitialLoad: true);
      }
    });
  }

  // Configuración inicial síncrona para no bloquear el UI
  void _handleInitialSetup() {
    final prefs = context.read<SharedPreferences>();
    final isFirstTime = prefs.getBool('app_first_time_open') ?? true;

    if (isFirstTime) {
      _configureInitialLocation(prefs);
    }
  }

  // Lógica asíncrona para la primera apertura, no bloquea el arranque.
  Future<void> _configureInitialLocation(SharedPreferences prefs) async {
    await WidgetsBinding.instance.endOfFrame;
    if (!mounted) return;

    final locationProvider = context.read<LocationFilterProvider>();
    await locationProvider.selectComunidad('Aragón');
    await locationProvider.selectProvince('Zaragoza');
    locationProvider.setSelectedCities(['Zaragoza']);
    await prefs.setBool('app_first_time_open', false);
  }

  void _loadBannerAd() {
    // Asegurarse de que los anuncios solo se cargan en plataformas móviles soportadas
    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
      return;
    }

    _bannerAd = BannerAd(
      adUnitId: 'ca-app-pub-6390898456030392/8417730461', // Production ID for Banner
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          if (mounted) {
            setState(() {
              _isBannerAdLoaded = true;
            });
          }
        },
        onAdFailedToLoad: (ad, err) {
          ad.dispose();
        },
      ),
    )..load();
  }

  void _loadDataForSelectedTab(int index, {bool isInitialLoad = false}) {
    if (index == _eventScreenIndex || index == _gastronomiaScreenIndex) {
      final locationFilterProvider =
          Provider.of<LocationFilterProvider>(context, listen: false);

      if (isInitialLoad) {
      } else {
        locationFilterProvider.refresh();
      }
    } else if (index == _cineScreenIndex) {
      if (!isInitialLoad) {
        final cineCityProvider =
            Provider.of<CineCitySelectionProvider>(context, listen: false);
        if (!cineCityProvider.isLoadingCineCities) {
          cineCityProvider.refreshCineCities();
        } else {
        }
      }
    } else {
    }
  }

  void _onItemTapped(int index) {
    final previousIndex = _selectedIndex;
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);

    if (_selectedIndex == index) {
      if (index == _eventScreenIndex || index == _gastronomiaScreenIndex) {
        final locationFilterProvider =
            Provider.of<LocationFilterProvider>(context, listen: false);
        locationFilterProvider.refresh();
      } else if (index == _cineScreenIndex) {
        final cineCityProvider =
            Provider.of<CineCitySelectionProvider>(context, listen: false);
        cineCityProvider.refreshCineCities();
      }
      return;
    }

    if (mounted) {
      setState(() {
        _selectedIndex = index;
      });
    }

    if (previousIndex != index) {
      _loadDataForSelectedTab(index, isInitialLoad: false);

      String itemName;
      switch (index) {
        case 0:
          itemName = 'Eventos';
          break;
        case 1:
          itemName = 'Favoritos';
          break;
        case 2:
          itemName = 'Cine';
          break;
        case 3:
          itemName = 'Programas';
          break;
        case 4:
          itemName = 'Gastronomía';
          break;
        default:
          itemName = 'Desconocido';
      }
      analyticsService.logBottomNavBarTapped(itemName: itemName);
    }
  }

  @override
  void dispose() {
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final List<Widget> widgetOptions = <Widget>[
      EventScreen(scaffoldKey: _scaffoldKey),
      const FavoriteEventsScreen(),
      CineScreenProviderWrapper(scaffoldKey: _scaffoldKey),
      ProgramasScreen(scaffoldKey: _scaffoldKey),
      GastronomiaScreen(scaffoldKey: _scaffoldKey),
    ];

    return Scaffold(
      key: _scaffoldKey,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: <Widget>[
            DrawerHeader(
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
              ),
              child: Text(
                'Menú',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontSize: 24,
                ),
              ),
            ),
            ListTile(
              iconColor: theme.colorScheme.onSurface,
              textColor: theme.colorScheme.onSurface,
              leading: const Icon(Icons.contact_mail),
              title: const Text('Contacto'),
              onTap: () async {
                final Uri emailLaunchUri = Uri(
                  scheme: 'mailto',
                  path: 'arituki.app@gmail.com',
                );
                final scaffoldMessenger = ScaffoldMessenger.of(context);
                Navigator.pop(context);
                if (await canLaunchUrl(emailLaunchUri)) {
                  await launchUrl(emailLaunchUri);
                } else {
                  if (!mounted) return;
                  scaffoldMessenger.showSnackBar(
                    const SnackBar(content: Text('No se pudo abrir la aplicación de correo.')),
                  );
                }
              },
            ),
            ListTile(
              iconColor: theme.colorScheme.onSurface,
              textColor: theme.colorScheme.onSurface,
              leading: const Icon(Icons.privacy_tip_outlined),
              title: const Text('Términos y Privacidad'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PrivacyPolicyPage()),
                );
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: IndexedStack(
              index: _selectedIndex,
              children: widgetOptions,
            ),
          ),
          if (_isBannerAdLoaded && _bannerAd != null)
            SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(ad: _bannerAd!),
            )
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.event),
            label: 'Eventos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: 'Favoritos',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.movie_creation_outlined),
            label: 'Cine',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.festival_outlined),
            label: 'Programas',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            label: 'Gastronomía',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
      ),
    );
  }
}

class CineScreenProviderWrapper extends StatelessWidget {
  final GlobalKey<ScaffoldState> scaffoldKey;
  const CineScreenProviderWrapper({super.key, required this.scaffoldKey});

  @override
  Widget build(BuildContext context) {
    return CineScreen(scaffoldKey: scaffoldKey);
  }
}
