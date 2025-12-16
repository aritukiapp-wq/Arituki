import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:arituki/screens/privacy_policy_page.dart';
import 'package:arituki/screens/startup_ad_gate.dart';


class PolicyGate extends StatelessWidget {
  const PolicyGate({super.key});

  @override
  Widget build(BuildContext context) {
    final prefs = context.read<SharedPreferences>();
    final hasAcceptedPolicy = prefs.getBool('privacy_policy_accepted') ?? false;

    // Si el usuario ya ha aceptado la política, vamos a la puerta de anuncios.
    // De lo contrario, le mostramos la página de la política.
    if (hasAcceptedPolicy) {
      return const StartupAdGate();
    } else {
      return const PrivacyPolicyPage(isFirstTime: true);
    }
  }
}
