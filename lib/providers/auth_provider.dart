/// Gestiona el estado de autenticación del usuario anónimo.
///
/// Este provider se encarga de:
/// - Mantener el estado actual del usuario (logueado anónimamente o no).
/// - Escuchar los cambios en el estado de autenticación de Supabase y notificar a los listeners.
library;
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthProvider with ChangeNotifier {
  final SupabaseClient _supabaseClient;
  User? _currentUser;
  StreamSubscription<AuthState>? _authSubscription;

  User? get currentUser => _currentUser;

  bool get isLoggedIn => _currentUser != null;

  AuthProvider({required SupabaseClient supabaseClient}) : _supabaseClient = supabaseClient {
    _currentUser = _supabaseClient.auth.currentUser;

    _authSubscription = _supabaseClient.auth.onAuthStateChange.listen(
      (data) {
        _currentUser = data.session?.user;

        notifyListeners();
      },
      onError: (error) {
      },
    );
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}
