/// Fichero de configuración centralizado para la aplicación.
///
/// Contiene constantes estáticas que se utilizan en toda la aplicación, como
/// las claves de API, nombres, locales y otros valores de configuración.
/// Centralizar estos valores aquí facilita su modificación sin tener que
/// buscar en todo el código base.
class AppConfig {
  static const String supabaseUrl = 'https://tgnxgdlnzfobdizwydfc.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InRnbnhnZGxuemZvYmRpend5ZGZjIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDA5MjUwODQsImV4cCI6MjA1NjUwMTA4NH0.t-23-TrDE6_XoKOjcLJ-Ggy8cbtDalv5YX7lppqi0i0';

  // --- AÑADIDO ---
  /// Determina si un usuario debe haber confirmado su email para acceder
  /// a las partes principales de la aplicación después de iniciar sesión.
  ///
  /// Establece esto a `true` si la confirmación de email está habilitada en
  /// la configuración de Supabase Auth y quieres forzarla.
  /// Establécelo a `false` si la confirmación de email no es necesaria o
  /// si los usuarios pueden acceder a la app incluso antes de confirmar.
  static const bool requiresEmailConfirmation = true; // O `false` según tu configuración/preferencia

  // --- AÑADIDOS PARA RESOLVER ERRORES ---
  static const String appName = 'ZgzApp'; // Puedes cambiar este nombre
  static const String appLocale = 'es_ES'; // Puedes cambiar el locale si es necesario
// --- FIN DE LO AÑADIDO ---
}