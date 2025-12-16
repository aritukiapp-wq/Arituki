/// Fichero de utilidades generales.
///
/// Contiene funciones auxiliares y de formato que se utilizan en múltiples
/// partes de la aplicación. Incluye funciones para:
/// - Inicializar la configuración regional para el formato de fechas.
/// - Formatear fechas, horas y rangos de fechas en diferentes estilos.
/// - Extraer el dominio de una URL.
library;
// lib/utils/utils.dart
import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

// Constante para el locale, para asegurar consistencia
const String _appLocale = 'es_ES';

/// Función para inicializar los datos de localización para las fechas.
Future<void> initializeAppLocale() async {
  try {
    await initializeDateFormatting(_appLocale, null);
    if (kDebugMode) {
      print('[$_appLocale] Datos de localización para fechas inicializados correctamente.');
    }
  } catch (e) {
    if (kDebugMode) {
      print('Error al inicializar datos de localización para $_appLocale: $e');
    }
  }
}

String _capitalize(String s) => s.isEmpty ? '' : s[0].toUpperCase() + s.substring(1);

String formatEventDates(DateTime? startDate, DateTime? endDate, String? time) {
  if (startDate == null) {
    return 'Fecha no disponible';
  }

  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = today.add(const Duration(days: 1));

  final bool isSameDay = endDate == null ||
      (startDate.year == endDate.year &&
          startDate.month == endDate.month &&
          startDate.day == endDate.day);

  if (!isSameDay) {
    final dateToCompare = DateTime(endDate.year, endDate.month, endDate.day);
    String finText;
    if (dateToCompare == today) {
      finText = 'hoy';
    } else if (dateToCompare == tomorrow) {
      finText = 'mañana';
    } else {
      finText = DateFormat('E, d MMM', 'es_ES').format(endDate);
    }
    return 'Hasta $finText';
  } else {
    final dateToCompare = DateTime(startDate.year, startDate.month, startDate.day);
    String iniText;
    if (dateToCompare == today) {
      iniText = 'hoy';
    } else if (dateToCompare == tomorrow) {
      iniText = 'mañana';
    } else {
      iniText = DateFormat('E, d MMM', 'es_ES').format(startDate);
    }
    
    String timePart = '';
    if (time != null && time.isNotEmpty) {
      final formattedTime = formatTime(time);
      if (formattedTime.isNotEmpty && !formattedTime.contains('inválida') && !formattedTime.contains('especificada')) {
          timePart = ', $formattedTime';
      }
    }
    return '$iniText$timePart';
  }
}

String formatDate(DateTime? date, {String formatType = 'FULL'}) {
  if (date == null) {
    return 'Fecha no especificada';
  }

  final DateTime localDate = date.toLocal();
  String formattedString;

  try {
    switch (formatType.toUpperCase()) {
      case 'SHORT':
        final dayNumber = DateFormat('d', _appLocale).format(localDate);
        final monthNameAbbr = DateFormat('MMM', _appLocale).format(localDate);
        formattedString = '$dayNumber ${_capitalize(monthNameAbbr.replaceAll('.', ''))}';
        break;

      case 'LONG':
        final dayNameAbbr = DateFormat('E', _appLocale).format(localDate);
        final dayNumber = DateFormat('d', _appLocale).format(localDate);
        final monthNameAbbr = DateFormat('MMM', _appLocale).format(localDate);
        final year = DateFormat('yyyy', _appLocale).format(localDate);
        
        formattedString =
        '${_capitalize(dayNameAbbr.replaceAll('.', ''))}, $dayNumber ${_capitalize(monthNameAbbr.replaceAll('.', ''))} $year';
        break;

      case 'FULL':
        final dayNameFull = DateFormat('EEEE', _appLocale).format(localDate);
        final dayNumber = DateFormat('d', _appLocale).format(localDate);
        final monthNameFull = DateFormat('MMMM', _appLocale).format(localDate);
        final year = DateFormat('yyyy', _appLocale).format(localDate);
        
        formattedString =
        '${_capitalize(dayNameFull)}, $dayNumber ${_capitalize(monthNameFull)} $year';
        break;

      default:
        formattedString = localDate.toIso8601String().substring(0, 10);
        break;
    }
    return formattedString;
  } catch (e) {
    return 'Fecha inválida (error)';
  }
}

String formatDateRange(DateTime? startDate, DateTime? endDate,
    {String formatType = 'SHORT'}) {
  if (startDate == null && endDate == null) {
    return 'Fechas no disponibles';
  }

  String result;

  if (startDate != null && endDate != null) {
    final bool isSameDay = startDate.year == endDate.year &&
        startDate.month == endDate.month &&
        startDate.day == endDate.day;

    if (isSameDay) {
      result = formatDate(startDate, formatType: formatType);
    } else {
      final String startFormatted = formatDate(
          startDate, formatType: formatType);
      final String endFormatted = formatDate(endDate, formatType: formatType);
      result = "$startFormatted - $endFormatted";
    }
  } else if (startDate != null) {
    result = formatDate(startDate, formatType: formatType);
  } else {
    result = formatDate(endDate!,
        formatType: formatType);
  }

  return result;
}

String formatFullDateFromString(String? dateString) {
  if (dateString == null || dateString.isEmpty) {
    return 'Fecha no especificada';
  }
  try {
    final DateTime dateTime = DateTime.parse(dateString);
    return formatDate(dateTime, formatType: 'FULL');
  } catch (e) {
    return 'Fecha inválida';
  }
}

String formatTime(String? timeString) {
  if (timeString == null || timeString.isEmpty) {
    return 'Hora no especificada';
  }

  try {
    DateTime parsedTime;
    try {
      final now = DateTime.now();
      List<String> parts = timeString.split(':');
      if (parts.length >= 2) {
        int hour = int.parse(parts[0]);
        int minute = int.parse(parts[1]);
        int second = parts.length > 2 ? int.parse(parts[2]) : 0;
        parsedTime =
            DateTime(now.year, now.month, now.day, hour, minute, second);
      } else {
        throw const FormatException("Formato de hora inválido");
      }
    } catch (e) {
      return 'Hora inválida (parseo)';
    }

    final formatter = DateFormat('HH:mm', _appLocale);
    return formatter.format(parsedTime);
  } catch (e) {
    return 'Hora inválida';
  }
}

String extractDomainFromUrl(String? urlString) {
  if (urlString == null || urlString.isEmpty) {
    return '';
  }
  try {
    Uri uri = Uri.parse(urlString);
    String host = uri.host;

    if (host.isEmpty) {
      return '';
    }

    List<String> parts = host.split('.');
    if (parts.length > 2) {
      if (parts[parts.length - 2].length <= 3 &&
          parts.length - 3 >= 0) { 
        return parts.sublist(parts.length - 3).join('.');
      }
      return parts.sublist(parts.length - 2).join('.');
    } else {
      return host;
    }
  } catch (e) {
    return '';
  }
}
