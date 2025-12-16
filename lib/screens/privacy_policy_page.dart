/// Pantalla que muestra el descargo de responsabilidad y la política de privacidad.
///
/// Esta pantalla presenta al usuario los términos de uso y la política de privacidad
/// de la aplicación. Se accede a ella desde el menú lateral para su consulta.
library;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arituki/screens/startup_ad_gate.dart';

class PrivacyPolicyPage extends StatelessWidget {
  final bool isFirstTime;

  const PrivacyPolicyPage({super.key, this.isFirstTime = false});

  Future<void> _acceptTerms(BuildContext context) async {
    final navigator = Navigator.of(context);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('privacy_policy_accepted', true);
    
    if (!navigator.mounted) return;
    navigator.pushReplacement(MaterialPageRoute(builder: (context) => const StartupAdGate()));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final headlineStyle = theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold);
    final bodyStyle = theme.textTheme.bodyLarge;
    final italicStyle = theme.textTheme.bodySmall?.copyWith(fontStyle: FontStyle.italic);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Términos y Privacidad'),
        automaticallyImplyLeading: !isFirstTime, // No muestra el botón de atrás si es la primera vez
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Descargo de Responsabilidad', style: headlineStyle),
                  const SizedBox(height: 10),
                  Text('Última actualización: 24 de Octubre de 2023', style: italicStyle),
                  const SizedBox(height: 10),
                  Text(
                    'La información presentada en Arituki (la "Aplicación") sobre eventos, cines, gastronomía y otros se obtiene a través de fuentes de acceso público y, en ocasiones, a través de APIs públicas. Hacemos todo lo posible por mantener la información actualizada y precisa, pero no podemos garantizarlo.\n\n'
                    'Arituki no se hace responsable de posibles inexactitudes, cambios de horarios, precios incorrectos, cancelaciones de eventos u otra información errónea. Le recomendamos encarecidamente que verifique siempre los detalles importantes directamente con la fuente oficial (el organizador del evento, el cine, el restaurante, etc.) antes de tomar cualquier decisión.\n\n'
                    'La Aplicación puede contener enlaces a sitios web de terceros (por ejemplo, para la compra de entradas o para obtener más información). No tenemos control sobre el contenido o las prácticas de estos sitios y no asumimos ninguna responsabilidad por ellos.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                  const SizedBox(height: 30),
                  Text('Política de Privacidad', style: headlineStyle),
                  const SizedBox(height: 10),
                  Text('Última actualización: 24 de Octubre de 2023', style: italicStyle),
                  const SizedBox(height: 10),
                  Text(
                    'Su privacidad es importante para nosotros. Esta política explica qué información recopilamos y cómo la usamos.\n\n'
                    '1. Información que recopilamos:\n'
                    '   - Identificador Anónimo: Para usar funciones como "me gusta" o "no me gusta", la aplicación utiliza un identificador anónimo y temporal que no está vinculado a su información personal. Este proceso es gestionado por nuestro proveedor de autenticación, Supabase.\n'
                    '   - Datos de uso anónimos: Usamos Firebase Analytics para recopilar datos anónimos sobre cómo interactúa con la Aplicación (qué pantallas visita, qué funciones usa, etc.). Esto nos ayuda a entender qué es lo más útil y a mejorar la experiencia.\n'
                    '   - Datos para anuncios: La aplicación muestra anuncios a través de Google AdMob, que puede recopilar y usar datos anónimos para mostrarle publicidad relevante.\n\n'
                    '2. Cómo usamos su información:\n'
                    '   - El identificador anónimo se usa exclusivamente para gestionar sus interacciones (likes/dislikes).\n'
                    '   - Los datos anónimos de uso y de anuncios se utilizan para el funcionamiento, mantenimiento y mejora de la Aplicación.\n\n'
                    '3. Con quién compartimos su información:\n'
                    '   No vendemos ni compartimos su información personal. Los datos son procesados por nuestros proveedores de servicios de confianza, quienes tienen sus propias políticas de privacidad:\n'
                    '   - Supabase (Autenticación)\n'
                    '   - Google Analytics (Analíticas de uso)\n'
                    '   - Google AdMob (Publicidad)\n\n'
                    '4. Seguridad:\n'
                    '   Tomamos medidas razonables para proteger su información, pero ningún método de transmisión por internet es 100% seguro.\n\n'
                    '5. Contacto:\n'
                    '   Si tiene alguna pregunta sobre esta política, puede contactarnos en arituki.app@gmail.com.\n\n'
                    'Al usar Arituki, usted acepta los términos de este Descargo de Responsabilidad y nuestra Política de Privacidad.',
                    style: bodyStyle,
                    textAlign: TextAlign.justify,
                  ),
                ],
              ),
            ),
          ),
          if (isFirstTime)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16.0),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                  ),
                  onPressed: () => _acceptTerms(context),
                  child: const Text('Aceptar y Continuar'),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
