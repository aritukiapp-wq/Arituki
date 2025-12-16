/// Pantalla para visualizar una imagen a pantalla completa.
///
/// Esta pantalla recibe la URL de una imagen y un "tag" de Hero para crear una
/// animación de transición suave desde la vista anterior. Permite al usuario
/// hacer zoom y panorámica sobre la imagen (`InteractiveViewer`). Incluye un
/// botón para cerrar la vista y volver a la pantalla anterior.
library;
import 'package:flutter/material.dart';

class FullscreenImagePage extends StatelessWidget {
  final String imageUrl;
  final String tag; // Usaremos un tag para la animación de Hero

  const FullscreenImagePage({
    super.key,
    required this.imageUrl,
    required this.tag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo negro para la vista de imagen
      body: Stack( // Usamos Stack para colocar la imagen y el botón de cerrar
        children: [
          // Imagen centrada que ocupa el máximo espacio posible
          Center(
            child: Hero( // <--- Widget Hero para una animación suave al hacer clic
              tag: tag, // Debe coincidir con el tag del Hero en EventDetailPage
              child: InteractiveViewer(
                panEnabled: true,
                minScale: 1.0,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  // Asegura que la imagen completa sea visible sin recortar
                  errorBuilder: (context, error, stackTrace) =>
                  const Center(
                    child: Icon(Icons.error, color: Colors.red,
                        size: 50), // Icono de error si la imagen no carga
                  ),
                  loadingBuilder: (BuildContext context, Widget child,
                      ImageChunkEvent? loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                            : null,
                        color: Colors
                            .white, // Indicador de carga blanco sobre fondo negro
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // Botón de cerrar en la esquina superior izquierda
          Positioned(
            top: 40, // Ajusta el padding superior según sea necesario
            left: 20, // Ajusta el padding izquierdo según sea necesario
            child: SafeArea( // Para evitar la barra de estado y notches
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () {
                  Navigator.pop(
                      context); // Cierra esta pantalla y regresa a la anterior
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}