import 'package:flutter/material.dart';
import '../data/lavorazioni_store.dart';
import '../data/preventivi_store.dart';

class CreaPreventivoScreen extends StatefulWidget {
  const CreaPreventivoScreen({super.key});
  @override
  State<CreaPreventivoScreen> createState() => _CreaPreventivoScreenState();
}

class _CreaPreventivoScreenState extends State<CreaPreventivoScreen> {
  final lavStore = LavorazioniStore.instance;
  final prevStore = PreventiviStore.instance;

  final _nomeController = TextEditingController(); // <<— AGGIUNTO
  Lavorazione? _selectedLav;
  final _mqController = TextEditingController();
  final List<RigaPreventivo> _righe = <RigaPreventivo>[];

  @override
  void dispose() {
    _nomeController.dispose(); // <<— AGGIUNTO
    _mqController.dispose();
    super.dispose();
  }

  double? _parseNum(String s) => double.tryParse(s.trim().replaceAll(',', '.'));

  void _addRiga() {
    if (_selectedLav == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleziona una lavorazione')),
      );
      return;
    }
    final mq = _parseNum(_mqController.text);
    if (mq == null || mq <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Inserisci mq validi')));
      return;
    }
    setState(() {
      _righe.add(RigaPreventivo(lavorazione: _selectedLav!, mq: mq));
      _mqController.clear();
    });
  }

  void _removeRiga(int i) => setState(() => _righe.removeAt(i));

  double get _totale => _righe.fold(0, (p, r) => p + r.subtotale);

  void _salva() {
    final nome = _nomeController.text.trim(); // <<— AGGIUNTO
    if (nome.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inserisci il nome del preventivo')),
      );
      return;
    }
    if (_righe.isEmpty) return;

    prevStore.add(
      Preventivo(
        // SE il tuo modello ha il campo, passa il nome qui:
        // es. titolo/nome/descrizione: usa quello che hai nel modello.
        titolo: nome, // <<— AGGIUNTO (se il modello prevede "titolo")
        righe: List<RigaPreventivo>.from(_righe),
        createdAt: DateTime.now(),
      ),
    );

    setState(() {
      _righe.clear();
      _nomeController.clear();
    });
    Navigator.pushNamed(context, '/salvati');
  }

  @override
  Widget build(BuildContext context) {
    final items = lavStore.items;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Crea preventivo'),
        leading: BackButton(onPressed: () => Navigator.of(context).maybePop()),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: items.isEmpty
            ? Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('Nessuna lavorazione. Aggiungila prima.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () =>
                          Navigator.pushNamed(context, '/lavorazioni'),
                      child: const Text('Apri Lavorazioni'),
                    ),
                  ],
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // NOME PREVENTIVO  <<— AGGIUNTO
                  TextField(
                    controller: _nomeController,
                    decoration: const InputDecoration(
                      labelText: 'Nome preventivo',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // LAVORAZIONE (solo nome, niente prezzo)
                  DropdownButtonFormField<Lavorazione>(
                    key: const ValueKey('lavorazioneDropdownV2'),
                    value: _selectedLav,
                    isExpanded: true,
                    items: items
                        .map(
                          (l) => DropdownMenuItem<Lavorazione>(
                            value: l,
                            child: Text(
                              l.tipo,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        )
                        .toList(),
                    selectedItemBuilder: (context) => items
                        .map<Widget>(
                          (l) => Text(l.tipo, overflow: TextOverflow.ellipsis),
                        )
                        .toList(),
                    onChanged: (v) => setState(() => _selectedLav = v),
                    decoration: const InputDecoration(
                      labelText: 'Lavorazione',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // MQ sotto alla lavorazione (tutta larghezza)
                  TextField(
                    controller: _mqController,
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(
                      labelText: 'mq',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Bottone Aggiungi riga sotto (tutta larghezza)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _addRiga,
                      child: const Text('Aggiungi riga'),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Righe del preventivo
                  Expanded(
                    child: _righe.isEmpty
                        ? const Center(child: Text('Nessuna riga aggiunta'))
                        : ListView.separated(
                            itemCount: _righe.length,
                            separatorBuilder: (_, __) =>
                                const Divider(height: 16),
                            itemBuilder: (context, i) {
                              final r = _righe[i];
                              return ListTile(
                                title: Text(
                                  '${r.lavorazione.tipo}  —  € ${r.lavorazione.prezzo.toStringAsFixed(2)}',
                                ),
                                subtitle: Text(
                                  'mq: ${r.mq.toStringAsFixed(2)}   •   Subtotale: € ${r.subtotale.toStringAsFixed(2)}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _removeRiga(i),
                                ),
                              );
                            },
                          ),
                  ),

                  // Totale + Salva
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Totale: € ${_totale.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      ElevatedButton(
                        onPressed: _righe.isEmpty ? null : _salva,
                        child: const Text('Salva preventivo'),
                      ),
                    ],
                  ),
                ],
              ),
      ),
    );
  }
}
