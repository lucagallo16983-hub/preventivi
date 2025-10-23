import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';

import 'screens/home_screen.dart';
import 'screens/lavorazioni_screen.dart';
import 'screens/crea_preventivo_screen.dart';
import 'screens/preventivi_salvati_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(const PreventiviApp());
}

class PreventiviApp extends StatelessWidget {
  const PreventiviApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Preventivi',
      debugShowCheckedModeBanner: false,
      home: const HomeScreen(),
      routes: {
        '/lavorazioni': (_) => const InserisciModificaLavorazioniScreen(),
        '/crea': (_) => const CreaPreventivoScreen(),
        '/salvati': (_) => const PreventiviSalvatiScreen(), // <— aggiunta
      },
    );
  }
}
