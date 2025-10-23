import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/lavorazioni_store.dart';

class InserisciModificaLavorazioniScreen extends StatefulWidget {
  const InserisciModificaLavorazioniScreen({super.key});
  @override
  State<InserisciModificaLavorazioniScreen> createState() =>
      _InserisciModificaLavorazioniScreenState();
}

class _InserisciModificaLavorazioniScreenState
    extends State<InserisciModificaLavorazioniScreen> {
  final store = LavorazioniStore.instance;

  final _tipoCtrl = TextEditingController();
  final _dicituraCtrl = TextEditingController();
  final _prezzoCtrl = TextEditingController();

  String? _editingId; // <— traccio l’id del doc in modifica

  @override
  void dispose() {
    _tipoCtrl.dispose();
    _dicituraCtrl.dispose();
    _prezzoCtrl.dispose();
    super.dispose();
  }

  double? _num(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  void _reset() {
    setState(() {
      _editingId = null;
      _tipoCtrl.clear();
      _dicituraCtrl.clear();
      _prezzoCtrl.clear();
    });
  }

  Future<void> _salva() async {
    final tipo = _tipoCtrl.text.trim();
    final dic = _dicituraCtrl.text.trim();
    final prezzo = _num(_prezzoCtrl.text);

    if (tipo.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inserisci il tipo')));
      return;
    }
    if (prezzo == null || prezzo <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Prezzo non valido')));
      return;
    }

    final lav = Lavorazione(
      tipo: tipo,
      prezzo: prezzo,
      dicitura: dic.isEmpty ? null : dic,
    );

    try {
      if (_editingId == null) {
        await store.add(lav);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lavorazione aggiunta')));
      } else {
        await store.update(_editingId!, lav);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Lavorazione aggiornata')));
      }
      _reset();
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore salvataggio: $e')));
    }
  }

  void _caricaPerEdit(Lavorazione l) {
    setState(() {
      _editingId = l.id;
      _tipoCtrl.text = l.tipo;
      _dicituraCtrl.text = l.dicitura ?? '';
      _prezzoCtrl.text = l.prezzo.toStringAsFixed(2);
    });
  }

  Future<void> _elimina(String id) async {
    try {
      await store.delete(id);
      if (_editingId == id) _reset();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Lavorazione eliminata')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore eliminazione: $e')));
    }
  }

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
            // FORM
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _tipoCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Tipo',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _dicituraCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Dicitura (opzionale)',
                      hintText: 'es. “Solo pareti interne”',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _prezzoCtrl,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'Prezzo',
                      prefixText: '€ ',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _salva,
                          icon: const Icon(Icons.save),
                          label: Text(
                            _editingId == null ? 'Aggiungi' : 'Aggiorna',
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton(
                        onPressed: _reset,
                        child: const Text('Annulla'),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // LISTA — si aggiorna da sola via snapshots()
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
                        trailing: Wrap(
                          spacing: 4,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.edit),
                              tooltip: 'Modifica',
                              onPressed: () => _caricaPerEdit(l),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete),
                              tooltip: 'Elimina',
                              onPressed: () => _elimina(l.id),
                            ),
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
