/// Representa el modelo de datos para un ítem de una ruta gastronómica,
/// mapeado desde la base de datos de Supabase.
///
/// Esta clase encapsula la información de un punto de interés gastronómico,
/// como un restaurante o un bar, dentro de una ruta o evento específico.
/// Incluye detalles como el nombre, la tapa, la dirección y los datos de contacto.
library;
import 'package:equatable/equatable.dart';
import 'package:flutter/foundation.dart'; // Para kDebugMode y print

class RutaGastroItem extends Equatable {
  final String id;
  final String? nombreRutaPadre;
  final String? restaurante;
  final String? evento;
  final String? tapa;
  final String? sinopsis;
  final String? direccion;
  final String? ciudad;
  final String? provincia;
  final String? comunidad;
  final String? telefono;
  final String? precio;
  final DateTime? dia;
  final String? imageUrl;
  final String? eventoUrl;
  final String? googleUrl;
  final String? wwwUrl;
  final String? tipo;
  final String? facebook;
  final String? instagram;
  final String? email;
  final String? xUrl;

  const RutaGastroItem({
    required this.id,
    this.nombreRutaPadre,
    this.restaurante,
    this.evento,
    this.tapa,
    this.sinopsis,
    this.direccion,
    this.ciudad,
    this.provincia,
    this.comunidad,
    this.telefono,
    this.precio,
    this.dia,
    this.imageUrl,
    this.eventoUrl,
    this.googleUrl,
    this.wwwUrl,
    this.tipo,
    this.facebook,
    this.instagram,
    this.email,
    this.xUrl,
  });

  factory RutaGastroItem.fromJson(Map<String, dynamic> json) {
    T getRequiredField<T>(String key) {
      final value = json[key];
      if (value == null) {
        throw FormatException("El campo '$key' es nulo en el JSON, pero es requerido.");
      }
      return value as T;
    }

    DateTime? parseSafeDate(String? dateStr) {
      if (dateStr == null || dateStr.isEmpty) return null;
      try {
        return DateTime.parse(dateStr);
      } catch (e) {
        if (kDebugMode) {
          print("Error parsing date in RutaGastroItem for '$dateStr': $e. Source JSON: $json");
        }
        return null;
      }
    }

    return RutaGastroItem(
      id: getRequiredField<String>('id'),
      nombreRutaPadre: json['NombreRuta'] as String?,
      restaurante: json['Restaurante'] as String?,
      evento: json['Evento'] as String?,
      tapa: json['Tapa'] as String?,
      sinopsis: json['Sinopsis'] as String?,
      direccion: json['Direccion'] as String?,
      ciudad: json['Ciudad'] as String?,
      provincia: json['Provincia'] as String?,
      comunidad: json['Comunidad'] as String?,
      telefono: json['Telefono'] as String?,
      precio: json['Precio'] as String?,
      dia: parseSafeDate(json['Dia'] as String?),
      imageUrl: json['ImagenURL'] as String?,
      eventoUrl: json['EventoURL'] as String?,
      googleUrl: json['GoogleURL'] as String?,
      wwwUrl: json['www_url'] as String?,
      tipo: json['Tipo'] as String?,
      facebook: json['Facebook'] as String?,
      instagram: json['Instagram'] as String?,
      email: json['Email'] as String?,
      xUrl: json['x_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'NombreRuta': nombreRutaPadre,
      'Restaurante': restaurante,
      'Evento': evento,
      'Tapa': tapa,
      'Sinopsis': sinopsis,
      'Direccion': direccion,
      'Ciudad': ciudad,
      'Provincia': provincia,
      'Comunidad': comunidad,
      'Telefono': telefono,
      'Precio': precio,
      'Dia': dia?.toIso8601String().split('T').first,
      'ImagenURL': imageUrl,
      'EventoURL': eventoUrl,
      'GoogleURL': googleUrl,
      'www_url': wwwUrl,
      'Tipo': tipo,
      'Facebook': facebook,
      'Instagram': instagram,
      'Email': email,
      'x_url': xUrl,
    }..removeWhere((key, value) => value == null);
  }

  RutaGastroItem copyWith({
    String? id,
    String? nombreRutaPadre,
    String? restaurante,
    String? evento,
    String? tapa,
    String? sinopsis,
    String? direccion,
    String? ciudad,
    String? provincia,
    String? comunidad,
    String? telefono,
    String? precio,
    DateTime? dia,
    String? imageUrl,
    String? eventoUrl,
    String? googleUrl,
    String? wwwUrl,
    String? tipo,
    String? facebook,
    String? instagram,
    String? email,
    String? xUrl,
  }) {
    return RutaGastroItem(
      id: id ?? this.id,
      nombreRutaPadre: nombreRutaPadre ?? this.nombreRutaPadre,
      restaurante: restaurante ?? this.restaurante,
      evento: evento ?? this.evento,
      tapa: tapa ?? this.tapa,
      sinopsis: sinopsis ?? this.sinopsis,
      direccion: direccion ?? this.direccion,
      ciudad: ciudad ?? this.ciudad,
      provincia: provincia ?? this.provincia,
      comunidad: comunidad ?? this.comunidad,
      telefono: telefono ?? this.telefono,
      precio: precio ?? this.precio,
      dia: dia ?? this.dia,
      imageUrl: imageUrl ?? this.imageUrl,
      eventoUrl: eventoUrl ?? this.eventoUrl,
      googleUrl: googleUrl ?? this.googleUrl,
      wwwUrl: wwwUrl ?? this.wwwUrl,
      tipo: tipo ?? this.tipo,
      facebook: facebook ?? this.facebook,
      instagram: instagram ?? this.instagram,
      email: email ?? this.email,
      xUrl: xUrl ?? this.xUrl,
    );
  }

  @override
  List<Object?> get props => [
        id,
        nombreRutaPadre,
        restaurante,
        evento,
        tapa,
        sinopsis,
        direccion,
        ciudad,
        provincia,
        comunidad,
        telefono,
        precio,
        dia,
        imageUrl,
        eventoUrl,
        googleUrl,
        wwwUrl,
        tipo,
        facebook,
        instagram,
        email,
        xUrl,
      ];

  @override
  bool get stringify => true;
}
