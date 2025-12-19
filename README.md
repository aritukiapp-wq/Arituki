# Arituki 🚀

Arituki es una aplicación móvil moderna desarrollada con **Flutter**, diseñada para ofrecer una experiencia fluida y eficiente en la gestión de eventos y lugares.

## 🛠️ Tecnologías utilizadas

Esta aplicación utiliza un stack tecnológico robusto y escalable:

*   **Frontend:** [Flutter](https://flutter.dev/) - Framework para el desarrollo multiplataforma.
*   **Gestión de Estado:** [Provider](https://pub.dev/packages/provider) - Solución flexible y eficiente para el manejo de estados.
*   **Backend:** [Supabase](https://supabase.com/) - Alternativa de código abierto a Firebase para la base de datos y autenticación.
*   **Servicios Cloud:**
    *   **Firebase Analytics:** Para el seguimiento de métricas y comportamiento del usuario.
    *   **Firebase Crashlytics:** Para el reporte y análisis de errores en tiempo real.
*   **Monetización:** **Google Mobile Ads** - Integración de anuncios nativos y de apertura.
*   **Persistencia Local:** **SharedPreferences** - Para el almacenamiento de preferencias de usuario y datos ligeros.

## 🏗️ Arquitectura del Proyecto

El proyecto sigue una estructura limpia y organizada para facilitar el mantenimiento y la escalabilidad:

*   `lib/services`: Lógica de negocio y comunicación con APIs externas.
*   `lib/providers`: Gestión del estado reactivo de la aplicación.
*   `lib/repositories`: Abstracción de la capa de datos.
*   `lib/screens`: Definición de la interfaz de usuario por pantallas.
*   `lib/theme`: Configuración centralizada de estilos y temas (claro/oscuro).

## 🚀 Cómo empezar

1.  **Clonar el repositorio:**
    ```bash
    git clone https://github.com/aritukiapp-wq/Arituki.git
    ```
2.  **Instalar dependencias:**
    ```bash
    flutter pub get
    ```
3.  **Configuración:** Asegúrate de configurar correctamente los archivos de configuración para Firebase (`google-services.json` / `GoogleService-Info.plist`) y las claves de Supabase en `lib/config.dart`.
4.  **Ejecutar la app:**
    ```bash
    flutter run
    ```

## 📈 Estado del Proyecto

Actualmente, la aplicación se encuentra en desarrollo activo, con funcionalidades implementadas de filtrado por localización, gestión de favoritos, integración de anuncios y sistema de reporte de errores.
