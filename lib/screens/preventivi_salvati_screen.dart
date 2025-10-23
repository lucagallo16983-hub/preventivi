import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/preventivi_store.dart';
import '../pdf/pdf_preventivo_screen.dart';

class PreventiviSalvatiScreen extends StatelessWidget {
  const PreventiviSalvatiScreen({super.key});

  String _fmtDate(DateTime dt) {
    String two(int n) => n < 10 ? '0$n' : '$n';
    dt = dt.toLocal();
    return '${two(dt.day)}/${two(dt.month)}/${dt.year} ${two(dt.hour)}:${two(dt.minute)}';
  }

  Future<void> _confirmDelete(BuildContext context, Preventivo p) async {
    final canDelete = p.id.isNotEmpty;
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossibile eliminare: ID mancante.')),
      );
      return;
    }

    final yes = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Elimina preventivo'),
        content: Text(
          'Vuoi eliminare definitivamente questo preventivo?\n\n'
          '${p.titolo.isNotEmpty ? p.titolo : _fmtDate(p.createdAt)}',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Annulla'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Elimina'),
          ),
        ],
      ),
    );

    if (yes != true) return;

    try {
      await PreventiviStore.instance.delete(p.id);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Preventivo eliminato.')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Errore eliminazione: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final query = FirebaseFirestore.instance
        .collection('preventivi')
        .orderBy('createdAt', descending: true);

    return Scaffold(
      appBar: AppBar(title: const Text('Preventivi salvati')),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: query.snapshots(),
        builder: (context, snap) {
          if (snap.hasError)
            return Center(child: Text('Errore: ${snap.error}'));
          if (!snap.hasData)
            return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          if (docs.isEmpty)
            return const Center(child: Text('Nessun preventivo salvato'));

          final items = docs.map(Preventivo.fromDoc).toList();

          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final p = items[i];
              final title = (p.titolo.isNotEmpty)
                  ? p.titolo
                  : 'Preventivo del ${_fmtDate(p.createdAt)}';

              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header riga: titolo/nome + totale + azioni
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          Text(
                            'Totale: € ${p.totale.toStringAsFixed(2)}',
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(width: 4),
                          IconButton(
                            tooltip: 'PDF',
                            icon: const Icon(Icons.picture_as_pdf),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => PdfPreventivoScreen(
                                    preventivo: p,
                                    spettabile: 'Cliente / Azienda',
                                    preventivoPer: 'Oggetto lavori',
                                    descrizione: 'Descrizione generale…',
                                    condizioni:
                                        'Es: 30% acconto, saldo a fine lavori',
                                    mostraIva: true,
                                    aliquotaIva: 0.22,
                                  ),
                                ),
                              );
                            },
                          ),
                          IconButton(
                            tooltip: 'Elimina',
                            icon: const Icon(Icons.delete_forever_outlined),
                            onPressed: () => _confirmDelete(context, p),
                          ),
                        ],
                      ),

                      // Sottotitolo con data
                      const SizedBox(height: 4),
                      Text(
                        'Creato il ${_fmtDate(p.createdAt)}',
                        style: const TextStyle(
                          color: Colors.black54,
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 8),
                      const Divider(height: 1),
                      const SizedBox(height: 8),

                      // Righe del preventivo
                      ...p.righe.map((r) {
                        final sub = r.subtotale;
                        final titoloRiga =
                            (r.lavorazione.dicitura != null &&
                                r.lavorazione.dicitura!.isNotEmpty)
                            ? '${r.lavorazione.tipo} — ${r.lavorazione.dicitura}'
                            : r.lavorazione.tipo;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  titoloRiga,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '€ ${r.lavorazione.prezzo.toStringAsFixed(2)}',
                              ),
                              const SizedBox(width: 8),
                              Text('mq ${r.mq.toStringAsFixed(2)}'),
                              const SizedBox(width: 8),
                              Text('€ ${sub.toStringAsFixed(2)}'),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
