/// Fichero de configuración centralizado para la aplicación.
class AppConfig {
  /// URL de Supabase. Se puede sobrescribir con --dart-define=SUPABASE_URL=valor
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://tgnxgdlnzfobdizwydfc.supabase.co',
  );

  /// Key anónima de Supabase. Se puede sobrescribir con --dart-define=SUPABASE_ANON_KEY=valor
  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRnbnhnZGxuemZvYmRpend5ZGZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA5MjUwODQsImV4cCI6MjA1NjUwMTA4NH0.t-23-TrDE6_XoKOjcLJ-Ggy8cbtDalv5YX7lppqi0i0',
  );

  static const bool requiresEmailConfirmation = true;
  static const String appName = 'ZgzApp';
  static const String appLocale = 'es_ES';
}
