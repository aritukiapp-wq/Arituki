/// Modela los datos de un evento, directamente desde la base de datos de Supabase.
///
/// Esta clase define la estructura de un evento, conteniendo todos los campos
/// relevantes como el título, la descripción, las fechas y la información de
/// ubicación. Facilita la conversión de datos JSON a objetos Dart y viceversa.
library;
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart';

class EventoSupabase extends Equatable {
  final String id;
  final DateTime createdAt;
  final String? ciudad;
  final String? lugar;
  final String? categoria;
  final String? titulo;
  final String? subtitulo;
  final String? imageUrl;
  final String? eventoUrl;
  final DateTime? dia;
  final String? hora;
  final String? sinopsis;
  final String? precio;
  final String? duracion;
  final String? edad;
  final String? etiqueta;
  final String? ticketUrl;
  final DateTime? diaIni;
  final DateTime? diaFin;
  final DateTime? fechaInscripIni;
  final DateTime? fechaInscripFin;
  final String? fecha;
  final int? likesCount;
  final int? dislikesCount;
  final String? comunidad;
  final String? provincia;
  final String? googleMapsUrl;
  final String? programaUrl;

  const EventoSupabase({
    required this.id,
    required this.createdAt,
    this.ciudad,
    this.lugar,
    this.categoria,
    this.titulo,
    this.subtitulo,
    this.imageUrl,
    this.eventoUrl,
    this.dia,
    this.hora,
    this.sinopsis,
    this.precio,
    this.duracion,
    this.edad,
    this.etiqueta,
    this.ticketUrl,
    this.diaIni,
    this.diaFin,
    this.fechaInscripIni,
    this.fechaInscripFin,
    this.fecha,
    this.likesCount,
    this.dislikesCount,
    this.comunidad,
    this.provincia,
    this.googleMapsUrl,
    this.programaUrl,
  });

  factory EventoSupabase.fromJson(Map<String, dynamic> json) {
    DateTime? parseSafeDateTime(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        if (kDebugMode) {
          print('[EventoSupabase.fromJson] Error parsing date: "$dateStr", error: $e');
        }
        return null;
      }
    }

    return EventoSupabase(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      ciudad: json['Ciudad'] as String?,
      lugar: json['Lugar'] as String?,
      categoria: json['Categoria'] as String?,
      titulo: json['Titulo'] as String?,
      subtitulo: json['Subtitulo'] as String?,
      imageUrl: json['ImagenURL'] as String?,
      eventoUrl: json['EventoURL'] as String?,
      dia: parseSafeDateTime(json['Dia'] as String?),
      hora: json['Hora'] as String?,
      sinopsis: json['Sinopsis'] as String?,
      precio: json['Precio'] as String?,
      duracion: json['Duracion'] as String?,
      edad: json['Edad'] as String?,
      etiqueta: json['Etiqueta'] as String?,
      ticketUrl: json['TicketURL'] as String?,
      diaIni: parseSafeDateTime(json['DiaIni'] as String?),
      diaFin: parseSafeDateTime(json['DiaFin'] as String?),
      fechaInscripIni: parseSafeDateTime(json['FechaInscripIni'] as String?),
      fechaInscripFin: parseSafeDateTime(json['FechaInscripFin'] as String?),
      fecha: json['Fecha'] as String?,
      likesCount: json['likes_count'] as int?,
      dislikesCount: json['dislikes_count'] as int?,
      comunidad: json['Comunidad'] as String?,
      provincia: json['Provincia'] as String?,
      googleMapsUrl: json['GoogleMapsURL'] as String?,
      programaUrl: json['ProgramaURL'] as String?,
    );
  }

   Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'Ciudad': ciudad,
      'Lugar': lugar,
      'Categoria': categoria,
      'Titulo': titulo,
      'Subtitulo': subtitulo,
      'ImagenURL': imageUrl,
      'EventoURL': eventoUrl,
      'Dia': dia?.toIso8601String().split('T').first,
      'Hora': hora,
      'Sinopsis': sinopsis,
      'Precio': precio,
      'Duracion': duracion,
      'Edad': edad,
      'Etiqueta': etiqueta,
      'TicketURL': ticketUrl,
      'DiaIni': diaIni?.toIso8601String().split('T').first,
      'DiaFin': diaFin?.toIso8601String().split('T').first,
      'FechaInscripIni': fechaInscripIni?.toIso8601String().split('T').first,
      'FechaInscripFin': fechaInscripFin?.toIso8601String().split('T').first,
      'Fecha': fecha,
      'likes_count': likesCount,
      'dislikes_count': dislikesCount,
      'Comunidad': comunidad,
      'Provincia': provincia,
      'GoogleMapsURL': googleMapsUrl,
      'ProgramaURL': programaUrl,
    }..removeWhere((key, value) => value == null);
  }

  @override
  List<Object?> get props => [
        id,
        createdAt,
        ciudad,
        lugar,
        categoria,
        titulo,
        subtitulo,
        imageUrl,
        eventoUrl,
        dia,
        hora,
        sinopsis,
        precio,
        duracion,
        edad,
        etiqueta,
        ticketUrl,
        diaIni,
        diaFin,
        fechaInscripIni,
        fechaInscripFin,
        fecha,
        likesCount,
        dislikesCount,
        comunidad,
        provincia,
        googleMapsUrl,
        programaUrl,
      ];

  @override
  bool get stringify => true;
}
