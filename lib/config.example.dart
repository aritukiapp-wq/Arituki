/// Fichero de ejemplo para la configuración de la aplicación.
/// 
/// Para usarlo, copia este archivo como `lib/config.dart` y completa
/// los valores con tus propias claves.
class AppConfig {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'TU_SUPABASE_URL_AQUI',
  );
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'TU_SUPABASE_ANON_KEY_AQUI',
  );

  static const bool requiresEmailConfirmation = true;
  static const String appName = 'Arituki';
  static const String appLocale = 'es_ES';
}
