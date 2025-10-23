import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Preventivi')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () =>
                        Navigator.pushNamed(context, '/lavorazioni'),
                    icon: const Icon(Icons.build),
                    label: const Text('Inserisci / Modifica lavorazioni'),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/crea'),
                    icon: const Icon(Icons.add),
                    label: const Text('Crea preventivo'),
                  ),
                ),
                const SizedBox(height: 12),
                // <<< NUOVO BOTTONE
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/salvati'),
                    icon: const Icon(Icons.folder_open),
                    label: const Text('Preventivi salvati'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
