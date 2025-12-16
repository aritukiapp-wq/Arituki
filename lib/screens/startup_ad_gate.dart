import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:arituki/services/app_open_ad_manager.dart';
import 'package:arituki/screens/home_page.dart';

class StartupAdGate extends StatefulWidget {
  const StartupAdGate({super.key});

  @override
  State<StartupAdGate> createState() => _StartupAdGateState();
}

class _StartupAdGateState extends State<StartupAdGate> {
  Timer? _timeoutTimer;
  bool _navigationHandled = false;
  late AppOpenAdManager _adManager;

  @override
  void initState() {
    super.initState();
    _adManager = context.read<AppOpenAdManager>();
    
    // Iniciar un temporizador de seguridad. Si el anuncio no se carga
    // en 5 segundos, navegamos a la home para no bloquear al usuario.
    _timeoutTimer = Timer(const Duration(seconds: 5), _navigateToHome);

    // Escuchamos los cambios de estado del manager de anuncios.
    _adManager.addListener(_onAdStateChanged);

    // Comprobar el estado actual por si el anuncio ya estaba listo
    _onAdStateChanged();
  }

  void _onAdStateChanged() {
    if (_navigationHandled) return;

    final adState = _adManager.adState;

    if (adState == AppOpenAdState.loaded) {
      // El anuncio está listo, lo mostramos.
      _timeoutTimer?.cancel();
      _adManager.showAdIfAvailable(
        fromLogin: true,
        onAdDismissed: _navigateToHome,
      );
    } else if (adState == AppOpenAdState.error) {
      // Si hay un error, no esperamos y vamos a la home.
      _timeoutTimer?.cancel();
      _navigateToHome();
    }
  }

  void _navigateToHome() {
    if (!mounted || _navigationHandled) return;
    
    _navigationHandled = true; // Prevenir múltiples navegaciones
    _timeoutTimer?.cancel();
    _adManager.removeListener(_onAdStateChanged);

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const HomePage()),
    );
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _adManager.removeListener(_onAdStateChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Siempre mostramos una pantalla de carga mientras se gestiona el anuncio.
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}
