import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arituki/models/event_supabase.dart';
import 'package:arituki/repositories/event_repository.dart';
import 'package:arituki/providers/event_fetching_provider.dart';
import 'package:arituki/providers/event_filter_provider.dart';
import 'package:arituki/providers/event_sort_provider.dart';
import 'package:arituki/providers/location_filter_provider.dart';
import 'package:arituki/services/analytics_service.dart';

import 'widget_test.mocks.dart';

@GenerateMocks([
  SharedPreferences,
  EventRepository,
  EventFetchingProvider,
  EventFilterProvider,
  EventSortProvider,
  LocationFilterProvider,
  AnalyticsService,
])
void main() {
  late MockSharedPreferences mockSharedPreferences;
  late MockEventRepository mockEventRepository;
  late MockLocationFilterProvider mockLocationFilterProvider;
  late MockAnalyticsService mockAnalyticsService;

  final mockEvento1 = EventoSupabase(
    id: '1',
    titulo: 'Evento Test',
    ciudad: 'Zaragoza',
    provincia: 'Zaragoza',
    createdAt: DateTime.now(),
    comunidad: 'Aragón',
  );

  final mockEvento2 = EventoSupabase(
    id: '2',
    titulo: 'Otro Evento',
    ciudad: 'Huesca',
    provincia: 'Huesca',
    createdAt: DateTime.now(),
    comunidad: 'Aragón',
  );

  final List<EventoSupabase> mockEventList = [mockEvento1, mockEvento2];

  const String selectedComunidadPrefKey = 'selected_event_comunidad_pref_v1';
  const String selectedProvincePrefKey = 'selected_event_province_pref_v1';
  const String selectedCitiesPrefKey = 'selected_event_cities_pref_v1';

  setUp(() {
    WidgetsFlutterBinding.ensureInitialized();

    mockSharedPreferences = MockSharedPreferences();
    mockEventRepository = MockEventRepository();
    mockLocationFilterProvider = MockLocationFilterProvider();
    mockAnalyticsService = MockAnalyticsService();

    // Configuración genérica para SharedPreferences
    when(mockSharedPreferences.getStringList(any)).thenReturn([]);
    when(mockSharedPreferences.setStringList(any, any)).thenAnswer((_) async => true);
    when(mockSharedPreferences.getString(any)).thenReturn(null);
    when(mockSharedPreferences.setString(any, any)).thenAnswer((_) async => true);

    // Configuración específica para SharedPreferences
    when(mockSharedPreferences.getString(selectedComunidadPrefKey)).thenReturn('Aragón');
    when(mockSharedPreferences.getString(selectedProvincePrefKey)).thenReturn('Zaragoza');
    when(mockSharedPreferences.getString(selectedCitiesPrefKey)).thenReturn('["Zaragoza"]');

    // Configuración para el nuevo AnalyticsService
    when(mockAnalyticsService.logEventFavoriteToggle(eventName: anyNamed('eventName'), isFavorite: anyNamed('isFavorite')))
        .thenAnswer((_) async => Future.value(null));
    when(mockAnalyticsService.logEventBlockToggle(eventName: anyNamed('eventName'), isBlocked: anyNamed('isBlocked')))
        .thenAnswer((_) async => Future.value(null));
    when(mockAnalyticsService.logEventDetailView(eventName: anyNamed('eventName'), placeName: anyNamed('placeName'), cityName: anyNamed('cityName')))
        .thenAnswer((_) async => Future.value(null));
    when(mockAnalyticsService.logEventInteraction(eventName: anyNamed('eventName'), interaction: anyNamed('interaction')))
        .thenAnswer((_) async => Future.value(null));
    when(mockAnalyticsService.logEventLinkClick(eventName: anyNamed('eventName'), linkType: anyNamed('linkType')))
        .thenAnswer((_) async => Future.value(null));
    when(mockAnalyticsService.logFilterChange(filterType: anyNamed('filterType'), value: anyNamed('value')))
        .thenAnswer((_) async => Future.value(null));
    when(mockAnalyticsService.logLocationFilterChange(
      filterType: anyNamed('filterType'),
      comunidad: anyNamed('comunidad'),
      province: anyNamed('province'),
      cities: anyNamed('cities'),
    )).thenAnswer((_) async => Future.value(null));
    when(mockAnalyticsService.logBottomNavBarTapped(itemName: anyNamed('itemName')))
        .thenAnswer((_) async => Future.value());

    // Configuración para EventRepository
    when(mockEventRepository.getEventCount(
      startDate: anyNamed('startDate'),
      endDate: anyNamed('endDate'),
      city: anyNamed('city'),
      province: anyNamed('province'),
      selectedPlaceName: anyNamed('selectedPlaceName'),
    )).thenAnswer((_) async => mockEventList.length);
    when(mockEventRepository.fetchEvents(
      searchQuery: anyNamed('searchQuery'),
      limit: argThat(isA<int>(), named: 'limit'),
      offset: argThat(isA<int>(), named: 'offset'),
      startDate: anyNamed('startDate'),
      endDate: anyNamed('endDate'),
      city: anyNamed('city'),
      province: anyNamed('province'),
      selectedPlaceName: anyNamed('selectedPlaceName'),
    )).thenAnswer((_) async => mockEventList);
    when(mockEventRepository.getDistinctComunidades()).thenAnswer((_) async => ['Aragón', 'Cataluña']);
    when(mockEventRepository.getDistinctProvinces(comunidadName: anyNamed('comunidadName'))).thenAnswer((_) async => ['Zaragoza', 'Huesca', 'Teruel']);
    when(mockEventRepository.getCitiesForProvince(any)).thenAnswer((invocation) async {
      final province = invocation.positionalArguments[0] as String?;
      if (province == 'Zaragoza') return ['Zaragoza', 'Calatayud'];
      if (province == 'Huesca') return ['Huesca', 'Jaca'];
      return ['Otra Ciudad'];
    });

    // Configuración para LocationFilterProvider
    when(mockLocationFilterProvider.comunidades).thenReturn(['Aragón', 'Cataluña']);
    when(mockLocationFilterProvider.selectedComunidad).thenReturn('Aragón');
    when(mockLocationFilterProvider.isLoadingComunidades).thenReturn(false);
    when(mockLocationFilterProvider.comunidadError).thenReturn(null);
    when(mockLocationFilterProvider.provinces).thenReturn(['Zaragoza', 'Huesca', 'Teruel']);
    when(mockLocationFilterProvider.selectedProvince).thenReturn('Zaragoza');
    when(mockLocationFilterProvider.isLoadingProvinces).thenReturn(false);
    when(mockLocationFilterProvider.provinceError).thenReturn(null);
    when(mockLocationFilterProvider.availableCitiesForProvince).thenReturn(['Zaragoza', 'Calatayud']);
    when(mockLocationFilterProvider.selectedEventCities).thenReturn(['Zaragoza']);
    when(mockLocationFilterProvider.isLoadingCities).thenReturn(false);
    when(mockLocationFilterProvider.cityError).thenReturn(null);
    when(mockLocationFilterProvider.isReady).thenReturn(true);
    when(mockLocationFilterProvider.loadComunidades()).thenAnswer((_) async {});
    when(mockLocationFilterProvider.selectComunidad(any)).thenAnswer((_) async {});
    when(mockLocationFilterProvider.loadProvinces(fromUser: anyNamed('fromUser'))).thenAnswer((_) async {});
    when(mockLocationFilterProvider.selectProvince(any)).thenAnswer((_) async {});
  });

  // Aquí irían tus tests...
}
