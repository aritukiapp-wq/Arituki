/// Define enumeraciones utilizadas a lo largo de la aplicación.
///
/// Este fichero centraliza las enumeraciones para mantener la consistencia y
/// evitar errores tipográficos, por ejemplo, en los tipos de filtros.
library;

enum PlaceFilter {
  all,
  specific // Podrías usar String? null para 'Todos' en lugar de este enum si prefieres
}

enum DateFilter {
  all,
  today,
  tomorrow,
  thisWeekend,
  nextWeekend,
  thisWeek,
  nextWeek,
  next30Days,
}