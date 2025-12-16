/// Fichero principal de la aplicación.
///
/// Contiene el punto de entrada `main` y la configuración inicial de la app,
/// incluyendo la inicialización de servicios y la configuración de los
/// providers de estado.
library;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

// Packages
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:provider/single_child_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Config & Theme
import 'config.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';

// Services
import 'services/analytics_service.dart';
import 'services/app_lifecycle_reactor.dart';
import 'services/app_open_ad_manager.dart';
import 'services/cine_service.dart';
import 'services/event_service.dart';
import 'services/gastro_service.dart';
import 'services/like_service.dart';
import 'services/location_service.dart';
import 'services/programas_service.dart';

// Repositories
import 'repositories/event_repository.dart';

// Providers
import 'providers/auth_provider.dart';
import 'providers/blocked_event_provider.dart';
import 'providers/blocked_place_provider.dart';
import 'providers/cine_city_provider.dart';
import 'providers/cine_provider.dart';
import 'providers/event_fetching_provider.dart';
import 'providers/event_filter_provider.dart';
import 'providers/event_interaction_provider.dart';
import 'providers/event_presentation_provider.dart';
import 'providers/event_sort_provider.dart';
import 'providers/favorite_event_provider.dart';
import 'providers/favorite_place_provider.dart';
import 'providers/favorite_presentation_provider.dart';
import 'providers/gastro_provider.dart';
import 'providers/location_filter_provider.dart';
import 'providers/programas_provider.dart';

// Screens
import 'screens/policy_gate.dart';

void main() {
  // Wrap the app in a guarded zone to catch all uncaught errors.
  runZonedGuarded<Future<void>>(() async {
    WidgetsFlutterBinding.ensureInitialized();
    // Initialize Firebase first.
    await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

    // Set up Crashlytics error handlers.
    // Pass all uncaught "fatal" errors from the framework to Crashlytics.
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

    // Pass all uncaught asynchronous errors that are not handled by the Flutter framework to Crashlytics.
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    runApp(const MyApp());
  }, 
  // This is the handler for errors caught by the zone.
  (error, stack) => FirebaseCrashlytics.instance.recordError(error, stack, fatal: true));
}

/// Clase de datos para contener los resultados de la inicialización asíncrona.
class _AppInitializationResult {
  final SharedPreferences prefs;
  final SupabaseClient supabaseClient;
  final AppOpenAdManager appOpenAdManager;
  final AppLifecycleReactor appLifecycleReactor;
  final FirebaseAnalyticsObserver navigatorObserver;

  _AppInitializationResult({
    required this.prefs,
    required this.supabaseClient,
    required this.appOpenAdManager,
    required this.appLifecycleReactor,
    required this.navigatorObserver,
  });
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<_AppInitializationResult> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initialize();
  }

  /// Ejecuta todas las inicializaciones asíncronas necesarias para la app.
  Future<_AppInitializationResult> _initialize() async {
    // --- Pre-inicializaciones ---
    final AppOpenAdManager appOpenAdManager = AppOpenAdManager();
    final AppLifecycleReactor appLifecycleReactor =
        AppLifecycleReactor(appOpenAdManager: appOpenAdManager);

    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      appOpenAdManager.loadAd();
      appLifecycleReactor.init();
    }
    
    // --- Inicializaciones en Paralelo ---
    // Firebase is already initialized in main().
    final List<Future> initFutures = [
      Supabase.initialize(url: AppConfig.supabaseUrl, anonKey: AppConfig.supabaseAnonKey),
      initializeDateFormatting(AppConfig.appLocale, null),
      SharedPreferences.getInstance(),
    ];

    if (!kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS)) {
      initFutures.add(MobileAds.instance.initialize());
    }

    final List<dynamic> initResults = await Future.wait(initFutures);

    // --- Post-inicializaciones ---
    final SharedPreferences prefs = initResults[2] as SharedPreferences;
    final SupabaseClient supabaseClient = Supabase.instance.client;

    if (supabaseClient.auth.currentUser == null) {
      await supabaseClient.auth.signInAnonymously();
    }
    
    final FirebaseAnalyticsObserver navigatorObserver =
        FirebaseAnalyticsObserver(analytics: FirebaseAnalytics.instance);

    return _AppInitializationResult(
      prefs: prefs,
      supabaseClient: supabaseClient,
      appOpenAdManager: appOpenAdManager,
      appLifecycleReactor: appLifecycleReactor,
      navigatorObserver: navigatorObserver,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_AppInitializationResult>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        // --- Pantalla de Error ---
        if (snapshot.hasError) {
          // Also report this error to Crashlytics
          FirebaseCrashlytics.instance.recordError(snapshot.error, snapshot.stackTrace, fatal: true);
          return SupabaseInitErrorApp(error: snapshot.error.toString());
        }

        // --- Pantalla de Carga ---
        if (snapshot.connectionState != ConnectionState.done) {
          return const MaterialApp(
            home: Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          );
        }
        
        // --- App Inicializada ---
        final initResult = snapshot.data!;
        return MultiProvider(
          providers: _buildProviders(
            initResult.prefs,
            initResult.supabaseClient,
            initResult.appOpenAdManager,
            initResult.appLifecycleReactor,
          ),
          child: MaterialApp(
            title: AppConfig.appName,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: ThemeMode.system,
            navigatorObservers: [initResult.navigatorObserver],
            home: const PolicyGate(),
          ),
        );
      },
    );
  }
}

