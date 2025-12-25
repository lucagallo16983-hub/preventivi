import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/lavorazioni_store.dart';

class ListaLavorazioniScreen extends StatelessWidget {
  const ListaLavorazioniScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('lavorazioni')
        .orderBy('tipo');

    return Scaffold(
      appBar: AppBar(title: const Text('Lavorazioni')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Expanded(
              child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: query.snapshots(),
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Errore: ${snap.error}'));
                  }
                  if (!snap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final docs = snap.data!.docs;
                  if (docs.isEmpty) {
                    return const Center(child: Text('Nessuna lavorazione'));
                  }
                  final items = docs.map(Lavorazione.fromDoc).toList();

                  return ListView.separated(
                    itemCount: items.length,
                    separatorBuilder: (_, __) => const Divider(height: 16),
                    itemBuilder: (_, i) {
                      final l = items[i];
                      return ListTile(
                        title: Text(l.tipo),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((l.dicitura ?? '').isNotEmpty)
                              Text(l.dicitura!),
                            Text('€ ${l.prezzo.toStringAsFixed(2)}'),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
