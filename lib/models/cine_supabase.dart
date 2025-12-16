/// Define el modelo de datos para una película, mapeado desde la base de datos de Supabase.
///
/// Esta clase representa la estructura de una película, incluyendo todos sus
/// atributos relevantes como título, sinopsis, horarios, etc. Se utiliza para
/// la serialización y deserialización de datos entre la aplicación y Supabase.
library;
import 'package:equatable/equatable.dart';

class PeliculaSupabase extends Equatable {
  final String id;
  final DateTime createdAt;
  final String? ciudad;
  final String? lugar;
  final String? titulo;
  final String? fecha;
  final String? dia;
  final String? hora;
  final String? tecnologia;
  final String? duracion;
  final String? edad;
  final String? genero;
  final String? imageUrl;
  final String? ticketUrl;
  final String? eventoUrl;
  final String? sinopsis;
  final String? director;
  final String? reparto;
  final String? cine;
  final int? anio;
  final double? ratingAvg;
  final int? ratingCount;
  final String? pais;

  const PeliculaSupabase({
    required this.id,
    required this.createdAt,
    this.ciudad,
    this.lugar,
    this.titulo,
    this.fecha,
    this.dia,
    this.hora,
    this.tecnologia,
    this.duracion,
    this.edad,
    this.genero,
    this.imageUrl,
    this.ticketUrl,
    this.eventoUrl,
    this.sinopsis,
    this.director,
    this.reparto,
    this.cine,
    this.anio,
    this.ratingAvg,
    this.ratingCount,
    this.pais,
  });

  factory PeliculaSupabase.fromJson(Map<String, dynamic> json) {
    return PeliculaSupabase(
      id: json['id'] as String,
      createdAt: DateTime.parse(json['created_at'] as String),
      ciudad: json['Ciudad'] as String?,
      lugar: json['Lugar'] as String?,
      titulo: json['Titulo'] as String?,
      fecha: json['Fecha'] as String?,
      dia: json['Dia'] as String?,
      hora: json['Hora'] as String?,
      tecnologia: json['Tecnologia'] as String?,
      duracion: json['Duracion'] as String?,
      edad: json['Edad'] as String?,
      genero: json['Genero'] as String?,
      imageUrl: json['ImagenURL'] as String?,
      ticketUrl: json['TicketURL'] as String?,
      eventoUrl: json['EventoURL'] as String?,
      sinopsis: json['Sinopsis'] as String?,
      director: json['Director'] as String?,
      reparto: json['Reparto'] as String?,
      cine: json['Cine'] as String?,
      anio: json['Anio'] as int?,
      ratingAvg: (json['RatingAvg'] as num?)?.toDouble(),
      ratingCount: json['RatingCount'] as int?,
      pais: json['Pais'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'created_at': createdAt.toIso8601String(),
      'Ciudad': ciudad,
      'Lugar': lugar,
      'Titulo': titulo,
      'Fecha': fecha,
      'Dia': dia,
      'Hora': hora,
      'Tecnologia': tecnologia,
      'Duracion': duracion,
      'Edad': edad,
      'Genero': genero,
      'ImagenURL': imageUrl,
      'TicketURL': ticketUrl,
      'EventoURL': eventoUrl,
      'Sinopsis': sinopsis,
      'Director': director,
      'Reparto': reparto,
      'Cine': cine,
      'Anio': anio,
      'RatingAvg': ratingAvg,
      'RatingCount': ratingCount,
      'Pais': pais,
    };
  }

  @override
  List<Object?> get props => [
        id,
        createdAt,
        ciudad,
        lugar,
        titulo,
        fecha,
        dia,
        hora,
        tecnologia,
        duracion,
        edad,
        genero,
        imageUrl,
        ticketUrl,
        eventoUrl,
        sinopsis,
        director,
        reparto,
        cine,
        anio,
        ratingAvg,
        ratingCount,
        pais,
      ];

  @override
  bool get stringify => true;
}