List<SingleChildWidget> _buildProviders(
  SharedPreferences prefs,
  SupabaseClient supabaseClient,
  AppOpenAdManager appOpenAdManager,
  AppLifecycleReactor appLifecycleReactor,
) {
  return [
    // --- ADS ---
    ChangeNotifierProvider<AppOpenAdManager>.value(value: appOpenAdManager),
    Provider<AppLifecycleReactor>.value(value: appLifecycleReactor),
    
    // --- CORE SERVICES & DATA ---
    Provider<SharedPreferences>.value(value: prefs),
    Provider<SupabaseClient>.value(value: supabaseClient),
    Provider<AnalyticsService>(create: (_) => AnalyticsService(FirebaseAnalytics.instance)),
    Provider<EventService>(create: (_) => EventService(supabaseClient)),
    Provider<LocationService>(create: (_) => LocationService(supabaseClient: supabaseClient)),
    Provider<LikeService>(create: (_) => LikeService(supabaseClient: supabaseClient)),
    Provider<CineService>(create: (_) => CineService(supabaseClient: supabaseClient)),
    Provider<ProgramaService>(create: (_) => ProgramaService(supabaseClient: supabaseClient)),
    Provider<GastronomiaService>(create: (_) => GastronomiaService(supabaseClient: supabaseClient)),
    Provider<EventRepository>(
      create: (context) => EventRepository(
          eventService: context.read<EventService>(),
          locationService: context.read<LocationService>()),
    ),

    // --- USER & AUTHENTICATION ---
    ChangeNotifierProvider<AuthProvider>(
        create: (_) => AuthProvider(supabaseClient: supabaseClient)),
    ChangeNotifierProxyProvider4<SharedPreferences, AuthProvider, AnalyticsService, LikeService, EventInteractionProvider>(
        create: (context) => EventInteractionProvider(
            prefs: context.read<SharedPreferences>(),
            authProvider: context.read<AuthProvider>(),
            analyticsService: context.read<AnalyticsService>(),
            likeService: context.read<LikeService>()),
        update: (_, prefs, auth, analytics, likeService, prev) {
            final provider = prev ?? EventInteractionProvider(
                prefs: prefs, authProvider: auth, analyticsService: analytics, likeService: likeService);
            provider.updateAuth(auth);
            return provider;
        }),

    // --- FAVORITES & BLOCKED ---
    ChangeNotifierProvider(
      create: (context) => FavoriteEventProvider(
        prefs: context.read<SharedPreferences>(),
        analyticsService: context.read<AnalyticsService>(),
      ),
    ),
    ChangeNotifierProvider(
      create: (context) => BlockedEventProvider(
        prefs: context.read<SharedPreferences>(),
        analyticsService: context.read<AnalyticsService>(),
      ),
    ),
    ChangeNotifierProxyProvider2<SharedPreferences, AnalyticsService, BlockedPlaceProvider>(
        create: (context) => BlockedPlaceProvider(
            prefs: context.read<SharedPreferences>(),
            analyticsService: context.read<AnalyticsService>()),
        update: (_, prefs, analytics, prev) => prev ?? BlockedPlaceProvider(prefs: prefs, analyticsService: analytics)),
    ChangeNotifierProxyProvider2<SharedPreferences, AnalyticsService, FavoritePlaceProvider>(
        create: (context) => FavoritePlaceProvider(
            prefs: context.read<SharedPreferences>(),
            analyticsService: context.read<AnalyticsService>()),
        update: (_, prefs, analytics, prev) => prev ?? FavoritePlaceProvider(prefs: prefs, analyticsService: analytics)),
    ChangeNotifierProxyProvider2<FavoritePlaceProvider, FavoriteEventProvider, FavoritesPresentationProvider>(
        create: (context) => FavoritesPresentationProvider(context.read<EventRepository>()),
        update: (context, favPlaceProvider, favEventProvider, presentationProvider) {
          presentationProvider?.updateDependencies(
            favoritePlaceProvider: favPlaceProvider,
            favoriteEventProvider: favEventProvider,
          );
          return presentationProvider!;
        },
    ),

    // --- CONTENT SPECIFIC PROVIDERS ---
    ChangeNotifierProvider<LocationFilterProvider>(
      create: (context) => LocationFilterProvider(
        eventRepository: context.read<EventRepository>(),
        analyticsService: context.read<AnalyticsService>(),
        prefs: context.read<SharedPreferences>(),
      ),
    ),
    ChangeNotifierProxyProvider<LocationFilterProvider, ProgramasProvider>(
      create: (context) => ProgramasProvider(programaService: context.read<ProgramaService>()),
      update: (context, locationProvider, programasProvider) {
        programasProvider?.updateDependencies(locationProvider);
        return programasProvider!;
      },
    ),
    ChangeNotifierProxyProvider<LocationFilterProvider, GastronomiaProvider>(
      create: (context) => GastronomiaProvider(gastronomiaService: context.read<GastronomiaService>()),
      update: (context, locationProvider, gastronomiaProvider) {
        gastronomiaProvider?.updateDependencies(locationProvider);
        return gastronomiaProvider!;
      },
    ),
    ChangeNotifierProvider<CineCitySelectionProvider>(
      create: (context) => CineCitySelectionProvider(
          prefs: context.read<SharedPreferences>(),
          analyticsService: context.read<AnalyticsService>(),
          cineService: context.read<CineService>()),
    ),
    ChangeNotifierProxyProvider<CineCitySelectionProvider, CineProvider>(
      create: (context) => CineProvider(context.read<CineService>()),
      update: (context, cityProvider, cineProvider) {
        cineProvider?.updateDependencies(cityProvider);
        return cineProvider!;
      },
    ),

    // --- EVENT PRESENTATION LAYER ---
    ChangeNotifierProvider<EventSortProvider>(create: (_) => EventSortProvider()),
    ChangeNotifierProxyProvider2<BlockedPlaceProvider, AnalyticsService, EventFilterProvider>(
      create: (context) => EventFilterProvider(
          blockedProvider: context.read<BlockedPlaceProvider>(),
          analyticsService: context.read<AnalyticsService>(),
          initialDateFilterValue: "Hoy"),
      update: (context, blocked, analytics, prev) {
        return prev ?? EventFilterProvider(blockedProvider: blocked, analyticsService: analytics, initialDateFilterValue: "Hoy");
      },
    ),
    ChangeNotifierProxyProvider3<EventFilterProvider, LocationFilterProvider, BlockedPlaceProvider, EventFetchingProvider>(
      create: (context) => EventFetchingProvider(eventRepository: context.read<EventRepository>()),
      update: (context, filterProvider, locationProvider, blockedPlaceProvider, fetchingProvider) {
        fetchingProvider!.updateDependencies(filterProvider, locationProvider, blockedPlaceProvider);
        return fetchingProvider;
      },
    ),
    ChangeNotifierProxyProvider4<
        EventFetchingProvider,
        EventFilterProvider, 
        EventSortProvider,
        BlockedEventProvider,
        EventPresentationProvider>(
      create: (context) => EventPresentationProvider(
          fetchingProvider: context.read<EventFetchingProvider>(),
          filterProvider: context.read<EventFilterProvider>(), 
          sortProvider: context.read<EventSortProvider>(),
          blockedEventProvider: context.read<BlockedEventProvider>()),
      update: (_, fetching, filter, sort, blocked, prev) {
        final provider = prev ?? EventPresentationProvider(
              fetchingProvider: fetching, filterProvider: filter, sortProvider: sort, blockedEventProvider: blocked);
        provider.updateDependencies(
            newFetchingProvider: fetching,
            newFilterProvider: filter, 
            newSortProvider: sort,
            newBlockedEventProvider: blocked, 
          );
        return provider;
      },
    ),
  ];
}

// Se mantiene para ser usado en caso de error en el FutureBuilder
class SupabaseInitErrorApp extends StatelessWidget {
  final String error;
  const SupabaseInitErrorApp({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Text(
              "Error inicializando la app:\n$error\n\nPor favor, reinicia la aplicación.",
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
